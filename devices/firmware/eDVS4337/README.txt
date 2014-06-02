This document aims to describe the general setup of the projects needed to compile an image for the eDVS board with the LPC4337.

Basic steps to get the project compiling:
1. Download the LPCXpresso IDE from http://www.lpcware.com/lpcxpresso/download and install it. After the installation is completed, open the LPCXpresso IDE and select an empty workspace. If LPCXpresso was already installed beforehand, please switch to a new empty workspace using the option in the File menu to avoid conflicts with the peripherals drivers' library.
2. Download the latest eDVS firmware code from https://svn.code.sf.net/p/jaer/code/devices/firmware/eDVS4337/ using Subversion.
3. Open LPCXpresso and go to File -> Import. In the new window, select the option "Existing Projects into Workspace", and go to the next step. Depending on whether you're using a zip archive or the latest SVN version, select the archive file or the root directory. There should be four projects which can be imported: 
	a. EDVSBoardOS - The M4 codebase
	b. EDVSBoardOSM0 - The M0 code where the events are fetched and put into a buffer
	c. CMSISv2p10_LPC43xx_DriverLib - peripherals drivers' library for the M4
	d. CMSISv2p10_LPC43xx_DriverLib-M0 - peripherals drivers' library for the M0
4. Build the EDVSBoardOS project which will take care of building the rest.

Memory layout:
The M0 core has its RAM on the 40k memory bank which starts at 0x10080000. The shared variables between both cores are also stored in this memory bank.
The 32k memory bank starting at 0x10000000 is reserved for the M4 core.

M0 Core
Flash bank location=0x1b000000 size=0x80000
Ram location=0x1008600c size=0x3ff4

M4 Core
Flash bank location=0x1a000000 size=0x80000
Ram location=0x10000000 size=0x8000

The same between both cores
BufferWritePointer location=0x10080000 size=0x4
BufferReadPointer location=0x10080004 size=0x4 
EventRate location=0x10080008 size=0x4 
EventsBuffer location=0x1008000c size=0x2000
TimeStampsBuffer location=0x1008200c size=0x4000
