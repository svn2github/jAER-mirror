@echo Converting SVF file to XSVF format ...

..\..\svf2xsvf\svf2xsvf502.exe -extensions -w -i SystemLogic2_MachXO_DAVIS240b\SystemLogic2_MachXO_DAVIS240b.svf -o SystemLogic2_MachXO_DAVIS240b\SystemLogic2_MachXO_DAVIS240b.xsvf

copy /Y SystemLogic2_MachXO_DAVIS240b\SystemLogic2_MachXO_DAVIS240b.xsvf ..\bin\MachXO_DAVIS\SystemLogic2_MachXO_DAVIS240b.xsvf
copy /Y SystemLogic2_MachXO_DAVIS240b\SystemLogic2_MachXO_DAVIS240b_SystemLogic2_MachXO_DAVIS240b.jed ..\bin\MachXO_DAVIS\SystemLogic2_MachXO_DAVIS240b.jed
