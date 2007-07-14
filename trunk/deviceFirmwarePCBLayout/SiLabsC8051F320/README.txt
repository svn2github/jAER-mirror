This folder holds device and host side code AE monitor and biasgen controller
boards based on Silicon Labs (formerly Cygnal) C8051F320 microcontroller, which is
a single chip USB1 controller. 

This code enables monitoring address-events using this 
simple bus-powered board and capturing the AE's into matlab 
for display or analysis. 

It also allows for controlling an on-chip bias generator.

This code uses the Silicon Labs USBXPress device USB library 
and host driver. 

It consists of firmware (in folder SimpleMonitorBoardFirmware and BiasgenAEMonitorFirmware) 
as an SiLabs IDE project for the C8051F320 controller.

links:

http://www.silabs.com

SiLabs site that provides the USBXPress driver. This driver 
must be loaded prior to plugging in the USB device.
