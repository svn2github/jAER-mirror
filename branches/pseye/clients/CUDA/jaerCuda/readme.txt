CUDA-jAER Project
=================
Jayram Moorkanikara, Yingxue Wang, Tobi Delbruck

Important parameters ( Will be updated in the future with more details)
====================

1) This parameters is used to run the simulation in CUDA or Standard CPU.

#define  CUDA 1 ( or 0 )   -> template.cu

2) These parameters are useful to run the simulator in READBACK mode. Here you do not need a jAER interface but you can readback from pre-stored filtered spike information. The filename needed is filtered_spike.txt. One such file is preloaded in the repository

#define REPLAY_MODE			1    -> config.h

3) This parameters allows you to dump the filtered spike information into filtered_spike.txt file. We assume jaER is available now.

#define RECORD_MODE			1    -> config.h

4) DEBUGGING PURPOSE:
   =================
For debugging purpose use the following switches.

// it will generate a detailed membrance potential as a matlab file
#define RECORD_MEMBRANE_POTENTIAL	1
// total files will start from 0 to 99. One file is generated after every
// call to the CUDA kernel
#define	RECORD_START 0
#define RECORD_END   100

then use the matlab programs 'plotMem.m', 'plotMemMod.m' to visualize the input
spikes, and also the variation in the membrane potential after each kernel call.


Revision History
================

(1.0) First included in the repository with basic info about configuration


Below is email exchange mostly having to do with getting project running in VC2005


Figured it out: you need to add to project properties/linker/input "winmm.lib" (along with existing cudart.lib and cutil32D.lib).
i have no idea how you guys can build without doing this, since the project was checked in, do you know why it works for you?
tobi

-- from jay feb 4 2009 about the code

As a first step I will remove all code that corresponds to single spike kernel processing.

We will have kernels only of multiple spike type.

We will have three kernel
(1) Kernel for single object
(2) Kernel for multiple object
(3) A global inhibitory kernel

The overall logic is as follows:

GPU => contains the complete network for convolution

CPU => has the logic for inhibitory neuron. The reason is explained below.

The GPU sends the CPU the number of neurons that has fired recently.

The CPU uses that for simulating the inhibitory neuron.
Only if the inhibitory neuron fires we need to call the kernel for inhibition of all the excitatory neurons.
Calling kernels on GPU is sometimes expensive so by maintaining the inhibitory potential in CPU
we can avoid making expensive kernel calls in our case.
the code for inhibitory neuron on CPU can be found in cudaUpdateINeuron function.
When we have multiple objects, we instantiate one inhibitory neuron
for each object and the code is pretty similar and can be found in cudaUpdateINeuronMO.

Regarding your comments on
firingId - this is treated like a boolean but name suggests some neuron number
numFiring1Addr - what are these?
numFiring0Addr

This one was little bit outdated. 
I did this one to remove the memCpy call from the CPU to GPU for resetting the number of fired neurons.
Odd kernel calls, the GPU will use numFiring0Addr to store the number of fired neurons, and numFiring1Addr will be reset to 0.
Even kernel calls, the GPU will use numFiring1Addr to store the number of fired neurons, and numFiring0Addr will be reset to 0.
This way the CPU need not do an exclusive memCpy call reset the number of fired neurons.
I think this scheme is not elegant and confusing.
I have a simpler mechanism which I will implement and include in the next update of the source code.

struct params - the fields are mysterious. why is there only a single addrV?
I used this when implementing single spike kernel call. We dont need them for multiple spike kernel call.
I will remove it too.

we construct a grid of threads with dimensions (x,y,z)
x = number of neurons = 128 fixed
y = number of neurons = 128 fixed
z = number of objects to be scanned.
For singleObject (we scan/track only one Object at a time) objId = 0;
For multipleObject (we scan many Objects at a time) objId = z;


For Visual Studio, set for All configurations/Debugging/Environment

path=%NVSDKCUDA_ROOT%\common\lib;%NVSDKCUDA_ROOT%\bin\$(PlatformName)\$(ConfigurationName);%CUDA_BIN_PATH%;%PATH%;

otherwise you will get cudart.dll or cutil32.dll or cutil32D.dll missing warning when trying to run. The VC project is set up
to use the proper subdirectory of the CUDA SDK for debug/release configs.
 
CUDA_BIN_PATH=H:\CUDA\bin and NVSDKCUDA_ROOT=H:\Documents and Settings\All Users\Application Data\NVIDIA Corporation\NVIDIA CUDA SDK?'??A,

http://www.rapidee.com/en/download is a useful tool for windows environment variable editing.