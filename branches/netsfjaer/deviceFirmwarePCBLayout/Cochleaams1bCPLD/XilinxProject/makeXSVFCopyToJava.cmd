

rem ******************** copy xsvf firmware download file to java package folder for integration into jar file

iMPACT -batch impact_commands.cmd

copy Cochleaams1bCPLD.xsvf ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\Cochleaams1bCPLD.xsvf
pause