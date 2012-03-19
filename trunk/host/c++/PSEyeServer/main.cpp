/* 
 * File:   main.cpp
 * Author: mlk11
 *
 * Created on 29 December 2011, 12:24
 */

#include "src/server.h"

/*
 * 
 */
int main(int argc, char** argv) {
    
    std::cerr << "HERE" << std::endl;
    
    // no arguments passed so start in listen mode
    if (argc == 0) { 
        
        std::cout << "Started Server." << std::endl;
        PSEyeServer server = PSEyeServer();
        server.listen();
    }
    else {
        CLEyeCameraInstance camera = NULL;
        int result;
        int frames = 1000;
        int frame_size = 320*240;
        uint8_t *buffer = NULL;
        double ts;
        int exp;
        char filename[128];
    
        LARGE_INTEGER ticksPerSecond;
        LARGE_INTEGER stick;   // A point in time
        LARGE_INTEGER etick;   // A point in time 

        camera = CLEyeCreateCamera(
                CLEyeGetCameraUUID(0),
                CLEYE_BAYER_RAW, 
                CLEYE_QVGA, 
                125);
    
        if (camera == NULL) {
            std::cerr << "Unable to create camera" << std::endl;
            return -1;
        }
    
        CLEyeSetCameraParameter(camera, CLEYE_AUTO_GAIN, 0);
        result = CLEyeGetCameraParameter(camera, CLEYE_AUTO_GAIN);
        std::cout << "CLEYE_AUTO_GAIN set to " << result << std::endl;                  
        
        CLEyeSetCameraParameter(camera, CLEYE_AUTO_EXPOSURE, 0);
        result = CLEyeGetCameraParameter(camera, CLEYE_AUTO_EXPOSURE);
        std::cout << "CLEYE_AUTO_EXPOSURE set to " << result << std::endl;

        CLEyeSetCameraParameter(camera, CLEYE_EXPOSURE, 277);
        result = CLEyeGetCameraParameter(camera, CLEYE_EXPOSURE);
        std::cout << "CLEYE_EXPOSURE set to " << result << std::endl;           
        
        CLEyeSetCameraParameter(camera, CLEYE_AUTO_WHITEBALANCE, 0);
        result = CLEyeGetCameraParameter(camera, CLEYE_AUTO_WHITEBALANCE);
        std::cout << "CLEYE_AUTO_WHITEBALANCE set to " << result << std::endl;
        
        CLEyeSetCameraParameter(camera, CLEYE_WHITEBALANCE_RED, 255);
        result = CLEyeGetCameraParameter(camera, CLEYE_WHITEBALANCE_RED);
        std::cout << "CLEYE_WHITEBALANCE_RED set to " << result << std::endl;

        CLEyeSetCameraParameter(camera, CLEYE_WHITEBALANCE_GREEN, 255);
        result = CLEyeGetCameraParameter(camera, CLEYE_WHITEBALANCE_GREEN);
        std::cout << "CLEYE_WHITEBALANCE_GREEN set to " << result << std::endl;

        CLEyeSetCameraParameter(camera, CLEYE_WHITEBALANCE_BLUE, 255);
        result = CLEyeGetCameraParameter(camera, CLEYE_WHITEBALANCE_BLUE);
        std::cout << "CLEYE_WHITEBALANCE_BLUE set to " << result << std::endl;        
        
        for (exp = 0; exp < 80; exp+=5) {
            
        CLEyeSetCameraParameter(camera, CLEYE_GAIN, exp);
        result = CLEyeGetCameraParameter(camera, CLEYE_GAIN);
        std::cout << "CLEYE_GAIN set to " << result << std::endl;
            
            
        if (!CLEyeCameraStart(camera)) {
            std::cerr << "Unable to start camera" << std::endl;
            return -1;
        }
        
        sprintf(filename, "D:\\%i.txt", exp);
        
        HANDLE hFile = CreateFile(TEXT(filename), 
                GENERIC_READ | GENERIC_WRITE,
                0,
                NULL,
                CREATE_ALWAYS,
                FILE_ATTRIBUTE_NORMAL,
                NULL);

        if (hFile == INVALID_HANDLE_VALUE)
        {   
            std::cerr << "Could not open file" << std::endl;    
            return -1;
        }

        HANDLE hMapFile = CreateFileMapping(hFile, 
                NULL, 
                PAGE_READWRITE, 
                0, 
                frames * frame_size, 
                NULL);
        
        QueryPerformanceFrequency(&ticksPerSecond);
        QueryPerformanceCounter(&stick);
        
        ts = (double) (stick.QuadPart + 4 * ticksPerSecond.QuadPart);

        QueryPerformanceCounter(&etick);
        do {
            QueryPerformanceCounter(&etick);
            CLEyeCameraLED(camera, false);
        } while (etick.QuadPart < ts);

        buffer = (uint8_t *) MapViewOfFile(hMapFile, 
                FILE_MAP_ALL_ACCESS,
                0,
                0,
                frames * frame_size);        
        
        QueryPerformanceCounter(&stick);
        for (int i = 0; i < frames; i++) {
            while (!CLEyeCameraGetFrame(camera, &(buffer[i * frame_size]))) {
            }
            
        }
        QueryPerformanceCounter(&etick);
        
        std::cout << "FPS " << ((double) frames * ticksPerSecond.QuadPart / (etick.QuadPart - stick.QuadPart)) << std::endl;
        
        UnmapViewOfFile(buffer);
        CloseHandle(hMapFile);
        CloseHandle(hFile);        

        CLEyeCameraStop(camera);
        
        }
        
        CLEyeDestroyCamera(camera);        
    }
    
    
    return 0;
}

