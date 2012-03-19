/* 
 * File:   server.h
 * Author: mlk11
 *
 * Created on 29 December 2011, 13:35
 */

#ifndef SERVER_H
#define	SERVER_H

#include <windows.h>
#include<iostream>
#include<map>
#include "../include/PSEyeServer.h"
#include "../include/CLEyeMulticam.h"

class PSEyeServer {
   
   class PSEyeCamera {
       PSEyeMemoryMappedFile mmf;    
       uint32_t frameSize;
       HANDLE hEvent;               // handle for stopping thread
       HANDLE hThread;              // thread for getting frames
       
       PSEyeInstance instance;      // camera instance
       volatile bool running;       // flag used by thread
       
       // create and destroy shared memory
       bool allocateMemoryFile();
       bool deallocateMemoryFile(); 
       
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
       
       // settings structure
       PSEyeState state;
       
       bool create();
       bool destroy();
       
       bool start();
       bool stop();
       
       int setParameter();
       int getParameter();
   };
   
   // map of index to camera objects
   std::map<int32_t, PSEyeCamera> cameras;   
   
   // pipe used for direct ipc 
   HANDLE hPipe;
   bool createPipe();
   bool destroyPipe(); 
   void answerMessage(PSEyeMessage &message);
   
public:
    PSEyeServer();
    ~PSEyeServer();
    
    bool listen();
    bool createCamera(int32_t index, PSEyeColourMode colourMode, PSEyeResolution resolution, float frameRate);
    bool destroyCamera(int32_t index);
    
    bool startCamera(int32_t index);
    bool stopCamera(int32_t index);
    
    static CLEyeCameraColorMode mapColourMode(PSEyeColourMode colourMode);
    static CLEyeCameraResolution mapResolution(PSEyeResolution resolution);
    static CLEyeCameraParameter mapParameter(PSEyeParameter parameter);
};

#endif	/* SERVER_H */

