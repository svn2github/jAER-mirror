@echo Converting SVF file to XSVF format ...

..\..\svf2xsvf\svf2xsvf502.exe -extensions -w -i StreamTester_FX2_MachXO\StreamTester_FX2_MachXO.svf -o StreamTester_FX2_MachXO\StreamTester_FX2_MachXO.xsvf

copy /Y StreamTester_FX2_MachXO\StreamTester_FX2_MachXO.xsvf ..\bin\StreamTester_FX2_MachXO.xsvf
copy /Y StreamTester_FX2_MachXO\StreamTester_FX2_MachXO_StreamTester_FX2_MachXO.jed ..\bin\StreamTester_FX2_MachXO.jed
