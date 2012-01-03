/* 
 * File:   server.h
 * Author: mlk11
 *
 * Created on 29 December 2011, 13:35
 */

#ifndef SERVER_H
#define	SERVER_H

#include <windows.h>
#include<map>
#include "../include/PSEyeServer.h"
#include "../include/CLEyeMulticam.h"

class PSEyeServer {
   
   class PSEyeCamera {
       HANDLE hMmf;                 // handle to memory-mapped file
       uint8_t *pBuffer;            // pointer to mmf buffer
       PSEyeFrameBuffer *frameBuffer;
       HANDLE hThread;              // thread for getting frames
       
       PSEyeInstance instance;      // camera instance
       volatile bool running;       // flag used by thread
       
       // settings structure
       PSEyeState state;
       
       // create and destroy shared memory
       bool allocateSharedMemory();
       bool deallocateSharedMemory(); 
       
       int getFrameSize();
       
       // thread function
       void runThread();
       
       // thread entry point
       static DWORD WINAPI startThread(void * pThis)
       {
           PSEyeCamera *pseye = (PSEyeCamera *) pThis;
           pseye->runThread();
           return 1;          // the thread exit code
       }

   public:    
       PSEyeCamera();
       ~PSEyeCamera();
       
       bool create();
       bool destroy();
       
       bool start();
       bool stop();
       
       int setParameter();
       int getParameter();
   };
   
   // map of index to camera objects
   std::map<uint32_t, PSEyeCamera> cameras;   
   
   // pipe used for direct ipc 
   HANDLE hPipe;
   bool createPipe();
   bool destroyPipe(); 
   
   void answerRequest(PSEyeMessage * request);
   
public:
    PSEyeServer();
    ~PSEyeServer();
    
    bool run();
    static CLEyeCameraColorMode mapColourMode(PSEyeColourMode colourMode);
    static CLEyeCameraResolution mapResolution(PSEyeResolution resolution);
    static CLEyeCameraParameter mapParameter(PSEyeParameter parameter);
};

#endif	/* SERVER_H */

