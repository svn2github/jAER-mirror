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

__device__ float *gpu_conv_template; //[MAX_NUM_OBJECT][MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];
texture <float> template_tex;

__device__ float gpu_membranePotential[MAX_NUM_OBJECT][MAX_Y][MAX_X];
__device__ unsigned long gpu_lastTimeStamp[MAX_NUM_OBJECT][MAX_Y][MAX_X];
//__device__ const float gpu_objSizeArray[MAX_NUM_OBJECT] = {16.0,8.0};	
__device__ const float gpu_objSizeArray[] = {15.0,7.0,20.0,19.0,18.0,12.0,11.0,10.0};	//ball size
__device__ float temp_conv_value[NUM_CUDA_PACKETS][MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];

__device__ int numErrors;

__constant__ globalNeuronParams_t constNeuronParams;

#define MAX_FIRING 1000

__device__ int   totFiring  = 0;
__device__ int   numFiring0 = 0;
__device__ int   numFiring1 = 0;
__device__ int   numFiring2 = 0;
__device__ int   totFiringMO[MAX_NUM_OBJECT];
__device__ int   numFiring0MO[MAX_NUM_OBJECT];
__device__ int   numFiring1MO[MAX_NUM_OBJECT];
__device__ int   numFiring2MO[MAX_NUM_OBJECT];
__device__ unsigned int   firedNeuronAddr[MAX_NUM_OBJECT*MAX_FIRING];
__device__ float gpu_iNeuronPotential[MAX_NUM_OBJECT];
__device__ int   gpu_iNeuronFired;

__global__ void WTAKernel1D()
{
	// TODO: current scheme works with only
	// one object map
	int objId  = 0;
	
	// Thread index
	int tx = threadIdx.x;
	int bx = blockIdx.x;
	
	int my_addrx = tx;
	int my_addry = bx;
			 
	float temp = gpu_membranePotential[objId][my_addry][my_addrx];

	temp -= constNeuronParams.iESynWeight;
		
	if ( temp < constNeuronParams.membranePotentialMin )
		temp = constNeuronParams.membranePotentialMin;
			
	gpu_membranePotential[objId][my_addry][my_addrx] = temp;

}	

__global__ void WTAKernel1DMO(int firingId, int num_object)
{	
	// Thread index
	int tx = threadIdx.x;
	int bx = blockIdx.x;

	int my_addrx = tx;
	int my_addry = bx;
	__shared__ volatile int numFiring;
	
	for(int objId=0; objId < num_object; objId++) {
		
		if (tx == 0) {
			if (firingId ) 
				numFiring = numFiring1MO[objId];
			else
				numFiring = numFiring0MO[objId];
		}
		
		__syncthreads();
		
		if( (volatile int) numFiring!=0 ) {			
				 
			float temp = gpu_membranePotential[objId][my_addry][my_addrx];

			temp -= constNeuronParams.iESynWeight;
			
			if ( temp < constNeuronParams.membranePotentialMin )
				temp = constNeuronParams.membranePotentialMin;
				
			gpu_membranePotential[objId][my_addry][my_addrx] = temp;
		}
	}
}	
__global__ void WTAKernel()
{
	int objId = 0;  // TODO: currently we support inhibition only in 1st membranePotential Array
	
    // Block index
    int bx = blockIdx.x;
    int by = blockIdx.y;
	
    // Thread index
    int tx = threadIdx.x;
    int ty = threadIdx.y;

	int my_addrx = bx*blockDim.x + tx;
	int my_addry = by*blockDim.y + ty;	
	  
	float temp_iNeuronPotential = gpu_iNeuronPotential[objId] + constNeuronParams.eISynWeight*numFiring0;

	if (temp_iNeuronPotential > constNeuronParams.threshold) {
		//CHECK_COALESE( (blockDim.x*ty+ tx), (int)&gpu_membranePotential[objId][my_addry][my_addrx]);
		gpu_membranePotential[objId][my_addry][my_addrx] -= constNeuronParams.iESynWeight;
			
		if(gpu_membranePotential[objId][my_addry][my_addrx] < constNeuronParams.membranePotentialMin ) 
			gpu_membranePotential[objId][my_addry][my_addrx] = constNeuronParams.membranePotentialMin;		
	}
}

////////////////////////////////////////////////////////////////////////////////
//! Simple test kernel for device functionality
//! @param g_idata  input data in global memory
//! @param g_odata  output data in global memory
////////////////////////////////////////////////////////////////////////////////
__global__ void
generateGlobalTemplateKernel( cudaParameters_t params, int prevFired, int firingId)
{
	int objId = 0;
	
    // Block index
    int bx = blockIdx.x;//%3;
    int by = blockIdx.y;///3;
	int bz = blockIdx.z;
	
    // Thread index
    int tx = threadIdx.x;
    int ty = threadIdx.y;

	// location of conv. blocks
//	int eventId = bz;
	int subTemplateId_x = bx;
	int subTemplateId_y = by;
	
	int* numFiring;
	
	if ( firingId )
		numFiring = &numFiring1;
	else
		numFiring = &numFiring0;

	if ( prevFired ) {
		if ((blockIdx.x == 0) && (blockIdx.y == 0) && (threadIdx.x == 0) && (threadIdx.y == 0)) {
			if (firingId)
				numFiring0 = 0;
			else
				numFiring1 = 0;
		}
	}	
	
	if ( bz < params.len )  {

		unsigned int addr  = params.addrV;//*(params.addr + eventId);
		unsigned int addrx = (addr)&0xff;
		unsigned int addry = (addr>>8)&0xff;
		unsigned long timeStamp  = params.timeStampV ; //*(params.timeStamp + eventId);
		
		int min_x = addrx - (MAX_TEMPLATE_SIZE/2) + 1;
		int min_y = addry - (MAX_TEMPLATE_SIZE/2) + 1;
		
		int my_addrx = min_x + subTemplateId_x*MAX_SUB_TEMPLATE_SIZE_X + tx; 
		int my_addry = min_y + subTemplateId_y*MAX_SUB_TEMPLATE_SIZE_Y + ty;
				
 		if  ( (my_addrx > 0) &&
			  (my_addrx < MAX_X) &&
			  (my_addry > 0) &&
			  (my_addry < MAX_Y))  {
		
			unsigned long ltStamp = gpu_lastTimeStamp[objId][my_addry][my_addrx];
		
			// we are within logical boundary of frame
			//signed long long timeDiff = 0xFFFFFFFFLL&(timeStamp-ltStamp); 
		    unsigned long timeDiff = timeStamp-ltStamp;
		    //unsigned long tDiff = timeStamp - ltStamp;	
			//if ( tDiff & 0x80000000L)
			//	tDiff = 0;
			
			//signed long timeDiff = (signed long)(-tDiff);
		    
			float temp = (float)(timeDiff/constNeuronParams.membraneTau);
			float convTempValue = 0.0;    

			int tempId_x,tempId_y;

			tempId_x = my_addrx - min_x;
			tempId_y = my_addry - min_y;

			// make this texture cache access
			// convTempValue  = gpu_conv_template[params.objectId][tempId_y][tempId_x];
			int texPos = /*params.objectId*/0*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + tempId_y*MAX_TEMPLATE_SIZE + tempId_x;
		    convTempValue = tex1Dfetch (template_tex, texPos);
		    
			if (temp >  10 || (temp < 0)) {
				gpu_membranePotential[objId][my_addry][my_addrx] = convTempValue;		
			}
			else{
				float refValue = gpu_membranePotential[objId][my_addry][my_addrx];
				refValue = refValue*__expf(-temp) + convTempValue;
				//if(temp < 1)
				//	refValue = refValue*(1-temp) + convTempValue;
				//else
				//	refValue = convTempValue;
				gpu_lastTimeStamp[objId][my_addry][my_addrx]     = timeStamp;
				
				if (refValue > constNeuronParams.threshold)  {
					refValue = 0.0;
					int fireId = atomicAdd(numFiring, 1);
					atomicAdd(&totFiring,1);
					firedNeuronAddr[fireId] = (my_addry<<8)+ my_addrx;
				}
				else if (refValue < constNeuronParams.membranePotentialMin) 
					refValue = constNeuronParams.membranePotentialMin;
					
		
				// write back the calculated refValue 
				gpu_membranePotential[objId][my_addry][my_addrx] = refValue;
		   
		   } 
		}  // timeDiff calculation ends 
	} // if boundary calculation ends
}

////////////////////////////////////////////////////////////////////////////////
//! Simple test kernel for device functionality
//! @param g_idata  input data in global memory
//! @param g_odata  output data in global memory
////////////////////////////////////////////////////////////////////////////////
__global__ void
convNN_singleSpikeKernel( cudaParameters_t params, int prevFired, int firingId)
{    
	int objId = 0;
	
    // Block index
    int bx = blockIdx.x; //blockIdx.x%4;
    int by = blockIdx.y; //blockIdx.x/4;
	int bz = blockIdx.z;
	
    // Thread index
    int tx = threadIdx.x;
    int ty = threadIdx.y;

	// location of conv. blocks
//	int eventId = bz;
//	int subTemplateId_x = bx;
//	int subTemplateId_y = by;
	
	int* numFiring;
	
	if ( firingId )
		numFiring = &numFiring1;
	else
		numFiring = &numFiring0;

	if ( prevFired ) {
		if ((blockIdx.x == 0) && (blockIdx.y == 0) && (threadIdx.x == 0) && (threadIdx.y == 0)) {
			if (firingId)
				numFiring0 = 0;
			else
				numFiring1 = 0;
		}
	}	
	
	if ( bz < params.len )  {

		unsigned long timeStamp  = params.timeStampV ; //*(params.timeStamp + eventId);
		
#if 1			
		unsigned int addr  = params.addrV;//*(params.addr + eventId);
		unsigned int addrx = (addr)&0xff;
		unsigned int addry = (addr>>8)&0xff;
		int min_x = addrx - (MAX_TEMPLATE_SIZE/2) + 1;
		int min_y = addry - (MAX_TEMPLATE_SIZE/2) + 1;
		int max_x = addrx + (MAX_TEMPLATE_SIZE/2);
		int max_y = addry + (MAX_TEMPLATE_SIZE/2);
		
		if (max_x >= MAX_X )
		   max_x = MAX_X - 1;
		
		if (max_y >= MAX_Y )
		   max_y = MAX_Y - 1;

		int align_min_y = min_y;
		int align_min_x;
		
		if ( min_x >= 0 )
			align_min_x = min_x - min_x%16;	
		else 
			align_min_x = 0;
			
		if ( min_y < 0 )
			align_min_y  = 0;	
#else			
	
		const int align_min_x = params.align_min_x;
		const int align_min_y = params.align_min_y;
		const int max_x = params.max_x;
		const int max_y= params.max_y;
		const int min_x = params.min_x;
		const int min_y = params.min_y;		
#endif		
		int3 globalId;
				
		globalId.x = tx + (bx * blockDim.x);
		globalId.y = ty + (by * blockDim.y);
		
		int my_addrx  = align_min_x + globalId.x;
		int my_addry  = align_min_y + globalId.y;
		
		if ( my_addrx >= 0 &&
			 my_addry >= 0 &&
			 my_addrx >= min_x &&
			 my_addry >= min_y &&
			 my_addrx <= max_x &&
			 my_addry <= max_y ) {			
				   
			int tempId_x = my_addrx - min_x;
			int tempId_y = my_addry - min_y;			
		
			unsigned long ltStamp = gpu_lastTimeStamp[objId][my_addry][my_addrx];
		
			// we are within logical boundary of frame
			//signed long long timeDiff = 0xFFFFFFFFLL&(timeStamp-ltStamp); 
		    unsigned long timeDiff = timeStamp-ltStamp;
		    //unsigned long tDiff = timeStamp - ltStamp;	
			//if ( tDiff & 0x80000000L)
			//	tDiff = 0;			
			//signed long timeDiff = (signed long)(-tDiff);
		    
			float temp = (float)(timeDiff/constNeuronParams.membraneTau);
			float convTempValue = 0.0;    

			// make this texture cache access
			// convTempValue  = gpu_conv_template[params.objectId][tempId_y][tempId_x];
			int texPos = params.objectId*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + tempId_y*MAX_TEMPLATE_SIZE + tempId_x;
		    convTempValue = tex1Dfetch (template_tex, texPos);
		    
			if (temp >  10 || (temp < 0)) {
				gpu_membranePotential[objId][my_addry][my_addrx] = convTempValue;		
			}
			else{
				float refValue = gpu_membranePotential[objId][my_addry][my_addrx];
				refValue = refValue*__expf(-temp) + convTempValue;
				gpu_lastTimeStamp[objId][my_addry][my_addrx]     = timeStamp;
				
				if (refValue > constNeuronParams.threshold)  {
					refValue = 0.0;									
					int fireId = atomicAdd(numFiring, 1);
					atomicAdd(&totFiring,1);
					firedNeuronAddr[fireId] = (my_addry<<8)+ my_addrx;
				}
				else if (refValue < constNeuronParams.membranePotentialMin) 
					refValue = constNeuronParams.membranePotentialMin;
		
				// write back the calculated refValue 
				gpu_membranePotential[objId][my_addry][my_addrx] = refValue;		   
		   } 
		}  // timeDiff calculation ends 
	} // if boundary calculation ends
}

////////////////////////////////////////////////////////////////////////////////
//! Simple test kernel for device functionality
//! @param g_idata  input data in global memory
//! @param g_odata  output data in global memory
////////////////////////////////////////////////////////////////////////////////
__global__ void
generateGlobalTemplateKernel2( cudaParameters_t params, int prevFired, int firingId)
{    
	// TODO: Temporarily we are only using one object map
	int objId = 0;
	
    // Block index
    int bx = blockIdx.x; //blockIdx.x%4;
    int by = blockIdx.y; //blockIdx.x/4;
	int bz = blockIdx.z;
	
    // Thread index
    int tx = threadIdx.x;
    int ty = threadIdx.y;

	// location of conv. blocks
//	int eventId = bz;
//	int subTemplateId_x = bx;
//	int subTemplateId_y = by;
	
	int* numFiring;
	
	if ( firingId )
		numFiring = &numFiring1;
	else
		numFiring = &numFiring0;

	if ( prevFired ) {
		if ((blockIdx.x == 0) && (blockIdx.y == 0) && (threadIdx.x == 0) && (threadIdx.y == 0)) {
			if (firingId)
				numFiring0 = 0;
			else
				numFiring1 = 0;
		}
	}	
	
	if ( bz < params.len )  {

		unsigned long timeStamp  = params.timeStampV ; //*(params.timeStamp + eventId);
		
#if 1			
		unsigned int addr  = params.addrV;//*(params.addr + eventId);
		unsigned int addrx = (addr)&0xff;
		unsigned int addry = (addr>>8)&0xff;
		int min_x = addrx - (MAX_TEMPLATE_SIZE/2) + 1;
		int min_y = addry - (MAX_TEMPLATE_SIZE/2) + 1;
		int max_x = addrx + (MAX_TEMPLATE_SIZE/2);
		int max_y = addry + (MAX_TEMPLATE_SIZE/2);
		
		if (max_x >= MAX_X )
		   max_x = MAX_X - 1;
		
		if (max_y >= MAX_Y )
		   max_y = MAX_Y - 1;

		int align_min_y = min_y;
		int align_min_x;
		
		if ( min_x >= 0 )
			align_min_x = min_x - min_x%16;	
		else 
			align_min_x = 0;
			
		if ( min_y < 0 )
			align_min_y  = 0;	
#else			
	
		const int align_min_x = params.align_min_x;
		const int align_min_y = params.align_min_y;
		const int max_x = params.max_x;
		const int max_y= params.max_y;
		const int min_x = params.min_x;
		const int min_y = params.min_y;		
#endif		
		int3 globalId;
				
		globalId.x = tx + (bx * blockDim.x);
		globalId.y = ty + (by * blockDim.y);
		
		int my_addrx  = align_min_x + globalId.x;
		int my_addry  = align_min_y + globalId.y;
		
		if ( my_addrx >= 0 &&
			 my_addry >= 0 &&
			 my_addrx >= min_x &&
			 my_addry >= min_y &&
			 my_addrx <= max_x &&
			 my_addry <= max_y ) {			
				   
			int tempId_x = my_addrx - min_x;
			int tempId_y = my_addry - min_y;			
		
			unsigned long ltStamp = gpu_lastTimeStamp[objId][my_addry][my_addrx];
		
			// we are within logical boundary of frame
			//signed long long timeDiff = 0xFFFFFFFFLL&(timeStamp-ltStamp); 
		    unsigned long timeDiff = timeStamp-ltStamp;
		    //unsigned long tDiff = timeStamp - ltStamp;	
			//if ( tDiff & 0x80000000L)
			//	tDiff = 0;			
			//signed long timeDiff = (signed long)(-tDiff);
		    
			float temp = (float)(timeDiff/constNeuronParams.membraneTau);
			float convTempValue = 0.0;    

			// make this texture cache access
			// convTempValue  = gpu_conv_template[params.objectId][tempId_y][tempId_x];
			int texPos = params.objectId*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + tempId_y*MAX_TEMPLATE_SIZE + tempId_x;
		    convTempValue = tex1Dfetch (template_tex, texPos);
		    
			if (temp >  10 || (temp < 0)) {
				gpu_membranePotential[objId][my_addry][my_addrx] = convTempValue;		
			}
			else{
				float refValue = gpu_membranePotential[objId][my_addry][my_addrx];
				refValue = refValue*__expf(-temp) + convTempValue;
				gpu_lastTimeStamp[objId][my_addry][my_addrx]     = timeStamp;
				
				if (refValue > constNeuronParams.threshold)  {
					refValue = 0.0;									
					int fireId = atomicAdd(numFiring, 1);
					atomicAdd(&totFiring,1);
					firedNeuronAddr[fireId] = (my_addry<<8)+ my_addrx;
				}
				else if (refValue < constNeuronParams.membranePotentialMin) 
					refValue = constNeuronParams.membranePotentialMin;
		
				// write back the calculated refValue 
				gpu_membranePotential[objId][my_addry][my_addrx] = refValue;		   
		   } 
		}  // timeDiff calculation ends 
	} // if boundary calculation ends
}

#define SPIKE_BUFFER_LEN 128

__device__ unsigned long gpu_blockLastFiring[MAX_NUM_BLOCKS][MAX_NUM_BLOCKS];
__device__ float gpu_iNeuronPotentialBlock[MAX_NUM_BLOCKS];
__device__ int spikeInfo[GPU_MAX_SPIKE_PACKETS];

__global__ void
convNN_multiSpikeKernel( cudaParameters_t params, int prevFired, int firingId)
{
	// TODO: Temporarily we are only using one object map
	int objId = 0;
	
	__shared__ volatile int sh_potential;
	__shared__ volatile float sh_decayFactor;      
	__shared__ volatile int sh_numInpSpikes;   
   
	/* blockIdx.x,blockIdx.y can range from 0-31 */
	int my_addrx = blockIdx.x*MAX_SUB_TEMPLATE_SIZE_X + threadIdx.x;
	int my_addry = blockIdx.y*MAX_SUB_TEMPLATE_SIZE_Y + threadIdx.y;   
    int my_localId = threadIdx.y*blockDim.x+threadIdx.x; // unique local id within a block 	

	int* numFiring;
	
	if ( firingId )
		numFiring = &numFiring1;
	else
		numFiring = &numFiring0;

	if ( prevFired && ((blockIdx.x == 0) && (blockIdx.y == 0) && (threadIdx.x == 0) && (threadIdx.y == 0))) {
		if (firingId)
			numFiring0 = 0;
		else
			numFiring1 = 0;			
	}
			
   __syncthreads();
  
   float refValue  = gpu_membranePotential[objId][my_addry][my_addrx];    
   unsigned long timeStamp = params.timeStampV;;   
   
   if(threadIdx.x == 0) {
		unsigned long ltStamp = gpu_lastTimeStamp[objId][my_addry][my_addrx];		
		unsigned long timeDiff = timeStamp-ltStamp;	    
		float temp = (float)(timeDiff/constNeuronParams.membraneTau);
		sh_decayFactor = __expf(-temp);		
   }
   __syncthreads();   

    /* get the reference potential value */
    refValue = refValue*sh_decayFactor;
    
    //bool neuronSelected = false;
    __shared__ volatile unsigned int sh_spike_addr[SPIKE_BUFFER_LEN];        
	int cnt=SPIKE_BUFFER_LEN;
	for(int i=0; i < params.len;) {
		
		if(cnt==SPIKE_BUFFER_LEN)	{
			// all thread with address less then spike buffer length will fetch data from memory				
			if(my_localId < SPIKE_BUFFER_LEN)	
				sh_spike_addr[my_localId] = spikeInfo[i+my_localId]; //params.addrV;//*(params.addr + eventId);
			__syncthreads();
			cnt=0;				
		}	    			
				
		unsigned int addrx = (sh_spike_addr[cnt])&0xff;
		unsigned int addry = (sh_spike_addr[cnt]>>8)&0xff;
		cnt++;
		i++;

		/* region of template that is valid */
		int min_x = addrx - (MAX_TEMPLATE_SIZE/2) + 1;
		int min_y = addry - (MAX_TEMPLATE_SIZE/2) + 1;
		int max_x = addrx + (MAX_TEMPLATE_SIZE/2);
		int max_y = addry + (MAX_TEMPLATE_SIZE/2);

		if (max_x >= MAX_X )
		   max_x = MAX_X - 1;

		if (max_y >= MAX_Y )
		   max_y = MAX_Y - 1;

		if ( my_addrx >= min_x &&
			 my_addry >= min_y &&
			 my_addrx <= max_x &&
			 my_addry <= max_y ) {
			
	   		int tempId_x = my_addrx - min_x;
			int tempId_y = my_addry - min_y;
			
			/* we can read the template and get a valid data */
			int texPos = params.objectId*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + tempId_y*MAX_TEMPLATE_SIZE + tempId_x;
			refValue = refValue + tex1Dfetch (template_tex, texPos);
			//neuronSelected = true;
		}

		if (refValue > constNeuronParams.threshold)  {
			refValue = 0.0;									
			int fireId = atomicAdd(numFiring, 1);
			atomicAdd(&totFiring,1);
			firedNeuronAddr[fireId] = (my_addry<<8)+ my_addrx;
		}
		else if (refValue < constNeuronParams.membranePotentialMin) 
			refValue = constNeuronParams.membranePotentialMin;

#if LOOP_UNROLL_2
		
		if(cnt >= params.len)
			break;
			
		unsigned int addrx1 = (sh_spike_addr[cnt+1])&0xff;
		unsigned int addry1 = (sh_spike_addr[cnt+1]>>8)&0xff;
		cnt++;
		i++;

		/* region of template that is valid */
		int min_x1 = addrx1 - (MAX_TEMPLATE_SIZE/2) + 1;
		int min_y1 = addry1 - (MAX_TEMPLATE_SIZE/2) + 1;
		int max_x1 = addrx1 + (MAX_TEMPLATE_SIZE/2);
		int max_y1 = addry1 + (MAX_TEMPLATE_SIZE/2);

		if (max_x1 >= MAX_X )
		   max_x1 = MAX_X - 1;

		if (max_y1 >= MAX_Y )
		   max_y1 = MAX_Y - 1;

		if ( my_addrx >= min_x1 &&
			 my_addry >= min_y1 &&
			 my_addrx <= max_x1 &&
			 my_addry <= max_y1 ) {
			
	   		int tempId_x = my_addrx - min_x1;
			int tempId_y = my_addry - min_y1;
			
			/* we can read the template and get a valid data */
			int texPos = params.objectId*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + tempId_y*MAX_TEMPLATE_SIZE + tempId_x;
			refValue = refValue + tex1Dfetch (template_tex, texPos);
			//neuronSelected = true;
		}

		if (refValue > constNeuronParams.threshold)  {
			refValue = 0.0;									
			int fireId = atomicAdd(numFiring, 1);
			atomicAdd(&totFiring,1);
			firedNeuronAddr[fireId] = (my_addry<<8)+ my_addrx;
		}
		else if (refValue < constNeuronParams.membranePotentialMin) 
			refValue = constNeuronParams.membranePotentialMin;			
#endif			
	}
	

    if(threadIdx.x == 0)
    	gpu_lastTimeStamp[objId][my_addry][my_addrx] = timeStamp;		

	// write back the calculated refValue 
	//if (neuronSelected)
	gpu_membranePotential[objId][my_addry][my_addrx] = refValue;
}

__device__ int tmp[MAX_NUM_OBJECT][1000];
__global__ void
convNN_multiObjectmultiSpikeKernel( cudaParameters_t params, int prevFired, int firingId, int callCount)
{
	__shared__ volatile int sh_potential;
	__shared__ volatile float sh_decayFactor;      
	__shared__ volatile int sh_numInpSpikes;   
   
	/* blockIdx.x,blockIdx.y can range from 0-31 */
	int bx = blockIdx.x;
	//TODO: This code is specific to a image of size 128, with 8 blocks
	//each operating 16x16 pixel array.
	//We encode the object dimension in blockId itself.last 3 bit denotes
	//block number, the remaining bits denote the object number
	int by = (blockIdx.y&0x7);
	int bz = (blockIdx.y>>3);
	int my_addrx = bx*MAX_SUB_TEMPLATE_SIZE_X + threadIdx.x;
	int my_addry = by*MAX_SUB_TEMPLATE_SIZE_Y + threadIdx.y;  	
	int my_localId = threadIdx.y*blockDim.x+threadIdx.x; // unique local id within a block 	
	int objId = bz;
		 
	int* numFiring;
	
	if ( firingId )
		numFiring = &numFiring1MO[objId];
	else
		numFiring = &numFiring0MO[objId];
	
	if ((bx == 0) && (by == 0) && (threadIdx.x == 0) && (threadIdx.y == 0)) {		
		if( prevFired ) {
			if (firingId)
				numFiring0MO[objId] = 0;
			else
				numFiring1MO[objId] = 0;			
		}
	}
			
	__syncthreads();
 
	//for each object we have a separate array of membrane potential. This can
	//can be called as neuron area0. Each area is sensitive to one specific object
	//template. Currently we evaluate the given spike for all the area, 
	//but return the result corresponding to only the area0. 
	//TODO: future work would include picking up the peak response from
	//one of the area using a winner-take-all network. so that we can
	//select the peak responding area and associate it with the object
	float refValue = gpu_membranePotential[objId][my_addry][my_addrx];
	unsigned long timeStamp = params.timeStampV;

	if(threadIdx.x == 0) {
		unsigned long ltStamp = gpu_lastTimeStamp[objId][my_addry][my_addrx];
		unsigned long timeDiff = timeStamp-ltStamp;
		float temp = (float)(timeDiff/constNeuronParams.membraneTau);
		sh_decayFactor = __expf(-temp);
	}
	__syncthreads();

	/* get the reference potential value */
	refValue = refValue*sh_decayFactor;
    
	//bool neuronSelected = false;
	__shared__ volatile unsigned int sh_spike_addr[SPIKE_BUFFER_LEN];        
	int cnt=SPIKE_BUFFER_LEN;
	for(int i=0; i < params.len; i+=1) {
	
		if(cnt==SPIKE_BUFFER_LEN)	{
			// all thread with address less then spike buffer length will fetch data from memory				
			if(my_localId < SPIKE_BUFFER_LEN)	
				sh_spike_addr[my_localId] = spikeInfo[i+my_localId]; //params.addrV;//*(params.addr + eventId);
			__syncthreads();
			cnt=0;				
		}	    									
		unsigned int addrx = (sh_spike_addr[cnt])&0xff;
		unsigned int addry = (sh_spike_addr[cnt]>>8)&0xff;
		cnt++;
		
		/* region of template that is valid */
		int min_x = addrx - (MAX_TEMPLATE_SIZE/2) + 1;
		int min_y = addry - (MAX_TEMPLATE_SIZE/2) + 1;
		int max_x = addrx + (MAX_TEMPLATE_SIZE/2);
		int max_y = addry + (MAX_TEMPLATE_SIZE/2);

		if (max_x >= MAX_X )
		   max_x = MAX_X - 1;

		if (max_y >= MAX_Y )
		   max_y = MAX_Y - 1;

		if ( my_addrx >= min_x &&
			 my_addry >= min_y &&
			 my_addrx <= max_x &&
			 my_addry <= max_y ) {
			
			int tempId_x = my_addrx - min_x;
			int tempId_y = my_addry - min_y;
			
			/* we can read the template and get a valid data */
			int texPos = objId*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + tempId_y*MAX_TEMPLATE_SIZE + tempId_x;
			refValue = refValue + tex1Dfetch (template_tex, texPos);
			//neuronSelected = true;
		}
		
		if (refValue > constNeuronParams.threshold)  {
			refValue = 0.0;												
			// TODO: currently we track all object but put them in only
			// one queue. Update to include the object id along with spiking location			
			int fireId = atomicAdd(numFiring, 1);
			atomicAdd(&totFiring,1);			
			firedNeuronAddr[objId*MAX_FIRING+fireId] = (my_addry<<8)+ my_addrx;			
		}
		else if (refValue < constNeuronParams.membranePotentialMin) 
			refValue = constNeuronParams.membranePotentialMin;
	}

	if(threadIdx.x == 0)
		gpu_lastTimeStamp[objId][my_addry][my_addrx] = timeStamp;		

	// write back the calculated refValue 
	gpu_membranePotential[objId][my_addry][my_addrx] = refValue;
	
}
#endif // #ifndef _TEMPLATE_KERNEL_H_