// includes, project
#include <stdio.h>
#include <stdlib.h>
#include <cutil.h>

#include "config.h"

int countMem = 0;

extern "C"	{
	void dumpTemplate(FILE* fp, char* fstr);
	void printResults(FILE* fpLog);
	void showMembranePotential(unsigned int* spikeAddr, int spikeCnt);
	void dumpResults(int objId);
}

// Function dumps the template parameters into a file
// pointed by fp. The file can be executed in matlab
void dumpTemplate(FILE* fp, char* fstr)
{
	if(fp==NULL)
		return;

	printf( "Dumping %d templates to %s\n", num_object, fstr);
	fflush(stdout); // for jaer to print this
	for(int i = 0; i < num_object; i++){		
		fprintf( fp, " template%d = [ ", i);
		for(int j=0; j < MAX_TEMPLATE_SIZE; j++) {
			for(int k=0; k < MAX_TEMPLATE_SIZE; k++) {
				fprintf( fp, " %f ", conv_template[i][j][k]);
			}
			fprintf(fp, "; \n");
		}
		fprintf(fp , " ];\nfigure;imagesc(template%d);\n\n",i);		
	}
	fflush(fp);	

}

void dumpTemplateArr(float templ[][MAX_TEMPLATE_SIZE], char* name, int id)
{
	char fname[25];
	int j,k;
	sprintf( fname, "%s%d.txt", name, id);
	static FILE* fp = fopen(fname,"w");
	
	fprintf( fp, " template%d = [ ", id);
 	for(j=0; j < MAX_TEMPLATE_SIZE; j++) {
		for(k=0; k < MAX_TEMPLATE_SIZE; k++) {
			fprintf( fp, " %f ", templ[j][k]);
		}
		fprintf(fp, "; \n");
	}
	fprintf(fp , " ];\n\n " );

	fclose(fp);
}


// only for debug, writes the membrane potentials to a file
void showMembranePotential(unsigned int* spikeAddr=NULL, int spikeCnt=0)
{
#if RECORD_MEMBRANE_POTENTIAL
		void* devPtr;		
		if((countMem >= RECORD_START && countMem <= RECORD_END))
		{
			if(runCuda)
				cudaMemcpyFromSymbol(membranePotential, "gpu_membranePotential", sizeof(membranePotential), 0, cudaMemcpyDeviceToHost);

			char fname[100];
			sprintf(fname, "mem_pot%d.m", countMem);
			FILE* fpDumpPot;	
			fpDumpPot = fopen(fname, "w");

			fprintf( fpDumpPot, " memPot = [ " );		

			for(int i=0; i < MAX_Y; i++) {
				for(int j=0; j < MAX_X; j++) {
					fprintf( fpDumpPot, " %f ", membranePotential[0][i][j]);
				}
				fprintf(fpDumpPot, "; \n");
			}

			fprintf(fpDumpPot , " ]; " );
			fclose(fpDumpPot);

			if(spikeAddr != NULL) {
				char fname[100];
				sprintf(fname, "inpSpike%d.m", countMem);
				FILE* fpDumpPot;
				fpDumpPot = fopen(fname, "w");
				fprintf( fpDumpPot, " inpSpike = [ " );
				for(int j=0; j < spikeCnt; j++) {					
					fprintf( fpDumpPot, " %u ", spikeAddr[j]);
				}
				fprintf(fpDumpPot , " ]; " );
				fclose(fpDumpPot);	
			}		
		}	
		
		countMem++;			
#endif

}

float g_temp_conv_value[NUM_CUDA_PACKETS][MAX_TEMPLATE_SIZE][MAX_TEMPLATE_SIZE];

void cudaCopyOutputs()
{
	void* devPtr;// = gpu_conv_template;
	
	CUDA_SAFE_CALL ( cudaGetSymbolAddress(&devPtr, "temp_conv_value"));
#pragma warning(disable:4313)
	printf("Copying temporary template values from GPU (loc = %x size = %d\n", devPtr, sizeof(g_temp_conv_value));
#pragma warning(default:4313)
	CUDA_SAFE_CALL( cudaMemcpy( g_temp_conv_value, devPtr, sizeof(g_temp_conv_value), cudaMemcpyDeviceToHost));

	for(int id=0; id < NUM_CUDA_PACKETS; id++) {

//		char fname[25];
		int j,k;

		static FILE* fp = fopen("gpu_template.txt","w");

//#define G_TEMP_CONV_VALUE(i,j,k)  *(g_temp_conv_value + i*MAX_TEMPLATE_SIZE*MAX_TEMPLATE_SIZE + j*MAX_TEMPLATE_SIZE + k)
		
		fprintf( fp, " template%d = [ ", id);
 		for(j=0; j < MAX_TEMPLATE_SIZE; j++) {
			for(k=0; k < MAX_TEMPLATE_SIZE; k++) {
				fprintf( fp, " %f ", g_temp_conv_value[id][j][k]);
			}
			fprintf(fp, "; \n");
		}
		fprintf(fp , " ];\n\n " );

	}
}


void printResults(FILE* fpLog)
{
	if(!runCuda) {
		extern int cpu_totFiring;
		tot_fired = cpu_totFiring;
		extern int cpu_totFiringMO[MAX_NUM_OBJECT];
		printf(" Number of fired neurons is %d\n", tot_fired);	
		printf(" Template size is %dx%d\n", MAX_TEMPLATE_SIZE, MAX_TEMPLATE_SIZE);					
		fprintf(fpLog, " Template size is %dx%d\n", MAX_TEMPLATE_SIZE, MAX_TEMPLATE_SIZE);	
		fprintf(fpLog, " Number of fired neurons is %d\n", tot_fired);
		for(int i=0; i < num_object; i++) {
			printf(" Total firing in Array %d => %d\n", i, cpu_totFiringMO[i]);
			fprintf(fpLog, " Total firing in Array %d => %d\n", i, cpu_totFiringMO[i]);		
		}
	}
	else {
		printf("Kernel 1 called %d times\n", callCount);
		printf(" Total number of spikes computed : %d\n", tot_filteredSpikes);
		printf(" Number of fired neurons is %d\n", tot_fired);	
		printf(" Template size is %dx%d\n", MAX_TEMPLATE_SIZE, MAX_TEMPLATE_SIZE);			
		fprintf(fpLog, "Kernel 1 called %d times\n", callCount);
		fprintf(fpLog, " Total number of spikes computed : %d\n", tot_filteredSpikes);
		fprintf(fpLog, " Number of fired neurons is %d\n", tot_fired);
		fprintf(fpLog, " Template size is %dx%d\n", MAX_TEMPLATE_SIZE, MAX_TEMPLATE_SIZE);

		if (multi_object) {
			for(int i=0; i < num_object; i++) {
				printf(" Total firing in Array %d => %d\n", i, tot_fired_MO[i]);
				fprintf(fpLog, " Total firing in Array %d => %d\n", i, tot_fired_MO[i]);												
			}	
		}
	}
	
#if !VERSION_0_1
	int tot=0;
	int minLen=1000;
	int mini=0;
	int maxLen=-1;
	int maxi=0;
	int cnt=(callCount>PARAM_LEN_SIZE)?PARAM_LEN_SIZE:callCount;
	for(int i=0; i < cnt; i++) {
	  tot+= paramLenArr[i];
	  if (paramLenArr[i] < minLen) {minLen =paramLenArr[i];  mini=i; }
	  if (paramLenArr[i] > maxLen) {maxLen = paramLenArr[i]; maxi=i; }
	}
	if(runCuda) {
		printf(" Spike Distribution Per Kernel Call: \nmean(%f), min (i=%d, val=%d), max(i=%d,val=%d)\n", tot*1.0/cnt, mini, minLen, maxi,maxLen);
		fprintf(fpLog, " Spike Distribution Per Kernel Call: \nmean(%f), min (i=%d, val=%d), max(i=%d,val=%d)\n", tot*1.0/cnt, mini, minLen, maxi,maxLen);
	}
#endif

		if(runCuda) {
		int test_fired;
		cudaMemcpyFromSymbol(&test_fired, "totFiring", 4, 0, cudaMemcpyDeviceToHost);
		printf( " Total Object scanned : %d\n", num_object);
		printf( " Total firing from Inhibition Neuron : %d\n", inhFireCnt);
		printf( " Total firing is equal to %d\n", test_fired);	
		printf( " Average firing is equal to %f\n", test_fired*1.0/callCount);
		printf( "\n\nAvg. GPU Processing time per spike: %f (ms)\n", accTimer/(tot_filteredSpikes));
		printf( "\n\nTotal GPU Processing time : %f (ms)\n", accTimer);
		fprintf( fpLog,  " Total Object scanned : %d\n", num_object);
		fprintf( fpLog,  " Total firing from Inhibition Neuron : %d\n", inhFireCnt);
		fprintf( fpLog,  " Total firing is equal to %d\n", test_fired);
		fprintf( fpLog,  "\n\nAvg. GPU Processing time per spike: %f (ms)\n", accTimer/(tot_filteredSpikes));
		fprintf( fpLog,  "\n\nTotal GPU Processing time : %f (ms)\n", accTimer);	
	}
	else {	
		extern int cpu_totFiring;
		extern int iNeuronFiringCnt;
		extern int iNeuronCallingCnt;    
		printf( " Total Object scanned : %d\n", num_object);
		printf("  INeuron Grouping Impact, Calls = %d, Firing = %d\n", iNeuronCallingCnt, iNeuronFiringCnt);
		printf( " Total firing is equal to %d\n", cpu_totFiring);
		printf( "\n\nCPU Processing time per spike: %f (ms)\n",  accTimer/(tot_filteredSpikes));
		printf( "\n\nTotal CPU Processing time : %f (ms)\n", accTimer);
		fprintf( fpLog,  " Total Object scanned : %d\n", num_object);
		fprintf( fpLog,  " Total firing from Inhibition Neuron : %d\n", iNeuronFiringCnt);
		fprintf( fpLog,  " Total firing is equal to %d\n", cpu_totFiring);
		fprintf( fpLog,  "\n\nCPU Processing time per spike: %f (ms)\n",  accTimer/(tot_filteredSpikes));
		fprintf( fpLog, "\n\nTotal CPU Processing time : %f (ms)\n", accTimer);	
	}

	fflush(stdout);  // so jaer gets it
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