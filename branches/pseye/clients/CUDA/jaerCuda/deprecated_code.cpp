/*
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

int jaerRecv()
{
	grabIoMutex();
	if (!wsaActive)
	{	
		fprintf(stderr,"\n Socket Not initialized Wrong version\n");
		return 0;
	}

	int flag = recv(inputSocket, recvBuf, RECV_SOCK_BUFLEN, 0);
	if (flag == INVALID_SOCKET)
	{
		PRINTERROR("recv()");
		closesocket(outputSocket);
		return 0;
	}
	
	// what is this? (tobi)
	while(!((recvBuf[0] == 0 && recvBuf[1] == 0) || (recvBuf[0] == -1 && recvBuf[1] == -1)))
	{
		flag = recv(outputSocket, recvBuf, RECV_SOCK_BUFLEN, 0);	
		
		if (flag == INVALID_SOCKET)
		{
			PRINTERROR("recv()");
			closesocket(outputSocket);
			return 0;
		}

	}
	
	if ( flag == -1 ) {
		perror("recv call failed\n");
		fflush(stdout);
	}	
	
	if ( flag % 8 != 0) {
		printf("Amount of data received is %d (not multiple of 8) \n", flag);
		fflush(stdout);
	}
	releaseIoMutex();
	return flag;
}

int jaerClientConnect()
{
	int iResult;
	struct addrinfo *result = NULL,
		*ptr = NULL,
		hints;

	if (wsaActive == 0)
	{	
		fprintf(stderr,"\n Socket Not initialized Wrong version\n");
		return -1;
	}

	ZeroMemory( &hints, sizeof(hints) );
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;

	// Resolve the server address and port
	char port_str[25];
	_itoa(AE_INPUT_PORT, port_str, 10);
	printf("Trying to connect to JAER Server %s on port %s to receive events\n", JAER_SERVER_IP_ADDRESS, port_str);
		fflush(stdout);
	iResult = getaddrinfo( JAER_SERVER_IP_ADDRESS, port_str, &hints, &result);

	if ( iResult != 0 ) {
		printf("getaddrinfo failed: %d\n", iResult);
		WSACleanup();
		return -1;
	}

	// Attempt to connect to the first address returned by
	// the call to getaddrinfo
	ptr=result;

	// Create a SOCKET for connecting to server
	ConnectSocket = socket(ptr->ai_family, ptr->ai_socktype, 
		ptr->ai_protocol);

	if (ConnectSocket == INVALID_SOCKET) {
		printf("Error at socket(): %ld\n", WSAGetLastError());
		freeaddrinfo(result);
		WSACleanup();
		return -1;
	}

	// Connect to server.
	iResult = connect( ConnectSocket, ptr->ai_addr, (int)ptr->ai_addrlen);
	if (iResult == SOCKET_ERROR) {
		closesocket(ConnectSocket);
		ConnectSocket = INVALID_SOCKET;
		return -1;
	}

	// Should really try the next address returned by getaddrinfo
	// if the connect call failed
	// But for this simple example we just free the resources
	// returned by getaddrinfo and print an error message

	freeaddrinfo(result);

	if (ConnectSocket == INVALID_SOCKET) {
		printf("Unable to connect to server!\n");
		fflush(stdout);
		WSACleanup();
		return -1;
	}
	printf("Connected to server of events\n");
	fflush(stdout);
	return 0;
}
int jaerServerInit()
{
	if (wsaActive == 0)
	{	
		fprintf(stderr,"\n Socket Not initialized Wrong version\n");
		return -1;
	}

	//
	// Create a TCP/IP stream socket to "listen" for client connections to receive events from us.
	//
	
	listenSocket = socket(AF_INET,			// Address family
						  SOCK_STREAM,		// Socket type
						  IPPROTO_TCP);		// Protocol
	if (listenSocket == INVALID_SOCKET)
	{
		PRINTERROR("socket()");
		return -1;
	}

	//
	// Fill in the address structure
	//
	SOCKADDR_IN saServer;		

	saServer.sin_family = AF_INET;
	saServer.sin_addr.s_addr = INADDR_ANY;	// Let WinSock supply address
	saServer.sin_port = htons(AE_OUTPUT_PORT);		// Use port from command line

	//
	// bind the name to the socket
	//
	int nRet;

	nRet = bind(listenSocket,				// Socket 
				(LPSOCKADDR)&saServer,		// Our address
				sizeof(struct sockaddr));	// Size of address structure
	if (nRet == SOCKET_ERROR)
	{
		PRINTERROR("bind()");
		closesocket(listenSocket);
		return -1;
	}

	//
	// This isn't normally done or required, but in this 
	// example we're printing out where the server is waiting
	// so that you can connect the example client.
	//
//	int nLen;
//	nLen = sizeof(SOCKADDR);
	char szBuf[256];

	nRet = gethostname(szBuf, sizeof(szBuf));
	if (nRet == SOCKET_ERROR)
	{
		PRINTERROR("gethostname()");
		closesocket(listenSocket);
		return -1;
	}

	//
	// Show the server name and port number
	//
	printf("\nServer named %s waiting on port %d\n",
			szBuf, AE_OUTPUT_PORT);

	//
	// Set the socket to listen
	//

	printf("\nlisten()");
	nRet = listen(listenSocket,					// Bound socket
				  SOMAXCONN);					// Number of connection request queue
	if (nRet == SOCKET_ERROR)
	{
		PRINTERROR("listen()");
		closesocket(listenSocket);
		return -1;
	}

	//
	// Wait for an incoming request
	//


	printf("\nBlocking at accept() on port %d; jAER viewer should open AE stream socket input connection from us.\n",AE_OUTPUT_PORT);
	remoteSocket = accept(listenSocket,			// Listening socket
						  NULL,					// Optional client address
						  NULL);
	if (remoteSocket == INVALID_SOCKET)
	{
		PRINTERROR("accept()");
		closesocket(listenSocket);
		return -1;
	}

	printf("\nConnection established with client()");

	return 0;
	
}

int jaerServerSend(char buf[], int bufSize)
{
	int nRet;

	//
	// Send data back to the client
	//
	if(debugLevel>0){
		printf("\nSending %d bytes to client", bufSize);
	}
	nRet = send(remoteSocket,				// Connected socket
				buf,						// Data buffer
				bufSize,				// Length of data
				0);							// Flags

	if(debugLevel>0)
		printf("\nSent %d bytes to client", nRet);
	return nRet;

}

*/
