rem signing USB drivers for windows using stored iniLabs GmbH certificate

rem signing 32 bit driver

set root=..\driverServoController

set d=%root%\x32
del %d%\usbio.cat
Inf2Cat.exe /driver:%d% /os:XP_X86,Vista_X86,7_X86 /verbose
signtool sign /v /n "iniLabs GmbH" /ac MSCV-GlobalSign.cer /t http://timestamp.verisign.com/scripts/timestamp.dll %d%\usbio.cat

rem signing 64 bit driver

set d=%root%\x64
del %d%\usbio_x64.cat
Inf2Cat.exe /driver:%d% /os:XP_X86,Vista_X64,7_X64 /verbose
signtool sign /v /n "iniLabs GmbH" /ac MSCV-GlobalSign.cer /t http://timestamp.verisign.com/scripts/timestamp.dll %d%\usbio_x64.cat

pause