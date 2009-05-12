#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <time.h>

#include <Winsock2.h>
#include <Ws2tcpip.h>

#include <windows.h>

#include "config.h"

// jAERInteface.cpp - event IO for jaercuda

// use jaerInit() to initialize.

// CUDA waits for jAER to contact it on its control port (CONTROL_PORT, hardcoded), then reads 
// from this which host to send events to. Control commands from jaer also set the port to which 
// events are sent from jaer (outputPort) and on which they should be received by CUDA (inputPort).
// Control is via a separate thread that shares a mutex with the main thread. 
// These ports are set via the
// inputPort <port> and outputport <port> control commands sent from jaer.
// only after these ports are set does jaerCuda receive, process, then send events.
// all communication is by unreliable UDP datagram packets. The maximum datagram packet size is
// set by RECV_SOCK_BUFLEN and SEND_SOCK_BUFLEN.

// events are sent from jaercuda by sendEvent() which automatically sends out packets when they are full
// or timeout has been passed. This timeout avoids starving jaer when CUDA only produces a small number of events.
// sendEvent accepts x, y, timestamp, and type, where type can be used for polarity or for some extended event
// class that can be rendered in e.g. different colors in jaer.

// events are recieved from jaer by jaerRecv, which returns the number of bytes recieved.
 

#include <winsock2.h>
#include <stdio.h>
#include <assert.h>
#pragma comment(lib,"ws2_32.lib")
#include "config.h"

extern "C" {
int jaerCommandConnect(); // we are controlled by a thread which receives commands from jaer and sets variables here
int jaerClientConnect(); // connects or reconnects to jAER
int jaerInit();
int jaerRecv();
void jaerSendEvent(unsigned int addrx, unsigned int addry, unsigned long timeStamp, unsigned char type);
int makeOutputSocket();
int makeInputSocket();
}


SOCKET controlSocket = INVALID_SOCKET; // socket we receive and send commands/status on
SOCKET	inputSocket = INVALID_SOCKET; // socket we receive ae data on
SOCKET outputSocket = INVALID_SOCKET; // socket we send ae data on

struct sockaddr_in jaerAEInputAddr; /* addr we get AE data from */
struct sockaddr_in jaerAEOutputAddr; /* addr we send AE data to, set from control peer host and outputPort*/
int jaerAddrSize = sizeof(sockaddr_in);

int visits=0; /*the number client connect*/
DWORD maxXmitIntervalMs=MAX_XMIT_INTERVAL_MS; // max interval in ms to send packets, to avoid starving jaer 
DWORD lastXmitTime=0;

int controlPort = CONTROL_PORT; // out local control port on which we receive control/parameters  - hard coded
int outputPort=-1; // port on jaer we send ae data to - set by jaer
int inputPort=-1; // local port we receive data on - set by jaer
WSADATA wsaData;
bool wsaActive = false; // flag that shows we got winsock running
char recvBuf[RECV_SOCK_BUFLEN]; // buffer that holds received ae data
char sendBuf[SEND_SOCK_BUFLEN]; // buffer that holds ae data we send
int  sendBufLen = 0; // bytes we have accumulated to send
HANDLE ioMutex; // mutex for io, shared between main thread and command processor 

int  cmdRecvBufLen = 1024; 
char cmdRecvBuf[1024]; // buffer to hold received command strings

int jaerCommandConnect(); // we are controlled by a thread which receives commands from jaer and sets variables here
int jaerClientConnect();  // connects or reconnects to jAER
int jaerCreateCommandProcessingThread();
int sendAEPacket();
int jaerRecv();
void grabIoMutex();
void releaseIoMutex();
int startJaerCommandProcessingThread();
void jaerSendEvent(unsigned int addrx, unsigned int addry, unsigned long timeStamp, unsigned char type);

extern globalNeuronParams_t hostNeuronParams;
extern bool stopEnabled, tmpRunCuda, sendGlobalNeuronParamsEnabled, wsaActive;
extern int debugLevel;
extern DWORD maxXmitIntervalMs;
extern int inputPort, outputPort;
extern DWORD maxXmitIntervalMs;

// Helper macro for displaying errors
#define PRINTERROR(s)	\
		fprintf(stderr,"\nError %s: WSAGetLastError()= %d\n", s, WSAGetLastError())

bool isTimeToSend(){
	DWORD t=GetTickCount();
	if(t-lastXmitTime>maxXmitIntervalMs){
		lastXmitTime=t;
		return true;
	}else{
		return false;
	}
}

// adds single event to outgoing packet and sends it if the buffer is full or there is a timeout on sending
void jaerSendEvent(unsigned int addrx, unsigned int addry, unsigned long timeStamp, unsigned char type)
{
	assert(sendBufLen <= (SEND_SOCK_BUFLEN-EVENT_LEN));
//	assert(addrx < MAX_X);
//	assert(addry < MAX_Y);

	char* aerBuf = &sendBuf[sendBufLen];
	aerBuf[0] = 0;
	aerBuf[1] = type;
	aerBuf[2] = addry&0x7f;
	aerBuf[3] = (((MAX_X - 1 - addrx) << 1)&0xfe);
	aerBuf[4] = (char)((timeStamp >> 24)&0xff);
	aerBuf[5] = (char)((timeStamp >> 16)&0xff);
	aerBuf[6] = (char)((timeStamp >> 16)&0xff);
	aerBuf[7] = (char)((timeStamp >> 0 )&0xff);

	sendBufLen+=EVENT_LEN;
				
	// accumulate fired neuron and send to jaerViewer
	if ( sendBufLen >= SEND_SOCK_BUFLEN || isTimeToSend()) {
		sendAEPacket();
		sendBufLen = 0;
	}

	//if(debugLevel> 2) {
	//	if(sendBufLen == 0){
	//		printf("addrx[0] = %d, addry[0] = %d",aerBuf[3],aerBuf[4]);
	//	}
	//}
		

	return;
}

// sends the output buffer
int sendAEPacket()
{
	grabIoMutex();
	if(outputPort<=0){
		fprintf(stderr,"sendAEPacket(): no outputPort yet, can't send\n");
	    fflush(stderr);
		return -1;
	}

   int nSent=sendto(outputSocket,sendBuf,sendBufLen,0,(LPSOCKADDR)&jaerAEOutputAddr,jaerAddrSize);
   if(nSent==SOCKET_ERROR){
	   fprintf(stderr,"sendAEPacket(): error %d sending events",WSAGetLastError());
	   fflush(stderr);
	   releaseIoMutex();
	   return nSent;
   }
   if(debugLevel>1){
	printf("sendAEPacket: sent %d bytes to jaer\n",nSent);
	fflush(stdout);
   }

   releaseIoMutex();
   if(nSent<sendBufLen){
	   fprintf(stderr,"only sent %d of %d bytes\n",nSent,sendBufLen);
   }
   sendBufLen=0; // point to start of buffer

   return nSent;
}


// blocks until an input packet comes
int jaerRecv()
{
	sockaddr_in recvAddr;
	int recvAddrSize=sizeof(recvAddr);
	if(inputPort<=0){
		return 0;
	}
	if(inputSocket==INVALID_SOCKET){
		return 0;
	}
   
	// jaerAddr information will be filled in when control command is recieved to set outputPort recvfrom executes

   //// Check for messages
   //FD_SET set;
   //timeval timeVal;

   //FD_ZERO( &set );
   //FD_SET( serverSock, &set );

   //timeVal.tv_sec = 0;
   //timeVal.tv_usec = 0;

   //result = select( FD_SETSIZE, &set, NULL, NULL, &timeVal );

   //if( result == 0 )
   //{
   //   Sleep( 300 );
   //   continue;
   //}

   //if( result == SOCKET_ERROR )
   //{
   //  fprintf(stderr,"select error\n");
   //  exit(1);
   //}

   // memset(buf,0,sizeof(buf));
	int addrLen=0;
	int recvLen=sizeof(recvBuf);

	grabIoMutex();
	int len=recvfrom(inputSocket,recvBuf,recvLen,0,(SOCKADDR *)&recvAddr,&recvAddrSize);
	if(len==0){
		fprintf(stderr,"jaerRecv: inputSocket was gracefully closed\n");
		fflush(stderr);
	}else if(len==SOCKET_ERROR){
		fprintf(stderr,"jaerRecv: SOCKET_ERROR=%d\n",WSAGetLastError());
		fflush(stderr);
	}else if(len>0){
#ifdef USE_PACKET_SEQUENCE_NUMBER
		len-=4;
#endif
		if(len%EVENT_LEN!=0){
			fprintf(stderr,"jaerRecv: %d bytes received is not a multiple of EVENT_SIZE (%d)",len,EVENT_LEN);
			fflush(stderr);
		}
	}
	releaseIoMutex();

 /*   visits++;
    strcpy(ip,inet_ntoa(jaerAddr.sin_addr));
    clientPort=ntohs((u_short)jaerAddr.sin_port);

    fprintf(stdout,"\nA client come from ip:%s port:%d .\nThis server has been contacted %d time%s\n",ip,clientPort,visits,visits==1?".":"s.");*/

   return len;
}


// constructs inputSocket given that inputPort has been set to >0
int makeInputSocket(){
	if(!wsaActive){
		fprintf(stderr,"makeInputSocket: sockets not active\n");
		fflush(stderr);
		exit(1);
	}

	if(inputSocket!=INVALID_SOCKET){
		int err=closesocket(inputSocket);
		if(err==SOCKET_ERROR){
			fprintf(stderr,"makeInputSocket: closesocket error WSAGetLastError=%d\n",WSAGetLastError());
			fflush(stderr);
		}
		inputSocket=INVALID_SOCKET;
	}

	grabIoMutex();

	if(inputPort<=0){
		fprintf(stderr,"makeInputSocket: invalid inputPort %d",inputPort);
		fflush(stderr);
		return -1;
	}
   int len=sizeof(struct sockaddr);
//   char ip[15]; /*client address*/
  
	inputSocket=socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP);/*create a socket*/
	if (inputSocket==INVALID_SOCKET){
		fprintf(stderr,"makeInputSocket: creating inputSocket failed, WSAGetLastError=%d\n",WSAGetLastError());
 		fflush(stderr);
		releaseIoMutex();
	    return -1;
	}

	//memset((char*)&jaerAEInputAddr,0,sizeof(jaerAEInputAddr));
	jaerAEInputAddr.sin_family=AF_INET; /*set server address protocol family*/
	jaerAEInputAddr.sin_addr.s_addr=htonl(INADDR_ANY); // we're receiving from anywhere
    jaerAEInputAddr.sin_port=htons(inputPort);/*set port*/

	if (bind(inputSocket,(SOCKADDR *)&jaerAEInputAddr,sizeof(jaerAEInputAddr))==SOCKET_ERROR){/*bind a server address and port*/
		fprintf(stderr,"makeInputSocket: inputSocket bind to port %d failed: WSAGetLastError=%d\n",inputPort,WSAGetLastError());
 		fflush(stderr);
		releaseIoMutex();
		return -1;
  }
	printf("makeInputSocket: bound inputSocket to port %d\n",inputPort);
	fflush(stdout);

   // Set Non Blocking Mode, specified via last parameter
   // 0 Disabled 
   // !0 Enabled 
 /*  unsigned long int nonBlockingMode = 1;
   int result = ioctlsocket( serverSock, FIONBIO, &nonBlockingMode );

   if ( result )
   {
     fprintf(stderr,"ioctlsocket failed\n");
     exit(1);
   }*/
   releaseIoMutex();
   return 0;
}

// makes output datagram socket (outputSocket) from recieved hostname and outputPort
int makeOutputSocket(){
	if(!wsaActive){
		fprintf(stderr,"makeOutputSocket: sockets not active\n");
		fflush(stderr);
		exit(1);
	}

	if(outputSocket!=INVALID_SOCKET){
		int err=closesocket(outputSocket);
		if(err==SOCKET_ERROR){
			fprintf(stderr,"makeOutputSocket: closesocket error WSAGetLastError=%d\n",WSAGetLastError());
			fflush(stderr);
		}
		outputSocket=INVALID_SOCKET;
	}

	grabIoMutex();

	if(outputPort<=0){
	   fprintf(stderr,"makeOutputSocket: invalid output port %d<0\n",outputPort);
	   fflush(stderr);
	   return -1;
   }

   outputSocket=socket(PF_INET,SOCK_DGRAM,0);/*create a socket*/
   if (outputSocket<0){
	   fprintf(stderr,"makeOutputSocket: creating output socket failed. WSAGetLastError=%d\n",WSAGetLastError());
 	   fflush(stderr);
		releaseIoMutex();
	    return -1;
   }

   printf("makeOutputSocket: created AE output socket\n");
   fflush(stdout);

  /* should have been received from jaer on control port */
   //memset((char*)&jaerAddr,0,sizeof(jaerAddr));
   //jaerAddr.sin_family=AF_INET; /*set client address protocol family*/
   //jaerAddr.sin_addr.s_addr=INADDR_ANY;
   //jaerAddr.sin_port=htons((u_short)AE_INPUT_PORT); /*set client port*/

   jaerAEOutputAddr.sin_family=AF_INET;
   jaerAEOutputAddr.sin_port=htons((u_short)outputPort);

   // we don't bind to the outputSocket since we'll be sending datagrams to jaer

   // jaerAEOutputAddr set when we recieved the control that set outputPort
  // int len=sizeof(jaerAEOutputAddr);
  // if (bind(outputSocket,(LPSOCKADDR)&jaerAEOutputAddr,len)<0){// bind  jaer address and port
	 //  fprintf(stderr,"makeOutputSocket: bind failed\n");
 	//   fflush(stderr);
		//return -1;
  // }
   releaseIoMutex();
	return 0;
}

void grabIoMutex()
{
	    DWORD waitResult = WaitForSingleObject( 
            ioMutex,    // handle to mutex
            INFINITE);  // no time-out interval
 
}

void releaseIoMutex()
{
	ReleaseMutex(ioMutex);
}

int jaerInit()
{
	int iResult;
	
	// Initialize Winsock
	iResult = (int)WSAStartup(MAKEWORD(2,2), &wsaData);
	if (iResult != 0) {
		printf("Windows sockets WSAStartup failed: %d (tried for Winsock version 2.2)\n", iResult);
		return -1;
	}
	
	wsaActive = true;
	ioMutex=CreateMutex(NULL,FALSE,NULL); //http://msdn.microsoft.com/en-us/library/ms686927(VS.85).aspx
   if (ioMutex == NULL) 
    {
        printf("CreateMutex error: %d\n", GetLastError());
        return -1;
    }
 	startJaerCommandProcessingThread();
       
	//switch (waitResult) 
 //       {
 //           // The thread got ownership of the mutex
 //           case WAIT_OBJECT_0: 
 //               __try { 
	//				startJaerCommandProcessingThread();
 //               } 
 //               __finally { 
 //                   // Release ownership of the mutex object
 //                   if (! ReleaseMutex(ioMutex)) 
 //                   { 
 //                       return -1;
 //                   } 
 //               } 
 //               break; 

 //           // The thread got ownership of an abandoned mutex
 //           // The database is in an indeterminate state
 //           case WAIT_ABANDONED: 
 //               return FALSE; 
 //       }
 //   }

	return 0;
}

void ErrorHandler(LPTSTR lpszFunction) 
{ 
    // Retrieve the system error message for the last-error code.
    DWORD dw = GetLastError(); 
         fprintf(stderr,"%s failed with error %d",lpszFunction, dw); 
}

void parseJaerCommand(char* buf)
{
	if(strstr(buf,"threshold")){
		sscanf(buf,"%*s%f",&hostNeuronParams.threshold);
		printf("set threshold=%f\n",hostNeuronParams.threshold);
	}else if(strstr(buf,"membraneTau")){
		sscanf(buf,"%*s%f",&hostNeuronParams.membraneTau);
		printf("set membraneTau=%f\n",hostNeuronParams.membraneTau);
	}else if(strstr(buf,"membranePotentialMin")){
		sscanf(buf,"%*s%f",&hostNeuronParams.membranePotentialMin);
		printf("set membranePotentialMin=%f\n",hostNeuronParams.membranePotentialMin);
	}else if(strstr(buf,"minFiringTimeDiff")){
		sscanf(buf,"%*s%f",&hostNeuronParams.minFiringTimeDiff);
		printf("set minFiringTimeDiff=%f\n",hostNeuronParams.minFiringTimeDiff);
	}else if(strstr(buf,"membranePotentialMin")){
		sscanf(buf,"%*s%f",&hostNeuronParams.membranePotentialMin);
		printf("set membranePotentialMin=%f\n",hostNeuronParams.membranePotentialMin);
	}else if(strstr(buf,"eISynWeight")){
		sscanf(buf,"%*s%f",&hostNeuronParams.eISynWeight);
		printf("set eISynWeight=%f\n",hostNeuronParams.eISynWeight);
	}else if(strstr(buf,"iESynWeight")){
		sscanf(buf,"%*s%f",&hostNeuronParams.iESynWeight);
		printf("set iESynWeight=%f\n",hostNeuronParams.iESynWeight);
	}else if(strstr(buf,"exit")){
		printf("setting stopEnabled according to command\n");
		fflush(stdout);
		stopEnabled=1;
	}else if(strstr(buf,"cudaEnabled")){
		if(strstr(buf,"true")) {tmpRunCuda=1;} else {tmpRunCuda=0;}
		printf("set cudaEnabled=%d (on next packet)\n", tmpRunCuda);
		fflush(stdout);
	}else if(strstr(buf,"debugLevel")){
		sscanf(buf,"%*s%d",&debugLevel);
		printf("set debugLevel=%d\n",debugLevel);
		fflush(stdout);
	}else if(strstr(buf,"maxXmitIntervalMs")){
		sscanf(buf,"%*s%d",&maxXmitIntervalMs);
		printf("set maxXmitIntervalMs=%d\n",maxXmitIntervalMs);
		fflush(stdout);
	}else if(strstr(buf,"outputPort")){
		sscanf(buf,"%*s%d",&outputPort);
		printf("set outputPort=%d\n",outputPort);
		makeOutputSocket();
		fflush(stdout);
	}else if(strstr(buf,"inputPort")){
		sscanf(buf,"%*s%d",&inputPort);
		printf("set inputPort=%d\n",inputPort);
		makeInputSocket();
		fflush(stdout);
	}else if(strstr(buf,"deltaTimeUs")){
		sscanf(buf,"%*s%d",&delta_time);
		printf("set delta_time=%d\n",delta_time);
		fflush(stdout);	
	}else if(strstr(buf,"numObject")){
		sscanf(buf,"%*s%d",&num_object);
		if(num_object>MAX_NUM_OBJECT) num_object=MAX_NUM_OBJECT ; else if(num_object<0) num_object=0; // bounds checking
		printf("set num_object=%d\n",num_object);
		fflush(stdout);
	}else{
		printf("unknown command %s\n",buf);
	}
	fflush(stdout);
	sendGlobalNeuronParamsEnabled=1;
}


DWORD WINAPI jaerCommandProcessorThreadFunction(LPVOID lpParam)
{
	sockaddr_in recvAddr;
	int recvAddrSize=sizeof(recvAddr);
	sockaddr_in jaerAddr;

	if (!wsaActive)
	{	
		fprintf(stderr,"\n Socket Not initialized Wrong version\n");
		exit(1);
	}

	//-----------------------------------------------
	  // Create a receiver socket to receive datagrams
	  controlSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

	if (controlSocket==INVALID_SOCKET){
		fprintf(stderr,"startJaerCommandProcessingThread: creating controlSocket failed, WSAGetLastError=%d\n",WSAGetLastError());
 		closesocket(controlSocket);
		fflush(stderr);
	    exit(1);
	}
	  //-----------------------------------------------
	  // Bind the socket to any address and the specified port.
	  jaerAddr.sin_family = AF_INET;
	  jaerAddr.sin_addr.s_addr = htonl(INADDR_ANY);
	  jaerAddr.sin_port = htons(controlPort);

	  int bindResult=bind(controlSocket, (SOCKADDR *) &jaerAddr, sizeof(jaerAddr));
	  if(bindResult==SOCKET_ERROR){
		  fprintf(stderr,"startJaerCommandProcessingThread: can't bind to control port %d, WSAGetLastError=%d, quitting\n", controlPort,WSAGetLastError());
		  fflush(stderr);
			exit(1);
	  }

	printf("startJaerCommandProcessingThread: bound controlSocket to port %d\n",controlPort);

	printf("receiving control datagrams on command port %d\n",controlPort);
		while(stopEnabled == 0){
		  //-----------------------------------------------
		  // Call the recvfrom function to receive datagrams
		  // on the bound socket.
		  int nbytes=recvfrom(controlSocket, 
			cmdRecvBuf, 
			cmdRecvBufLen, 
			0, 
			(SOCKADDR *)&recvAddr,  // stores jaer addr info for use by makeInputSocket? and makeOutputSocket
			&recvAddrSize);
		  if(nbytes==SOCKET_ERROR){
			  fprintf(stderr,"jaerCommandProcessorThreadFunction: receive error WSAGetLastError=%d\n",WSAGetLastError());
			  fflush(stderr);
			  continue;
		  }
		  if(nbytes==0){
			  fprintf(stderr,"jaerCommandProcessorThreadFunction: socket was closed\n");
			  fflush(stderr);
			  continue;
		  }
			cmdRecvBuf[nbytes]=0; // terminate string
			if(debugLevel>0){
				printf("got jaer command \"%s\" from address %d\n",cmdRecvBuf,recvAddr.sin_addr);
				fflush(stdout);
			}
			jaerAEOutputAddr.sin_addr=recvAddr.sin_addr; // set output address to be same as from where we received command
			parseJaerCommand(cmdRecvBuf);
		}

		WSACleanup();
		printf("closed all the sockets\n");
		exit(1);
		
	  //-----------------------------------------------
	  // Close the socket when finished receiving datagrams
	  //printf("Finished receiving. Closing socket.\n");
	  //closesocket(controlSocket);

}


int startJaerCommandProcessingThread()
{
	DWORD WINAPI jaerCommandProcessorThreadFunction( LPVOID lpParam );
	void ErrorHandler(LPTSTR lpszFunction);
    DWORD   dwThreadId;
    HANDLE  hThread; 
	  hThread = CreateThread( 
            NULL,                   // default security attributes
            0,                      // use default stack size  
            jaerCommandProcessorThreadFunction,       // thread function name
            0,					// argument to thread function 
            0,                      // use default creation flags 
            &dwThreadId);   // returns the thread identifier 

        // Check the return value for success.
        // If CreateThread fails, terminate execution. 
        // This will automatically clean up threads and memory. 

        if (hThread == NULL) 
        {
          fprintf(stderr,"couldn't create jaer command processing thread\n");
		  fflush(stderr);
          return -1;
        }
        return 0;
}










