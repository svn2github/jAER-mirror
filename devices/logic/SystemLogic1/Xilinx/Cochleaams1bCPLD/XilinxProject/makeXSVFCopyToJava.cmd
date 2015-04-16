

rem ******************** copy xsvf firmware download file to java package folder for integration into jar file

iMPACT -batch impact_commands.cmd

copy Cochleaams1bCPLD.xsvf ..\..\..\host\java\src\net\sf\jaer\hardwareinterface\usb\cypressfx2\Cochleaams1bCPLD.xsvf
pause