#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>
#include <string.h>

#include "config.h"

////////////////////////////////////////////////////////////////////////////////
// export C interface
extern "C" {
	int extractJaerRawData( unsigned int* addr, unsigned long* timeStamp, char* Data, const unsigned int len);
	void computeGold( unsigned int* addr, unsigned long* timeStamp);
	int  templateConvInit(int selectType=TEMP_METHOD1, int templateType=TEMPLATE_DoG);
	void setInitLastTimeStamp(unsigned long timeStamp, int objId=0);
}


//===========================================================
// Functions related to dumping trace info and other matlab scripts
//=========================================================== 
extern "C"{
	void dumpTemplate(FILE* fp, char* fstr);
}
	
//=========================================================
// Functions for jAER communication
//=========================================================

extern "C"{
	void jaerSendEvent(unsigned int addrx, unsigned int addry, unsigned long timeStamp, unsigned char type);
}


extern unsigned int delta_time;
extern int num_object;
extern globalNeuronParams_t hostNeuronParams;


////////////////////////////////////////////////////////////////////////////////


int			  cpu_totFiring=0;					// used to calculate the average firing rate from CPU model
int			  cpu_totFiringMO[MAX_NUM_TEMPLATE];	// store the firing count for each object that is tracked.
float		  conv_template[MAX_NUM_TEMPLATE][MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];		// template of all objects
unsigned long lastInputStamp[MAX_X][MAX_Y];		// stores the time of last firing of the input addr. This is used
												// to filter spikes that happens at a high rate.
float		  membranePotential[MAX_NUM_TEMPLATE][MAX_X][MAX_Y];	// corresponds to membrane potential of each neuron.																	
unsigned long lastTimeStamp[MAX_NUM_TEMPLATE][MAX_X][MAX_Y];		// store the firing time of each neuron. This is used
																// calcuate the membrane potential decay.
const float	  objSizeArray[] = {10,8,5,3,2}; // 15.0,7.0,22.0,21.0,20.0,19.0,18.0,12.0,11.0,10.0};	// ball size in pixels
float		  iNeuronPotential[MAX_NUM_TEMPLATE];	// membrane potential of inhibitory neuron. one inhibitory neuron
												// for each object plane or object to be recognized
int iNeuronFiringCnt = 0;						// used to calculate the firing rate of inhibitory neurons
int iNeuronCallingCnt = 0;						// keeps track of number of times an inhibitory neuron is called.

int lastSequenceNumber=0;	// to check dropped packets from jaer

// paramters for gabor template
float f_gabor_bandwidth = GABOR_BAND_WIDTH; //bandwidth of the gabor function
float f_gabor_theta[] = {0,45,90,135};  // orientation of the gabor function
float f_gabor_lambda = GABOR_WAVELENGTH;	//wavelength of the gabor function
float f_gabor_psi = GABOR_PHASE_OFFSET;	//phase offset of the gabor function
float f_gabor_gamma = GABOR_ASPECT_RATIO;	// aspect ratio of the gabor function
float f_gabor_xymax = GABOR_XY_MAX;	// the maximum value of x and y value
float f_gabor_maxamp = GABOR_MAX_AMP; // the maximum amplitude of the gabor function

/** convert 4-byte char to an integer
 * @param: data		data stream reveived from jaer
 * return: the converted integer, could be timestamp or address of a spike
 **/
unsigned long getInt( char* data)
{
	// java is little endian, so LSB comes first to us. we put it at the MSB here and vice versa.
	unsigned long temp = (((data[0]&0xffUL) << 24) 
		+ ((data[1]&0xffUL) << 16) 
		+ ((data[2]&0xffUL) << 8) 
		+ (data[3]&0xffUL));
	return temp;
}

/** initiate the matrix "lastTimeStamp" using the time stamp of the first received spike
 * @param: timeStamp	the reference time stamp, which is the timestamp of the first reveived spike
 * @param: objId		the id of the object
 * return 
 **/
void setInitLastTimeStamp(unsigned long timeStamp, int objId){
	for(int i = 0; i < MAX_X; i++){
		for(int j = 0; j < MAX_Y; j++){
			lastTimeStamp[objId][i][j] = timeStamp;
		}
	}
}

/** filter input spikes based on the refractory period
 * @param: addrx & addry	the x and y address of the input spike within retina coordinates
 * @param: timeStamp		current time stamp
 * return	true  if the spike is not filtered out
			false otherwise
 **/
bool spikeFilter(unsigned int addrx, unsigned int addry, unsigned long timeStamp){
	if((timeStamp - lastInputStamp[addrx][addry]) > hostNeuronParams.minFiringTimeDiff){
		lastInputStamp[addrx][addry] = timeStamp;
		return true;
	}else{
		return false;
	}
}


/** Reads spikes information from a file 'filtered_packet.txt' and returns the info in addr,timeStamp array.
 * @param: addr			parsed address array
 * @param: timeStamp	parsed time stamp array
 * return  the total number of parsed events 
 **/
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

unsigned long prevTimeStamp = 0;	// stores the time when last event happened
unsigned int lenData = 0;			// stores the length of data generated from input
long long num_packets = 0;			// 

/** store the filtered spikes in a file for quickly testing without jAER TCP/UDP interface.
 * @param: addr			the address array
 * @param: timeStamp	the time stamp array
 * return  the total number of parsed events 
 **/
void storeFilteredSpikes(unsigned int* addr, unsigned long* timeStamp)
{
	static FILE* fp = NULL;
	static unsigned int tot_filtered_spikes  = 0;	
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

	tot_filtered_spikes++;
	if(tot_filtered_spikes == (unsigned)RECORD_MODE_SAMPLES_CNT) {
		fprintf(stdout, "RECORD MODE ===> %d filtered spikes recorded\n", numRecorded);		
		fprintf(stdout, "RECORDING MODE FINISHED....\n");
		fclose(fp);
		fflush(stdout);
		exit(0);
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
	num_packets++;

#ifdef REPLAY_MODE
	lenData= readSpikeFromFile(addr, timeStamp);	
	return lenData;
#endif

#if DUMP_RECV_DATA
	char fname[100];
	sprintf(fname, "recv_packet%d.m", num_packets);
	FILE* fpDumpSpike;
	fpDumpSpike = fopen(fname, "w");
	fprintf( fpDumpSpike, " spikes = [ " );
#endif

	lenData = 0; // reset lenData for each received packet

	unsigned int* addrCur = addr;
	unsigned long* timeStampCur = timeStamp;
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
		unsigned int addrxCur = MAX_X - 1  - (Data[i*EVENT_LEN+3] >> 1)& 0x7f;
		unsigned int addryCur = (Data[i*EVENT_LEN+2]& 0x7f);
		*timeStampCur = getInt( &Data[i*EVENT_LEN+4]); //*((unsigned int *)&Data[i*6+2]);
	
#if DUMP_RECV_DATA
		 fprintf(fpDumpSpike, "%u %u %u\n", addrxCur, addryCur, *timeStampCur);
#endif

		if ( *timeStampCur < prevTimeStamp ) {
			printf("AE timestamp time reversal occured\n");		
			printf("packet number = %d", num_packets);
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
			addrCur++;
			lenData++;
		}

	}				

#if DUMP_RECV_DATA
	fprintf(fpDumpSpike, " ]; " );
	fclose(fpDumpSpike);

	if(num_packets == (unsigned)RECORD_MODE_SAMPLES_CNT){
		exit(0);
	}
#endif

#ifdef DUMP_FILTERED_DATA
	storeFilteredSpikes(addr,timeStamp);
#endif

	return lenData;
}


/******************************************************************************************************************************/
/********************************** MEMBRANE POTENTIAL CALCULATION ************************************************************/
/******************************************************************************************************************************/

/** This function implements the integration of the global inhibitory neuron.
 *  The change of inhibitory membrane potential is dependent upon the number of exc neurons fired ('numFired'). 
 *  TODO: Add leaky term into the equation. Currently the neuron does not have leaky behaviour. 
 *  It just accumulates and then fires if the membrane potential of inhibitory crosses the threshold.
 * @param: fp			pointer to a log file which records inhibitory neuron firing time.
 * @param: timeStamp	current time stamp
 * @param: objId		the id of the object
 * @param: numFired	    the number of excitatory spikes generated at this timestamp and this object
 * return  1	if the inhibitory neuron fires
		   0	otherwise
 **/ 
int update_inh_neuron(FILE *fp, unsigned long timeStamp, int objId=0,int numFired=1)
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

/** update neuron membrane potentials when input spike is received (single spike mode)
 * @param: addrx & addry	the x and y address of the input spike within retina coordinates
 * @param: timeStamp		current time stamp
 **/

void update_neurons(unsigned int addrx, unsigned int addry, unsigned long timeStamp)
{
	static FILE* fpFiring = NULL;
	
#if RECORD_FIRING_INFO
	if(fpFiring == NULL){
		if ((fpFiring = fopen("firing.m", "w")) == NULL){
			printf("failed to open file firing.m");
			return;
		}
	}	
#endif

	// calculate the coverage of the template which centers around the address of the current spike 
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

	// calculate the membrane potential of each neuron
	for( int k = 0; k < num_object; k++) {
		for( int i = min_x; i < max_x; i++) {
			for( int j = min_y; j < max_y; j++) {
				assert(i-temp_min_x>=0);
				assert(i-temp_min_x<MAX_TEMPLATE_SIZE);
				assert(j-temp_min_y>=0);
				assert(j-temp_min_y<MAX_TEMPLATE_SIZE);

				// check if the time is reversed
				if((timeStamp-lastTimeStamp[k][i][j]) < 0) {
					printf("Time stamp reversal\n");

#if RECORD_FIRING_INFO
				fclose(fpFiring);
#endif
					return;
				}

				// calculate membrane potential
				signed long long timeDiff = 0xFFFFFFFFLL&(timeStamp-lastTimeStamp[k][i][j]);
				float temp = (float)timeDiff/hostNeuronParams.membraneTau;
				temp = (float)exp(-temp);
				membranePotential[k][i][j] = membranePotential[k][i][j]*temp +
										   conv_template[k][i-temp_min_x][j-temp_min_y];
				lastTimeStamp[k][i][j] = timeStamp;

				if((membranePotential[k][i][j]) > hostNeuronParams.threshold) {
					cpu_totFiring++;
					cpu_totFiringMO[k]++;
					int ineuron_fired = update_inh_neuron(fpFiring, timeStamp, k);
					membranePotential[k][i][j] = 0;

				// send the output events back to cuda
				#if !REPLAY_MODE
					// accumulate fired neuron and send to jaer
					jaerSendEvent(i,j,timeStamp,k);

					if (ineuron_fired)
						jaerSendEvent(1,1,timeStamp,0);

				#endif
				}
				else if ( membranePotential[k][i][j] < hostNeuronParams.membranePotentialMin ) {
						membranePotential[k][i][j] = hostNeuronParams.membranePotentialMin;
				}		
			}
		}
	}
}

unsigned long lastGroupingTimeStamp=0;

/** update neuron membrane potentials when input spike is received (single spike mode)
 * @param: addrx & addry	the x and y address of the input spike within retina coordinates
 * @param: timeStamp		current time stamp
 **/	
void update_neurons_grouping(unsigned int addrx, unsigned int addry, unsigned long timeStamp)
{
	static FILE* fpFiring = NULL;
	int ineuron_fired = 0;
	int numFired = 0;

	signed long long groupDiff = 0xFFFFFFFFLL&(timeStamp - lastGroupingTimeStamp);
	
#if RECORD_FIRING_INFO
	if(fpFiring == NULL){
		if ((fpFiring = fopen("firing.m", "w")) == NULL){
			printf("failed to open file firing.m");
			return;
		}
	}	
#endif

	// calculate the coverage of the template which centers around the address of the current spike 
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

	for( int objId = 0; objId < num_object; objId++) {
		for( int i = min_x; i < max_x; i++) {
			for( int j = min_y; j < max_y; j++) {
				assert(i-temp_min_x>=0);
				assert(i-temp_min_x<MAX_TEMPLATE_SIZE);
				assert(j-temp_min_y>=0);
				assert(j-temp_min_y<MAX_TEMPLATE_SIZE);

				// check if time is reversed
				if((timeStamp-lastTimeStamp[objId][i][j]) < 0) {
					printf("Time stamp reversal\n");

#if RECORD_FIRING_INFO
					fclose(fpFiring);
#endif
					return;
				}

				// group the input spikes so that the leak of the membrane potential is only calculated every delta_time
				signed long long timeDiff = 0xFFFFFFFFLL&(timeStamp-lastTimeStamp[objId][i][j]);
				float temp = 1.0;						
				if(groupDiff>delta_time) {
						lastGroupingTimeStamp = timeStamp;

						temp = (float)timeDiff/hostNeuronParams.membraneTau;
						temp = (float)exp(-temp);
				}
				lastTimeStamp[objId][i][j] = timeStamp;

				membranePotential[objId][i][j] = membranePotential[objId][i][j]*temp +
										   conv_template[objId][i-temp_min_x][j-temp_min_y];				
				if((membranePotential[objId][i][j]) > hostNeuronParams.threshold) {
					cpu_totFiring++;
					numFired++;
					cpu_totFiringMO[objId]++;
					membranePotential[objId][i][j] = 0;

#if RECORD_FIRING_INFO
					fprintf(fpFiring, "%u %d %d\n", timeStamp, i, j);
#endif

				// send the excitatory output events back to cuda
				#if !REPLAY_MODE
				// accumulate fired neuron and send to jaer
					jaerSendEvent(i,j,timeStamp,objId);
				#endif
				}
				else if ( membranePotential[objId][i][j] < hostNeuronParams.membranePotentialMin ) {
						membranePotential[objId][i][j] = hostNeuronParams.membranePotentialMin;
				}
			}
		}

		// Delta crossed for grouping, and calculate the inhibitory membrane potential
		if(numFired)
			ineuron_fired = update_inh_neuron(fpFiring, timeStamp, objId, numFired);	
#if !REPLAY_MODE
		jaerSendEvent(1,1,timeStamp,0);
#endif
	}
}


/** cpu mode computation
 * @param: addr:		address array after filtering
 * @param: timeStamp	time stamp array after filtering
 **/
void computeGold( unsigned int* addr, unsigned long* timeStamp) 
{
	unsigned int i;
	for(i = 0; i < lenData; i++) {
		unsigned int addrx = addr[i]&0xff; 
		unsigned int addry = (addr[i]>>8)&0xff;
#if CPU_ENABLE_SPIKE_GROUPING
		update_neurons_grouping( addrx, addry, timeStamp[i]);
#else
		update_neurons( addrx, addry, timeStamp[i]);
#endif
	}
}

/******************************************************************************************************************************/
/********************************** TEMPLATE GENERATION ***********************************************************************/
/******************************************************************************************************************************/

/** generate a two dimensional Gaussian template with constant negative margin 
 * @param:  templateIndex		the index of the template
 * @param:  sizeObject			the size of the ball
 **/
void templateConvGau(int templateIndex, float sizeObject)
{
	if(debugLevel>0) {
		printf("templateConvGau: Generating Template #%d for sizeObject=%f\n",templateIndex,sizeObject);
	}

	float center = (float)(MAX_TEMPLATE_SIZE/2);
	int i, j;
	
	if(sizeObject < MAX_TEMPLATE_SIZE){
		//float ampFactor = MAX_TEMPLATE_SIZE/sizeObject/2;
		float maxNegAmp = MAX_NEG_AMP;
		float maxAmpActivation = MAX_AMP_ACTIVATION;
		for(i = 0; i < MAX_TEMPLATE_SIZE; i++){ // scanning through vertical axis
			float dist = abs(i - center);
			for(j = 0; j < MAX_TEMPLATE_SIZE; j++){ // scanning through horizontal axis, each row contains 0 to 2 Gaussian bumps depending on their vertical location 
				if(dist > sizeObject) // if the vertical distance is larger than the size of the object, the amplitude is defined as max negative value
					conv_template[templateIndex][i][j] = maxNegAmp;
				else if(dist == sizeObject){ // if the vertical distance is equal to the size of the object, there is one peak which is located at the center of the row
					float meanGauss = center; 
					conv_template[templateIndex][i][j] = maxAmpActivation*exp(-(pow((j - meanGauss),2))/(GAUSS_VAR*GAUSS_VAR)) + maxNegAmp;
				} 
				else { // if the vertical distance is smaller than the size of the object, there are two Gaussian peaks symmetric around the center 
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

		//transpose of the template matrix to reverse the horizontal and vertical axis
		float temp;
		for(i = 0; i < MAX_TEMPLATE_SIZE; i++){
			for(j = 0; j < MAX_TEMPLATE_SIZE; j++){
				if(i > j){
					temp = conv_template[templateIndex][i][j];
					conv_template[templateIndex][i][j] = conv_template[templateIndex][j][i];
					conv_template[templateIndex][j][i] = temp;
				}
			}
		}

		// calculate the amplitude in the transposed orientation again to eliminate the unsymmetry of the resulting template
		for(i = 0; i < MAX_TEMPLATE_SIZE; i++){
			float dist = abs(i - center);
			for(j = 0; j < MAX_TEMPLATE_SIZE; j++){
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

		// transpose back to the original orientation
		for(i = 0; i < MAX_TEMPLATE_SIZE; i++){
			for(j = 0; j < MAX_TEMPLATE_SIZE; j++){
				if(i > j){
					temp = conv_template[templateIndex][i][j];
					conv_template[templateIndex][i][j] = conv_template[templateIndex][j][i];
					conv_template[templateIndex][j][i] = temp;
				}
			}
		}

		// make templates have zero integral
		 // compute sum of all template values to check zero integral
		 float templateSum=0;
		 for(i=0;i<MAX_TEMPLATE_SIZE;i++)
			 for(j=0;j<MAX_TEMPLATE_SIZE;j++)
				 templateSum+= conv_template[templateIndex][j][i]; // integrate
		float f=templateSum/MAX_TEMPLATE_SIZE/MAX_TEMPLATE_SIZE; // compute value to subtract from each element
		 for(i=0;i<MAX_TEMPLATE_SIZE;i++)
			 for(j=0;j<MAX_TEMPLATE_SIZE;j++)
				 conv_template[templateIndex][j][i]-=f; // subtract it

		if(debugLevel>1){ // now print integral
			float templateSum=0;
			for(i=0;i<MAX_TEMPLATE_SIZE;i++)
				for(j=0;j<MAX_TEMPLATE_SIZE;j++)
					templateSum+= conv_template[templateIndex][j][i];
			printf("Integral of template #%d for sizeObject=%f is %f\n",templateIndex,sizeObject,templateSum);
		}
	} 
	else{
		fprintf(stderr,"object size (%f) should be smaller than template size (%d).\n",sizeObject,MAX_TEMPLATE_SIZE);
	}
}


/** generate a two dimensional DOG template 
 * @param:  templateIndex		the index of the template
 * @param:  sizeObject			the size of the ball
 **/
void templateConvDoG(int templateIndex, float sizeObject)
{
 
	if(debugLevel>0){
		printf("Generating DoG Template #%d for sizeObject=%f\n",templateIndex,sizeObject);
	}

	 //float sizeObject = MAX_OBJECT_SIZE;
	 float center = (float)(MAX_TEMPLATE_SIZE/2);
	 int i, j;
	 
	 // difference of gaussian shape template
	 if(sizeObject < MAX_TEMPLATE_SIZE){
		  //float ampFactor = MAX_TEMPLATE_SIZE/sizeObject/2;
		  float maxNegAmp = MAX_NEG_AMP;
		  float maxAmpActivation = MAX_AMP_ACTIVATION;
		  for(i = 0; i < MAX_TEMPLATE_SIZE; i++){
		   float dist = abs(i - center);
		   for(j = 0; j < MAX_TEMPLATE_SIZE; j++){
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
		  for(i = 0; i < MAX_TEMPLATE_SIZE; i++){
		   for(j = 0; j < MAX_TEMPLATE_SIZE; j++){
			if(i > j){
			 temp = conv_template[templateIndex][i][j];
			 conv_template[templateIndex][i][j] = conv_template[templateIndex][j][i];
			 conv_template[templateIndex][j][i] = temp;
			}
		   }
		  }
		  for(i = 0; i < MAX_TEMPLATE_SIZE; i++){
		   float dist = abs(i - center);
		   for(j = 0; j < MAX_TEMPLATE_SIZE; j++){
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

	  for(i = 0; i < MAX_TEMPLATE_SIZE; i++){
	   for(j = 0; j < MAX_TEMPLATE_SIZE; j++){
		if(i > j){
		 temp = conv_template[templateIndex][i][j];
		 conv_template[templateIndex][i][j] = conv_template[templateIndex][j][i];
		 conv_template[templateIndex][j][i] = temp;
		}
	   }
	  }
	 } else{
	  fprintf(stderr, "object size (%f) should be smaller than template size (%d); no template generated\n",sizeObject,MAX_TEMPLATE_SIZE);
	  fflush(stderr);
	 }

	 // make templates have zero integral
	 // compute sum of all template values to check zero integral
	 float templateSum=0;
	 for(i=0;i<MAX_TEMPLATE_SIZE;i++)
		 for(j=0;j<MAX_TEMPLATE_SIZE;j++)
			 templateSum+= conv_template[templateIndex][j][i]; // integrate
	 float f=templateSum/MAX_TEMPLATE_SIZE/MAX_TEMPLATE_SIZE; // compute value to subtract from each element
	 for(i=0;i<MAX_TEMPLATE_SIZE;i++)
		 for(j=0;j<MAX_TEMPLATE_SIZE;j++)
			 conv_template[templateIndex][j][i]-=f; // subtract it

	if(debugLevel>1){ // now print integral
		float templateSum=0;
		for(i=0;i<MAX_TEMPLATE_SIZE;i++)
			for(j=0;j<MAX_TEMPLATE_SIZE;j++)
				templateSum+= conv_template[templateIndex][j][i];
		printf("Integral of template #%d for sizeObject=%f is %f\n",templateIndex,sizeObject,templateSum);
	}
}  

/** generate a two dimensional DOG template 
 * @param:  templateIndex		the index of the template
 **/
void templateGabor(int templateIndex)
{
	float sigma_x = 1/PI * sqrt( log( 2.0F )/2) * ((pow(2,f_gabor_bandwidth)+1) / (pow(2,f_gabor_bandwidth)-1)) * f_gabor_lambda;
	float sigma_y = sigma_x / f_gabor_gamma;

	float x, y, theta_radian = f_gabor_theta[templateIndex]/360*2*PI;
	float x_theta, y_theta;
	for(int i = 0; i < MAX_TEMPLATE_SIZE; i++){
		y = -f_gabor_xymax+i*f_gabor_xymax/(float)(MAX_TEMPLATE_SIZE-1)*2;
		for(int j = 0; j < MAX_TEMPLATE_SIZE; j++){
			x = -f_gabor_xymax+j*f_gabor_xymax/(float)(MAX_TEMPLATE_SIZE-1)*2;
			x_theta=x*cos(theta_radian)+y*sin(theta_radian);
			y_theta=-x*sin(theta_radian)+y*cos(theta_radian);

			conv_template[templateIndex][i][j] = f_gabor_maxamp*exp(-(pow(x_theta,2)/pow(sigma_x,2)+pow(y_theta,2)/pow(sigma_y,2))/2) * cos(2 * PI / f_gabor_lambda*x_theta + f_gabor_psi);
		}
	}
}

/*
function gb=gabor_fn(b,theta,lambda,psi,gamma)
 
sigma_x = 1/pi*sqrt(log(2)/2)*((2^b+1)/2^b-1)*lambda;
sigma_y = sigma_x/gamma;

templateSize = 16;
 
[x,y] = meshgrid(-1:1/(templateSize-1)*2:1,-1:1/(templateSize-1)*2:1);
% Rotation 
x_theta=x*cos(theta)+y*sin(theta);
y_theta=-x*sin(theta)+y*cos(theta);
 
gb=exp(-.5*(x_theta.^2/sigma_x^2+y_theta.^2/sigma_y^2)).*cos(2*pi/lambda*x_theta+psi);

*/

int circleArr[MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];
int countPixel=0;
int pixelPos[2*MAX_TEMPLATE_SIZE][2];

#define setPixel(a,b) {circleArr[a][b]=1; assert(countPixel < 2*MAX_TEMPLATE_SIZE); pixelPos[countPixel][0]=a; pixelPos[countPixel][1]=b; countPixel++;}

/** generate a circle for given radius and centered at x0,y0.
 * @param: x0,y0	the center of the circle
 * @pram: radius	the radius of the circle
 **/
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
	if(debugLevel>1){
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
	sprintf(fstr,"template.m");
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
			
			if(templateType==TEMPLATE_DoG){
				for(i = 0; i < num_object; i++){
					templateConvDoG(i,objSizeArray[i]);
				}
			}else if(templateType==TEMPLATE_Gau){
				for(i = 0; i < num_object; i++){
					templateConvGau(i,objSizeArray[i]);
				}
			}else{
				for(i = 0; i < num_object; i++){
					templateGabor(i);
				}
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
