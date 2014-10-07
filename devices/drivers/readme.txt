Holds USB drivers for jAER devices.

To install the driver

1. plug in the device.
2. when Windows asks whether you want to search for a driver, answer No.
3. Choose to install from a specific location.
4. Navigate to select the appropriate device driver folder and the driver should install, if the 
   device USB VID/PID match the ones in the folders .inf file. 

DVS128 or Tmpdiff128: navigate to folder driverUSBIO_Tmpdiff128_USBAERmini2

A blank CypressFX2 has VID=0x04b4 PID=0x8613

----------------------------------------------
USB VID/PID assignments for jAER
----------------------------------------------

The USB VID/PIDs licensed from Thesycon for use in jAER are documented in ../doc/USBIO_VID_PID_Assignments_Neuroinformatik.pdf.
The Thesycon VID=0x152a and the range of PIDs is from 0x8400 to 0x841F, a total of 32 PIDs.

The current assignements are as follows for the Thesycon PIDs

0x8400 DVS128
0x8401 DVS320
0x8402  
0x8403 
0x8404 
0x8405 CochleaAMS1b
0x8406 CochleaAMS1c
0x8407 
0x8408 
0x8409 
0x840A cDVSTest
0x840B SeeBetter
0x840C SeeBetter20
0x840D SBret10
0x840E 
0x840F 

0x8410 SimpleAESequencer
0x8411 DVS128_PAER
0x8412 
0x8413 
0x8414 
0x8415 
0x8416 
0x8417 
0x8418 
0x8419 Retina Teresa (provisorial)
0x841A DAViS FX3 boards, SeeBetterLogic
0x841B DAViS FX2 boards, SeeBetterLogic
0x841C DVS128 FX2 boards, SeeBetterLogic
0x841D 
0x841E 
0x841F 



The assignments of VID/PID actually used are scattered over the .inf files in different driver folders. A search 12.5.2009 showed 
the preceeding. 

Some of the devices predate the licensing and use either the Cypress blank VID 0x04B4 or the SiLabs VID 0x0547.
The Thesycon VID 0x152a is used for more recent devices.


----------------------------------------
Find 'Pid_' in 'H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverCarServoController\usbio.inf':
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverCarServoController\usbio.inf(92): %S_DeviceDesc%=_Install, USB\Vid_0547&Pid_8751
Found 'Pid_' 1 time(s).
----------------------------------------
Find 'Pid_' in 'H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverOpticalFlowChipUSBWinXP\optflowusb.inf':
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverOpticalFlowChipUSBWinXP\optflowusb.inf(92): %S_DeviceDesc%=_Install, USB\Vid_0547&Pid_8760&Rev_0000
Found 'Pid_' 1 time(s).
----------------------------------------
Find 'Pid_' in 'H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverServoController\usbio.inf':
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverServoController\usbio.inf(92): %S_DeviceDesc%=_Install, USB\Vid_0547&Pid_8750
Found 'Pid_' 1 time(s).
----------------------------------------
Find 'Pid_' in 'H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon.inf':
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon.inf(95): %S_DeviceDescBlank%=_Install, USB\Vid_04B4&Pid_8613
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon.inf(96): %S_DeviceDescRetina%=_Install, USB\Vid_0547&Pid_8700
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon.inf(97): %S_DeviceDescRetinaCPLD%=_Install, USB\Vid_0547&Pid_8701
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon.inf(98): %S_DeviceDescUSBAERmini2%=_Install, USB\Vid_0547&Pid_8801
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon.inf(99): %S_DeviceDescMapper%=_Install, USB\Vid_0547&Pid_8900
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon.inf(100): %S_DeviceDescTCVS320%=_Install, USB\Vid_0547&Pid_8702
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon.inf(101): %S_DeviceDescStereoTmpdiff128%=_Install, USB\Vid_0547&Pid_8703
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon.inf(102): %S_DeviceDescDVS128%=_Install, USB\Vid_152A&Pid_8400
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon.inf(103): %S_DeviceDescDVS320%=_Install, USB\Vid_152A&Pid_8401
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon.inf(104): %S_DeviceDescCochleaAMS%=_Install, USB\Vid_152A&Pid_8405
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon.inf(106): %S_DeviceDescSimpleAESequencer%=_Install, USB\Vid_152A&Pid_8410
Found 'Pid_' 11 time(s).
----------------------------------------
Find 'Pid_' in 'H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon_x64.inf':
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon_x64.inf(90): %S_DeviceDescRetina%=_Install, USB\Vid_0547&Pid_8700
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon_x64.inf(91): %S_DeviceDesc%=_Install, USB\Vid_0547&Pid_8801
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon_x64.inf(92): %S_DeviceDescMapper%=_Install, USB\Vid_0547&Pid_8900
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon_x64.inf(93): %S_DeviceDescBlank%=_Install, USB\Vid_04B4&Pid_8613
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon_x64.inf(94): %S_DeviceDescStereoTmpdiff128%=_Install, USB\Vid_0547&Pid_8703
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driverUSBIO_Tmpdiff128_USBAERmini2\usb2aemon_x64.inf(95): %S_DeviceDescDVS128%=_Install, USB\Vid_152A&Pid_8400
Found 'Pid_' 6 time(s).
----------------------------------------
Find 'Pid_' in 'H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driver_ToradexAccelerometer\usbio.inf':
H:\Documents and Settings\thkoch\My Documents\~jaer-all\trunk\drivers\driver_ToradexAccelerometer\usbio.inf(92): %S_DeviceDesc%=_Install, USB\Vid_1b67&Pid_000a&Rev_0100
Found 'Pid_' 1 time(s).
Search complete, found 'Pid_' 21 time(s). (6 file(s)).



