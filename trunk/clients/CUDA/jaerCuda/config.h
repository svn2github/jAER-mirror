#ifndef __CONFIG_H_
#define __CONFIG_H_

#define MAX_X  128	//x axis
#define MAX_Y  128	//y axis

#define DEBUG_START				10000000000000
#define DEBUG_END				10000000000000
#define DEBUG_LEVEL				2	// -1 to suppress warnings, 0 for default, 2 or larger prints all messages
#define SCALE_FACTOR			1	// template size is 16*SCALE_FACTOR
#define MAX_SUB_TEMPLATE_SIZE_X	16
#define MAX_SUB_TEMPLATE_SIZE_Y	16
#define MAX_TEMPLATE_SIZE		(SCALE_FACTOR*MAX_SUB_TEMPLATE_SIZE_X)	//template size 

#define MAX_NUM_OBJECT			5 // tobi changed from 5 because of texture fetch failure in emulation 
#define SACCADE_TIME_INTERVAL	500000ul // the time interval to make one saccade
#define USE_DoG					1

#define TEMPLATE_Gau 1 // TODO what are these methods?
#define TEMPLATE_DoG 0

#define TEMP_METHOD0 1	// TODO ?? what are these? should be under jaer control
#define TEMP_METHOD1 0

// used by normal gaussian
#define SIGMA0			2.0f
#define MAX_AMP0		2.5f
#define MIN_AMP0		(-0.25f*MAX_AMP0)

// used by DoG
#define SIGMA1			2.0f
#define MAX_AMP1		3.2f

#define SIGMA2			12.0f
#define MAX_AMP2		0.7f

#if USE_DoG
	#define MAX_AMP_ACTIVATION 2.5F					// max conductance of excitation in the template
	#define GAUSS_VAR 2.0F							// gaussian variance of excitation amplitude
	#define MAX_NEG_AMP MAX_AMP_ACTIVATION*0.25f	// negative gaussian amplitude
	#define GAUSS_VAR_NEG 10.0F						// negative gaussian variance
#else
	#define MAX_AMP_ACTIVATION 2.5F					// max conductance of excitation in the template
	#define GAUSS_VAR 2.0F							// gaussian variance of excitation amplitude
	#define MAX_NEG_AMP -MAX_AMP_ACTIVATION*0.25f	// min conductance in the template
	#define GAUSS_VAR_NEG 10.0F						// negative gaussian variance
#endif

#define REPLAY_MODE			1
//#define RECORD_MODE			1
//#define RECORD_MEMBRANE_POTENTIAL	1
#define	RECORD_START 0
#define RECORD_END   20
#define RECORD_MODE_SAMPLES_CNT	1000		// -1 record all samples			
//#define RECORD_FIRING_INFO		0
//#define DUMP_DEBUG				1

#define MAX_NUM_BLOCKS 64
//#define VERSION_0_1 1
#define PLAY_AUDIO 0
#define GPU_MAX_SPIKE_PACKETS  100000  // max number spikes to xfer to GPU per kernel invocation, limited by global memory
#define DELTA_TIME 1000		// (this is default value). delta_time is time in us that spikes are chunked together to be sent with common timestamp. increasing speeds up processing but quantizes time more.
#define MEASUREMENT_MODE 1
#define MULTI_OBJECT 1 // TODO does multiobject work?
//#define LOOP_UNROLL_2 1
#define CPU_ENABLE_SPIKE_GROUPING 1

// global neuron parameters default initial values - modified by jaer through control port interface
#define MEMBRANE_TAU			10000.0F	// membrane time constant
#define MEMBRANE_THRESHOLD		.1F		// membrane threshold
#define MEMBRANE_POTENTIAL_MIN	-10.0F		// membrane equilibrium potential
#define MIN_FIRING_TIME_DIFF	15000		// low pass filter the events from retina

#define EI_SYN_WEIGHT	10.0		// excitatory to inhibitory synaptic weight
#define IE_SYN_WEIGHT	10.0		// inhibitory to excitatory synaptic weight

// global neuron parameters, this is a host structure and a __const__ structure for the device
typedef struct{
	float threshold;
	float membraneTau;
	float membranePotentialMin;
	float minFiringTimeDiff;
	float eISynWeight;
	float iESynWeight;
} globalNeuronParams_t;

// miscellaneous

#define DING_SOUND "ding.wav"

// network
#define JAER_SERVER_IP_ADDRESS "localhost" //"128.195.54.156" // host who we recieve/send AE from/to
#define AE_INPUT_PORT    9999 // we receive events from jaer on this port
#define AE_OUTPUT_PORT  7000 // we send events to jaer on this port
#define CONTROL_PORT 9998 // we are controlled by jaer on this port

#define RECV_SOCK_BUFLEN		63000 // 63000 is jaer buffer size // 0x8000 // 32k	// socket buffer size for incoming events in bytes, if too small, then datagrams will not be received
#define SEND_SOCK_BUFLEN		63000// as big on GPU side // 0x800			// socket buffer size for outgoing events in bytes
#define EVENT_LEN 8							// bytes/event over socket connection (will be changed to 8 soon)
#define USE_PACKET_SEQUENCE_NUMBER 1 // define to use leading 4 bytes sequence number in incoming packets to detect dropped packets
#define MAX_XMIT_INTERVAL_MS	40 // default max interval in ms between sending out packets of spikes, even if buffer is not full

#define NUM_CUDA_PACKETS	1 //8 ??? what is this

// Helper macro for displaying errors
#define PRINTERROR(s)	\
		fprintf(stderr,"\nError %s: WSAGetLastError()= %d\n", s, WSAGetLastError())

extern float conv_template[MAX_NUM_OBJECT][MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];
extern unsigned long lastInputStamp[MAX_X][MAX_Y];
extern float membranePotential[MAX_NUM_OBJECT][MAX_X][MAX_Y];
extern unsigned long lastTimeStamp[MAX_NUM_OBJECT][MAX_X][MAX_Y];
extern float iNeuronPotential[MAX_NUM_OBJECT];

extern int   callCount;
extern long  tot_fired;
extern long  tot_filteredSpikes;
extern float accTimer;
///extern float cpu_accTimer;
///extern int   timerCount;

extern bool runCuda;
extern bool tmpRunCuda; // tmp is for command processing
extern int  gnFired;
extern long tot_fired_MO[MAX_NUM_OBJECT];
extern int  inhFireCnt;
extern int  multi_object;
extern int  num_object;   
extern unsigned int delta_time;

extern int debugLevel;
#define PARAM_LEN_SIZE 500
extern int paramLenArr[PARAM_LEN_SIZE];

extern globalNeuronParams_t hostNeuronParams;

extern bool sendGlobalNeuronParamsEnabled; // flag set from control thread
extern bool sendTemplateEnabled; // set from control thread
extern bool stopEnabled;  // set by jaer command 

// TODO why is this limit set here, not in config.h? 
// TODO what determines it and why is is not set by network buffer size?
#define MAX_FIRING 100000 // max number of stored spikes by a kernel, using GPU global memory (big)
#define MAX_SENDING_SPIKES MAX_FIRING*MAX_NUM_OBJECT // max number of spikes sent from GPU to CPU per invocation
#endif

