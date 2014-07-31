
*****************************************************************************
 eDVS 4337
*****************************************************************************


*****************************************************************************
Project setup to compile an image for the LPC4337-eDVS.

1. Download the LPCXpresso IDE http://www.lpcware.com/lpcxpresso/download
  and install. After the installation is complete, open the LPCXpresso and
  select an empty workspace. If LPCXpresso was already installed before,
  please create and switch to a new empty workspace using the option in the
  File menu, to avoid conflicts with peripherals drivers' library.

1a. You need to register the LPCXpresso IDE for it to work and activate,
  at least, the free edition.

2. Download https://bitbucket.org/rui_araujo/edvsboardos/downloads.

3. Open LPCXpresso, go to File -> Import. In the new window, select the
  option "Existing Projects into Workspace", and go to the next step.
  Select the ZIP archive file; click "Next".

4. Select all three projects and click "Finish".
a. EDVSBoardOS   - The M4 codebase
b. EDVSBoardOSM0 - The M0 code (for fetching events into a ring buffer)
c. lpc_chip_43xx - peripherals drivers' library for the LPC4337 (M0
                   just uses the headers)

5. Use "Project->Clean" to clean all (tick "Start a build immediately").
  Done.


Build the EDVSBoardOS project which will take care of building the rest.
The "final" executable is in "EDVSBoardOS/Release/EDVSBoard.bin" (for
release builds) or "EDVSBoardOS/Debug/EDVSBoard.bin" (for debug builds).


*****************************************************************************
Memory layout (SRAM)

The memory layout was designed with the constraint of leaving the biggest
continuous block of memory available. So there is a 48k (possibly 64k with
changed configurations) unused block, AHB SRAM.

The M0 core run the main loop from RAM (40k bank). It shares the same Flash
bank at start up which allows to disable the second Flash bank to save power
consumption.

There are several shared variables between the two cores. 
1. The UART reception and transmission ring buffer
2. The Events ring buffer
3. Flag that indicates to the M4 core that M0 has started running its main loop.

These shared variables are usually structs and the C standard assures us that
the compiler is not free to change the order of the declared elements so this
approach is safe as long as the variables are 32 bit aligned. Relying on
packing behaviour will lead to subtle bugs which are hard to debug.

The M4 core uses the rest of the RAM available in the 40k bank as its RAM.

The memory layout used leaves about 24k free in the 32k bank (although with the
SD card support enabled, this value drops to about 8k) and up to 64k in the AHB
SRAM.

*****************************************************************************
Exclusive Memory layout (SRAM + FLASH)

M0 Core
FLASH bank            location=0x1a040000 size=0x40000
RAM                   location=0x20000000 size=0x200

M4 Core
FLASH bank            location=0x1a000000 size=0x40000
RAM                   location=0x10086014 size=0x3fec


*****************************************************************************
Shared SRAM between both cores

EventsBuffer          location=0x10080000 size=0x8010
UartBuffer            location=0x10000000 size=0x2014
M0Start               location=0x1008840c size=0x4
