#ifndef __CONFIG_H_
#define __CONFIG_H_

/****************************************** Network Size ****************************************************/
#define MAX_X						128				//x axis
#define MAX_Y						128				//y axis

#define MAX_NUM_OBJECT				5				// total number of objects if using template DoG or Gaussian
#define GABOR_MAX_NUM_ORIENTATION	4				// orientation of the gabor function
#define MAX_NUM_TEMPLATE			((GABOR_MAX_NUM_ORIENTATION >= MAX_NUM_OBJECT) ? GABOR_MAX_NUM_ORIENTATION:MAX_NUM_OBJECT) //?????

/****************************************** Template Parameters ***************************************************/
#define SCALE_FACTOR				1				// template size is 16*SCALE_FACTOR
#define MAX_SUB_TEMPLATE_SIZE_X		16
#define MAX_SUB_TEMPLATE_SIZE_Y		16
#define MAX_TEMPLATE_SIZE			(SCALE_FACTOR*MAX_SUB_TEMPLATE_SIZE_X)	//template size 


#define TEMPLATE_Gab				2				//gabor template
#define TEMPLATE_Gau				1				//gaussian template with constant negative tail
#define TEMPLATE_DoG				0				//difference of gaussian template

#define TEMP_METHOD0				1				//jay's template generation method
#define TEMP_METHOD1				0				//the default method


/******* used by method 0 ********/
// used by normal gaussian 
#define SIGMA0						2.0f
#define MAX_AMP0					2.5f
#define MIN_AMP0					(-0.25f*MAX_AMP0)

// used by DoG 
#define SIGMA1						2.0f
#define MAX_AMP1					3.2f
#define SIGMA2						12.0f
#define MAX_AMP2					0.7f

/******* used by method 1 *********/
// used by DOG and gaussian with constant negative tail
#define MAX_AMP_ACTIVATION			2.5F							// max conductance of excitation in the template
#define GAUSS_VAR					2.0F							// gaussian variance of excitation amplitude
#define MAX_NEG_AMP					-MAX_AMP_ACTIVATION*1.0f		// negative gaussian amplitude
#define GAUSS_VAR_NEG				10.0F							// negative gaussian variance

// used by gabor function
#define GABOR_MAX_AMP				2.0F			// maximum amplitude of gabor function
#define GABOR_BAND_WIDTH			1.5F			// bandwidth of the gabor function
#define GABOR_WAVELENGTH			2.0F			// wavelength of the gabor function
#define GABOR_PHASE_OFFSET			0.0F			// phase offset of the gabor function(-90 to 90 degree)
#define GABOR_ASPECT_RATIO			0.5F			// aspect ratio of the gabor function
#define GABOR_XY_MAX				5.0F			// the maximum value of x and y value
#define PI							3.14159265358979323846F


/******************************************** Kernel Parameters *****************************************/
#define GPU_MAX_SPIKE_PACKETS		100000		// max number spikes to xfer to GPU per kernel invocation, limited by global memory
#define DELTA_TIME					1000		// (this is default value). delta_time is time in us that spikes are chunked together to be sent with common timestamp. increasing speeds up processing but quantizes time more.
#define MAX_FIRING					100000 // max number of stored spikes by a kernel, using GPU global memory (big)
#define MAX_SENDING_SPIKES			MAX_FIRING*MAX_NUM_TEMPLATE // max number of spikes sent from GPU to CPU per invocation

/******************************************** Debuging Parameters ****************************************/
#define MEASUREMENT_MODE			1			// write log file if it is set to 0
#define DEBUG_LEVEL					2			// -1 to suppress warnings, 0 for default, 2 or larger prints all messages
//#define REPLAY_MODE				1			// replay from a file if defined	

//#define RECORD_MEMBRANE_POTENTIAL	1			// set to record membrane potentials
#define	RECORD_START				0			// set the start recording cycle for membrane potential recording
#define RECORD_END					20			// set the stop recording cycle for membrane potential recording

//#define RECORD_FIRING_INFO		0			// record the output spikes under CPU mode

//#define DUMP_RECV_DATA			1			// dump the data received from jaer into a file
//#define DUMP_FILTERED_DATA		1			// dump the filtered input spikes 
#define RECORD_MODE_SAMPLES_CNT		1000		// -1 record all samples, the number of packets to be recorded, used in both DUMP_RECV_DATA and DUMP_FILTERED_DATA mode

#define PARAM_LEN_SIZE				500



/******************************************** Neuron Parameters ******************************************/
// global neuron parameters default initial values - modified by jaer through control port interface
#define MEMBRANE_TAU				10000.0F	// membrane time constant
#define MEMBRANE_THRESHOLD			.1F			// membrane threshold
#define MEMBRANE_POTENTIAL_MIN		-200.0F		// membrane equilibrium potential
#define MIN_FIRING_TIME_DIFF		15000		// low pass filter the events from retina
#define EI_SYN_WEIGHT				10.0		// excitatory to inhibitory synaptic weight
#define IE_SYN_WEIGHT				10.0		// inhibitory to excitatory synaptic weight

// inhibition type
#define GLOBAL_INH					1			// global inhibition among populations
#define LOCAL_WTA					1			// network with inhibitory coupling between different features at the same network position

/******************************************** JAER Communication Parameters *******************************/
#define JAER_SERVER_IP_ADDRESS		"localhost" //"128.195.54.156" // host who we recieve/send AE from/to
#define AE_INPUT_PORT				9999		// we receive events from jaer on this port
#define AE_OUTPUT_PORT				7000		// we send events to jaer on this port
#define CONTROL_PORT				9998		// we are controlled by jaer on this port

#define RECV_SOCK_BUFLEN			63000		// 63000 is jaer buffer size // 0x8000 // 32k	// socket buffer size for incoming events in bytes, if too small, then datagrams will not be received
#define SEND_SOCK_BUFLEN			63000		// as big on GPU side // 0x800			// socket buffer size for outgoing events in bytes
#define CMD_SOCK_BUFLEN			8000		// buffer for string commands sent from jaer
#define EVENT_LEN 8								// bytes/event over socket connection (will be changed to 8 soon)
#define USE_PACKET_SEQUENCE_NUMBER	1			// define to use leading 4 bytes sequence number in incoming packets to detect dropped packets
#define MAX_XMIT_INTERVAL_MS		40			// default max interval in ms between sending out packets of spikes, even if buffer is not full

/******************************************** Audio Parameter *********************************************/
#define DING_SOUND					"ding.wav"


// global neuron parameters, this is a host structure and a __const__ structure for the device
typedef struct{
	float threshold;
	float membraneTau;
	float membranePotentialMin;
	float minFiringTimeDiff;
	float eISynWeight;
	float iESynWeight;
} globalNeuronParams_t;


extern float conv_template[MAX_NUM_TEMPLATE][MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];
extern unsigned long lastInputStamp[MAX_X][MAX_Y];
extern float membranePotential[MAX_NUM_TEMPLATE][MAX_X][MAX_Y];
extern unsigned long lastTimeStamp[MAX_X][MAX_Y];
extern float iNeuronPotential[MAX_NUM_TEMPLATE];

extern long tot_fired_MO[MAX_NUM_TEMPLATE];
extern int  inhFireCnt;
extern long  tot_filteredSpikes;

extern int  num_object;   
extern int  template_type;
extern unsigned int delta_time;

extern int debugLevel;

extern int paramLenArr[PARAM_LEN_SIZE];

extern globalNeuronParams_t hostNeuronParams;

extern int   callCount;
extern float accTimer;

extern bool runCuda;
extern bool tmpRunCuda; // tmp is for command processing

extern bool sendGlobalNeuronParamsEnabled; // flag set from control thread
extern bool sendTemplateEnabled; // set from control thread
extern bool stopEnabled;  // set by jaer command 

extern float f_gabor_bandwidth; //bandwidth of the gabor function
extern float f_gabor_theta[];  // orientation of the gabor function
extern float f_gabor_lambda;	//wavelength of the gabor function
extern float f_gabor_psi;	//phase offset of the gabor function
extern float f_gabor_gamma;	// aspect ratio of the gabor function
extern float f_gabor_xymax;	// the maximum value of x and y value
extern float f_gabor_maxamp; // the maximum amplitude of the gabor function

#endif

