@echo Converting SVF file to XSVF format ...

..\..\svf2xsvf\svf2xsvf502.exe -extensions -w -i StreamTester_MachXO\StreamTester_MachXO.svf -o StreamTester_MachXO\StreamTester_MachXO.xsvf

copy /Y StreamTester_MachXO\StreamTester_MachXO.xsvf ..\bin\StreamTester_MachXO.xsvf
copy /Y StreamTester_MachXO\StreamTester_MachXO_StreamTester_MachXO.jed ..\bin\StreamTester_MachXO.jed
