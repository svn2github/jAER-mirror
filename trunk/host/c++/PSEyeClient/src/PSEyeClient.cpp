
#include <windows.h> 
#include "../include/PSEyeClient.h"
#include "../include/PSEyeServer.h"

HANDLE hPipe = INVALID_HANDLE_VALUE;

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
        if (hPipe == INVALID_HANDLE_VALUE) {
            return INVALID_HANDLE_VALUE;
        } 
        bool fSuccess = false;
        fSuccess = SetNamedPipeHandleState( 
                hPipe,    // pipe handle 
                PIPE_READMODE_MESSAGE,  // new pipe mode 
                NULL,     // don't set maximum bytes 
                NULL);    // don't set maximum time 
        if (!fSuccess) 
        {
            CloseHandle(hPipe);
            hPipe = INVALID_HANDLE_VALUE;
            return INVALID_HANDLE_VALUE;
        }
    }
    
    return hPipe;
}


/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeGetCameraCount
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeGetCameraCount
  (JNIEnv *env, jclass pseye)
{
    
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeGetCameraUUID
 * Signature: (I)Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeGetCameraUUID
  (JNIEnv *env, jclass pseye, jint index);

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeCreateCamera
 * Signature: (IIIF)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeCreateCamera
  (JNIEnv *env, jclass pseye, jint index, jint, jint, jfloat)
{
    return true;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeDestroyCamera
 * Signature: (I)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeDestroyCamera
  (JNIEnv *env, jclass pseye, jint index)
{
    return true;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeCameraStart
 * Signature: (I)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeCameraStart
  (JNIEnv *env, jclass pseye, jint index)
{
    return true;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeCameraStop
 * Signature: (I)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeCameraStop
  (JNIEnv *env, jclass pseye, jint index)
{
    return true;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeCameraLED
 * Signature: (IZ)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeCameraLED
  (JNIEnv *env, jclass pseye, jint index, jboolean on)
{
    return true;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeSetCameraParameter
 * Signature: (III)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeSetCameraParameter
  (JNIEnv *env, jclass pseye, jint index, jint parameter, jint value)
{
    return true;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeGetCameraParameter
 * Signature: (II)I
 */
JNIEXPORT jint JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeGetCameraParameter
  (JNIEnv *env, jclass pseye, jint index, jint parameter)
{
    return 0;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeCameraGetFrameDimensions
 * Signature: (I[I)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeCameraGetFrameDimensions
  (JNIEnv *env, jclass pseye, jint index, jintArray dimensions)
{
    return true;
}

/*
 * Class:     uk_ac_imperial_pseye_PSEyeCamera
 * Method:    PSEyeCameraGetFrame
 * Signature: (ILjava/nio/ByteBuffer;I)Z
 */
JNIEXPORT jboolean JNICALL Java_uk_ac_imperial_pseye_PSEyeCamera_PSEyeCameraGetFrame
  (JNIEnv *env, jclass pseye, jint index, jobject, jint)
{
    return true;
}