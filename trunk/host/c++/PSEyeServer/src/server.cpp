
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

bool PSEyeServer::listen() {
    bool fConnected, fSuccess;
    PSEyeMessage message;
    uint32_t bytesPosted;
    
    std::cout << "Creating pipe." << std::endl;
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
                    &message,    // buffer to receive data 
                    sizeof(PSEyeMessage), // size of buffer 
                    (DWORD*) &bytesPosted, // number of bytes read
                    NULL);        // not overlapped I/O
            // successfully read message
            if (fSuccess && bytesPosted == sizeof(PSEyeMessage)) {
                // deal with message
                answerMessage(message);
                //post response
                fSuccess = WriteFile( 
                        hPipe,        // handle to pipe 
                        &message,     // buffer to write from 
                        sizeof(PSEyeMessage), // number of bytes to write 
                        (DWORD*) &bytesPosted,   // number of bytes written
                        NULL);        // not overlapped I/O
                // flush buffer so response can be read
                FlushFileBuffers(hPipe);
            }   
        }
        else {
            // client closed handle to pipe
            if (GetLastError() == ERROR_NO_DATA) {
                DisconnectNamedPipe(hPipe);
            }
        }
    }
}

void PSEyeServer::answerMessage(PSEyeMessage &message) {
    switch (message.type) {
        case CAMERA_COUNT:
            message.state.index = CLEyeGetCameraCount();
            break;
        case CAMERA_GUID:
            message.state.guid = CLEyeGetCameraUUID(message.state.index);
            break;
        case CREATE_CAMERA:
            if (!createCamera(message.state.index, message.state.colourMode, 
                    message.state.resolution, message.state.frameRate)) message.type = SERVER_ERROR;
            break;
        case DESTROY_CAMERA:
            if (!destroyCamera(message.state.index)) message.type = SERVER_ERROR;
            break;
        case START_CAMERA:
            if (!startCamera(message.state.index)) message.type = SERVER_ERROR;
            break;            
        case STOP_CAMERA:
            if (!stopCamera(message.state.index)) message.type = SERVER_ERROR;
            break;            
        case GET_PARAMETERS:
        case SET_PARAMETERS:
        default:
            message.state.index = CLEyeGetCameraCount();
            break;
    }
}

bool PSEyeServer::createCamera(int32_t index, PSEyeColourMode colourMode, PSEyeResolution resolution, float frameRate) {
    cameras[index].state.index = index;
    cameras[index].state.guid = CLEyeGetCameraUUID(index);
    cameras[index].state.colourMode = colourMode;
    cameras[index].state.resolution = resolution;
    cameras[index].state.frameRate = frameRate;
    
    return cameras[index].create();
}

bool PSEyeServer::destroyCamera(int32_t index) {
    return cameras[index].destroy();
}

bool PSEyeServer::startCamera(int32_t index) {
    return cameras[index].start();
}

bool PSEyeServer::stopCamera(int32_t index) {
    return cameras[index].stop();
}

PSEyeServer::PSEyeCamera::PSEyeCamera() : hEvent(NULL), hThread(NULL), frameSize(0), 
        instance(NULL), running(false) {
    mmf.index = 0;
    mmf.handle = NULL;
    mmf.rawBuffer = NULL;
    mmf.frameBuffer = NULL;
}

PSEyeServer::PSEyeCamera::~PSEyeCamera() {
    stop();
    destroy();
    deallocateMemoryFile();
}

int PSEyeServer::PSEyeCamera::getFrameSize() {
    int bytesPerPixel;
    int nPixels;
    
    switch(state.colourMode) {
        case COLOUR_RAW: bytesPerPixel = 3; break;
        default: bytesPerPixel = 1;
    }
    switch(state.resolution) {
        case QVGA: nPixels = 320 * 240; break;
        default: nPixels = 640 * 480; 
    }
    
    return nPixels * bytesPerPixel;
}

bool PSEyeServer::PSEyeCamera::allocateMemoryFile() {
    if (mmf.handle != NULL || mmf.rawBuffer != NULL) {
        deallocateMemoryFile();
    }
    
    std::cout << "allocating memory." << std::endl;
    
    // concatenate index and base name to get unique mmf
    char mmfName[1024];
    mmf.index = state.index;
    sprintf(mmfName, "%s%i", mmfBaseName, mmf.index);

    // calculate buffer sizes needed
    frameSize = getFrameSize();
    int padding = frameSize % CACHE_LINE_SIZE;
    int totalFrameSize = frameSize + padding;
    int bufferSize = sizeof(PSEyeFrameBuffer) + BUFFER_FRAMES * totalFrameSize;
    std::cout << "buffer size: " << bufferSize << std::endl;
    // create memory-mapped file
    mmf.handle = CreateFileMapping(
            INVALID_HANDLE_VALUE,       // use memory
            NULL,                       // no security
            PAGE_READWRITE,             // allow read/write access
            0,                          // high-endian size???
            bufferSize,                 // size of buffer
            mmfName                     // name of memory-mapped file
            );
    
    if (mmf.handle == NULL) {
        return false;
    }
    
    // create local buffer view of mmf
    mmf.rawBuffer = (uint8_t *) MapViewOfFile(mmf.handle,   // handle to map object
            FILE_MAP_ALL_ACCESS, // read/write permission
            0,
            0,
            bufferSize);

    if (mmf.rawBuffer == NULL) {
        CloseHandle(mmf.handle);
        mmf.handle = NULL;
        return false;
    }
    
    // Clear the buffer
    ZeroMemory(mmf.rawBuffer, bufferSize);
    
    // Pack buffer with objects using placement new (don't need to free as buffer freed)
    mmf.frameBuffer = new(mmf.rawBuffer) PSEyeFrameBuffer;
    int offset = sizeof(PSEyeFrameBuffer);
    PSEyeFrame *frame;
    for (int i = 1; i <= BUFFER_FRAMES; i++) {
        std::cout << "offset: " << offset << std::endl;
        frame = &(mmf.frameBuffer->frames[i - 1]);
        new(mmf.rawBuffer + offset) uint8_t[totalFrameSize];
        frame->dataOffset = offset;
        frame->size = frameSize;
        frame->_padding = padding;
        frame->next = (i == BUFFER_FRAMES ? 0 : i);
        offset += totalFrameSize;
    }
    
    mmf.frameBuffer->head = 0;
    mmf.frameBuffer->tail = 0;

    return true;
}

bool PSEyeServer::PSEyeCamera::deallocateMemoryFile() {
    std::cout << "deallocating memory." << std::endl;
    if (mmf.rawBuffer != NULL) {
        UnmapViewOfFile(mmf.rawBuffer);
        mmf.rawBuffer = NULL;
    }

    if (mmf.handle != NULL) {
        CloseHandle(mmf.handle);
        mmf.handle = NULL;
    }
    
    mmf.frameBuffer = NULL;
    return true;
}

bool PSEyeServer::PSEyeCamera::start() {
    if (mmf.frameBuffer == NULL) {
        return false;
    }
    if (!running) {
        std::cout << "Starting camera...";
        if (!CLEyeCameraStart(instance)) {
            return false;
        }
        // create event to stop thread
        hEvent = CreateEvent(
                 NULL,     // no security attributes
                 false,    // auto-reset event
                 false,    // initial state is non-signaled
                 NULL);    // lpName
        
        if (hEvent == NULL) {
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
        if (hThread == NULL) {
            CloseHandle(hEvent);
            hEvent = NULL;
            return false;
        }
        running = true;
        ResumeThread(hThread);
        std::cout << "Done." << std::endl;
    }
    return true;
}

bool PSEyeServer::PSEyeCamera::stop() {
    if (running) {
        std::cout << "Stopping camera...";
        running = false;
        SetEvent(hEvent);
        WaitForSingleObject(hThread, INFINITE);
        CloseHandle(hThread);
        CloseHandle(hEvent);
        hThread = NULL;
        hEvent = NULL;
        std::cout << "Done." << std::endl;
        return CLEyeCameraStop(instance);
    }
    return true;
}

void PSEyeServer::PSEyeCamera::runThread() {
    PSEyeFrame frame;
    bool run = true;
    while(run) {
        frame = mmf.frameBuffer->frames[mmf.frameBuffer->head];
        if (CLEyeCameraGetFrame(instance, (BYTE *) (mmf.rawBuffer + frame.dataOffset))) {
            if (frame.next != mmf.frameBuffer->tail) {
                mmf.frameBuffer->head = frame.next;
            }
        }
        // running check
        if (WaitForSingleObject(hEvent, 0) == WAIT_OBJECT_0) run = false;

    }
}

bool PSEyeServer::PSEyeCamera::create() {
    if (instance != NULL) {
        destroy();
    }
    
    if (frameSize != getFrameSize()) {
        allocateMemoryFile();
    }

    std::cout << "Creating camera...";
    
    instance = CLEyeCreateCamera(state.guid, 
            PSEyeServer::mapColourMode(state.colourMode), 
            PSEyeServer::mapResolution(state.resolution), 
            state.frameRate);

    if (instance != NULL) {
        std::cout << "Done." << std::endl << "Reading Parameters...";
        state.exposure.isAuto = CLEyeGetCameraParameter(instance, CLEYE_AUTO_GAIN);
        state.exposure.value = CLEyeGetCameraParameter(instance, CLEYE_GAIN);
        
        state.gain.isAuto = CLEyeGetCameraParameter(instance, CLEYE_AUTO_EXPOSURE);
        state.gain.value = CLEyeGetCameraParameter(instance, CLEYE_EXPOSURE);
    
        state.balance.isAuto = CLEyeGetCameraParameter(instance, CLEYE_AUTO_WHITEBALANCE);
        state.balance.red = CLEyeGetCameraParameter(instance, CLEYE_WHITEBALANCE_RED);
        state.balance.green = CLEyeGetCameraParameter(instance, CLEYE_WHITEBALANCE_GREEN);
        state.balance.blue = CLEyeGetCameraParameter(instance, CLEYE_WHITEBALANCE_BLUE);
        std::cout << "Done." << std::endl;    
        return true;
    }
    else {
        return false;
    }
}

bool PSEyeServer::PSEyeCamera::destroy() {
    std::cout << "Destroying camera...";
    if (instance != NULL) {
        if (!CLEyeDestroyCamera(instance)) {
            return false;
        }
        instance = NULL;
    }
    std::cout << "Done." << std::endl;
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

