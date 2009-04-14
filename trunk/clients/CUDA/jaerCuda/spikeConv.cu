// includes, system
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <time.h>

//#include "aer.h"

// includes, project
#include <cutil.h>

#include <Winsock2.h>
#include <Ws2tcpip.h>

#include <windows.h>

#include "config.h"

// includes, kernels
#include "spikeConv_kernel.cu"

#define CUDA   1
bool runCuda=1, tmpRunCuda=1; // tmp is for command processing

//===========================================================
// Server and client related code using Windows Socket
//===========================================================

extern char recvBuf[RECV_SOCK_BUFLEN];

//============================================
// Variables related to Audio Playback
//============================================

void waveInit();
void playAudio();
void waveClose();

//=========================================================
// Functions for jAER connections
//=========================================================

extern "C" {
	int jaerInit();
	int jaerRecv(); // fills up recvBuf with some spike data
	void jaerSendEvent(unsigned int addrx, unsigned int addry, unsigned long timeStamp, unsigned char type);
}
//==========================================================
// Functions that interface with golden reference
//==========================================================

extern "C" {
	int   templateConvInit(int selectType=TEMP_METHOD1, int templateType=TEMPLATE_DoG);
	void  computeGold( unsigned int* addr, unsigned long* timeStamp, int templateIndex);	
	int   extractJaerRawData( unsigned int* addr, unsigned long* timeStamp, char* Data, unsigned int len);	
	void  setInitLastTimeStamp(unsigned long timeStamp, int objId=0);
}

//===========================================================
// Functions related to dumping trace info and other matlab scripts
//===========================================================
extern "C"{
	void dumpResults(int objId=0);
	void showMembranePotential(unsigned int* spikeAddr=NULL, int spikeCnt=0);
	void printResults(FILE* fpLog);
	void dumpTemplate(FILE* fp, char* fstr);
}


//===========================================================
// Cuda related functions
//===========================================================

void  allocateDeviceMemory();
int   runjaerCUDA( int argc, char** argv);

extern int curTemplateIndex;

////////////////////////////////////////////////////////////////////////////////
// declaration, forward
////////////////////////////////////////////////////////////////////////////////

float inh_mem_potential[MAX_NUM_OBJECT];			// value of the inhibition potential
bool  cpu_polarity[RECV_SOCK_BUFLEN/EVENT_LEN];		// currently unused...
unsigned int  filteredSpike_addr[RECV_SOCK_BUFLEN/EVENT_LEN];	// array of filterred spike's address
unsigned long filteredSpike_timeStamp[RECV_SOCK_BUFLEN/EVENT_LEN];	// array of filtered spikes's timestamp

FILE *fpLog;						// Pointer to the log file...
long tot_fired_MO[MAX_NUM_OBJECT];  // total number of firing per neuronArray
int  inhFireCnt=0;					// total firing by inhibitory neuron
int  multi_object=MULTI_OBJECT;		
// TODO, why is num_object set here???  nothing to do with config.h or any parameter
int  num_object=MAX_NUM_OBJECT;   
// delta_time is time in us that spikes are chunked together to be sent with common timestamp. 
// increasing speeds up processing but quantizes time more.
unsigned int delta_time=1000;

int debugLevel=DEBUG_LEVEL;

void* conv_templateAddr;	//  address of convolution template kernal on device
void* numFiring0AddrMO;		//  points to device memory. contains list of fired neurons for odd runs
void* numFiring1AddrMO;		//	points to device memory. contains list of fired neurons for even runs
void* devPtrSpikeAddr;		//  points to device memory. cpu copies spikes to gpu through this memory
void* devPtrSpikeTime;		//  points to device memory. cpu copies spikes time to this memory in gpu

unsigned int firedNeuron_addr[MAX_SENDING_SPIKES];

int   callCount=0;				// keeps track of number of times kernel is called
long  tot_fired = 0;			// total fired neurons since the start...
long  tot_filteredSpikes = 0;	// total number of filtered spikes since the start...
float accTimer = 0;				// total executing time is kept here...

////////////////////////////////////////////////////////////////////////////////
// Program main
////////////////////////////////////////////////////////////////////////////////
int main( int argc, char** argv)
{
    fpLog = fopen("sim.log","w");
	if(!fpLog) {
		fprintf(stderr, "Cannot create simulation logging file sim.log in current directory\n");		
		exit(1);
	}

	printf("starting jaercuda \n");

	/* Print out the date and time in the standard format. */
    /* Convert it to local time representation. */
    time_t curTime = time(NULL);
    struct tm *locTime;
	locTime = localtime (&curTime);     
    fprintf(fpLog, "==============================================================\n");
    fprintf(fpLog, "jAER-CUDA Simulation Log \n");
	fprintf(fpLog, "==============================================================\n");
    fputs (asctime (locTime), fpLog);
    fprintf(fpLog, "Delta time value : %d\n", delta_time);
	fflush(fpLog);    
	fflush(stdout);
	
	runjaerCUDA( argc, argv);

	fprintf(fpLog, "**END**\n");
	fclose(fpLog);

}

// initial values for the parameters are set here...
globalNeuronParams_t hostNeuronParams={
	MEMBRANE_THRESHOLD,
	MEMBRANE_TAU,
	MEMBRANE_POTENTIAL_MIN,
	MIN_FIRING_TIME_DIFF,
	EI_SYN_WEIGHT,
	IE_SYN_WEIGHT
};

bool sendGlobalNeuronParamsEnabled=1; // flag set from control thread
bool sendTemplateEnabled=1; // set from control thread
bool stopEnabled=0;  // set by jaer command 

cudaArray* cuArray; // used for texture template memory

void allocateDeviceMemory()
{
	
//	void* devPtr;
	//int size=sizeof(float)*MAX_NUM_OBJECT*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE;
	//int size=sizeof(conv_template); // 46k bytes (48x48x5 object* 4 bytes/float), OK
	
	CUDA_SAFE_CALL(cudaGetSymbolAddress(&conv_templateAddr, "gpu_conv_template"));     // no such address on device
	//CUDA_SAFE_CALL(cudaMalloc(&conv_templateAddr, sizeof(conv_template))); // devPtr is the device (global) memory we will treat as a texture on the device
	//CUDA_SAFE_CALL(cudaMemcpy(devPtr, &conv_templateAddr, sizeof(conv_templateAddr), cudaMemcpyHostToDevice));

	// allocate GPU cudaArray for convolution kernel, will be bound to a texture
	// cudaArray is 1d array of size sizeof(conv_template) which is M*n*n where M is # of templates and n is kernel size
	// cudaArray contains float values
	cudaChannelFormatDesc channelDesc = cudaCreateChannelDesc(32, 0, 0, 0, cudaChannelFormatKindFloat);
	CUDA_SAFE_CALL (cudaMallocArray (&cuArray, &channelDesc, sizeof(conv_template), 1));
	CUDA_SAFE_CALL (cudaBindTextureToArray (template_tex, cuArray));
	template_tex.normalized=0; // use int lookup for texture
	template_tex.filterMode=cudaFilterModePoint; // nearest texture value

   
    // CUDA_SAFE_CALL(cudaMemset(conv_templateAddr,0,sizeof(conv_template)));
	// CUDA_SAFE_CALL(cudaGetSymbolAddress(&template_tex,"template_tex")); // template_tex is texture reference declared in device kernel
    // see http://forums.nvidia.com/index.php?showtopic=86599&hl=cudaBindTexture
    // CUDA_SAFE_CALL(cudaBindTexture(0, template_tex, conv_templateAddr, sizeof(conv_template))); // bind to this device memory as texture ?? where is template_tex set on host side???	
    // CUDA_SAFE_CALL(cudaBindTexture(0, template_tex, conv_templateAddr)); // bind to this device memory as texture ?? where is template_tex set on host side???

	CUDA_SAFE_CALL (cudaGetSymbolAddress ( &numFiring0AddrMO, "numFiring0"));
	CUDA_SAFE_CALL (cudaGetSymbolAddress ( &numFiring1AddrMO, "numFiring1"));
	CUDA_SAFE_CALL (cudaGetSymbolAddress ( &devPtrSpikeAddr, "gpu_spikeAddr"));
	CUDA_SAFE_CALL (cudaGetSymbolAddress ( &devPtrSpikeTime, "gpu_spikeTime"));

}

#define BASE_ADDRESS_COALESE 256
#define CHECK_ADDRESS

void sendTemplates()
{
	//void *devPtr;
	cudaThreadSynchronize();
	//CUDA_SAFE_CALL( cudaMemcpy( temp_conv_template,  devPtr, sizeof(conv_template), cudaMemcpyDeviceToHost));
	//dumpTemplate(temp_conv_template[1], "ref_template", 1);
	//CUDA_SAFE_CALL(cudaGetSymbolAddress(&devPtr, gpu_conv_template));
	CUDA_SAFE_CALL( cudaMemcpy( conv_templateAddr, &conv_template[0][0][0], sizeof(conv_template), cudaMemcpyHostToDevice));
	//assert(test != cudaErrorInvalidSymbol);
#pragma warning(disable:4313)
	printf("Copying templates to GPU (loc = %x, size = %d bytes)\n", conv_templateAddr, sizeof(conv_template));
#pragma warning(default:4313)

	//CUDA_SAFE_CALL( cudaMemcpy( conv_templateAddr, &conv_template[0][0][0], sizeof(conv_template), cudaMemcpyHostToDevice));
	CUDA_SAFE_CALL( cudaMemcpyToArray(cuArray, 0, 0, conv_template, sizeof(conv_template), cudaMemcpyHostToDevice) );

	cudaThreadSynchronize();
	// do we have to bind texture again here??
	//CUDA_SAFE_CALL(cudaBindTexture(0, template_tex, conv_templateAddr)); // bind to this device memory as texture ?? where is template_tex set on host side???
	sendTemplateEnabled=0;
	FILE *fp = fopen("gpu_template.m", "w");
	dumpTemplate( fp, "gpu_template.m");
	fclose(fp);
	fflush(stdout);
	CUT_CHECK_ERROR("after sendTemplates");
}

void initializeNeurons()
{
	void *devPtr;
	cudaThreadSynchronize();
	CUDA_SAFE_CALL ( cudaGetSymbolAddress(&devPtr, "gpu_membranePotential"));
#pragma warning(disable:4313)
	printf("Zeroing membrane Potentials on GPU (loc = %x, size = %d bytes)\n", devPtr, sizeof(gpu_membranePotential));
#pragma warning(default:4313)
	CUDA_SAFE_CALL( cudaMemset( devPtr, 0, sizeof(membranePotential)));
	//CUDA_SAFE_CALL( cudaMemcpy( devPtr, &membranePotential[0][0][0], sizeof(membranePotential), cudaMemcpyHostToDevice));
	cudaThreadSynchronize();

	CUDA_SAFE_CALL(cudaGetSymbolAddress(&devPtr, gpu_lastTimeStamp));
#pragma warning(disable:4313)
	printf("Copying last time stamp value to GPU (loc = %x)\n", devPtr);
#pragma warning(default:4313)
	//CUDA_SAFE_CALL( cudaMemset (devPtr, 0, sizeof(lastTimeStamp)));
	CUDA_SAFE_CALL( cudaMemcpy( devPtr, &lastTimeStamp[0][0][0], sizeof(lastTimeStamp), cudaMemcpyHostToDevice));
	cudaThreadSynchronize();
	
	printf("Initializing inhibitory neurons\n");
	CUDA_SAFE_CALL(cudaGetSymbolAddress(&devPtr, numFiring0));	
	CUDA_SAFE_CALL( cudaMemset (devPtr, 0, sizeof(int)*MAX_NUM_OBJECT));		

	CUDA_SAFE_CALL(cudaGetSymbolAddress(&devPtr, numFiring1));	
	CUDA_SAFE_CALL( cudaMemset (devPtr, 0, sizeof(int)*MAX_NUM_OBJECT));		

	memset(inh_mem_potential,0,sizeof(float)*MAX_NUM_OBJECT);
	memset(tot_fired_MO,0,sizeof(long)*MAX_NUM_OBJECT);

	cudaThreadSynchronize();
	
	CUT_CHECK_ERROR("after initializeNeurons");
	fflush(stdout);
}

void jaerCudaInit() 
{
	// already done in main loop //sendTemplates();
	initializeNeurons();
}

void cudaClean()
{
	
}

void cudaCopySpikesFromGPU2jAER(unsigned long timeStamp, int n_fired, int *n_firedMO)
{
		int t_ineuron_fired = 0;		
		int accAddr=0;
		
		// copy fired neurons
		if ( n_fired != 0 ) {			
			for ( int i=0; i < num_object; i++) {

				if(n_firedMO[i] >= MAX_SENDING_SPIKES) {
					if(debugLevel>-1) printf("# output spikes in kernel(%d) overflowed kernel buffer, dropping excess\n",n_firedMO[i]);
					continue;
					//TODO: copy them in smaller chunks and send to the jAER
				}

				// copy the fired array from GPU to CPU
				if (n_firedMO[i]){
					CUDA_SAFE_CALL(cudaMemcpyFromSymbol(&firedNeuron_addr[0], "firedNeuronAddr", sizeof(int)*n_firedMO[i], sizeof(int)*MAX_FIRING*i, cudaMemcpyDeviceToHost));
				}

				// TODO cast from raw address back to addrx, addry, shouldn't be necessary
				for(int j = 0; j < n_firedMO[i]; j++) {
					unsigned int addrx = (firedNeuron_addr[j]) & 0x7f;
					unsigned int addry = (firedNeuron_addr[j]>>8)&0x7f;
				
					// accumulate fired neuron and send to jaer
					jaerSendEvent(addrx,addry,timeStamp,i);
				}

				if (t_ineuron_fired) // TODO never set???
					jaerSendEvent(1,1,timeStamp,255);  // type=1 for inhibitory neuron TODO

				accAddr += n_firedMO[i];	
			}		
		}

		if(debugLevel>1)
			fprintf(stdout,"cudaUpdateStatus: sent %d spikes to jaer\n", n_fired);

}

/*
void cudaUpdateStatus(unsigned long timeStamp, int n_fired)
{
//		int i_val = 0;
		int t_ineuron_fired = 0;
//		float f_val = 0.0;			
		
		// copy fired neurons
		if ( n_fired != 0 ) {				
				
			CUDA_SAFE_CALL (cudaMemcpyFromSymbol(&firedNeuron_addr, "firedNeuronAddr", sizeof(int)*n_fired, 0, cudaMemcpyDeviceToHost));				
	
			for(int i = 0; i < n_fired; i++) {
			
				unsigned int addrx = (firedNeuron_addr[i]) & 0xff;
				unsigned int addry = (firedNeuron_addr[i]>>8)&0xff;
				
				// accumulate fired neuron and send to jaer
				jaerSendEvent(addrx,addry,timeStamp,0);

				if (t_ineuron_fired)
					jaerSendEvent(1,1,timeStamp,1);
			}		

		}						
}*/

int cpu_nfiredMO[MAX_NUM_OBJECT];// number of neurons that got fired in the last kernel call

// function that updates the status of inibitory WTA neurons
// TODO: Make the inhibitory neurons also leaky....
// Currently the inhibitory neurons are NOT leaky...
// returns true if any WTA neuron from any template fired, else false
bool cudaUpdateINeuron(void* numFiringAddr, unsigned long timeStamp)
{
		bool retVal = false;

		// copy the number of template layer neurons that have fired...
		CUDA_SAFE_CALL(cudaMemcpy(cpu_nfiredMO, numFiringAddr, sizeof(int)*num_object, cudaMemcpyDeviceToHost));
		
		int net_firing=0;
		//logic implementing inhibitory neuron for each neuronArray
		for ( int i=0; i < num_object; i++) {
			int n_fired = cpu_nfiredMO[i];
			inh_mem_potential[i] = inh_mem_potential[i] + hostNeuronParams.eISynWeight*n_fired;
			net_firing += n_fired;
			if (inh_mem_potential[i] > hostNeuronParams.threshold) {
				inh_mem_potential[i] = 0.0;
				inhFireCnt++;
				retVal= true;
			}				
			tot_fired += n_fired;
			tot_fired_MO[i] += n_fired; //per object firing
		}

		if(debugLevel>2){
			printf("# spikes fired by object layers: ");
			for(int i=0;i<num_object;i++){
				printf("%d, ",cpu_nfiredMO[i]);
			}
			printf("\n");
		}
		
#ifndef REPLAY_MODE
		// TODO, ifdef branches are wierd, one calls function to copy and send spikes to jear, the other copies spikes from GPU to the same array only
		if (net_firing) {
			cudaCopySpikesFromGPU2jAER(timeStamp, net_firing, cpu_nfiredMO);			
		}
#else
		// TODO: we bring all spike info into one firedNeuron_addr array. So all the
		// object firing is lumped into one AER display. Use different
		// color to distinguish output from different object
		int accAddr=0;
		for ( int i=0; i < num_object; i++) {

			if(accAddr >= MAX_SENDING_SPIKES) {
				printf("Total generated spikes is more than sending array size;\n");
				accAddr = 0;
			}

			//TODO: Some problem in retrieving the multiobject data
			if (cpu_nfiredMO[i]){
				CUDA_SAFE_CALL(cudaMemcpyFromSymbol(&firedNeuron_addr[accAddr], "firedNeuronAddr", sizeof(int)*cpu_nfiredMO[i], sizeof(int)*MAX_FIRING*i, cudaMemcpyDeviceToHost));	
			}
			accAddr += cpu_nfiredMO[i];
		}			
		//assert(accAddr == net_firing);
#endif	
		return retVal;
}

/*
bool cudaUpdateINeuron(int firingId, unsigned long timeStamp)
{
		int n_fired = 0;
//		int i_val = 0;
		static float f_val = 0.0;
		bool retVal = false;
		
		// copy and then reset numFiring
		if ( firingId )
			cudaMemcpy( &n_fired, numFiring1Addr, 4, cudaMemcpyDeviceToHost);
		else
			cudaMemcpy( &n_fired, numFiring0Addr, 4, cudaMemcpyDeviceToHost);
	
		gnFired = n_fired;
		
		f_val = f_val + hostNeuronParams.eISynWeight*n_fired;
		
		if ( f_val > hostNeuronParams.threshold ) {
			f_val = 0.0;
			inhFireCnt++;
			retVal= true;
		}
		else	
			retVal = false;
		
		tot_fired += n_fired;							
		
#ifndef REPLAY_MODE
		if (n_fired) {
			cudaUpdateStatus(timeStamp, n_fired );			
		}
#else
		if ( n_fired != 0 )  {
				cudaMemcpyFromSymbol(&firedNeuron_addr, "firedNeuronAddr", sizeof(int)*n_fired, 0, cudaMemcpyDeviceToHost);
				fprintf(stdout,"Dumping %d spikes num\n", n_fired);
				fflush(stdout);
		}
#endif	
		return retVal;
}
*/

// keep tracks of how many spikes that are suppied to GPU kernel
// For performance evaluation and analysis....
int paramLenArr[PARAM_LEN_SIZE];

float  cpuDebugArr[MAX_NUM_BLOCKS][100];	//used for debugging...
unsigned long cpuDebugArrInt[MAX_NUM_BLOCKS][100];	//used for debugging...

////////////////////////////////////////////////////////////////////////////////
//! Main function that interacts with jAER and CUDA GPU
////////////////////////////////////////////////////////////////////////////////
int
runjaerCUDA( int argc, char** argv)
{
	int iResult;
	int numEvents;	

	// Initialize CUDA device. If we have multiple CUDA device we are using device 0.
	int dev;
	CUT_DEVICE_INIT(argc, argv);
	CUDA_SAFE_CALL(cudaSetDevice(0));
	CUDA_SAFE_CALL(cudaGetDevice(&dev));
	cudaDeviceProp deviceProp;                              
	CUDA_SAFE_CALL_NO_SYNC(cudaGetDeviceProperties(&deviceProp, dev)); 
	fprintf(stderr, "Using device %d: %s\n", dev, deviceProp.name); 

	// already initialized statically but we do it again here to be sure to get the fields
	hostNeuronParams.threshold=MEMBRANE_THRESHOLD;
	hostNeuronParams.membraneTau=MEMBRANE_TAU;
	hostNeuronParams.membranePotentialMin=MEMBRANE_POTENTIAL_MIN;
	hostNeuronParams.minFiringTimeDiff=MIN_FIRING_TIME_DIFF;
	hostNeuronParams.eISynWeight=EI_SYN_WEIGHT;
	hostNeuronParams.iESynWeight=IE_SYN_WEIGHT;

	// allocates and notes down various memory in the GPU side...	
	allocateDeviceMemory();

	//waveInit(); // TODO commented out because file not checked in yet


#ifndef REPLAY_MODE
	jaerInit();
#endif

//	int debugk=0;

	// CUDA GRID/BLOCK PARAMETERS ....	
	// setup execution parameters for single spike, single object case
	dim3 gridInhib(128,1,1);
	dim3 threadInhib(128,1,1);


	//if(runCuda) {
	//	printf("===> Grid configuration is (%d, %d, %d)\n", gridDim.x, gridDim.y, gridDim.z);
	//	printf("===> Block dimension is (%d, %d, %d)\n", threadDim.x, threadDim.y, threadDim.z);	

	//	fprintf(fpLog, "===> Grid configuration is (%d, %d, %d)\n", gridDim.x, gridDim.y, gridDim.z);
	//	fprintf(fpLog, "===> Block dimension is (%d, %d, %d)\n", threadDim.x, threadDim.y, threadDim.z);
	//}
	//fflush(stdout);
	
	multi_object=MULTI_OBJECT;
	unsigned int timer = 0;
	int setTimeStamp = 1;

	timer = 0;
	CUT_SAFE_CALL( cutCreateTimer( &timer));	
	
	// this is switched alternative to 0 and 1. every time kernel is called
	int firingId = 1;
	
		CUT_SAFE_CALL( cutStartTimer( timer));
	// Receive data until the server closes the connection
	do { 

		if(debugLevel>2){
			printf("*** start cycle\n");
		}
		// main loop
#ifndef REPLAY_MODE
		iResult=jaerRecv(); // in recvBuf, returns immediately if input port not yet open, blocks if waiting socket open
		//jaerServerSend(recvBuf, iResult); // debug to echo back data to jaer
		if ( iResult > 0 ) {			
			numEvents=iResult/EVENT_LEN;
			if(debugLevel>0) {
				printf("Unfiltered events received: %d\n", numEvents);
				fflush(stdout);
			}
		// don't quit if we receive 0 events (tobi), just continue
		} else if ( iResult == 0 ){
			Sleep(1);
			//fprintf(stderr, "Recieved packet with 0 events, continuing loop\n");		
			continue;
		} else {
			fprintf(stderr, "recv failed: WSAGetLastError=%d\n", WSAGetLastError());
			fflush(stderr);
			Sleep(1);
			continue;
		}
#else
		numEvents = 0;
		iResult = 0;
#endif

		if(tmpRunCuda!=runCuda){
			if(tmpRunCuda){
				sendGlobalNeuronParamsEnabled=true;
				sendTemplateEnabled=true;
				runCuda=1;
			}else{
				sendGlobalNeuronParamsEnabled=false;
				sendTemplateEnabled=false;
				runCuda=0;
			}
		} // make sure we get parameters to cuda and only change runCuda here in loop

		if(sendGlobalNeuronParamsEnabled) {
			sendGlobalNeuronParamsEnabled=0;
			fprintf(stdout, "Copying neuron global constants to device\n");
			CUDA_SAFE_CALL(cudaMemcpyToSymbol("constNeuronParams",&hostNeuronParams,sizeof(globalNeuronParams_t),(size_t)0,cudaMemcpyHostToDevice));
			CUT_CHECK_ERROR("Copy neuron global constants to device");
			fprintf(stderr,"Params th=%f, tau=%f, pot=%f, time=%f, eIWt=%f, iEWt=%f\n", 
				hostNeuronParams.threshold, hostNeuronParams.membraneTau, hostNeuronParams.membranePotentialMin, hostNeuronParams.minFiringTimeDiff,
				hostNeuronParams.eISynWeight, hostNeuronParams.iESynWeight);
		}
		
		if(sendTemplateEnabled){
			templateConvInit();
			sendTemplates();
		}

		// apply refractory filter to reduce number of events
		int numSpikes = extractJaerRawData(filteredSpike_addr, filteredSpike_timeStamp, recvBuf, numEvents);		
#ifdef REPLAY_MODE
		if (numSpikes == -1) {
			fprintf(stderr,"readNNFilter returned -1 (error), continuing\n");
			break;
		}
#else
		if (numSpikes == -1) {
			fprintf(stderr,"readNNFilter returned -1 (error), continuing\n");
			fflush(stderr);
	//		break;
			continue;
		}
#endif
		iResult = numSpikes;		
		tot_filteredSpikes += numSpikes;
		if(debugLevel>1) printf("number of spikes after refractory filter = %d\n", numSpikes);
		
		// init jAERCUDA
		if(setTimeStamp == 1)	{
			//first time we need to set the timeStamp value appropriately...
			setInitLastTimeStamp(*(filteredSpike_timeStamp));
			setTimeStamp = 0;
			if(runCuda) {				
				jaerCudaInit();
			}
		}

		int spikeLen, trackObjectId;
		unsigned long spikeTimeStampV;

		//////////////////////////////////////////
		//        CUDA-GPU MODEL				//
		//////////////////////////////////////////
		if(runCuda) {
			int  index_start=0;
			spikeLen = 0;
			// this loop iterates over spikes in the packet, calling the kernel periodically when it has collected enough
			// spikes. after copying the spike addresses to GPU memory, it passes struct params to the kernel along with 
			// gnFired and firingId (??? what are these). then it reads the number of neurons that fired and copies back the 
			// fired neuron addresses.
			for (int spk_i = 0; spk_i < numSpikes; spk_i++ ) {
				if(spk_i==0) { /* first spike in packet */
					spikeTimeStampV = filteredSpike_timeStamp[spk_i]; // set the global timestamp for packet					
					spikeLen  = 1; // 1 spike so far
					index_start = 0; // start copying addresses from here when we transfer addresses
					continue;
				}
				else if (spk_i==(numSpikes-1)){
					// this is the last spike then just go 
					// and process the bufferred spikes in the GPU.
					spikeLen++; // just increment number of spikes to be processed
				}
				else if (spikeLen == (GPU_MAX_SPIKE_PACKETS)) {
					// our buffer is full. so go and process existing spike buffer
					// the current spike will be part of next group..
				}
				else if ((filteredSpike_timeStamp[spk_i] - spikeTimeStampV) < delta_time) {		
					// if we're not the first or last spike or at the limit, and
					// If the current time stamp of a spike is within the delta_time then
					// we buffer the spike and start reading the next spike...
					spikeLen++;
					continue;
				}

				// Keep track of the number of spikes that are buffered and sent to CUDA. 
				// This is useful to understand the performance, as more grouping 
				// means good performance...and CUDA kernel launch overhead is reduced.
				if(callCount < PARAM_LEN_SIZE)
					paramLenArr[callCount]=spikeLen;
				
				assert(spikeLen!=0);		

#ifdef REPLAY_MODE
				trackObjectId = 0;
#else
				trackObjectId = curTemplateIndex; // TODO ??? who sets this???
				//printf("curtemplateIndex = %d\n",curTemplateIndex);
#endif

				// copy spikes addresses to GPU
				if(debugLevel>2){
					printf("copying %d spike addresses to GPU\n",spikeLen);
				}

				CUDA_SAFE_CALL(cudaMemcpy( devPtrSpikeAddr, &filteredSpike_addr[index_start], sizeof(int)*spikeLen, cudaMemcpyHostToDevice));
				CUT_CHECK_ERROR("Copy spike addresses to GPU");
				CUDA_SAFE_CALL(cudaMemcpy( devPtrSpikeTime, &filteredSpike_timeStamp[index_start], sizeof(unsigned long)*spikeLen, cudaMemcpyHostToDevice));
				CUT_CHECK_ERROR("Copy spike timestamps to GPU");

#if !MEASUREMENT_MODE			
				fprintf( fpLog, "%d => len=%d t=%d a=%d\n", callCount, spikeLen, spikeTimeStampV, filteredSpike_addr[index_start]);
#endif

				// firingId is a toggle 0/1 that is used for odd/even kernel launches.
				// the kernel writes the number of fired neurons for each template in the array
				// pointed to by numFiringArrayAddr, at the same time, it also sets the array pointed to 
				// by resetFiringArrayAddr all to zero. The host uses the numFiring values to update the WTA neurons.
				// this double buffering is necessary why ??? TODO
				firingId = (firingId ) ? 0 : 1;
				int* numFiringArrayAddr   = (int*)((firingId)?numFiring0AddrMO:numFiring1AddrMO);
				int* resetFiringArrayAddr = (int*)((firingId)?numFiring1AddrMO:numFiring0AddrMO); // TODO, this array is unused now
				
				// kernel evaluates multiple convolution kernels
				// setup parameters for multi-object case
				int blockY = 8*num_object; // TODO explain this grid and thread blocking 
				dim3 gridDim(8,blockY,1);
				dim3 threadDim(16,16,1);
				if(debugLevel>2){
					printf("calling multi object convNN_multiSpikeKernel with gridDim=(%d,%d,%d), threadDim=(%d,%d,%d)\n",gridDim.x, gridDim.y, gridDim.z, threadDim.x, threadDim.y,threadDim.z);
				}
				CUT_CHECK_ERROR("convNN_multiSpikeKernel Before kernel execution");
				convNN_multiSpikeKernelNew <<< gridDim, threadDim >>>
					(spikeTimeStampV, spikeLen, numFiringArrayAddr, resetFiringArrayAddr, trackObjectId);
				// check if kernel execution generated an error
				CUT_CHECK_ERROR("convNN_multiSpikeKernel Kernel execution failed");
				if(debugLevel>2) fprintf(stderr, "Kernel executed %d times...\n", callCount);
				CUT_CHECK_ERROR("Copy spikes to GPU");
				cudaThreadSynchronize();
				showMembranePotential(&filteredSpike_addr[index_start],spikeLen); // only for debug
				// execute updation of iNeuron potential in CPU
				// the single WTA neuron gets excited by the total number of spikes from the convolution
				bool iNeuronFired = cudaUpdateINeuron(numFiringArrayAddr, spikeTimeStampV);
				if (iNeuronFired) {
					// execute iNeuronCalculations; inhibition of all other neurons in GPU
					WTAKernel1DMO <<< gridInhib, threadInhib >>> (numFiringArrayAddr, num_object);
				}
				callCount++;
				spikeTimeStampV = filteredSpike_timeStamp[spk_i]; // store the time stamp of spike for next grouping
				spikeLen  = 1;					  // reset length
				index_start = spk_i;					  // reset the index
			} // iterate over spikes in this packet
			cudaThreadSynchronize();	
		} // end if(runCuda)

		//////////////////////////////////////////
		//        CPU MODEL						//
		//////////////////////////////////////////		
		else {		
			// compute reference solution
		#ifdef REPLAY_MODE
			int templateIndex = 0;
		#else
			int templateIndex = 0; //curTemplateIndex;
		#endif		
			computeGold( filteredSpike_addr, filteredSpike_timeStamp,templateIndex);
			showMembranePotential();
		}


		// dump results
		dumpResults();

	} while( stopEnabled==0 ); // until jaer tells us to exit
	
		CUT_SAFE_CALL( cutStopTimer(timer));
		accTimer += cutGetTimerValue(timer);
	CUT_SAFE_CALL( cutDeleteTimer( timer));
		
	printResults(fpLog);	
	
	//waveClose(); // TODO commented out because not checked in

	if(runCuda)	
		cudaClean();

	//Release WinSock	
	WSACleanup();
	fflush(stdout); // for jaer to get it
	return 0;

}
