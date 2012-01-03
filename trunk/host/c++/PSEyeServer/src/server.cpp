
// Includes
#include "server.h"

PSEyeServer::PSEyeServer() : hPipe(INVALID_HANDLE_VALUE) {}

PSEyeServer::~PSEyeServer() {
    destroyPipe();
}

bool PSEyeServer::createPipe() {
    if (hPipe == INVALID_HANDLE_VALUE) {
        hPipe = CreateNamedPipe(
                ipcPipeName,              // pipe name 
                PIPE_ACCESS_DUPLEX,       // read/write access 
                PIPE_TYPE_MESSAGE |       // message type pipe 
                PIPE_READMODE_MESSAGE |   // message-read mode 
                PIPE_WAIT,                // blocking mode 
                1,                        // max. instances  
                sizeof(PSEyeMessage),     // output buffer size 
                sizeof(PSEyeMessage),     // input buffer size
                0,                        // client time-out 
                NULL);
    }
    return hPipe != INVALID_HANDLE_VALUE;
}

bool PSEyeServer::destroyPipe() {
    if (hPipe != INVALID_HANDLE_VALUE) {
        CloseHandle(hPipe);
        hPipe == INVALID_HANDLE_VALUE;
    }
    
    return true;
}

bool PSEyeServer::run() {
    bool fConnected, fSuccess;
    PSEyeMessage * message;
    uint32_t bytesPosted;
    
    // try to create named pipe
    if (!createPipe()) {
        return false;
    }
    
    // wait for client connection
    for (;;) {
        // Wait for the client to connect; if it succeeds, 
        // the function returns a nonzero value. If the function
        // returns zero, GetLastError can return ERROR_PIPE_CONNECTED. 
        fConnected = false;
        fConnected = ConnectNamedPipe(hPipe, NULL) != 0;
        fConnected = fConnected || GetLastError() == ERROR_PIPE_CONNECTED;
        if (fConnected) { 
            // try to read client request
            fSuccess = false;
            fSuccess = ReadFile(
                    hPipe,        // handle to pipe 
                    message,    // buffer to receive data 
                    sizeof(PSEyeMessage), // size of buffer 
                    (DWORD*) &bytesPosted, // number of bytes read
                    NULL);        // not overlapped I/O
            // successfully read message
            if (fSuccess && bytesPosted == sizeof(PSEyeMessage)) {
                // deal with message
                answerRequest(message);
                
                //post response
                fSuccess = WriteFile( 
                        hPipe,        // handle to pipe 
                        message,     // buffer to write from 
                        sizeof(PSEyeMessage), // number of bytes to write 
                        (DWORD*) &bytesPosted,   // number of bytes written
                        NULL);        // not overlapped I/O
                // flush buffer so response can be read
                FlushFileBuffers(hPipe);
            }   
        }
    }
}

void PSEyeServer::answerRequest(PSEyeMessage* request) {
    switch (request->type) {
        case CAMERA_COUNT:
            request->state.index = CLEyeGetCameraCount();
            break;
        case CAMERA_GUID:
            request->state.guid = CLEyeGetCameraUUID(request->state.index);
            break;
        case CREATE_CAMERA:
        case DESTROY_CAMERA:
        case START_CAMERA:
        case STOP_CAMERA:
        case GET_PARAMETERS:
        case SET_PARAMETERS:
        default:
            request->state.index = CLEyeGetCameraCount();
            break;
    }
}

PSEyeServer::PSEyeCamera::PSEyeCamera() : hMmf(NULL), pBuffer(NULL), 
        hThread(NULL), frameBuffer(NULL), instance(NULL), running(false) {
    // default camera state
    state.index = 0;
    state.guid;  
       
    state.colourMode = BAYER_RAW;
    state.resolution = QVGA;
    state.frameRate = 0;
    
    state.exposure.isAuto = true;
    state.exposure.value = 0;
    
    state.gain.isAuto = true;
    state.gain.value = 0;
    
    state.balance.isAuto = true;
    state.balance.red = 0;
    state.balance.green = 0;
    state.balance.blue = 0;
}

PSEyeServer::PSEyeCamera::~PSEyeCamera() {
    deallocateSharedMemory();
}

int PSEyeServer::PSEyeCamera::getFrameSize() {
    int bytesPerPixel;
    int nPixels;
    
    switch(state.colourMode) {
        case MONO_RAW: bytesPerPixel = 1; break;
        default: bytesPerPixel = 3;
    }
    switch(state.resolution) {
        case QVGA: nPixels = 320 * 240; break;
        default: nPixels = 640 * 480; 
    }
    
    return nPixels * bytesPerPixel;
}

bool PSEyeServer::PSEyeCamera::allocateSharedMemory() {
    if (hMmf != NULL || pBuffer != NULL) {
        deallocateSharedMemory();
    }
    
    // concatenate index and base name to get unique mmf
    char mmfName[1024];
    sprintf(mmfName, "%s%i", mmfBaseName, state.index);

    // calculate buffer sizes needed
    int dataFrameSize = getFrameSize();
    int padding = dataFrameSize % CACHE_LINE_SIZE;
    int totalFrameSize = dataFrameSize + padding;
    int bufferSize = sizeof(PSEyeFrameBuffer) + BUFFER_FRAMES * totalFrameSize;
    
    // create memory-mapped file
    hMmf = CreateFileMapping(
            INVALID_HANDLE_VALUE,       // use memory
            NULL,                       // no security
            PAGE_READWRITE,             // allow read/write access
            0,                          // high-endian size???
            bufferSize,                 // size of buffer
            mmfName                     // name of memory-mapped file
            );
    
    if (hMmf == NULL) {
        return false;
    }
    
    // create local buffer view of mmf
    pBuffer = (uint8_t *) MapViewOfFile(hMmf,   // handle to map object
            FILE_MAP_ALL_ACCESS, // read/write permission
            0,
            0,
            bufferSize);

    if (pBuffer == NULL) {
        CloseHandle(hMmf);
        hMmf = NULL;
        return false;
    }
    
    // Clear the buffer
    ZeroMemory(pBuffer, bufferSize);
    
    // Pack buffer with objects using placement new (don't need to free as buffer freed)
    frameBuffer = new(pBuffer) PSEyeFrameBuffer;
    int offset = sizeof(PSEyeFrameBuffer);
    PSEyeFrame frame;
    for (int i = 1; i <= BUFFER_FRAMES; i++) {
        frame = frameBuffer->frames[i - 1];
        new(&(pBuffer[offset])) uint8_t[totalFrameSize];
        frame.dataOffset = offset;
        frame.size = dataFrameSize;
        frame._padding = padding;
        frame.next = i == BUFFER_FRAMES ? i : 0;
        offset += totalFrameSize;
    }
    
    frameBuffer->head = 0;
    frameBuffer->tail = 0;
    
    return true;
}

bool PSEyeServer::PSEyeCamera::deallocateSharedMemory() {
    if (pBuffer != NULL) {
        UnmapViewOfFile(pBuffer);
        pBuffer = NULL;
    }

    if (hMmf != NULL) {
        CloseHandle(hMmf);
        hMmf = NULL;
    }
    
    frameBuffer = NULL;
    return true;
}

bool PSEyeServer::PSEyeCamera::start() {
    if (frameBuffer == NULL) {
        return false;
    }
    if (!running) {
        if (!CLEyeCameraStart(instance)) {
            return false;
        }
        // Create a thread for this client. 
        hThread = CreateThread( 
                NULL,              // no security attribute 
                0,                 // default stack size 
                startThread,    // thread proc
                this,    // thread parameter 
                CREATE_SUSPENDED,   // create suspended 
                NULL);      // returns thread ID
        if (hThread == 0) {
            return false;
        }
        running = true;
        ResumeThread(hThread);
    }
    return true;
}

bool PSEyeServer::PSEyeCamera::stop() {
    if (running) {
        running = false;
        WaitForSingleObject(hThread, INFINITE);
        CloseHandle(hThread);
        hThread = NULL;
        return CLEyeCameraStop(instance);
    }
    return true;
}

void PSEyeServer::PSEyeCamera::runThread() {
    PSEyeFrame frame;
    while(running) {
        frame = frameBuffer->frames[frameBuffer->head];
        if (CLEyeCameraGetFrame(instance, (BYTE *) &pBuffer[frame.dataOffset])) {
            if (frame.next != frameBuffer->tail) {
                frameBuffer->head = frame.next;
            }
        }
    }
}

bool PSEyeServer::PSEyeCamera::create() {
    if (instance != NULL) {
        destroy();
    }
    instance = CLEyeCreateCamera(state.guid, 
            PSEyeServer::mapColourMode(state.colourMode), 
            PSEyeServer::mapResolution(state.resolution), 
            state.frameRate);
    
    return instance != NULL;
}

bool PSEyeServer::PSEyeCamera::destroy() {
    if (instance != NULL) {
        if (!CLEyeDestroyCamera(instance)) {
            return false;
        }
        instance = NULL;
    }
    return true;
}

CLEyeCameraColorMode PSEyeServer::mapColourMode(PSEyeColourMode colourMode) {
    switch(colourMode) {
        case MONO_RAW: return CLEYE_MONO_RAW;
        case COLOUR_RAW: return CLEYE_COLOR_RAW;
        case BAYER_RAW: return CLEYE_BAYER_RAW;
        default: return CLEYE_BAYER_RAW;
    }
}

CLEyeCameraResolution PSEyeServer::mapResolution(PSEyeResolution resolution) {
    switch (resolution) {
        case QVGA: return CLEYE_QVGA;
        case VGA: return CLEYE_VGA;
        default: return CLEYE_QVGA;        
    }
}

CLEyeCameraParameter PSEyeServer::mapParameter(PSEyeParameter parameter) {
    switch(parameter) {
        case AUTO_GAIN: return CLEYE_AUTO_GAIN;
        case GAIN: return CLEYE_GAIN;
        case AUTO_EXPOSURE: return CLEYE_AUTO_EXPOSURE;
        case EXPOSURE: return CLEYE_EXPOSURE;
        case AUTO_WHITEBALANCE: return CLEYE_AUTO_WHITEBALANCE;
        case WHITEBALANCE_RED: return CLEYE_WHITEBALANCE_RED;
        case WHITEBALANCE_GREEN: return CLEYE_WHITEBALANCE_GREEN;
        case WHITEBALANCE_BLUE: return CLEYE_WHITEBALANCE_BLUE;
        default: return CLEYE_AUTO_GAIN;
    }
}

