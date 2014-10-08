this folder holds firmware for true streaming of monoitored AER data using the SimpleMonitorBoard. 
It improves on the previous code by directly writing the USB FIFOs but it still uses the host side USBXPress drivers.

It also includes a special sync bit capability that allows connecting an external sync that gets sent as a special address.
Tobi 2009. Copied from streamingSimpleMonitorFirmware.

Developed Telluride 2007.

This folder holds device and host side code AE monitor and biasgen controller
boards based on Silicon Labs (formerly Cygnal) C8051F320 microcontroller, which is
a single chip USB1 controller. 

This code enables monitoring address-events using this 
simple bus-powered board and capturing the AE's into matlab 
for display or analysis. 

It also allows for controlling an on-chip bias generator.

Some of this code uses the Silicon Labs USBXPress device USB library 
and host driver. The more recent implementations use the Thesycon USBIO driver. 

It consists of firmware (in folder SimpleMonitorBoardFirmware and BiasgenAEMonitorFirmware) 
as an SiLabs IDE project for the C8051F320 controller.

links:

http://www.silabs.com
http://www.thesycon.de
