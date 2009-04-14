/* jaercuda project for running AER convolution processing on the GPU. 
    From template project which demonstrates the basics on how to setup a project 
 * example application.
 * Device code. This file is #included from template.cu.
 */

#ifndef _TEMPLATE_KERNEL_H_
#define _TEMPLATE_KERNEL_H_

#include <stdio.h>
#include "config.h"

#define SDATA( index)      CUT_BANK_CHECKER(sdata, index)

#define CHECK_COALESE(tid, addr )  if(tid%32==0) {  if((addr%256 != 0)) atomicAdd(&numErrors, 1); }

// this should not be a device pointer, it should be a host pointer which is cudaMalloc'ed and which has data copied to it from the host, then bound as texture
// we cannot refer to this data here except by texFetch1d
//__device__ float *gpu_conv_template; //[MAX_NUM_OBJECT][MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE]; // TODO tobi changed to cudaMalloc so that memory is accessible, may cause problems
//texture <float, 1, cudaReadModeElementType> template_tex;
texture <float> template_tex;
__device__ float gpu_conv_template[MAX_NUM_OBJECT][MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE]; // TODO tobi changed to cudaMalloc so that memory is accessible, may cause problems

__device__ float gpu_membranePotential[MAX_NUM_OBJECT][MAX_Y][MAX_X];
__device__ unsigned long gpu_lastTimeStamp[MAX_NUM_OBJECT][MAX_Y][MAX_X];
__device__ float temp_conv_value[NUM_CUDA_PACKETS][MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];

__device__ int numErrors;

__constant__ __device__  globalNeuronParams_t constNeuronParams;


__device__ int   totFiring  = 0;
__device__ int   numFiring0[MAX_NUM_OBJECT];
__device__ int   numFiring1[MAX_NUM_OBJECT];
__device__ unsigned int   firedNeuronAddr[MAX_NUM_OBJECT*MAX_FIRING]; // holds output spikes from each template

// This method implements part of the winner take-all functionality.
// The CPU calls this kernel whenever some neurons in the neuron array has fired.
// Each thread is responsible for inhibition of one neuron potential by iESynWeight amount.
// Finally each threads clips the membrane potential to stay within a specific value.
// We use a ID grid of 128x1 thread and 128 block to have simple addressing mechanism.
// 2D block of thread can also do similar computation but kernel needs slightly more address calculations.
__global__ void WTAKernel1DMO(int* numFiringAddr, int num_object)
{	
	// Thread index
	int tx = threadIdx.x;
	int bx = blockIdx.x;

	int my_addrx = tx; // this thread handles neuron (x,y)=(threadIdx.x, blockIdx.x)
	int my_addry = bx;

	__shared__ volatile int numFiring;  // shared by kernels in thread block
	
	for(int objId=0; objId < num_object; objId++) {
		
		if (tx == 0) {
			numFiring = numFiringAddr[objId]; // first thread gets the total number of spikes for this template objId and puts in shared memory
		}	

		__syncthreads(); // rest wait till here

		// only if some value exists for fired neuron
		// we update the 
		if( (volatile int) numFiring!=0 ) {	// FAQ: why cast to volatile int here? Just to be sure we are casting again to volatile. 
				 
			float temp = gpu_membranePotential[objId][my_addry][my_addrx]; // membrane potential of an LIF neuron for one template array

			temp -= constNeuronParams.iESynWeight; // reduce it by the iE weight (inhibitory to excitatory)
			
			if ( temp < constNeuronParams.membranePotentialMin )
				// clamp it to negative driving potential (negative weight can never make it fire)
				temp = constNeuronParams.membranePotentialMin; 
				
			gpu_membranePotential[objId][my_addry][my_addrx] = temp;
		}
	}	
}

// this array stores the incoming spikes from CPU...
__device__ int gpu_spikeAddr[GPU_MAX_SPIKE_PACKETS];
__device__ unsigned long gpu_spikeTime[GPU_MAX_SPIKE_PACKETS];

__device__ float debugArr[MAX_NUM_BLOCKS][100];	//used for debugging...
__device__ unsigned long debugArrInt[MAX_NUM_BLOCKS][100];	//used for debugging...

__global__ void
convNN_multiSpikeKernel( unsigned long timeStamp,	// time stamp of the first firing spike
						 int  len,					// length of the spikes given to GPU
						 int* numFiringArr,			// pointer to number of fired neurons
													// initial value is zero before calling
						 int* resetAddr,			// This memory will be reset to zero by GPU
						 int  templateId)			// value of the kernel/template that is used - TODO not used here, we're using part of blockIdx for template since all templates evaluated in parallel
					
{
	//__shared__ volatile int sh_potential;
	__shared__ volatile float sh_decayFactor;      
	//__shared__ volatile int sh_numInpSpikes;   
	// we first load the pointer... this is not useful if gpu_conv_template is statically allocated
	// if gpu_conv_template is a dynamic multi-dimensional pointer.. then it is better to do 
	// bring the pointer into register and then use integer offset to retreive corresponding data..
	// Better would be to move the gpu_conv access to texture memory...
	//float* tmp_gpu_conv_template = &gpu_conv_template[0][0][0];

	/* blockIdx.x,blockIdx.y can range from 0-31 */
	int bx = blockIdx.x;
	//TODO: This code is specific to an image of size 128, with 8 blocks
	//each operating 16x16 pixel array.

	//We encode the object dimension in blockId itself.last 3 bit denotes
	//block number, the remaining bits denote the object number neuronArrayId
	int by = (blockIdx.y&0x7);
	int neuronArrayId = (blockIdx.y>>3);

	/* blockIdx.x,blockIdx.y can range from 0-31 */
	int my_addrx = bx*MAX_SUB_TEMPLATE_SIZE_X + threadIdx.x;
	int my_addry = by*MAX_SUB_TEMPLATE_SIZE_Y + threadIdx.y;
    int my_localId = threadIdx.y*blockDim.x+threadIdx.x; // unique local id within a block

	// we get the address where we will update the number of neurons that has fired
	int* numFiring=&numFiringArr[neuronArrayId];

	// TODO only one thread needs to update this? why not use my_localId if it's unique???
	if (my_localId == 0) {		
		resetAddr[neuronArrayId]=0; // FAQ: why is the kernel doing this, what is resetAddr??? it's not used further in the kernel
									// we use a simple double buffering scheme. this address will be passed as
									// numFiringArr address during the next kernel call. We can save a cudaMemcpy or cudaMemset
									// by the CPU for reseting the number of firing by this mechanism.
	}
			
   __syncthreads();

   // calculate the exponential decay value or factor into shared memory for all threads in grid to use
   // just one thread needs to evaluate it.
   if(my_localId == 0) { // don't all threads with tx==0 do this??? TODO
	   unsigned long ltStamp = gpu_lastTimeStamp[neuronArrayId][my_addry][my_addrx];
	   unsigned long timeDiff = timeStamp-ltStamp;	    
	   float temp = (float)(timeDiff/constNeuronParams.membraneTau);
	   sh_decayFactor = __expf(-temp);   
   }
   __syncthreads();

   // retreive the initial value of the membrane potential and multiply by decay value
   float refValue  = gpu_membranePotential[neuronArrayId][my_addry][my_addrx];

   refValue = refValue*sh_decayFactor;

   // read SHM_SPIKE_BUFFER_LEN from the input spike pool and
   // generate the convolution for each of the spikes
	#define SHM_SPIKE_BUFFER_LEN 128 // FAQ, why not in config.h?  this is very small number of input spikes also.
									 // we are storing the spikes in the shared memory before doing
									 // the LIF calculations. This shared memory operation can saved
									 // by either using a constant cache or a texture cache
   __shared__ volatile unsigned int sh_spike_addr[SHM_SPIKE_BUFFER_LEN]; // FAQ, why use shared memory here? why not gpu_spikeAddr?
																		 // its better to read a whole bunch of spikes to get better bandwidth performance.
																		 // it would be better to map gpu_spikeAddr to texture or constant cache.
																		 // we dont have the headache of storing spikes in shared memory
   
   int cnt=SHM_SPIKE_BUFFER_LEN; // cnt takes care of reading new set of spikes into GPU shared memory 
   for(int i=0; i < len;i++) { // for each spike from CPU

	   if(cnt==SHM_SPIKE_BUFFER_LEN) {
		   // all thread with address less then spike buffer length will fetch data from memory
		   // TODO tobi doesn't understand this scheme, what about the other threads? 
		   if(my_localId < SHM_SPIKE_BUFFER_LEN)
			   sh_spike_addr[my_localId] = gpu_spikeAddr[i+my_localId]; //params.addrV;//*(params.addr + eventId);
		   cnt=0;				
	   }
	   __syncthreads();

	   // read the spike for spike buffer and calulate x and y addresst
	   unsigned int addrx = (sh_spike_addr[cnt])&0xff;
	   unsigned int addry = (sh_spike_addr[cnt]>>8)&0xff;		
	   cnt++;

	   /* find the region of neuron array that is valid and should change */		
	   int min_x = addrx - (MAX_TEMPLATE_SIZE/2) + 1;
	   int min_y = addry - (MAX_TEMPLATE_SIZE/2) + 1;
	   int max_x = addrx + (MAX_TEMPLATE_SIZE/2);
	   int max_y = addry + (MAX_TEMPLATE_SIZE/2);

	   /* we allow negative values for min_x and min_y 
	   and should allow max_x and max_y to exceed the size,
	   but only valid neurons will be updated */

	   // TODO: remove the two conditions below.
	   if (max_x >= MAX_X )
		   max_x = MAX_X - 1;
	   if (max_y >= MAX_Y )
		   max_y = MAX_Y - 1;

	   // check if the neuron address is within the 
	   // valid range where modification is going to happen
	   // due to convolution operation
	   if (my_addrx >= min_x &&
		   my_addry >= min_y &&
		   my_addrx <= max_x &&
		   my_addry <= max_y ) {

			   // evaluate the x and y values for the template
			   int tempId_x = my_addrx - min_x;
			   int tempId_y = my_addry - min_y;

			   /* we can read the template and get a valid data */
		//	   int texPos = templateId*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + tempId_y*MAX_TEMPLATE_SIZE + tempId_x;
			   int texPos = neuronArrayId*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + tempId_y*MAX_TEMPLATE_SIZE + tempId_x; // tobi changed to neuronId which is template in this block
			   // debug
			   float weight=tex1D(template_tex, texPos); // TODO always returns 0 now
			   //float weight = tmp_gpu_conv_template[texPos];			

			   // weights can be positive or negative based on the template type		
			   refValue = refValue + weight; // tex1D (template_tex, texPos);
	   }

	   // neuron's membrane potential value exceeds the threshold value
	   // and hence the neuron should fire and reset
	   if (refValue > constNeuronParams.threshold)  {
		   refValue = 0.0;
		   // increment the current kernel call's firing count
		   int fireId = atomicAdd(numFiring, 1);		// returns the *old* value of numFiring in fireId
		   // increment the total firing count for all kernel calls until now
		   atomicAdd(&totFiring,1);						// used for debug
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
	
	// only one thread writes down the timeStamp value.
	// TODO: currently we store the time corresponding to the first spike
	// should this be the last spike ????
    if(my_localId == 0)
    	gpu_lastTimeStamp[neuronArrayId][my_addry][my_addrx] = timeStamp;		

	// write back the calculated refValue 
	//if (neuronSelected)
	gpu_membranePotential[neuronArrayId][my_addry][my_addrx] = refValue;

}


__global__ void
convNN_multiSpikeKernelNew( unsigned long timeStamp,// time stamp of the first firing spike
						 int  numInpSpikes,			// length of the spikes given to GPU
						 int* numFiringArr,			// pointer to number of fired neurons
													// initial value is zero before calling
						 int* resetAddr,			// This memory will be reset to zero by GPU
						 int  templateId)			// value of the kernel/template that is used - TODO not used here, we're using part of blockIdx for template since all templates evaluated in parallel
					
{	
	__shared__ volatile float sh_decayFactor;

	// we first load the pointer... this is not useful if gpu_conv_template is statically allocated
	// if gpu_conv_template is a dynamic multi-dimensional pointer.. then it is better to do
	// bring the pointer into register and then use integer offset to retreive corresponding data..
	// Better would be to move the gpu_conv access to texture memory...
	//float* tmp_gpu_conv_template = &gpu_conv_template[0][0][0];

	/* blockIdx.x,blockIdx.y can range from 0-31 */
	int bx = blockIdx.x;
	//TODO: This code is specific to an image of size 128, with 8 blocks
	//each operating 16x16 pixel array.

	//We encode the object dimension in blockId itself.last 3 bit denotes
	//block number, the remaining bits denote the object number neuronArrayId
	int by = (blockIdx.y&0x7);
	int neuronArrayId = (blockIdx.y>>3);

	/* blockIdx.x,blockIdx.y can range from 0-31 */
	int my_addrx = bx*MAX_SUB_TEMPLATE_SIZE_X + threadIdx.x;
	int my_addry = by*MAX_SUB_TEMPLATE_SIZE_Y + threadIdx.y;
    int my_localId = threadIdx.y*blockDim.x+threadIdx.x; // unique local id within a block

	// we get the address where we will update the number of neurons that has fired
	int* numFiring=&numFiringArr[neuronArrayId];

	// TODO only one thread needs to update this? why not use my_localId if it's unique???
	if (my_localId == 0) {		
		resetAddr[neuronArrayId]=0; // FAQ: why is the kernel doing this, what is resetAddr??? it's not used further in the kernel
									// we use a simple double buffering scheme. this address will be passed as
									// numFiringArr address during the next kernel call. We can save a cudaMemcpy or cudaMemset
									// by the CPU for reseting the number of firing by this mechanism.
	}
			
   __syncthreads();

   int ltStamp = 0;

   // retreive the membrane potential
   if(my_localId == 0) {
	  ltStamp = gpu_lastTimeStamp[neuronArrayId][my_addry][my_addrx];
   }

   // retreive the initial value of the membrane potential and multiply by decay value
   float refValue  = gpu_membranePotential[neuronArrayId][my_addry][my_addrx];

   // for each spike from CPU
   for(int spkCnt=0; spkCnt < numInpSpikes;spkCnt++) {

		// only one thread within a block does the exponential operation
	    if(my_localId == 0) {
			unsigned long timeDiff = gpu_spikeTime[spkCnt]-ltStamp;
			float temp = (float)(timeDiff/constNeuronParams.membraneTau);
			sh_decayFactor = __expf(-temp);
			ltStamp = gpu_spikeTime[spkCnt];
		}

		__syncthreads();

		refValue = refValue*sh_decayFactor;

		// read the spike for spike buffer and calulate x and y addresst
		unsigned int addrx = (gpu_spikeAddr[spkCnt])&0xff;
		unsigned int addry = (gpu_spikeAddr[spkCnt]>>8)&0xff;		

		/* find the region of neuron array that is valid and should change */		
		int min_x = addrx - (MAX_TEMPLATE_SIZE/2) + 1;
		int min_y = addry - (MAX_TEMPLATE_SIZE/2) + 1;
		int max_x = addrx + (MAX_TEMPLATE_SIZE/2);
		int max_y = addry + (MAX_TEMPLATE_SIZE/2);

		// check if the neuron address is within the 
		// valid range where modification is going to happen
		// due to convolution operation
		if (my_addrx >= min_x &&
			my_addry >= min_y &&
			my_addrx <= max_x &&
			my_addry <= max_y ) {

				// evaluate the x and y values for the template
				int tempId_x = my_addrx - min_x;
				int tempId_y = my_addry - min_y;

				/* we can read the template and get a valid data */
				//	   int texPos = templateId*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + tempId_y*MAX_TEMPLATE_SIZE + tempId_x;
				int texPos = neuronArrayId*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + tempId_y*MAX_TEMPLATE_SIZE + tempId_x; // tobi changed to neuronId which is template in this block
				// debug
				float weight=tex1D(template_tex, texPos); // TODO always returns 0 now
				//float weight = tmp_gpu_conv_template[texPos];

				// weights can be positive or negative based on the template type		
				refValue = refValue + weight; // tex1D (template_tex, texPos);
		}

		// neuron's membrane potential value exceeds the threshold value
		// and hence the neuron should fire and reset
		if (refValue > constNeuronParams.threshold)  {
			refValue = 0.0;
			// increment the current kernel call's firing count
			int fireId = atomicAdd(numFiring, 1);		// returns the *old* value of numFiring in fireId
			// increment the total firing count for all kernel calls until now
			atomicAdd(&totFiring,1);						// used for debug
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

   // only one thread writes down the timeStamp value.
   // TODO: currently we store the time corresponding to the first spike
   // should this be the last spike ????
   if(my_localId == 0) {
	   gpu_lastTimeStamp[neuronArrayId][my_addry][my_addrx] = ltStamp;			   
   }

   // write back the calculated refValue    
   gpu_membranePotential[neuronArrayId][my_addry][my_addrx] = refValue;



}

#endif // #ifndef _TEMPLATE_KERNEL_H_
