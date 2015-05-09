@echo Converting SVF file to XSVF format ...

..\..\svf2xsvf\svf2xsvf502.exe -extensions -w -i SystemLogic2_MachXO_DAVIS240a\SystemLogic2_MachXO_DAVIS240a.svf -o SystemLogic2_MachXO_DAVIS240a\SystemLogic2_MachXO_DAVIS240a.xsvf

copy /Y SystemLogic2_MachXO_DAVIS240a\SystemLogic2_MachXO_DAVIS240a.xsvf ..\bin\MachXO_DAVIS\SystemLogic2_MachXO_DAVIS240a.xsvf
copy /Y SystemLogic2_MachXO_DAVIS240a\SystemLogic2_MachXO_DAVIS240a_SystemLogic2_MachXO_DAVIS240a.jed ..\bin\MachXO_DAVIS\SystemLogic2_MachXO_DAVIS240a.jed
