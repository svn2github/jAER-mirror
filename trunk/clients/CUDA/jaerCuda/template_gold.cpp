#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>
#include <string.h>

#include "config.h"

////////////////////////////////////////////////////////////////////////////////
// export C interface
extern "C" int readNFilter( unsigned int* addr, unsigned long* timeStamp, char* Data, const unsigned int len);

extern "C" {
void computeGold( unsigned int* addr, unsigned long* timeStamp, int templateIndex);
void templateConvInit();
void dumpResults(int objId=0);
int jaerServerSend(char* buf, int bufSize);
void playAudio();
void sendEvent(int addrx, int addry, unsigned long timeStamp, bool polarity);
void setInitLastTimeStamp(unsigned long timeStamp, int objId=0);
void printResults();
bool isTimeToSend();
}

extern int sendBufLen;
extern char sendBuf[SEND_SOCK_BUFLEN];
extern unsigned int delta_time;
extern int multi_object;
extern int num_object;
extern bool runCuda;
extern globalNeuronParams_t hostNeuronParams;

////////////////////////////////////////////////////////////////////////////////
//! Compute reference data set
//! Each element is multiplied with the number of threads / array length
//! @param reference  reference data, computed but preallocated
//! @param idata      input data as provided to device
//! @param len        number of elements in reference / idata
////////////////////////////////////////////////////////////////////////////////

unsigned long getInt( char* data)
{
	unsigned long temp = 0;

	temp = (((data[0]&0xffUL) << 24) + ((data[1]&0xffUL) << 16) + ((data[2]&0xffUL) << 8) + (data[3]&0xffUL));

	return temp;
}




int cpu_totFiring=0;
int cpu_totFiringMO[MAX_NUM_OBJECT];
float conv_template[MAX_NUM_OBJECT][MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];
unsigned long lastInputStamp[MAX_X][MAX_Y];
float membranePotential[MAX_NUM_OBJECT][MAX_X][MAX_Y];
unsigned long lastTimeStamp[MAX_NUM_OBJECT][MAX_X][MAX_Y];
//const float objSizeArray[MAX_NUM_OBJECT] = {15.0,7.0};	//ball size
const float objSizeArray[] = {15.0,7.0,20.0,19.0,18.0,12.0,11.0,10.0};	//ball size
float iNeuronPotential[MAX_NUM_OBJECT];
//float inputPotential[MAX_X][MAX_Y];
int iNeuronFiringCnt = 0;
int iNeuronCallingCnt = 0;

void setInitLastTimeStamp(unsigned long timeStamp, int objId){
	for(int i = 0; i < MAX_X; i++){
		for(int j = 0; j < MAX_Y; j++){
			lastTimeStamp[objId][i][j] = timeStamp;
		}
	}
}

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

unsigned long lastSaccadeTime = 0;
unsigned long prevTimeStamp = 0;
unsigned int lenData = 0;
long long num_packets = 0;
int curTemplateIndex = -1;

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
						sendEvent(i,j,timeStamp,0);

						if (ineuron_fired)
							sendEvent(1,1,timeStamp,0);

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
						sendEvent(i,j,timeStamp,0);

						if (ineuron_fired)
							sendEvent(1,1,timeStamp,0);
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

int
readNFilter( unsigned int* addr, unsigned long* timeStamp, char* Data, const unsigned int len) 
{

#ifdef REPLAY_MODE
	static FILE* fp = fopen("filtered_packet.txt", "r");	
	static int cntPacket = 1;
	curTemplateIndex = 0;
	if (!fp) {
		fprintf(stderr, "\n\n\nWARNING !!! filtered_packet.txt file not present in current directory\n");
		fprintf(stderr, "Generate one before continuing\n");
		exit(1);
	}
	if(!feof(fp)) {		
		int i=0;
		while(!feof(fp)&& (i<(RECV_SOCK_BUFLEN/8))) {					
				fscanf(fp, "%d %u\n", &addr[i], &timeStamp[i]);			
				i=i+1;
		}
		cntPacket++;
		lenData = i;
		//printf("Transmitting %d packet, len = %d\n", cntPacket, i);
		return i;
	}
	else {
		return -1;
	}		
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

	bool filterFlag = false;
    for(  i = 0; i < len; i++) 
    {
		int max_x = MAX_X - 1;
		unsigned int addrxCur = max_x  - (Data[i*8+3] >> 1)& 0x7f;
		unsigned int addryCur = (Data[i*8+2]& 0x7f);
		*timeStampCur = getInt( &Data[i*8+4]); //*((unsigned int *)&Data[i*6+2]);
		if(i == 0 && (*timeStampCur - lastSaccadeTime > SACCADE_TIME_INTERVAL)) {
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
			printf("i (%d)====>\n, Data[8*i] = %d\n, Data[8*i+1] = %d\n, Data[8*i+2] = %d\n, Data[8*i+3] = %d\n,  \
						Data[8*i+4] = %d\n, Data[8*i+5] = %d\n,	Data[8*i+6] = %d\n,	Data[8*i+7] = %d\n\n",	\
						i, Data[8*i] , Data[8*i+1] , Data[8*i+2] ,	Data[8*i+3] ,	Data[8*i+4] ,	Data[8*i+5] , \
						Data[8*i+6] , Data[8*i+7]); 
			//return -1;
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
	static FILE* fp = fopen("filtered_packet.txt", "w");
	static unsigned int fpOpened  = 0;	
	static int numRecorded = 0;		
	numRecorded += lenData;
	for(int i = 0; i < lenData; i++) {
		fprintf(fp, "%d %u\n", addr[i], timeStamp[i]);
	}
	fpOpened++;
	if(fpOpened == (unsigned)RECORD_MODE_SAMPLES_CNT) {
		printf("RECORD MODE ===> %d filtered spikes recorded\n", numRecorded);		
		fclose(fp);
		CUT_EXIT(argc, argv);
	}
#endif
	return lenData;
}

void dumpResults(int objId)
{
#if DUMP_DEBUG

	char fname[100];
	sprintf(fname, "recv_packet%d.m", num_packets);
	FILE* fpDump;
	fpDump = fopen(fname, "w");
	sprintf(fname, "mem_pot%d.m", num_packets);
	FILE* fpDumpPot;	
	fpDumpPot = fopen(fname, "w");

	num_packets++;


	for(int i=0; i < MAX_Y; i++) {
		for(int j=0; j < MAX_X; j++) {		
			signed long long timeDiff = 0xFFFFFFFFLL&(prevTimeStamp-lastTimeStamp[objId][i][j]);
			if(lastTimeStamp[objId][i][j] != 0 ) {
				membranePotential[objId][i][j] = membranePotential[objId][i][j]*exp(-timeDiff/hostNeuronParams.membraneTau);
			}
			if ( membranePotential[objId][i][j] < hostNeuronParams.membranePotentialMin ) {
				membranePotential[objId][i][j] = hostNeuronParams.membranePotentialMin;
			}
		}
	}

	if(num_packets >= DEBUG_START) {

		fprintf( fpDumpPot, " memPot = [ " );
		for(int i=0; i < MAX_Y; i++) {
			for(int j=0; j < MAX_X; j++) {
				fprintf( fpDumpPot, " %f ", membranePotential[objId][i][j]);
			}
			fprintf(fpDumpPot, "; \n");
		}
		
		fprintf(fpDumpPot , " ]; " );

		/*fprintf( fpDumpPot, " excSyn = [ " );
		for(int i=0; i < MAX_Y; i++) {
			for(int j=0; j < MAX_X; j++) {
				fprintf( fpDumpPot, " %f ", excSyn[i][j]);
			}
			fprintf(fpDumpPot, "; \n");
		}
		
		fprintf(fpDumpPot , " ]; " );

		fprintf( fpDumpPot, " inhSyn = [ " );
		for(int i=0; i < MAX_Y; i++) {
			for(int j=0; j < MAX_X; j++) {
				fprintf( fpDumpPot, " %f ", inhSyn[i][j]);
			}
			fprintf(fpDumpPot, "; \n");
		}
		
		fprintf(fpDumpPot , " ]; " );*/

		fflush(fpDumpPot);
		fclose(fpDumpPot);

	}

	if(num_packets > DEBUG_END) {
		CUT_EXIT(argc, argv);
	}

#endif

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

void templateConvGau(int templateIndex, float sizeObject)
{
	//printf("Generating Template\n");
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
		printf("object size should be smaller than template size.\n");
	}
}

void templateConvDoG(int templateIndex, float sizeObject)
{
 
	 printf("Generating Template\n");
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
			} 
			else {
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
	 } 
	 else{
	  printf("object size should be smaller than template size.\n");
	 }
}  


int circleArr[MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];
int countPixel=0;
int pixelPos[2*MAX_TEMPLATE_SIZE][2];

#define setPixel(a,b) {circleArr[a][b]=1; assert(countPixel < 2*MAX_TEMPLATE_SIZE); pixelPos[countPixel][0]=a; pixelPos[countPixel][1]=b; countPixel++;}

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

void initGaussian(int idx, float sigma0, float maxAmp0, float sigma1, float maxAmp1)
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

void initGaussian(float sigma0, float maxAmp0, float minAmp0)
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

void dumpGauss(int idx)
{

	int i,j;

#if 1

	static FILE *fp=fopen("initGaussian.m","w");

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
#endif
}


void wyxCircle(float sizeObject)
{
	int i, j;
	float circleArrTemp[MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];	

	printf("Generating Template\n");
	int sizeTemplate = MAX_TEMPLATE_SIZE;
	//float sizeObject = MAX_OBJECT_SIZE;
	float center = (float)(sizeTemplate/2);	
	
	do {

		for(i=0; i < MAX_TEMPLATE_SIZE; i++) {
			for(j=0; j < MAX_TEMPLATE_SIZE; j++) {
				circleArrTemp[i][j]=0.0;
			}
		}

		int xcenter = MAX_TEMPLATE_SIZE/2;
		for(i=0; i < sizeObject; i++) {
			int y = (int)(sqrt(sizeObject*sizeObject - i*i)+0.5f);
			circleArrTemp[xcenter+i][xcenter+y-1]=1.0;
			circleArrTemp[xcenter+i][xcenter-y-1]=1.0;
			circleArrTemp[xcenter-i][xcenter+y-1]=1.0;
			circleArrTemp[xcenter-i][xcenter-y-1]=1.0;
		}

		//transpose
		float temp;
		for(i = 0; i < sizeTemplate; i++){
			for(j = 0; j < sizeTemplate; j++){
				if(i > j){
					temp = circleArrTemp[i][j];
					circleArrTemp[i][j] = circleArrTemp[j][i];
					circleArrTemp[j][i] = temp;
				}
			}
		}

		for(i=0; i < sizeObject; i++) {
			int y = (int)(sqrt(sizeObject*sizeObject - i*i)+0.5f);
			circleArrTemp[xcenter+i][xcenter+y-1] +=1.0;
			circleArrTemp[xcenter+i][xcenter-y-1] +=1.0;
			circleArrTemp[xcenter-i][xcenter+y-1] +=1.0;
			circleArrTemp[xcenter-i][xcenter-y-1] +=1.0;
		}

		//break;

		if(sizeTemplate > sizeObject){
			float ampFactor = sizeTemplate/sizeObject/2;
			float maxNegAmp = ampFactor*MAX_NEG_AMP;
			float maxAmpActivation = ampFactor*MAX_AMP_ACTIVATION;
			for(i = 0; i < sizeTemplate; i++){
				float dist = abs(i - center);
				for(j = 0; j < sizeTemplate; j++){
					if(dist > sizeObject)
						circleArrTemp[i][j] = maxNegAmp;
					else if(dist == sizeObject){
						float meanGauss = center; 
						circleArrTemp[i][j] = maxAmpActivation*exp(-(pow((j - meanGauss),2))/(GAUSS_VAR*GAUSS_VAR)) + maxNegAmp;
					} 
					else {
						//continue;
						float radiusGauss = sqrt(sizeObject*sizeObject - dist*dist);
						float meanGauss1 = center - radiusGauss,
							  meanGauss2 = center + radiusGauss;
						if(j <= center)
							circleArrTemp[i][j] = maxAmpActivation*exp(-(pow((j - meanGauss1),2))/(GAUSS_VAR*GAUSS_VAR)) + maxNegAmp;
						else
							circleArrTemp[i][j] = maxAmpActivation*exp(-(pow((j - meanGauss2),2))/(GAUSS_VAR*GAUSS_VAR)) + maxNegAmp;
					}
				}
			}		

			//transpose
			float temp;
			for(i = 0; i < sizeTemplate; i++){
				for(j = 0; j < sizeTemplate; j++){
					if(i > j){
						temp = circleArrTemp[i][j];
						circleArrTemp[i][j] = circleArrTemp[j][i];
						circleArrTemp[j][i] = temp;
					}
				}
			}

			for(i = 0; i < sizeTemplate; i++){
				float dist = abs(i - center);
				for(j = 0; j < sizeTemplate; j++){
					if(dist > sizeObject)
						circleArrTemp[i][j] = circleArrTemp[i][j] + maxNegAmp;
					else if(dist == sizeObject){
						float meanGauss = center; 
						circleArrTemp[i][j] = circleArrTemp[i][j] + maxAmpActivation*exp(-(pow((j - meanGauss),2))/(GAUSS_VAR*GAUSS_VAR)) + maxNegAmp;
					} 
					else {
						//continue;
						float radiusGauss = sqrt(sizeObject*sizeObject - dist*dist);
						float meanGauss1 = center - radiusGauss,
							  meanGauss2 = center + radiusGauss;
						if(j <= center)
							circleArrTemp[i][j] = circleArrTemp[i][j] + maxAmpActivation*exp(-(pow((j - meanGauss1),2))/(GAUSS_VAR*GAUSS_VAR)) + maxNegAmp;
						else
							circleArrTemp[i][j] = circleArrTemp[i][j] + maxAmpActivation*exp(-(pow((j - meanGauss2),2))/(GAUSS_VAR*GAUSS_VAR)) + maxNegAmp;
					}
				}
			}

			for(i = 0; i < sizeTemplate; i++){
				for(j = 0; j < sizeTemplate; j++){
					if(i > j){
						temp = circleArrTemp[i][j];
						circleArrTemp[i][j] = circleArrTemp[j][i];
						circleArrTemp[j][i] = temp;
					}
				}
			}
		} 
		else{
			printf("object size should be smaller than template size.\n");
		}
	}	while(0);

	FILE *fp = fopen("wyxCircle.m","w");
	fprintf(fp, "wyxcircleArrTemp=[\n");
	for(i=0; i < MAX_TEMPLATE_SIZE; i++) {
		for(j=0; j < MAX_TEMPLATE_SIZE; j++) {
			fprintf(fp, "%f ", circleArrTemp[i][j] );
		}		
		fprintf(fp, ";\n");
	}	
	fprintf(fp, "];\n");
	fclose(fp);
}

void generateObjectTemplate(int templateIndex)
{
	int i,j,k;

	countPixel=0;
	int objectRadius = (int)objSizeArray[templateIndex];
	rasterCircle(MAX_TEMPLATE_SIZE/2,MAX_TEMPLATE_SIZE/2, objectRadius);
#if USE_DoG
	initGaussian(templateIndex,SIGMA1, MAX_AMP1, SIGMA2, MAX_AMP2);
#else
	initGaussian(SIGMA0, MAX_AMP0, MIN_AMP0);
#endif

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

#if USE_DoG
			conv_template[templateIndex][i][j] = diffGaussArr[(MAX_TEMPLATE_SIZE/2)+i-m][(MAX_TEMPLATE_SIZE/2)+j-n];
#else
			conv_template[templateIndex][i][j] = gaussianArr0[(MAX_TEMPLATE_SIZE/2)+i-m][(MAX_TEMPLATE_SIZE/2)+j-n];
#endif
		}
	}
	dumpGauss(templateIndex);
}

void templateConvInit()
{
	int i,j,k;	

	wyxCircle(15.0);	

#if USE_NEW_TEMPLATE
	for(i = 0; i < num_object; i++){
		generateObjectTemplate(i);
	}		

#else	
	for(i = 0; i < num_object; i++){
#if USE_DoG
		templateConvDoG(i,objSizeArray[i]);
#else
		templateConvGau(i,objSizeArray[i]);
#endif
	}
#endif

	for(k=0; k < num_object; k++)
		for(i = 0; i < MAX_X; i++)
			for(j = 0; j<MAX_Y; j++)
				membranePotential[k][i][j] = 0;

	for(k=0; k < num_object; k++)
		cpu_totFiringMO[k] = 0;

	printf( "Dumping %d templates to template.m\n", num_object);
	fflush(stdout); // for jaer to print this
	FILE *fp;
	fp = fopen("template.m","w");
	if(fp==NULL){
		fprintf(stderr,"Couldn't open template.m for output, skipping writing templates\n");
		fflush(stderr);
		return;
	}

	for(i = 0; i < num_object; i++){		
		fprintf( fp, " template%d = [ ", i);
		for(j=0; j < MAX_TEMPLATE_SIZE; j++) {
			for(k=0; k < MAX_TEMPLATE_SIZE; k++) {
				fprintf( fp, " %f ", conv_template[i][j][k]);
			}
			fprintf(fp, "; \n");
		}
		fprintf(fp , " ];\n\n " );
	}
    fflush(fp);


}
