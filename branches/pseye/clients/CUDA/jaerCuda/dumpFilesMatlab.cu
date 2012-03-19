// includes, project
#include <stdio.h>
#include <stdlib.h>
#include <cutil.h>

#include "config.h"

extern "C"	{
	void dumpTemplate(FILE* fp, char* fstr);
	void printResults(FILE* fpLog);
	void showMembranePotential(unsigned int* spikeAddr, int spikeCnt);
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

int countMem = 0;

// only for debug, writes the membrane potentials to a file
void showMembranePotential(unsigned int* spikeAddr=NULL, int spikeCnt=0)
{		
		if((countMem >= RECORD_START && countMem <= RECORD_END))
		{
			if(runCuda)
				cudaMemcpyFromSymbol(membranePotential, "gpu_membranePotential", sizeof(membranePotential), 0, cudaMemcpyDeviceToHost);

			char fname[100];
			sprintf(fname, "mem_pot%d.m", countMem);
			FILE* fpDumpPot;	
			fpDumpPot = fopen(fname, "w");
	
			for(int k = 0; k < num_object; k++){
				fprintf( fpDumpPot, " memPot[%d] = [ ", k);
				for(int i=0; i < MAX_Y; i++) {
					for(int j=0; j < MAX_X; j++) {
						fprintf( fpDumpPot, " %f ", membranePotential[k][i][j]);
					}
					fprintf(fpDumpPot, "; \n");
				}
				fprintf( fpDumpPot, "];\n\n");
			}

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

}


void printResults(FILE* fpLog)
{
	int tot_fired = 0;
	if(!runCuda) {
		extern int cpu_totFiring;
		extern int cpu_totFiringMO[MAX_NUM_TEMPLATE];
		printf(" Number of fired neurons is %d\n", cpu_totFiring);	
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
		for(int i = 0; i < num_object; i++)
			tot_fired = tot_fired + tot_fired_MO[i]; 
		printf(" Number of fired neurons is %d\n", tot_fired);	
		printf(" Template size is %dx%d\n", MAX_TEMPLATE_SIZE, MAX_TEMPLATE_SIZE);			
		fprintf(fpLog, "Kernel 1 called %d times\n", callCount);
		fprintf(fpLog, " Total number of spikes computed : %d\n", tot_filteredSpikes);
		fprintf(fpLog, " Number of fired neurons is %d\n", tot_fired);
		fprintf(fpLog, " Template size is %dx%d\n", MAX_TEMPLATE_SIZE, MAX_TEMPLATE_SIZE);

		for(int i=0; i < num_object; i++) {
			printf(" Total firing in Array %d => %d\n", i, tot_fired_MO[i]);
			fprintf(fpLog, " Total firing in Array %d => %d\n", i, tot_fired_MO[i]);													
		}
	}
	
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

	if(runCuda) {
		printf( " Total Object scanned : %d\n", num_object);
		printf( " Total firing from Inhibition Neuron : %d\n", inhFireCnt);
		printf( " Total firing is equal to %d\n", tot_fired);	
		printf( " Average firing is equal to %f\n", tot_fired*1.0/callCount);
		printf( "\n\nAvg. GPU Processing time per spike: %f (ms)\n", accTimer/(tot_filteredSpikes));
		printf( "\n\nTotal GPU Processing time : %f (ms)\n", accTimer);
		fprintf( fpLog,  " Total Object scanned : %d\n", num_object);
		fprintf( fpLog,  " Total firing from Inhibition Neuron : %d\n", inhFireCnt);
		fprintf( fpLog,  " Total firing is equal to %d\n", tot_fired);
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

