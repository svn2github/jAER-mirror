

rem ******************** copy xsvf firmware download file to java package folder for integration into jar file

iMPACT -batch impact_commands.cmd

copy dvs128CPLD.xsvf ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\dvs128CPLD.xsvf
pause