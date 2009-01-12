

rem ******************** copy xsvf firmware download file to java package folder for integration into jar file

iMPACT -batch impact_commands.cmd

copy USBAERmini2.xsvf ..\..\..\host\java\src\net\sf\jaer\hardwareinterface\usb\cypressfx2\USBAERmini2.xsvf

pause