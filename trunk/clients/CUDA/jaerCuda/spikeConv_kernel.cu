/* jaercuda project for running AER convolution processing on the GPU. 
    From template project which demonstrates the basics on how to setup a project 
 * example application.
 * Device code. This file is #included from template.cu.
 */

#ifndef _TEMPLATE_KERNEL_H_
#define _TEMPLATE_KERNEL_H_

#include <stdio.h>
#include "config.h"


// this should not be a device pointer, it should be a host pointer which is cudaMalloc'ed and which has data copied to it from the host, then bound as texture
// we cannot refer to this data here except by texFetch1d
texture <float> template_tex;
//__device__ float gpu_conv_template[MAX_NUM_TEMPLATE][MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE]; // TODO tobi changed to cudaMalloc so that memory is accessible, may cause problems

__device__ float gpu_membranePotential[MAX_NUM_TEMPLATE][MAX_Y][MAX_X];
__device__ unsigned long gpu_lastTimeStamp[MAX_Y][MAX_X];

__constant__ __device__ globalNeuronParams_t constNeuronParams;

__constant__ __device__ int const_num_object; 
__constant__ __device__ int const_radius_loc_inh;
__constant__ __device__ int const_size_loc_inh;

__device__ int   numFiring0[MAX_NUM_TEMPLATE];
__device__ int   numFiring1[MAX_NUM_TEMPLATE];     
__device__ int   gpu_curNumFiring[MAX_NUM_TEMPLATE][MAX_Y][MAX_X]; // the number of generated spikes during current kernel cycle
__device__ unsigned int   firedNeuronAddr[MAX_NUM_TEMPLATE*MAX_FIRING]; // holds output spikes from each template

/** This method implements part of the winner-take-all functionality within each population.
 * The CPU calls this kernel whenever some neurons in the neuron array has fired.
 * Each thread is responsible for inhibition of one neuron potential by iESynWeight amount.
 * Finally each thread clamps the membrane potential to stay within a specific value.
 * We use a ID grid of 128x1 thread and 128*num_object block to have simple addressing mechanism.
 * 2D block of thread can also do similar computation but kernel needs slightly more address calculations.
 * @param:  numFiringAddr		the array recording the number of spikes generated within each population during the current cycle
 * @param:	iNeuronFired		each bit records if the global inhibitory neuron of the corresponding excitatory population has fired during the last cycle
 **/
__global__ void WTAKernelMO(int* numFiringAddr, char iNeuronFired) 
{	
	// Thread index
	int my_addrx = threadIdx.x; // this thread handles neuron (x,y)=(threadIdx.x, blockIdx.x)
	int my_addry = blockIdx.x;
	int neuronArrayId = blockIdx.y;
	
	// check if the global inhibitory neuron of a particular population fired
	char iFired = (char)(iNeuronFired & (0x01<<neuronArrayId));

	if(iFired){
		float temp = gpu_membranePotential[neuronArrayId][my_addry][my_addrx]; // membrane potential of an LIF neuron for one template array

		temp -= constNeuronParams.iESynWeight; // reduce it by the iE weight (inhibitory to excitatory)
		
		if ( temp < constNeuronParams.membranePotentialMin )
			// clamp it to negative driving potential (negative weight can never make it fire)
			temp = constNeuronParams.membranePotentialMin; 
			
		gpu_membranePotential[neuronArrayId][my_addry][my_addrx] = temp;
	}		
}

/** This method implements part of the global winner-take-all functionality among populations.
 * The CPU calls this kernel whenever some neurons in the neuron array has fired.
 * Each thread is responsible for inhibition of one neuron potential by iESynWeight amount.
 * Finally each thread clamps the membrane potential to stay within a specific value.
 * We use a ID grid of 128x1 thread and 128*num_object block to have simple addressing mechanism.
 * 2D block of thread can also do similar computation but kernel needs slightly more address calculations.
 * @param:  numFiringAddr		the array recording the number of spikes generated within each population during the current cycle
 * @param:	n_iNeuronFired		the number of spikes the global inhibitory neuron fired during the current cycle
 **/
__global__ void WTAKernelMOGlob(int* numFiringAddr, int n_iNeuronFired) 
{	
	// Thread index
	int my_addrx = threadIdx.x; // this thread handles neuron (x,y)=(threadIdx.x, blockIdx.x)
	int my_addry = blockIdx.x;
	int neuronArrayId = blockIdx.y;
	
	// check if the global inhibitory neuron of a particular population fired

	if(n_iNeuronFired != 0){
		float temp = gpu_membranePotential[neuronArrayId][my_addry][my_addrx]; // membrane potential of an LIF neuron for one template array

		temp -= n_iNeuronFired*constNeuronParams.iESynWeight; // reduce it by the iE weight (inhibitory to excitatory)
		
		if ( temp < constNeuronParams.membranePotentialMin )
			// clamp it to negative driving potential (negative weight can never make it fire)
			temp = constNeuronParams.membranePotentialMin; 
			
		gpu_membranePotential[neuronArrayId][my_addry][my_addrx] = temp;
	}		
}

// this array stores the incoming spikes from CPU...
__device__ int gpu_spikeAddr[GPU_MAX_SPIKE_PACKETS];
__device__ unsigned long gpu_spikeTime[GPU_MAX_SPIKE_PACKETS];


/** This kernel is to update the excitatory neurons within each population
 * @param:	numInpSpikes		total number of input spikes within current cycle
 * @param:  numFiringAddr		the array recording the number of spikes generated within each population during the current cycle
 * @param:	resetAddr			the array recording the number of spikes generated within each population during the last cycle, needs to be reset during the kernel call
 **/
__global__ void
convNN_multiSpike_Kernel(int  numInpSpikes,			// length of the spikes given to GPU
						 int* numFiringArr,			// pointer to number of fired neurons
													// initial value is zero before calling
						 int* resetAddr)			// This memory will be reset to zero by GPU						
					
{	
	
	//TODO: This code is specific to an image of size 128, with 8 blocks
	//each operating 16x16 pixel array.
	/* blockIdx.x,blockIdx.y can range from 0-31 */
	int my_addrx = blockIdx.x*MAX_SUB_TEMPLATE_SIZE_X + threadIdx.x;
	int my_addry = (blockIdx.y&0x7)*MAX_SUB_TEMPLATE_SIZE_Y + threadIdx.y;
	
	//We encode the object dimension in blockId itself.last 3 bit denotes
	//block number, the remaining bits denote the object number neuronArrayId
	int neuronArrayId = (blockIdx.y>>3);
	
    int my_localId = threadIdx.y*blockDim.x+threadIdx.x; // unique local id within a block

	// only one thread is updated to reduce the global memory access
	if (my_localId == 0) {		
		resetAddr[neuronArrayId]=0; // FAQ: why is the kernel doing this, what is resetAddr??? it's not used further in the kernel
									// we use a simple double buffering scheme. this address will be passed as
									// numFiringArr address during the next kernel call. We can save a cudaMemcpy or cudaMemset
									// by the CPU for reseting the number of firing by this mechanism.
	}
		
   __syncthreads();
   
   __shared__ unsigned long curSpikeTime;
   __shared__ unsigned int curSpikeAddr;

   unsigned long ltStamp = 0;
   // retreive the membrane potential
   ltStamp = gpu_lastTimeStamp[my_addry][my_addrx];
   
   // retreive the initial value of the membrane potential and multiply by decay value
   float refValue  = gpu_membranePotential[neuronArrayId][my_addry][my_addrx];

   // for each spike from CPU
   for(int spkCnt=0; spkCnt < numInpSpikes;spkCnt++) {

		// only one thread within a block does the exponential operation
	    if(my_localId == 0) {
			curSpikeTime = gpu_spikeTime[spkCnt];
			curSpikeAddr = gpu_spikeAddr[spkCnt];
		}

		__syncthreads();
		
		unsigned long timeDiff = curSpikeTime-ltStamp;
		float temp = (float)(timeDiff/constNeuronParams.membraneTau);
		float decayFactor = __expf(-temp);
	
		// read the spike for spike buffer and calulate x and y address
		unsigned int addrx = curSpikeAddr&0xff;
		unsigned int addry = (curSpikeAddr>>8)&0xff;		

		int offSetAddrX = my_addrx - (addrx - (MAX_TEMPLATE_SIZE/2) + 1); 
		int offSetAddrY = my_addry - (addry - (MAX_TEMPLATE_SIZE/2) + 1); 
			
		// check if the neuron address is within the 
		// valid range where modification is going to happen
		// due to convolution operation
		if (offSetAddrX >= 0 &&
			offSetAddrY >= 0 &&
			offSetAddrX < MAX_TEMPLATE_SIZE &&
			offSetAddrY < MAX_TEMPLATE_SIZE ) {

			/* we can read the template and get a valid data */
			int texPos = neuronArrayId*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + offSetAddrY*MAX_TEMPLATE_SIZE + offSetAddrX; 

			float weight=tex1D(template_tex, texPos); // TODO always returns 0 now

			// weights can be positive or negative based on the template type		
			refValue = refValue*decayFactor + weight; 
		
			ltStamp = curSpikeTime;

			// neuron's membrane potential value exceeds the threshold value
			// and hence the neuron should fire and reset
			if (refValue > constNeuronParams.threshold)  {
				refValue = 0.0;
				// increment the current kernel call's firing count
				int fireId = atomicAdd(&numFiringArr[neuronArrayId], 1);		// returns the *old* value of numFiring in fireId
				
				// store the fired neuron's id in the firing table
				// TODO: include the objId along with the array for rendering by jAER
				// TODO check that templateId is correct here as MSB of addr
				if(fireId<MAX_FIRING){ //  bounds check on output, TODO check is that correct with multi templates???
					firedNeuronAddr[neuronArrayId*MAX_FIRING+fireId] = (neuronArrayId<<16)+(my_addry<<8)+ my_addrx;
				}
			}
			// neuron's membrane potential value is lower than the threshold value hence saturate...
			else if (refValue < constNeuronParams.membranePotentialMin)
				refValue = constNeuronParams.membranePotentialMin;
		}
   }

   // only one thread writes down the timeStamp value.
   // TODO: currently we store the time corresponding to the first spike
   // should this be the last spike ????
   if(neuronArrayId == 0)
		gpu_lastTimeStamp[my_addry][my_addrx] = ltStamp;			   
   
   // write back the calculated refValue    
   gpu_membranePotential[neuronArrayId][my_addry][my_addrx] = refValue;
}

/** This kernel is to update neurons (from different populations) at the same position together, and add in lateral inhibition between these neurons for each input spike
 * @param:	numInpSpikes		total number of input spikes within current cycle
 * @param:  numFiringAddr		the array recording the number of spikes generated within each population during the current cycle
 * @param:	resetAddr			the array recording the number of spikes generated within each population during the last cycle, needs to be reset during the kernel call
 **/
__global__ void
convNN_LocalWTA_Kernel(int  numInpSpikes,		// length of the spikes given to GPU
						 int* numFiringArr,			// pointer to number of fired neurons
													// initial value is zero before calling
						 int* resetAddr)			// This memory will be reset to zero by GPU						
					
{	
	
	//TODO: This code is specific to an image of size 128, with 8 blocks
	//each operating 16x16 pixel array.
	/* blockIdx.x,blockIdx.y can range from 0-31 */
	int my_addrx = blockIdx.x*MAX_SUB_TEMPLATE_SIZE_X + threadIdx.x;
	int my_addry = (blockIdx.y&0x7)*MAX_SUB_TEMPLATE_SIZE_Y + threadIdx.y;
		
    int my_localId = threadIdx.y*blockDim.x+threadIdx.x; // unique local id within a block

	int i,j,spkCnt;
	// only one thread is updated to reduce the global memory access
	if (my_localId == 0) {
		for(i = 0 ; i < const_num_object; i++){
			resetAddr[i]=0; // FAQ: why is the kernel doing this, what is resetAddr??? it's not used further in the kernel
										// we use a simple double buffering scheme. this address will be passed as
										// numFiringArr address during the next kernel call. We can save a cudaMemcpy or cudaMemset
										// by the CPU for reseting the number of firing by this mechanism.
		}
	}
		
   __syncthreads();
   
   __shared__ unsigned long curSpikeTime;
   __shared__ unsigned int curSpikeAddr;

   unsigned long ltStamp = 0;
   // retreive the membrane potential
   ltStamp = gpu_lastTimeStamp[my_addry][my_addrx];
   
   // retreive the initial value of the membrane potential and multiply by decay value
	float refValue[MAX_NUM_TEMPLATE];
	char b_NeuronFired; // each bit record if the neuron in each population is fired due to the current input spike
	for(i = 0; i < const_num_object; i++){
		refValue[i]  = gpu_membranePotential[i][my_addry][my_addrx];
	}
	
	// calulate the membrane potential for each input spikes
    for(spkCnt=0; spkCnt < numInpSpikes;spkCnt++) {
   		
   		if(my_localId == 0) {
			curSpikeTime = gpu_spikeTime[spkCnt];
			curSpikeAddr = gpu_spikeAddr[spkCnt];
		}

		__syncthreads();
		
		b_NeuronFired = 0; // reset the spike flags
		
		unsigned long timeDiff = curSpikeTime-ltStamp;
		float decayFactor = __expf((float)(timeDiff/constNeuronParams.membraneTau)*(-1.0f));
		   								
		// read the spike for spike buffer and calulate x and y addresst
		unsigned int addrx = curSpikeAddr&0xff;
		unsigned int addry = (curSpikeAddr>>8)&0xff;		

		int offSetAddrX = my_addrx - (addrx - (MAX_TEMPLATE_SIZE/2) + 1); 
		int offSetAddrY = my_addry - (addry - (MAX_TEMPLATE_SIZE/2) + 1); 
			
		// check if the neuron address is within the 
		// valid range where modification is going to happen
		// due to convolution operation
		if (offSetAddrX >= 0 &&
			offSetAddrY >= 0 &&
			offSetAddrX < MAX_TEMPLATE_SIZE &&
			offSetAddrY < MAX_TEMPLATE_SIZE ) {
	
			ltStamp = curSpikeTime;
			
			for(i = 0 ; i < const_num_object; i++){
				/* we can read the template and get the weight */
				int texPos = i*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + offSetAddrY*MAX_TEMPLATE_SIZE + offSetAddrX; 
				float weight=tex1D(template_tex, texPos); // TODO always returns 0 now
				
				// weights can be positive or negative based on the template type		
				refValue[i] = refValue[i]*decayFactor + weight; 
			
				// neuron's membrane potential value exceeds the threshold value
				// and hence the neuron should fire and reset
				if (refValue[i] > constNeuronParams.threshold)  {
					refValue[i] = 0.0;
					// increment the current kernel call's firing count
					int fireId = atomicAdd(&numFiringArr[i], 1);		// returns the *old* value of numFiring in fireId
					
					b_NeuronFired = (char)(b_NeuronFired | (0x01 << i));
					
					// store the fired neuron's id in the firing table
					// TODO: include the objId along with the array for rendering by jAER
					// TODO check that templateId is correct here as MSB of addr
					if(fireId<MAX_FIRING){ //  bounds check on output, TODO check is that correct with multi templates???
						firedNeuronAddr[i*MAX_FIRING+fireId] = (i<<16)+(my_addry<<8)+ my_addrx;
					}
				}
				// neuron's membrane potential value is lower than the threshold value hence saturate...
				else if (refValue[i] < constNeuronParams.membranePotentialMin)
					refValue[i] = constNeuronParams.membranePotentialMin;
			}
			
			// if a spike is generated, inhibit all the neurons at the same location but in other populations 
			if(b_NeuronFired != 0){	 
				for(i = 0; i < const_num_object; i++){
					char neuronFired = (b_NeuronFired >> i) & (0x01);
					for(j = 0; j < const_num_object; j++){
						if(i != j){
							refValue[j] = refValue[j] - neuronFired * constNeuronParams.iESynWeight;
							if (refValue[i] < constNeuronParams.membranePotentialMin)
								refValue[i] = constNeuronParams.membranePotentialMin;
						}
					}
				}
			}
		}
	}
	
	for(i = 0; i < const_num_object; i++){   
	   // write back the calculated refValue    
	   gpu_membranePotential[i][my_addry][my_addrx] = refValue[i];
	}

   // only one thread writes down the timeStamp value.
   gpu_lastTimeStamp[my_addry][my_addrx] = ltStamp;			   
   
   
}

/** This kernel is to update neurons (from different populations) at the same position together, and add in lateral inhibition between these neurons for each input spike, 
 *  local inhibition between populations for each kernel call
 * @param:	numInpSpikes		total number of input spikes within current cycle
 * @param:  numFiringAddr		the array recording the number of spikes generated within each population during the current cycle
 * @param:	resetAddr			the array recording the number of spikes generated within each population during the last cycle, needs to be reset during the kernel call
 **/
__global__ void
convNN_LocalWTA_Kernel1(int  numInpSpikes,		// length of the spikes given to GPU
						 int* numFiringArr,			// pointer to number of fired neurons
													// initial value is zero before calling
						 int* resetAddr)			// This memory will be reset to zero by GPU						
					
{	
	
	//TODO: This code is specific to an image of size 128, with 8 blocks
	//each operating 16x16 pixel array.
	/* blockIdx.x,blockIdx.y can range from 0-31 */
	int my_addrx = blockIdx.x*MAX_SUB_TEMPLATE_SIZE_X + threadIdx.x;
	int my_addry = (blockIdx.y&0x7)*MAX_SUB_TEMPLATE_SIZE_Y + threadIdx.y;
		
    int my_localId = threadIdx.y*blockDim.x+threadIdx.x; // unique local id within a block

	int i,j,k,spkCnt;
	
	// only one thread is updated to reduce the global memory access
	if (my_localId == 0) {
		for(i = 0 ; i < const_num_object; i++){
			resetAddr[i]=0; 			// we use a simple double buffering scheme. this address will be passed as
										// numFiringArr address during the next kernel call. We can save a cudaMemcpy or cudaMemset
										// by the CPU for reseting the number of firing by this mechanism.
		}
	}

   __syncthreads();
	   
   __shared__ unsigned long curSpikeTime;
   __shared__ unsigned int curSpikeAddr;

   unsigned long ltStamp = 0;
   // retreive the membrane potential
   ltStamp = gpu_lastTimeStamp[my_addry][my_addrx];
   
   // retreive the initial value of the membrane potential and multiply by decay value
	float refValue[MAX_NUM_TEMPLATE];
	int curNumFiring[MAX_NUM_TEMPLATE]; //there are two functions for this variable
										// 1. accumulate the number of spikes generated during last kernel call from other populations within a local area centered by the neuron's location
										//	  this is to calculate the total amount of inhibition from last kernel call
										// 2. accumulate the number of spikes generated during the current kernel call from each population, and before quitting the kernel, write it back to gpu_curNumFiring
	char b_NeuronFired; // each bit record if the neuron in each population is fired due to the current input spike
	
	// count the number of inhibitory input spikes from last kernel cycle
	for(i = 0; i < const_num_object; i++){
		refValue[i]  = gpu_membranePotential[i][my_addry][my_addrx]; // get the membrane potential
		curNumFiring[i] = 0; // reset the counter for the accumulation of spikes generated during last kernel call from other populations
		
		for(k = -const_radius_loc_inh; k <= const_radius_loc_inh; k++){ // check the local area centered by the neuron's location
			int tmp_addrx = my_addrx + k;
			int tmp_addry = my_addry + k;
			if(tmp_addrx >= 0
				& tmp_addry >= 0
				& tmp_addrx < MAX_X
				& tmp_addry < MAX_Y){	// boundary check
				
				for(j = 0; j < const_num_object; j++){	// accumulate all the spikes generated from other populations
					if(j != i){
						curNumFiring[i] += gpu_curNumFiring[j][tmp_addry][tmp_addrx];
					}
				}
			}
		}
	}
	
	// calulate the membrane potential for each input spikes
    for(spkCnt=0; spkCnt < numInpSpikes;spkCnt++) {
   		
   		if(my_localId == 0) {
			curSpikeTime = gpu_spikeTime[spkCnt];
			curSpikeAddr = gpu_spikeAddr[spkCnt];
		}

		__syncthreads();
		
		b_NeuronFired = 0; // reset the spike flags
		
		unsigned long timeDiff = curSpikeTime-ltStamp;
		float decayFactor = __expf((float)(timeDiff/constNeuronParams.membraneTau)*(-1.0f));
		
		// at the beginning of the kernel call, calculate the amount of inhibition from the last kernel call
		if(spkCnt == 0){
			for(i = 0; i < const_num_object; i++){
				refValue[i] = (refValue[i] - curNumFiring[i] * constNeuronParams.iESynWeight) * decayFactor; // do not check the lower bound here, to maintain the real efficacy of inhibition
				curNumFiring[i] = 0;	// reset the counter again to be used for spike counting during current kernel call
			}
			
			// reset decay factor and last time stamp since the decay has been calculated
			decayFactor = 1;	
			ltStamp = curSpikeTime;	
		}
		   								
		// read the spike for spike buffer and calulate x and y addresst
		unsigned int addrx = curSpikeAddr&0xff;
		unsigned int addry = (curSpikeAddr>>8)&0xff;		

		int offSetAddrX = my_addrx - (addrx - (MAX_TEMPLATE_SIZE/2) + 1); 
		int offSetAddrY = my_addry - (addry - (MAX_TEMPLATE_SIZE/2) + 1); 
			
		// check if the neuron address is within the 
		// valid range where modification is going to happen
		// due to convolution operation
		if (offSetAddrX >= 0 &&
			offSetAddrY >= 0 &&
			offSetAddrX < MAX_TEMPLATE_SIZE &&
			offSetAddrY < MAX_TEMPLATE_SIZE ) {
	
			ltStamp = curSpikeTime;
			
			for(i = 0 ; i < const_num_object; i++){
				/* we can read the template and get the weight */
				int texPos = i*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + offSetAddrY*MAX_TEMPLATE_SIZE + offSetAddrX; 
				float weight=tex1D(template_tex, texPos); // TODO always returns 0 now
				
				// weights can be positive or negative based on the template type		
				refValue[i] = refValue[i]*decayFactor + weight; 
			
				// neuron's membrane potential value exceeds the threshold value
				// and hence the neuron should fire and reset
				if (refValue[i] > constNeuronParams.threshold)  {
					refValue[i] = 0.0;
					// increment the current kernel call's firing count
					int fireId = atomicAdd(&numFiringArr[i], 1);		// returns the *old* value of numFiring in fireId
					
					b_NeuronFired = (char)(b_NeuronFired | (0x01 << i)); // set the corresponding bit
					curNumFiring[i]++;	// increase the spike counter by 1
					
					// store the fired neuron's id in the firing table
					// TODO: include the objId along with the array for rendering by jAER
					// TODO check that templateId is correct here as MSB of addr
					if(fireId<MAX_FIRING){ //  bounds check on output, TODO check is that correct with multi templates???
						firedNeuronAddr[i*MAX_FIRING+fireId] = (i<<16)+(my_addry<<8)+ my_addrx;
					}
				}
				// neuron's membrane potential value is lower than the threshold value hence saturate...
				else if (refValue[i] < constNeuronParams.membranePotentialMin)
					refValue[i] = constNeuronParams.membranePotentialMin;
			}
			
			// if a spike is generated, inhibit all the neurons at the same location but in other populations 
			if(b_NeuronFired != 0){	
				for(i = 0; i < const_num_object; i++){
					char neuronFired = (b_NeuronFired >> i) & (0x01);
					for(j = 0; j < const_num_object; j++){
						if(i != j){
							refValue[j] = refValue[j] - neuronFired * constNeuronParams.iESynWeight;
							if (refValue[i] < constNeuronParams.membranePotentialMin)
								refValue[i] = constNeuronParams.membranePotentialMin;
						}
					}
				}
			}
		}
	}
	
	for(i = 0; i < const_num_object; i++){   
	   // write back the calculated refValue    
	   gpu_membranePotential[i][my_addry][my_addrx] = refValue[i];
	   gpu_curNumFiring[i][my_addry][my_addrx] = curNumFiring[i];
	}

   // only one thread writes down the timeStamp value.
   gpu_lastTimeStamp[my_addry][my_addrx] = ltStamp;			   
   
   
}

#endif // #ifndef _TEMPLATE_KERNEL_H_
