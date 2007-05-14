This is firmware for tmpdiff128 small cypress fx2lp retina pcb.


readme.txt for FX2_to_extsyncFIFO GPIF FIFO Transactions Auto mode
------------------------------------------------------------------

see GPIF Primer section on design examples for operating instructions
and details


To convert Keil output *.hex file to I2C eeprom dowloadable *.iic file
use Hex2bix.exe from command line with following switches:

 -i -R -F 0xc2 -O "output file name".iic "input file name".hex

Example: 
C:\Cypress\USB\Examples\FX2\fifo\hex2bix.exe -i -R -F 0xc2 -O FX2_to_extsyncFIFO.iic FX2_to_extsyncFIFO.hex

Here Hex2bix.exe is already copied from its default folder to the project 
folder C:\Cypress\USB\Examples\FX2\fifo\

Afterwards you can download the firmware file *.iic to I2C eeprom as follow:
First download the "eeprom loader" Vend_Ax.hex to Cypress using control panel 
DOWNLOAD... button.
Download firmware file *.iic to eeprom using control panel EEPROM... button 

