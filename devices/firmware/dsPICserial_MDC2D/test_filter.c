


#include <p33Fxxxx.h>


int main()
{
	unsigned long sum;
	unsigned int frame[]= {60000,30000,0,0};
	unsigned int i,avg,n;

	n= sizeof(frame)/sizeof(frame[0]);
	for(i=0; i<n; i++)
		sum+= frame[i];

	avg= sum/n;

	return (int) avg;
}