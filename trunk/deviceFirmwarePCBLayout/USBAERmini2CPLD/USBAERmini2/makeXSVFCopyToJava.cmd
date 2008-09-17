

rem ******************** copy xsvf firmware download file to java package folder for integration into jar file

iMPACT -batch impact_commands.cmd

copy USBAER_top_level.xsvf ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\USBAER_top_level.xsvf

pause