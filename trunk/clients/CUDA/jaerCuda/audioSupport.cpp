#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <time.h>

#include <windows.h>

#include <mmsystem.h>

#include "config.h"

HWAVEOUT hWaveOut; /* device handle */
WAVEFORMATEX wfx; /* look this up in your documentation */
LPSTR block;/* pointer to the block */
DWORD blockSize;/* holds the size of the block */

LPSTR loadAudioBlock(const char* filename, DWORD* blockSize);
void writeAudioBlock(HWAVEOUT hWaveOut, LPSTR block, DWORD size);

////////////////////////////////////
// intialize wave player
/////////////////////////////////////
void waveInit()
{
	    
    //MMRESULT result;/* for waveOut return values */
    
    /*
    * first we need to set up the WAVEFORMATEX structure. 
    * the structure describes the format of the audio.
    */
    wfx.nSamplesPerSec = 44100; /* sample rate */
    wfx.wBitsPerSample = 16; /* sample size */
    wfx.nChannels = 2; /* channels*/
    /*
    * WAVEFORMATEX also has other fields which need filling.
    * as long as the three fields above are filled this should
    * work for any PCM (pulse code modulation) format.
    */
    wfx.cbSize = 0; /* size of _extra_ info */
    wfx.wFormatTag = WAVE_FORMAT_PCM;
    wfx.nBlockAlign = (wfx.wBitsPerSample >> 3) * wfx.nChannels;
    wfx.nAvgBytesPerSec = wfx.nBlockAlign * wfx.nSamplesPerSec;
    
    /*
    * try to open the default wave device. WAVE_MAPPER is
    * a constant defined in mmsystem.h, it always points to the
    * default wave device on the system (some people have 2 or
    * more sound cards).
    */
    if(waveOutOpen(
    &hWaveOut, 
    WAVE_MAPPER, 
    &wfx, 
    0, 
    0, 
    CALLBACK_NULL) != MMSYSERR_NOERROR) {
        fprintf(stderr, "unable to open WAVE_MAPPER device\n");
        ExitProcess(1);
    }

    /*
    * device is now open so print the success message
    * and then close the device again.
    */
    printf("The Wave Mapper device was opened successfully!\n");
    
	// we don't know where windows is installed (may not be c:) so determine it dynamically
	char path[256];
	GetWindowsDirectory(path,256);
	strcat(path,"\\Media\\ding.wav");
    if((block = loadAudioBlock(path, &blockSize)) == NULL) {
        fprintf(stderr, "Unable to load file %s\n", DING_SOUND);
        ExitProcess(1);
    }
    
    return;

}

void waveClose()
{
	waveOutClose(hWaveOut);
}


void writeAudioBlock(HWAVEOUT hWaveOut, LPSTR block, DWORD size)
{
    WAVEHDR header;
    /*
    * initialise the block header with the size
    * and pointer.
    */
    ZeroMemory(&header, sizeof(WAVEHDR));
    header.dwBufferLength = size;
    header.lpData = block;
    /*
    * prepare the block for playback
    */
    waveOutPrepareHeader(hWaveOut, &header, sizeof(WAVEHDR));
    /*
    * write the block to the device. waveOutWrite returns immediately
    * unless a synchronous driver is used (not often).
    */
    waveOutWrite(hWaveOut, &header, sizeof(WAVEHDR));
    /*
    * wait a while for the block to play then start trying
    * to unprepare the header. this will fail until the block has
    * played.
    */
    Sleep(500);
    while(waveOutUnprepareHeader(
    hWaveOut, 
    &header, 
    sizeof(WAVEHDR)
    ) == WAVERR_STILLPLAYING)
    Sleep(100);
}

LPSTR loadAudioBlock(const char* filename, DWORD* blockSize)
{
    HANDLE hFile= INVALID_HANDLE_VALUE;
    DWORD size = 0;
    DWORD readBytes = 0;
    void* block = NULL;
    /*
    * open the file
    */
    if((hFile = CreateFile(
    filename,
    GENERIC_READ,
    FILE_SHARE_READ,
    NULL,
    OPEN_EXISTING,
    0,
    NULL
    )) == INVALID_HANDLE_VALUE)
    return NULL;
    
    /*
    * get it's size, allocate memory and read the file
    * into memory. don't use this on large files!
    */
    do {
        if((size = GetFileSize(hFile, NULL)) == 0) 
        break;
        if((block = HeapAlloc(GetProcessHeap(), 0, size)) == NULL)
        break;
        ReadFile(hFile, block, size, &readBytes, NULL);
    } while(0);

    CloseHandle(hFile);
    *blockSize = size;
    return (LPSTR)block;
}

 void playAudio()
 {
	writeAudioBlock(hWaveOut, block, blockSize);
 }
