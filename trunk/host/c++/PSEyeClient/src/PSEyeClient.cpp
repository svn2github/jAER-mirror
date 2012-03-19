
#include <windows.h>
#include<map>
#include<iostream>
#include "../include/PSEyeClient.h"
#include "../include/PSEyeServer.h"

HANDLE hPipe = INVALID_HANDLE_VALUE;
PSEyeMessage message;

std::map<int32_t, PSEyeMemoryMappedFile> sharedMemoryFiles;

void postMessage(PSEyeMessage &message);
void initMessage(PSEyeMessage &message);
HANDLE getPipe();
void deletePipe();

void initSharedMemory(int32_t index);
bool assignSharedMemory(int32_t index);
bool releaseSharedMemory(int32_t index);


/* methods for casting int to enum - verbose but safe */
PSEyeColourMode getColourMode(int value);
PSEyeResolution getResolution(int value);
PSEyeParameter getParameter(int value);

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeGetCameraCount
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeGetCameraCount
  (JNIEnv *env, jclass pseye)
{
    initMessage(message);
    message.type = CAMERA_COUNT;
    postMessage(message);
    return (jint) message.state.index;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeGetCameraUUID
 * Signature: (I)Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeGetCameraUUID
  (JNIEnv *env, jclass pseye, jint index) {
    char guidString[36];
    initMessage(message);
    message.type = CAMERA_GUID;
    message.state.index = index;
    postMessage(message);
    sprintf(guidString, "%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x",
            message.state.guid.Data1, message.state.guid.Data2, 
            message.state.guid.Data3, message.state.guid.Data4[0], 
            message.state.guid.Data4[1], message.state.guid.Data4[2], 
            message.state.guid.Data4[3], message.state.guid.Data4[4], 
            message.state.guid.Data4[5], message.state.guid.Data4[6], 
            message.state.guid.Data4[7]);
    // convert char array to java string
    return env->NewStringUTF(guidString);
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeCreateCamera
 * Signature: (IIIF)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeCreateCamera
  (JNIEnv *env, jclass pseye, jint index, jint mode, jint resolution, jfloat framerate)
{
    jboolean result = false;
    initMessage(message);
    initSharedMemory(index);
    releaseSharedMemory(index);
    
    std::cerr << "Creating camera." << std::endl;
    
    message.type = CREATE_CAMERA;
    message.state.index = index;   
    message.state.colourMode = getColourMode(mode);   
    message.state.resolution = getResolution(resolution);   
    message.state.frameRate = framerate;   
    postMessage(message);
    if (message.type != SERVER_ERROR) {
        std::cerr << "assigning memory." << std::endl;
        result = assignSharedMemory(index);
    }
    return result;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeDestroyCamera
 * Signature: (I)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeDestroyCamera
  (JNIEnv *env, jclass pseye, jint index)
{
    jboolean result = false;
    initMessage(message);
    message.type = DESTROY_CAMERA;
    message.state.index = index;   
    postMessage(message);
    if (message.type != SERVER_ERROR) {
        result = true;
    }
    return result;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeCameraStart
 * Signature: (I)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeCameraStart
  (JNIEnv *env, jclass pseye, jint index)
{
    jboolean result = false;
    initMessage(message);
    message.type = START_CAMERA;
    message.state.index = index;   
    postMessage(message);
    if (message.type != SERVER_ERROR) {
        result = true;
    }
    return result;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeCameraStop
 * Signature: (I)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeCameraStop
  (JNIEnv *env, jclass pseye, jint index)
{
    jboolean result = false;
    initMessage(message);
    message.type = STOP_CAMERA;
    message.state.index = index;   
    postMessage(message);
    if (message.type != SERVER_ERROR) {
        result = true;
    }
    return result;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeCameraLED
 * Signature: (IZ)Z
 */
/* NOT IMPLEMENTED YET
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeCameraLED
  (JNIEnv *env, jclass pseye, jint index, jboolean on)
{
    return (jboolean) true;
}
*/

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeSetCameraParameter
 * Signature: (III)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeSetCameraParameter
  (JNIEnv *env, jclass pseye, jint index, jint parameter, jint value)
{
    return (jboolean) true;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeGetCameraParameter
 * Signature: (II)I
 */
JNIEXPORT jint JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeGetCameraParameter
  (JNIEnv *env, jclass pseye, jint index, jint parameter)
{
    return (jint) 0;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeCameraGetFrameDimensions
 * Signature: (I[I)Z
 */
/* NOT IMPLEMENTED YET
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeCameraGetFrameDimensions
  (JNIEnv *env, jclass pseye, jint index, jintArray dimensions)
{
    return (jboolean) true;
}
 */ 

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeCameraGetFrame
 * Signature: (ILjava/nio/ByteBuffer;I)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeCameraGetFrame
  (JNIEnv *env, jclass pseye, jint index, jobject buffer)
{
    jboolean result = false;
    if (sharedMemoryFiles[index].frameBuffer != NULL) {
        // use pointer for neatness
        PSEyeMemoryMappedFile *smf = &sharedMemoryFiles[index];
        std::cerr << smf->frameBuffer->tail << std::endl;
        std::cerr << smf->frameBuffer->head << std::endl;
        if (smf->frameBuffer->tail != smf->frameBuffer->head) {
            PSEyeFrame frame = smf->frameBuffer->frames[smf->frameBuffer->tail];
            std::cerr << frame.dataOffset << std::endl;        
            //void * target = env->GetDirectBufferAddress(buffer);
            std::cerr << frame.dataOffset << std::endl;
            //memcpy(target, &(smf->rawBuffer[frame.dataOffset]), frame.size);
            smf->frameBuffer->tail = frame.next;
        }
    }
    return result;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeCameraFrameCount
 * Signature: (I)I
 */
JNIEXPORT jint JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeCameraFrameCount
  (JNIEnv *env, jclass pseye, jint index)
{
    jint result = 0;
    if (sharedMemoryFiles[index].frameBuffer != NULL) {
        // read local head and tail values
        uint32_t head = sharedMemoryFiles[index].frameBuffer->head;
        uint32_t tail = sharedMemoryFiles[index].frameBuffer->tail;
        result = head - tail;
        if (result < 0) {
            result += BUFFER_FRAMES;
        }
    }
    return result;
}

void postMessage(PSEyeMessage &message) {
    bool fSuccess = false;
    uint32_t bytesPosted;
    HANDLE hLocalPipe = getPipe();
    
    if (hLocalPipe == INVALID_HANDLE_VALUE) {
        message.type = SERVER_ERROR;
        return;
    }
    
    fSuccess = WriteFile(
            hLocalPipe,                  // pipe handle 
            &message,             // message 
            sizeof(PSEyeMessage), // message length 
            (DWORD*) &bytesPosted, // bytes written 
            NULL);                  // not overlapped 

    if (fSuccess) 
    {
        // Read from the pipe. 
        fSuccess = ReadFile( 
                hLocalPipe,    // pipe handle 
                &message,    // buffer to receive reply 
                sizeof(PSEyeMessage),  // size of buffer 
                (DWORD*) &bytesPosted,  // number of bytes read 
                NULL);    // not overlapped 
        if (!fSuccess) {
            message.type = SERVER_ERROR;
        }
    }
    else {
        message.type = SERVER_ERROR;
    }
}

void initMessage(PSEyeMessage &message) {
    message.type = SERVER_ERROR;
    message.state.index = 0;
    message.state.colourMode = IGNORE_MODE;
    message.state.resolution = IGNORE_RESOLUTION;
    message.state.frameRate = IGNORE_PARAMETER;
    
    message.state.exposure.isAuto = IGNORE_PARAMETER;
    message.state.exposure.value = IGNORE_PARAMETER;
    message.state.gain.isAuto = IGNORE_PARAMETER;
    message.state.gain.value = IGNORE_PARAMETER;
    message.state.balance.isAuto = IGNORE_PARAMETER;
    message.state.balance.red = IGNORE_PARAMETER;
    message.state.balance.green = IGNORE_PARAMETER;
    message.state.balance.blue = IGNORE_PARAMETER;
}

HANDLE getPipe() {
    if (hPipe == INVALID_HANDLE_VALUE) {
        hPipe = CreateFile( 
                ipcPipeName,   // pipe name 
                GENERIC_READ |  // read and write access 
                GENERIC_WRITE, 
                0,              // no sharing 
                NULL,           // default security attributes
                OPEN_EXISTING,  // opens existing pipe 
                0,              // default attributes 
                NULL);          // no template file
        if (hPipe != INVALID_HANDLE_VALUE) {
            bool fSuccess = false;
            DWORD dwMode = PIPE_READMODE_MESSAGE;
            fSuccess = SetNamedPipeHandleState( 
                    hPipe,    // pipe handle 
                    &dwMode,  // new pipe mode 
                    NULL,     // don't set maximum bytes 
                    NULL);    // don't set maximum time 
            if (!fSuccess) 
            {
                deletePipe();
            }
        }
    }
    
    return hPipe;
}

void deletePipe() {
    if (hPipe != INVALID_HANDLE_VALUE) {
        CloseHandle(hPipe);
        hPipe = INVALID_HANDLE_VALUE;
    }
}

PSEyeColourMode getColourMode(int value) 
{
    switch(value) {
        /* NOT IMPLEMENTED YET
        case 0: return MONO_PROCESSED;
        case 1: return COLOUR_PROCESSED;
         */
        case 2: return MONO_RAW;
        case 3: return COLOUR_RAW;
        case 4: return BAYER_RAW;
        default: return IGNORE_MODE;
    }
}

PSEyeResolution getResolution(int value)
{
    switch(value) {
        case 0: return QVGA;
        case 1: return VGA;
        default: return IGNORE_RESOLUTION;
    }
}

PSEyeParameter getParameter(int value)
{
    switch (value) {
        case 0: return AUTO_GAIN;
	case 1: return GAIN;
	case 2: return AUTO_EXPOSURE;
	case 3: return EXPOSURE;
	case 4: return AUTO_WHITEBALANCE;
	case 5: return WHITEBALANCE_RED;
	case 6: return WHITEBALANCE_GREEN;
	case 7: return WHITEBALANCE_BLUE;
        /* NOT IMPLEMENTED YET
	case 8: return CLEYE_HFLIP;
	case 9: return CLEYE_VFLIP;
	case 10: return CLEYE_HKEYSTONE;
	case 11: return CLEYE_VKEYSTONE;
	case 12: return CLEYE_XOFFSET;
	case 13: return CLEYE_YOFFSET;
	case 14: return CLEYE_ROTATION;
	case 15: return CLEYE_ZOOM;
	case 16: return CLEYE_LENSCORRECTION1;
	case 17: return CLEYE_LENSCORRECTION2;
	case 18: return CLEYE_LENSCORRECTION3;
	case 19: return CLEYE_LENSBRIGHTNESS;
         */
        default: return AUTO_GAIN;

    }
}

void initSharedMemory(int32_t index) {
    // create empty mmf if doesn't already exist
    if (sharedMemoryFiles.find(index) == sharedMemoryFiles.end()) {
        sharedMemoryFiles[index].index = index;
        sharedMemoryFiles[index].handle = NULL;
        sharedMemoryFiles[index].rawBuffer = NULL;
        sharedMemoryFiles[index].frameBuffer = NULL;
    }
}

bool assignSharedMemory(int32_t index) {
    releaseSharedMemory(index);
    
    // use pointer for neatness
    PSEyeMemoryMappedFile *smf = &sharedMemoryFiles[index];
   
    char mmfName[1024];
    sprintf(mmfName, "%s%i", mmfBaseName, index);
    
    smf->handle = OpenFileMapping(
            FILE_MAP_ALL_ACCESS,   // read/write access
            FALSE,                 // do not inherit the name
            mmfName);               // name of mapping object
    
    if (smf->handle == NULL) {
        return false;
    }
    
    smf->rawBuffer = (uint8_t *) MapViewOfFile(smf->handle, // handle to map object
            FILE_MAP_ALL_ACCESS,  // read/write permission
            0,
            0,
            0); // map whole file

    if (smf->rawBuffer == NULL)
    {
        CloseHandle(smf->handle);
        smf->handle = NULL;
        return false;
    }
    
    smf->frameBuffer = (PSEyeFrameBuffer *) smf->rawBuffer;
}

bool releaseSharedMemory(int32_t index) {
    if (sharedMemoryFiles[index].rawBuffer != NULL) {
        UnmapViewOfFile(sharedMemoryFiles[index].rawBuffer);        
        sharedMemoryFiles[index].rawBuffer = NULL;
    }
    
    if (sharedMemoryFiles[index].handle != NULL) {
        CloseHandle(sharedMemoryFiles[index].handle);        
        sharedMemoryFiles[index].handle = NULL;
    }
    
    sharedMemoryFiles[index].frameBuffer = NULL;
}

