#include <stdio.h>
#include "NativeConvolutionTest.h"
/*
 * NativeConvolutionTest.cpp
 *
 *  Created on: Dec 17, 2012
 *      Author: Dennis
 */
//JNIEXPORT void JNICALL Java_ch_unizh_ini_jaer_projects_apsdvsfusion_NativeConvolutionTest_runNative
//  (JNIEnv *, jobject, jint, jint, jint, jobject)
JNIEXPORT void JNICALL Java_ch_unizh_ini_jaer_projects_apsdvsfusion_NativeConvolutionTest_runNative
  (JNIEnv * env, jobject, jint, jint, jint, jobject spikeHandler) {
	jclass icls = env->GetObjectClass(spikeHandler);
   /* Adresse der Methode "callback" des aufrufenden Java Objektes ermitteln: */
	printf("inside!");
    jmethodID jmid = (env)->GetMethodID(icls, "spike", "(II)V");
	if (jmid == 0) {    printf("jmid == NULL\n");     }
	   /* Methode "callback" des aufrufenden Java Objektes aufrufen: */
    (env)->CallVoidMethod(spikeHandler, jmid, 100,100);
}

/*
 * Class:     ch_unizh_ini_jaer_projects_apsdvsfusion_NativeConvolutionTest
 * Method:    initNativeSimpleClass
 * Signature: ()J
 */
JNIEXPORT jlong JNICALL Java_ch_unizh_ini_jaer_projects_apsdvsfusion_NativeConvolutionTest_initNativeSimpleClass
  (JNIEnv *, jobject) {
	printf("Ich kanns nicht glauben!\n");
}

/*
 * Class:     ch_unizh_ini_jaer_projects_apsdvsfusion_NativeConvolutionTest
 * Method:    destroyNativeSimpleClass
 * Signature: ()V
 */
JNIEXPORT void JNICALL Java_ch_unizh_ini_jaer_projects_apsdvsfusion_NativeConvolutionTest_destroyNativeSimpleClass
  (JNIEnv *, jobject) {

}




