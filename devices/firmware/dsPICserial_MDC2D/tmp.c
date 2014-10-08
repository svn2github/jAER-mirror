
#include <stdio.h>


void cpyit(char *dst,const char *src)
{
	while(*src)
		*dst++=*src++;
	*dst=0;
}

#define WORDAT(buf,i) ((int*)(buf+5))[i]

int main() {
	char buf[30];
	int i;
	memset(buf,0,sizeof(buf));
	WORDAT(buf,0)= 0x101;
	WORDAT(buf,1)= 0x202;
	for(i=0; i<sizeof(buf); i++)
		printf("%02x ",buf[i]);
	printf("\n\n");

	return 0;
}
