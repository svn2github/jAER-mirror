/* 
 * File:   PSEyeServer.h
 * Author: mlk11
 *
 * Based on the fast IPC found here: http://www.codeproject.com/KB/threads/fast_ipc.aspx
 * but simplified for single consumer/producer model
 * 
 * Created on 27 December 2011, 17:38
 */

#pragma once

#ifndef PSEYE_SERVER_H
#define	PSEYE_SERVER_H

#include<windows.h>
#include<stdint.h>
#include "PSEyeConstants.h"

#define CACHE_LINE_SIZE 128
#define BUFFER_FRAMES 10

// name of memory-mapped file object to use for sharing frames
const char mmfBaseName[] = "Global\\MMFPSEyeBuffer";
// name of pipe to use for server control
const char ipcPipeName[] = "\\\\.\\pipe\\IPCPSEyePipe";

// Structure representing a frame of data, dynamically allocated
struct PSEyeFrame
{
    // Variables
    uint32_t next;                      // next frame in the circular linked list
    uint32_t size;                      // size of frame
    uint32_t _padding;                  // padding used to ensure cache line boundary
    
    uint32_t dataOffset;               // memory offset to data contained in this frame    
};

// Shared memory frame buffer that contains everything required to transmit
// frames between the consumer and producer
struct PSEyeFrameBuffer
{
    PSEyeFrame frames[BUFFER_FRAMES];   // array of frames that are used in the communication
        
    // Cursors
    volatile uint32_t head __attribute__ ((aligned (CACHE_LINE_SIZE)));             // write cursor
    uint8_t _padding1[CACHE_LINE_SIZE - sizeof(uint32_t)];
    volatile uint32_t tail __attribute__ ((aligned (CACHE_LINE_SIZE)));             // read cursor
    uint8_t _padding2[CACHE_LINE_SIZE - sizeof(uint32_t)];
};

/* Message structures */
enum PSEyeMessageType
{
    CAMERA_COUNT, CAMERA_GUID,
    CREATE_CAMERA, DESTROY_CAMERA,
    START_CAMERA, STOP_CAMERA,
    GET_PARAMETERS, SET_PARAMETERS
};

struct PSEyeExposure
{
    bool isAuto;
    int32_t value;
};

struct PSEyeGain
{
    bool isAuto;
    int32_t value;
};

struct PSEyeColourBalance
{
    bool isAuto;
    int32_t red;
    int32_t blue;
    int32_t green;
};

struct PSEyeState
{   
    uint8_t index;
    GUID guid;
       
    PSEyeColourMode colourMode;
    PSEyeResolution resolution;
    float frameRate;
    
    PSEyeExposure exposure;
    PSEyeGain gain;
    PSEyeColourBalance balance;
};

struct PSEyeMessage
{
    PSEyeMessageType type;
    PSEyeState state;
};
    

#endif	/* PSEYE_SERVER_H */

