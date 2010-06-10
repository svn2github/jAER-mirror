rem signing USB drivers for windows using stored iniLabs GmbH certificate

rem signing 32 bit driver

set r=..\driverDVS128AndOthersSigned\

set d=..\driverDVS128AndOthersSigned\x32
Inf2Cat.exe /driver:%d% /os:XP_X86,Vista_X86,7_X86 /verbose
signtool sign /v /n "iniLabs GmbH" /ac MSCV-GlobalSign.cer /t http://timestamp.verisign.com/scripts/timestamp.dll %d%\usb2aemon.cat

rem signing 64 bit driver

set d=..\driverDVS128AndOthersSigned\x64
Inf2Cat.exe /driver:%d% /os:XP_X86,Vista_X86,7_X86 /verbose
signtool sign /v /n "iniLabs GmbH" /ac MSCV-GlobalSign.cer /t http://timestamp.verisign.com/scripts/timestamp.dll %d%\usb2aemon.cat

