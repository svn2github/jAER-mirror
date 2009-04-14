#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>
#include <string.h>

#include "config.h"

////////////////////////////////////////////////////////////////////////////////
// export C interface
extern "C" int extractJaerRawData( unsigned int* addr, unsigned long* timeStamp, char* Data, const unsigned int len);

extern "C" {
	void computeGold( unsigned int* addr, unsigned long* timeStamp, int templateIndex);
	int  templateConvInit(int selectType=TEMP_METHOD1, int templateType=TEMPLATE_DoG);
	void dumpTemplate(FILE* fp, char* fstr);
	void playAudio();
	void setInitLastTimeStamp(unsigned long timeStamp, int objId=0);
	void printResults();

	void jaerSendEvent(unsigned int addrx, unsigned int addry, unsigned long timeStamp, unsigned char type);
}


extern unsigned int delta_time;
extern int multi_object;
extern int num_object;
extern bool runCuda;
extern globalNeuronParams_t hostNeuronParams;
extern void jaerSendEvent(unsigned int addrx, unsigned int addry, unsigned long timeStamp, unsigned char type);

////////////////////////////////////////////////////////////////////////////////

// returns jaer int (timestamp or address) from char *, using next bytes of data
unsigned long getInt( char* data)
{
	// java is little endian, so LSB comes first to us. we put it at the MSB here and vice versa.
	unsigned long temp = (((data[0]&0xffUL) << 24) 
		+ ((data[1]&0xffUL) << 16) 
		+ ((data[2]&0xffUL) << 8) 
		+ (data[3]&0xffUL));
	return temp;
}


int			  cpu_totFiring=0;					// used to calculate the average firing rate from CPU model
int			  cpu_totFiringMO[MAX_NUM_OBJECT];	// store the firing count for each object that is tracked.
float		  conv_template[MAX_NUM_OBJECT][MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];		// template of all objects
unsigned long lastInputStamp[MAX_X][MAX_Y];		// stores the time of last firing of the input addr. This is used
												// to filter spikes that happens at a high rate.
float		  membranePotential[MAX_NUM_OBJECT][MAX_X][MAX_Y];	// corresponds to membrane potential of each neuron.																	
unsigned long lastTimeStamp[MAX_NUM_OBJECT][MAX_X][MAX_Y];		// store the firing time of each neuron. This is used
																// calcuate the membrane potential decay.
const float	  objSizeArray[] = {15,8,5,3,20,30}; // 15.0,7.0,22.0,21.0,20.0,19.0,18.0,12.0,11.0,10.0};	// ball size in pixels
float		  iNeuronPotential[MAX_NUM_OBJECT];	// membrane potential of inhibitory neuron. one inhibitory neuron
												// for each object plane or object to be recognized
int iNeuronFiringCnt = 0;						// used to calculate the firing rate of inhibitory neurons
int iNeuronCallingCnt = 0;						// keeps track of number of times an inhibitory neuron is called.

int lastSequenceNumber=0;	// to check dropped packets from jaer

void setInitLastTimeStamp(unsigned long timeStamp, int objId){
	for(int i = 0; i < MAX_X; i++){
		for(int j = 0; j < MAX_Y; j++){
			lastTimeStamp[objId][i][j] = timeStamp;
		}
	}
}

// This function implement the behaviour of inhibitory neuron.
// the amount of inhibition is dependent upon the number
// of neuron that has fired recently ('numFired'). If the number
// of fired neuron increases, then the amount of inhibition increases.
// TODO: Add leaky behavior for inhibitory neurons. Currently
// the neuron does not have leaky behaviour. It just accumulates
// and then fires if the membrane potential of inhibitory crosses the threshold.
int update_inhibition_neuron(FILE *fp, unsigned long timeStamp, int objId=0,int numFired=1)
{
	iNeuronPotential[objId] += (float)(hostNeuronParams.eISynWeight*numFired);
	iNeuronCallingCnt++;

	if(iNeuronPotential[objId] > hostNeuronParams.threshold ) {
		iNeuronFiringCnt++;
		for(int i=0; i < MAX_Y; i++) {
			for(int j=0; j < MAX_X; j++) {		
				membranePotential[objId][i][j] -= hostNeuronParams.iESynWeight;
				if (membranePotential[objId][i][j]< hostNeuronParams.membranePotentialMin)
					membranePotential[objId][i][j] = hostNeuronParams.membranePotentialMin;
			}
		}

#if RECORD_FIRING_INFO
		if ( fp != NULL)
			fprintf( fp, "%u -1 -1\n", timeStamp);
#endif
		iNeuronPotential[objId] = 0.0;
		return 1;
	}
	return 0;
}

unsigned long lastSaccadeTime = 0;	// stores the time when last saccade happened
unsigned long prevTimeStamp = 0;	// stores the time when last event happened
unsigned int lenData = 0;			// stores the length of data generated from input
long long num_packets = 0;			// 
int curTemplateIndex = -1;			// stores the index of the current template. This switches
									// to a new value after each saccade interval.

void update_neurons(unsigned int addrx, unsigned int addry, unsigned long timeStamp, int templateIndex,int multiObj=0)
{
	static FILE* fpFiring = NULL;
	int objId=0;
	int numObj=1;
	if(multiObj) {
		numObj=num_object;
		objId = 0;		
	}

#if RECORD_FIRING_INFO
	if(fpFiring == NULL){
		if ((fpFiring = fopen("firing.m", "w")) == NULL){
			printf("failed to open file firing.m");
			return;
		}
	}	
#endif

	int min_x = addrx - (MAX_TEMPLATE_SIZE/2) + 1;
	int temp_min_x = (min_x < 0 ) ? min_x  - 1 : min_x;
	min_x = (min_x <  0 ) ? 0 : min_x;

	int min_y = addry - (MAX_TEMPLATE_SIZE/2) + 1;
	int temp_min_y = (min_y < 0 ) ? min_y  - 1 : min_y;
	min_y = (min_y < 0 ) ? 0 : min_y;

	int max_x = addrx + (MAX_TEMPLATE_SIZE/2);
	max_x = (max_x > MAX_X) ? MAX_X : max_x;

	int max_y = addry + (MAX_TEMPLATE_SIZE/2);
	max_y = (max_y > MAX_Y ) ? MAX_Y : max_y;

	for( int k = 0; k < numObj; k++) {
		for( int i = min_x; i < max_x; i++) {
			for( int j = min_y; j < max_y; j++) {
				assert(i-temp_min_x>=0);
				assert(i-temp_min_x<MAX_TEMPLATE_SIZE);
				assert(j-temp_min_y>=0);
				assert(j-temp_min_y<MAX_TEMPLATE_SIZE);

				if((timeStamp-lastTimeStamp[objId][i][j]) < 0) {
					printf("Time stamp reversal\n");

#if RECORD_FIRING_INFO
					fclose(fpFiring);
#endif
					//return;
				}

				signed long long timeDiff = 0xFFFFFFFFLL&(timeStamp-lastTimeStamp[objId][i][j]);

				float temp = (float)timeDiff/hostNeuronParams.membraneTau;
				//if(temp >  500){
				//	temp = 0;
				//}else{
					temp = (float)exp(-temp);
				//}
			
				//if(conv_template[curTemplateIndex][i-temp_min_x][j-temp_min_y] != 0.0)
				//	conv_template[curTemplateIndex][i-temp_min_x][j-temp_min_y] = conv_template[curTemplateIndex][i-temp_min_x][j-temp_min_y];
				
				if(multiObj)
					templateIndex = objId;	

				membranePotential[objId][i][j] = membranePotential[objId][i][j]*temp +
										   conv_template[templateIndex][i-temp_min_x][j-temp_min_y];
				
				lastTimeStamp[objId][i][j] = timeStamp;

				if((membranePotential[objId][i][j]) > hostNeuronParams.threshold) {

					cpu_totFiring++;
					cpu_totFiringMO[objId]++;

					// TODO: currently we do not distiguish based on objId
					// different color can be given to different object
					int ineuron_fired = update_inhibition_neuron(fpFiring, timeStamp, objId);

					membranePotential[objId][i][j] = 0;

				#if !REPLAY_MODE
					if(!runCuda) 
					{
						// accumulate fired neuron and send to jaer
						jaerSendEvent(i,j,timeStamp,0);

						if (ineuron_fired)
							jaerSendEvent(1,1,timeStamp,1);

					}
				#endif
				}
				else if ( membranePotential[objId][i][j] < hostNeuronParams.membranePotentialMin ) {
						membranePotential[objId][i][j] = hostNeuronParams.membranePotentialMin;
				}		
			}
		}
	}
}

unsigned long lastGroupingTimeStamp=0;
void update_neurons_grouping(unsigned int addrx, unsigned int addry, unsigned long timeStamp, int templateIndex,int multiObj=0)
{
	static FILE* fpFiring = NULL;
	bool  groupDiffSet = false;
	bool updateINeuron = false;
	int ineuron_fired = 0;
	int numFired = 0;
	int objId=0;
	int numObj=1;
	if(multiObj) {
		numObj=num_object;
		objId = 0;
	}

#if RECORD_FIRING_INFO
	if(fpFiring == NULL){
		if ((fpFiring = fopen("firing.m", "w")) == NULL){
			printf("failed to open file firing.m");
			return;
		}
	}	
#endif

	int min_x = addrx - (MAX_TEMPLATE_SIZE/2) + 1;
	int temp_min_x = (min_x < 0 ) ? min_x  - 1 : min_x;
	min_x = (min_x <  0 ) ? 0 : min_x;

	int min_y = addry - (MAX_TEMPLATE_SIZE/2) + 1;
	int temp_min_y = (min_y < 0 ) ? min_y  - 1 : min_y;
	min_y = (min_y < 0 ) ? 0 : min_y;

	int max_x = addrx + (MAX_TEMPLATE_SIZE/2);
	max_x = (max_x > MAX_X) ? MAX_X : max_x;

	int max_y = addry + (MAX_TEMPLATE_SIZE/2);
	max_y = (max_y > MAX_Y ) ? MAX_Y : max_y;

	for( int objId = 0; objId < numObj; objId++) {
		for( int i = min_x; i < max_x; i++) {
			for( int j = min_y; j < max_y; j++) {
				assert(i-temp_min_x>=0);
				assert(i-temp_min_x<MAX_TEMPLATE_SIZE);
				assert(j-temp_min_y>=0);
				assert(j-temp_min_y<MAX_TEMPLATE_SIZE);

				if((timeStamp-lastTimeStamp[objId][i][j]) < 0) {
					printf("Time stamp reversal\n");

#if RECORD_FIRING_INFO
					fclose(fpFiring);
#endif
					//return;
				}

				signed long long timeDiff = 0xFFFFFFFFLL&(timeStamp-lastTimeStamp[objId][i][j]);
				signed long long groupDiff = 0xFFFFFFFFLL&(timeStamp - lastGroupingTimeStamp);
				float temp = 1.0;				

				if(groupDiff>delta_time) {
						groupDiffSet = true;				
						temp = (float)timeDiff/hostNeuronParams.membraneTau;
						//if(temp >  500){
						//	temp = 0;
						//}else {
							temp = (float)exp(-temp);
						//}
				}
			
				lastTimeStamp[objId][i][j] = timeStamp;

				//TODO: Why this code was here ??
				//if(conv_template[curTemplateIndex][i-temp_min_x][j-temp_min_y] != 0.0)
				//	conv_template[curTemplateIndex][i-temp_min_x][j-temp_min_y] = conv_template[curTemplateIndex][i-temp_min_x][j-temp_min_y];
				
				if(multiObj)
					templateIndex = objId;	

				membranePotential[objId][i][j] = membranePotential[objId][i][j]*temp +
										   conv_template[templateIndex][i-temp_min_x][j-temp_min_y];
				
				if((membranePotential[objId][i][j]) > hostNeuronParams.threshold) {

					cpu_totFiring++;
					numFired++;
					cpu_totFiringMO[objId]++;

#if RECORD_FIRING_INFO
					fprintf(fpFiring, "%u %d %d\n", timeStamp, i, j);
#endif
					// TODO: currently we do not distiguish based on objId
					// different color can be given to different object								
					membranePotential[objId][i][j] = 0;

				#if !REPLAY_MODE
					if(!runCuda) {
					// accumulate fired neuron and send to jaer
						jaerSendEvent(i,j,timeStamp,0);

						if (ineuron_fired)
							jaerSendEvent(1,1,timeStamp,1);
					}
				#endif
				}
				else if ( membranePotential[objId][i][j] < hostNeuronParams.membranePotentialMin ) {
						membranePotential[objId][i][j] = hostNeuronParams.membranePotentialMin;
				}
			}
		}
	}

	// Delta crossed for grouping
	if(numFired)
		ineuron_fired = update_inhibition_neuron(fpFiring, timeStamp, objId, numFired);					

	if(groupDiffSet)
		lastGroupingTimeStamp = timeStamp;

}

bool spikeFilter(unsigned int addrx, unsigned int addry, unsigned long timeStamp){
	if((timeStamp - lastInputStamp[addrx][addry]) > hostNeuronParams.minFiringTimeDiff){
		lastInputStamp[addrx][addry] = timeStamp;
		return true;
	}else{
		return false;
	}
}

// Reads spikes information from a file 'filtered_packet.txt'
// and returns the info in addr,timeStamp array.
int readSpikeFromFile(unsigned int* addr, unsigned long* timeStamp)
{
	static FILE* fp = NULL;
	static int cntPacket = 1;	

	if(fp==NULL) {
		fp=fopen("filtered_packet.txt", "r");				
		if (!fp) {
			fprintf(stderr, "\n\n\nWARNING !!! filtered_packet.txt file not present in current directory\n");
			fprintf(stderr, "Generate one before continuing\n");
			exit(1);
		}
	}

	if(!feof(fp)) {		
		int i=0;
		while(!feof(fp)&& (i<(RECV_SOCK_BUFLEN/EVENT_LEN))) {					
				fscanf(fp, "%d %u\n", &addr[i], &timeStamp[i]);			
				i=i+1;
		}
		cntPacket++;
		return i;
	}
	else {
		return -1;
	}		
}

// store the filtered spikes in a file quicker testing
// without jAER TCP/UDP interface.
void storeFilteredSpikes(unsigned int* addr, unsigned long* timeStamp)
{
	static FILE* fp = NULL;
	static unsigned int fpOpened  = 0;	
	static int numRecorded = 0;		
	
	if(fp==NULL) {
		fp=fopen("filtered_packet.txt", "w");
		if (!fp) {
			fprintf(stderr, "\n\n\nError !!! Cannot create filtered_packet.txt in current directory\n");			
			exit(1);
		}
	}

	numRecorded += lenData;
	for(unsigned int i = 0; i < lenData; i++) {
		fprintf(fp, "%d %u\n", addr[i], timeStamp[i]);
	}
	fpOpened++;
	if(fpOpened == (unsigned)RECORD_MODE_SAMPLES_CNT) {
		fprintf(stdout, "RECORD MODE ===> %d filtered spikes recorded\n", numRecorded);		
		fprintf(stdout, "RECORDING MODE FINISHED....\n");
		fclose(fp);
		fflush(stdout);
		exit(0);
		//CUT_EXIT(argc, argv);
	}
}

/////////////////////////////////////////////////////////
// extractJaerRawData:
// This function filters incoming spikes and puts a list of filtered addresses and timeStamp
// for processing by remaining stage. This function can either take an incoming
// array of characters from TCP/UDP (stored in Data). Or it can also read the 
// input spikes from a local file called filtered_packet.txt.
// 
// Input
// -----
// Data:		The incoming spikes are stored as array of chars.
// len:			Length of the packet in events. Length of 1 corresponds to 1 AER event.
//
// Output
// ------
// addr:		List of addresses (events) after filtering
// timeStamp:	List of timeStamp for each address after filtering
////////////////////////////////////////////////////////
int
extractJaerRawData( unsigned int* addr, unsigned long* timeStamp, char* Data, const unsigned int len) 
{	
#ifdef REPLAY_MODE
	curTemplateIndex = 0;
	lenData= readSpikeFromFile(addr, timeStamp);	
	return lenData;
#endif

	lenData = 0;

#if DUMP_DEBUG
	char fname[100];
	sprintf(fname, "recv_packet%d.m", num_packets);
	FILE* fpDumpSpike;
	fpDumpSpike = fopen(fname, "w");
	fprintf( fpDumpSpike, " spikes = [ " );
#endif

	unsigned int* addrCur = addr;
	unsigned long* timeStampCur = timeStamp;
//	bool* polarityCur = polarity;
	unsigned int i;

#ifdef USE_PACKET_SEQUENCE_NUMBER
	int sequenceNumber=getInt(Data);
	if(sequenceNumber!=lastSequenceNumber+1 && lastSequenceNumber>0){
		//TODO doesn't ever seem to print out
		if(debugLevel>-1) fprintf(stderr,"extractJaerRawData: dropped packet %d packets? (sequenceNumber=%d, lastSequenceNumber=%d)\n",(sequenceNumber-lastSequenceNumber), sequenceNumber, lastSequenceNumber);
		//fflush(stderr);
	}
	lastSequenceNumber=sequenceNumber;
	Data+=4; // skip over 4 byte sequence number
#endif 

	// This code reads each packet, reconstructs addr and timeStamp
	// checks for errors, timeReversal and also filters the spikes
	// according to the frequency of occurence.
	bool filterFlag = false;
    for(  i = 0; i < len; i++)   {
		int max_x = MAX_X - 1;
		unsigned int addrxCur = max_x  - (Data[i*EVENT_LEN+3] >> 1)& 0x7f;
		unsigned int addryCur = (Data[i*EVENT_LEN+2]& 0x7f);
		*timeStampCur = getInt( &Data[i*EVENT_LEN+4]); //*((unsigned int *)&Data[i*6+2]);
		if(i == 0 && ((*timeStampCur - lastSaccadeTime) > SACCADE_TIME_INTERVAL)) {
			curTemplateIndex++;
			if(curTemplateIndex >= num_object)
				curTemplateIndex = 0;
			lastSaccadeTime = *timeStampCur;
#if	PLAY_AUDIO
			playAudio();
#endif
		}

#if DUMP_DEBUG
		 fprintf(fpDumpSpike, "%u %u %u\n", addrxCur, addryCur, *timeStampCur);
#endif

		if ( *timeStampCur < prevTimeStamp ) {
			printf("AE timestamp time reversal occured\n");			
			printf("Packet number %d\n", num_packets);
			printf("i (%d)====>\n, Data[EVENT_LEN*i] = %d\n, Data[EVENT_LEN*i+1] = %d\n, Data[EVENT_LEN*i+2] = %d\n, Data[EVENT_LEN*i+3] = %d\n,  \
						Data[EVENT_LEN*i+4] = %d\n, Data[EVENT_LEN*i+5] = %d\n,	Data[EVENT_LEN*i+6] = %d\n,	Data[EVENT_LEN*i+7] = %d\n\n",	\
						i, Data[EVENT_LEN*i] , Data[EVENT_LEN*i+1] , Data[EVENT_LEN*i+2] ,	Data[EVENT_LEN*i+3] ,	Data[EVENT_LEN*i+4] ,	Data[EVENT_LEN*i+5] , \
						Data[EVENT_LEN*i+6] , Data[EVENT_LEN*i+7]); 			
		}

		prevTimeStamp = *timeStampCur;

		filterFlag = spikeFilter(addrxCur, addryCur, *timeStampCur);
		
		if(filterFlag) {
			*addrCur = addrxCur + (addryCur << 8);
			timeStampCur++;
			//polarityCur++;
			addrCur++;
			lenData++;
		}

	}				

#if DUMP_DEBUG
	fprintf(fpDumpSpike, " ]; " );
	fclose(fpDumpSpike);
#endif

#ifdef RECORD_MODE
	storeFilteredSpikes(addr,timeStamp);
#endif

	return lenData;
}

void
computeGold( unsigned int* addr, unsigned long* timeStamp, int templateIndex) 
{
	unsigned int len = lenData;
	unsigned int i;
	for(i = 0; i < len; i++) {
		unsigned int addrx = addr[i]&0xff; 
		unsigned int addry = (addr[i]>>8)&0xff;
#if CPU_ENABLE_SPIKE_GROUPING
		update_neurons_grouping( addrx, addry, timeStamp[i], templateIndex,multi_object);
#else
		update_neurons( addrx, addry, timeStamp[i], templateIndex,multi_object);
#endif
	}
}

// generate the template for ball of given size using simple Gaussian parameters
void templateConvGau(int templateIndex, float sizeObject)
{
	if(debugLevel>0) {
		printf("templateConvGau: Generating Template #%d for sizeObject=%f\n",templateIndex,sizeObject);
	}
	int sizeTemplate = MAX_TEMPLATE_SIZE;
	//float sizeObject = MAX_OBJECT_SIZE;

	float center = (float)(sizeTemplate/2);
	int i, j;
	
	if(sizeTemplate > sizeObject){
		float ampFactor = sizeTemplate/sizeObject/2;
		float maxNegAmp = ampFactor*MAX_NEG_AMP;
		float maxAmpActivation = ampFactor*MAX_AMP_ACTIVATION;
		for(i = 0; i < sizeTemplate; i++){
			float dist = abs(i - center);
			for(j = 0; j < sizeTemplate; j++){
				if(dist > sizeObject)
					conv_template[templateIndex][i][j] = maxNegAmp;
				else if(dist == sizeObject){
					float meanGauss = center; 
					conv_template[templateIndex][i][j] = maxAmpActivation*exp(-(pow((j - meanGauss),2))/(GAUSS_VAR*GAUSS_VAR)) + maxNegAmp;
				} 
				else {
					float radiusGauss = sqrt(sizeObject*sizeObject - dist*dist);
					float meanGauss1 = center - radiusGauss,
						  meanGauss2 = center + radiusGauss;
					if(j <= center)
						conv_template[templateIndex][i][j] = maxAmpActivation*exp(-(pow((j - meanGauss1),2))/(GAUSS_VAR*GAUSS_VAR)) + maxNegAmp;
					else
						conv_template[templateIndex][i][j] = maxAmpActivation*exp(-(pow((j - meanGauss2),2))/(GAUSS_VAR*GAUSS_VAR)) + maxNegAmp;
				}
			}
		}

		//transpose
		float temp;
		for(i = 0; i < sizeTemplate; i++){
			for(j = 0; j < sizeTemplate; j++){
				if(i > j){
					temp = conv_template[templateIndex][i][j];
					conv_template[templateIndex][i][j] = conv_template[templateIndex][j][i];
					conv_template[templateIndex][j][i] = temp;
				}
			}
		}

		for(i = 0; i < sizeTemplate; i++){
			float dist = abs(i - center);
			for(j = 0; j < sizeTemplate; j++){
				if(dist > sizeObject)
					conv_template[templateIndex][i][j] = conv_template[templateIndex][i][j] + maxNegAmp;
				else if(dist == sizeObject){
					float meanGauss = center; 
					conv_template[templateIndex][i][j] = conv_template[templateIndex][i][j] + maxAmpActivation*exp(-(pow((j - meanGauss),2))/(GAUSS_VAR*GAUSS_VAR)) + maxNegAmp;
				} 
				else {
					float radiusGauss = sqrt(sizeObject*sizeObject - dist*dist);
					float meanGauss1 = center - radiusGauss,
						  meanGauss2 = center + radiusGauss;
					if(j <= center)
						conv_template[templateIndex][i][j] = conv_template[templateIndex][i][j] + maxAmpActivation*exp(-(pow((j - meanGauss1),2))/(GAUSS_VAR*GAUSS_VAR)) + maxNegAmp;
					else
						conv_template[templateIndex][i][j] = conv_template[templateIndex][i][j] + maxAmpActivation*exp(-(pow((j - meanGauss2),2))/(GAUSS_VAR*GAUSS_VAR)) + maxNegAmp;
				}
			}
		}

		for(i = 0; i < sizeTemplate; i++){
			for(j = 0; j < sizeTemplate; j++){
				if(i > j){
					temp = conv_template[templateIndex][i][j];
					conv_template[templateIndex][i][j] = conv_template[templateIndex][j][i];
					conv_template[templateIndex][j][i] = temp;
				}
			}
		}
	} 
	else{
		fprintf(stderr,"object size (%f) should be smaller than template size (%d).\n",sizeObject,sizeTemplate);
	}
}

// Generate a template for a ball using DoG for each point in the ball.
void templateConvDoG(int templateIndex, float sizeObject)
{
 
	if(debugLevel>0){
		printf("Generating DoG Template #%d for sizeObject=%f\n",templateIndex,sizeObject);
	}
	int sizeTemplate = MAX_TEMPLATE_SIZE;
	 //float sizeObject = MAX_OBJECT_SIZE;
	 float center = (float)(sizeTemplate/2);
	 int i, j;
	 
	 // difference of gaussian shape template
	 if(sizeTemplate > sizeObject){
		  float ampFactor = sizeTemplate/sizeObject/2;
		  float maxNegAmp = ampFactor*MAX_NEG_AMP;
		  float maxAmpActivation = ampFactor*MAX_AMP_ACTIVATION;
		  for(i = 0; i < sizeTemplate; i++){
		   float dist = abs(i - center);
		   for(j = 0; j < sizeTemplate; j++){
			if(dist > sizeObject)
			 conv_template[templateIndex][i][j] = maxNegAmp;
			else if(dist == sizeObject){
			 float meanGauss = center; 
			 conv_template[templateIndex][i][j] = maxAmpActivation*exp(-(pow((j - meanGauss),2))/(GAUSS_VAR*GAUSS_VAR)) - maxNegAmp*exp(-(pow((j - meanGauss),2))/(GAUSS_VAR_NEG*GAUSS_VAR_NEG));
			} else {
			 float radiusGauss = sqrt(sizeObject*sizeObject - dist*dist);
			 float meanGauss1 = center - radiusGauss,
				meanGauss2 = center + radiusGauss;
			 if(j <= center)
			  conv_template[templateIndex][i][j] = maxAmpActivation*exp(-(pow((j - meanGauss1),2))/(GAUSS_VAR*GAUSS_VAR)) - maxNegAmp*exp(-(pow((j - meanGauss1),2))/(GAUSS_VAR_NEG*GAUSS_VAR_NEG));
			 else
			  conv_template[templateIndex][i][j] = maxAmpActivation*exp(-(pow((j - meanGauss2),2))/(GAUSS_VAR*GAUSS_VAR)) - maxNegAmp*exp(-(pow((j - meanGauss2),2))/(GAUSS_VAR_NEG*GAUSS_VAR_NEG));
			}
		   }
		  }
		  //transpose
		  float temp;
		  for(i = 0; i < sizeTemplate; i++){
		   for(j = 0; j < sizeTemplate; j++){
			if(i > j){
			 temp = conv_template[templateIndex][i][j];
			 conv_template[templateIndex][i][j] = conv_template[templateIndex][j][i];
			 conv_template[templateIndex][j][i] = temp;
			}
		   }
		  }
		  for(i = 0; i < sizeTemplate; i++){
		   float dist = abs(i - center);
		   for(j = 0; j < sizeTemplate; j++){
			if(dist > sizeObject)
			 conv_template[templateIndex][i][j] = conv_template[templateIndex][i][j];
			else if(dist == sizeObject){
			 float meanGauss = center; 
			 conv_template[templateIndex][i][j] = conv_template[templateIndex][i][j] + maxAmpActivation*exp(-(pow((j - meanGauss),2))/(GAUSS_VAR*GAUSS_VAR)) - maxNegAmp*exp(-(pow((j - meanGauss),2))/(GAUSS_VAR_NEG*GAUSS_VAR_NEG));
			} 
			else {
			 float radiusGauss = sqrt(sizeObject*sizeObject - dist*dist);
			 float meanGauss1 = center - radiusGauss,
				meanGauss2 = center + radiusGauss;
			 if(j <= center)
			  conv_template[templateIndex][i][j] = conv_template[templateIndex][i][j] + maxAmpActivation*exp(-(pow((j - meanGauss1),2))/(GAUSS_VAR*GAUSS_VAR)) - maxNegAmp*exp(-(pow((j - meanGauss1),2))/(GAUSS_VAR_NEG*GAUSS_VAR_NEG));
			 else
			  conv_template[templateIndex][i][j] = conv_template[templateIndex][i][j] + maxAmpActivation*exp(-(pow((j - meanGauss2),2))/(GAUSS_VAR*GAUSS_VAR)) - maxNegAmp*exp(-(pow((j - meanGauss2),2))/(GAUSS_VAR_NEG*GAUSS_VAR_NEG));
			}
		   }
	  }

	  for(i = 0; i < sizeTemplate; i++){
	   for(j = 0; j < sizeTemplate; j++){
		if(i > j){
		 temp = conv_template[templateIndex][i][j];
		 conv_template[templateIndex][i][j] = conv_template[templateIndex][j][i];
		 conv_template[templateIndex][j][i] = temp;
		}
	   }
	  }
	 } else{
	  fprintf(stderr, "object size (%f) should be smaller than template size (%d); no template generated\n",sizeObject,sizeTemplate);
	  fflush(stderr);
	 }
}  


int circleArr[MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];
int countPixel=0;
int pixelPos[2*MAX_TEMPLATE_SIZE][2];

#define setPixel(a,b) {circleArr[a][b]=1; assert(countPixel < 2*MAX_TEMPLATE_SIZE); pixelPos[countPixel][0]=a; pixelPos[countPixel][1]=b; countPixel++;}

// generate a circle for given radius and centered at x0,y0.
void rasterCircle(int x0, int y0, int radius)
  {
	memset(circleArr,0,sizeof(circleArr));

    int f = 1 - radius;
    int ddF_x = 1;
    int ddF_y = -2 * radius;
    int x = 0;
    int y = radius;
 
    setPixel(x0, y0 + radius);
    setPixel(x0, y0 - radius);
    setPixel(x0 + radius, y0);
    setPixel(x0 - radius, y0);
 
    while(x < y) 
    {
      if(f >= 0) 
      {
        y--;
        ddF_y += 2;
        f += ddF_y;
      }
      x++;
      ddF_x += 2;
      f += ddF_x;    
      setPixel(x0 + x, y0 + y);
      setPixel(x0 - x, y0 + y);
      setPixel(x0 + x, y0 - y);
      setPixel(x0 - x, y0 - y);
      setPixel(x0 + y, y0 + x);
      setPixel(x0 - y, y0 + x);
      setPixel(x0 + y, y0 - x);
      setPixel(x0 - y, y0 - x);
    }
 }

float gaussianArr0[MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];
float gaussianArr1[MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];
float diffGaussArr[MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];

float gaussianRing[MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];
float diffGaussianRing[MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];

// generate a 2D diff-of-gaussian for given parameters
void initGaussianDoG(int idx, float sigma0, float maxAmp0, float sigma1, float maxAmp1)
{
	int i,j;

	float center = (MAX_TEMPLATE_SIZE/2);
	for(i=0; i < MAX_TEMPLATE_SIZE; i++) {
		for(j=0; j < MAX_TEMPLATE_SIZE; j++) {
			double distSqr = ((pow((double)(i-center),2))+(pow((double)(j-center),2.0)));
			gaussianArr0[i][j] = (float)( (maxAmp0)*exp(-distSqr/(2*sigma0*sigma0)));			
			gaussianArr1[i][j] = (float)( (maxAmp1)*exp(-distSqr/(2*sigma1*sigma1)));			
		}			
	}

	float sumDOG = 0.0;
	for(i=0; i < MAX_TEMPLATE_SIZE; i++) {
		for(j=0; j < MAX_TEMPLATE_SIZE; j++) {
			diffGaussArr[i][j] = gaussianArr0[i][j] - gaussianArr1[i][j];			
		}
	}
}

// generate a simple 2D gaussian for given parameters
void initGaussianGau(float sigma0, float maxAmp0, float minAmp0)
{
	int i,j;

	float center = (MAX_TEMPLATE_SIZE/2);

	for(i=0; i < MAX_TEMPLATE_SIZE; i++) {
		for(j=0; j < MAX_TEMPLATE_SIZE; j++) {
			double distSqr = ((pow((double)(i-center),2))+(pow((double)(j-center),2.0)));
			gaussianArr0[i][j] = (float)( (maxAmp0-minAmp0)*exp(-distSqr/(2*sigma0*sigma0)) + minAmp0);				
		}			
	}
}

///////////////////////////////////////////////////////////////
// This function dumps the generated gaussian 
// using method0, into a file pointed by fp.
// Run the generated file to visualize the 
// different kinds of generated templates using method0
// File name is: "template_[DoG|Gau][0|1].m"
////////////////////////////////////////////////////////////////
void dumpGauss(FILE* fp, int idx)
{
	int i,j;

	if(fp==NULL) {
		return;
	}

	fprintf(fp, "gauss%d=[\n",idx);
	for(i=0; i < MAX_TEMPLATE_SIZE; i++) {
		for(j=0; j < MAX_TEMPLATE_SIZE; j++) {
			fprintf(fp, "%f ", gaussianArr0[i][j] );
		}		
		fprintf(fp, ";\n");
	}
	fprintf(fp, "];\n");

	fprintf(fp, "circleArr%d=[\n",idx);
	for(i=0; i < MAX_TEMPLATE_SIZE; i++) {
		for(j=0; j < MAX_TEMPLATE_SIZE; j++) {
			fprintf(fp, "%d ", circleArr[i][j] );
		}		
		fprintf(fp, ";\n");
	}	
	fprintf(fp, "];\n");

	fprintf(fp, "ringTemplate%d=[\n",idx);
	for(i=0; i < MAX_TEMPLATE_SIZE; i++) {
		for(j=0; j < MAX_TEMPLATE_SIZE; j++) {
			fprintf(fp, "%f ", conv_template[idx][i][j]);
		}
		fprintf(fp, ";\n");
	}
	fprintf(fp, "];\n");
	fprintf(fp, "figure; subplot(1,3,1); surf(gauss%d); subplot(1,3,2);  imagesc(circleArr%d); subplot(1,3,3);  surf(ringTemplate%d);\n",idx,idx,idx);
	fflush(fp);
}

////////////////////////////////////////////////////
// Generate a template for ball using gaussian parameters
// Uses a different method0 for generating template.
// (1)  we draw a clear circle using 'rasterCircle' function.
// (2)  we create a simple 2D gaussian using 'initGaussian' function
// (3)  reproduce this gaussian for every point in the circle to create a gaussian ring
////////////////////////////////////////////////////
void generateObjectTemplate(FILE* fp, int templateIndex, int templateType)
{
	int i,j,k;


	countPixel=0;
	int objectRadius = (int)objSizeArray[templateIndex];
	rasterCircle(MAX_TEMPLATE_SIZE/2,MAX_TEMPLATE_SIZE/2, objectRadius);
	if (templateType==TEMPLATE_DoG)
		initGaussianDoG(templateIndex,SIGMA1, MAX_AMP1, SIGMA2, MAX_AMP2);
	else
		initGaussianGau(SIGMA0, MAX_AMP0, MIN_AMP0);
	float templateSum=0;
	for(i=0; i < MAX_TEMPLATE_SIZE; i++) {
		for(j=0; j < MAX_TEMPLATE_SIZE; j++) {
			
			float minVal=1000000;
			int m,n;
			for(k=0; k < countPixel; k++) {
				float distXY = sqrt(pow((float)(i-pixelPos[k][0]),2)+pow((float)(j-pixelPos[k][1]),2));
				if(distXY <= minVal) {
					minVal = distXY;
					m = pixelPos[k][0];
					n = pixelPos[k][1];
				}
			}

			if (templateType==TEMPLATE_DoG)
				conv_template[templateIndex][i][j] = diffGaussArr[(MAX_TEMPLATE_SIZE/2)+i-m][(MAX_TEMPLATE_SIZE/2)+j-n];
			else
				conv_template[templateIndex][i][j] = gaussianArr0[(MAX_TEMPLATE_SIZE/2)+i-m][(MAX_TEMPLATE_SIZE/2)+j-n];
			templateSum+=conv_template[templateIndex][i][j];
		}
	}
	if(debugLevel>0){
		printf("generated template %d, sum of values=%f\n",templateIndex,templateSum);
	}
	dumpGauss(fp, templateIndex);
}

//////////////////////////////////////////////////////////////
//  Generate template for different sizes of objects. 
//  We have two methods, and method 1 seems to work
//  well when it comes circular template.
// 
//  selectType   = 0 =>   Use method0
//  selectType   = 1 =>   Use method1 (default)
//  
//  templateType = TEMP_DoG => Simple Ring Diff-of-Gaussian
//  templateType = TEMP_GAU => Simple Ring Gaussian (default)
//  
//  return 0, if succesful, else return -1;
// 
//  TIP: After simulation, run the matlab script "template_[DoG|Gau][0|1].m"
//       to see the kinds of template generated/used by the program.
//	>>> template_[DoG|Gau][0|1]
//////////////////////////////////////////////////////////////////
int templateConvInit(int selectType, int templateType)
{
	int i,j,k;		

	/// .... dump the generated template as a matlab file.
	FILE *fp;
	char fstr[100];
	sprintf(fstr,"template_%s%d.m",(templateType==TEMPLATE_DoG)?"DoG":"Gau", selectType);
	fp = fopen(fstr,"w");
	if(fp==NULL){
		fprintf(stderr,"Warning !! ... Couldn't create %s for output, skipping writing templates\n", fstr);
		fflush(stderr);
	}

	switch(selectType)  {		
		case TEMP_METHOD0:
			// generate template using method0
			if(debugLevel>0) printf("generating template using method0\n");
			for(i = 0; i < num_object; i++){
				generateObjectTemplate(fp, i, templateType);
			}
			break;
		case TEMP_METHOD1:
			// generate template using method1
			if(debugLevel>0) printf("generating template using method1\n");
			for(i = 0; i < num_object; i++){
				if(templateType==TEMPLATE_DoG){
					templateConvDoG(i,objSizeArray[i]);
				}else{
					templateConvGau(i,objSizeArray[i]);
				}
			}
	}
	
	// make templates have zero integral
	 // compute sum of all template values to check zero integral
	int sizeTemplate=MAX_TEMPLATE_SIZE;
	for(int templateIndex = 0; templateIndex < num_object; templateIndex++){
		 float sizeObject=objSizeArray[templateIndex];
		 float templateSum=0;
		 for(i=0;i<sizeTemplate;i++)
			 for(j=0;j<sizeTemplate;j++)
				 templateSum+= conv_template[templateIndex][j][i]; // integrate
		float f=templateSum/sizeTemplate/sizeTemplate; // compute value to subtract from each element
		 for(i=0;i<sizeTemplate;i++)
			 for(j=0;j<sizeTemplate;j++)
				 conv_template[templateIndex][j][i]-=f; // subtract it

		if(debugLevel>0){ // now print integral
		 float templateSum=0;
		 for(i=0;i<sizeTemplate;i++)
			 for(j=0;j<sizeTemplate;j++)
				 templateSum+= conv_template[templateIndex][j][i];
			printf("Integral of template #%d for sizeObject=%f is %f\n",templateIndex,sizeObject,templateSum);
		}
	}
	dumpTemplate(fp,fstr);

	////...... reset the variables for simulations on CPU...
	for(k=0; k < num_object; k++)
		for(i = 0; i < MAX_X; i++)
			for(j = 0; j<MAX_Y; j++)
				membranePotential[k][i][j] = 0;

	for(k=0; k < num_object; k++)
		cpu_totFiringMO[k] = 0;

	return 0;
}
