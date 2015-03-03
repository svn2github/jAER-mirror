@echo Converting SVF file to XSVF format ...

..\..\..\svf2xsvf\svf2xsvf502.exe -extensions -w -i SeeBetterLogic_FX2_DAVIS240c\SeeBetterLogic_FX2_DAVIS240c.svf -o SeeBetterLogic_FX2_DAVIS240c\SeeBetterLogic_FX2_DAVIS240c.xsvf

copy /Y SeeBetterLogic_FX2_DAVIS240c\SeeBetterLogic_FX2_DAVIS240c.xsvf ..\bin\SeeBetterLogic_FX2-DAVIS240c.xsvf
copy /Y SeeBetterLogic_FX2_DAVIS240c\SeeBetterLogic_FX2_DAVIS240c_SeeBetterLogic_FX2_DAVIS240c.jed ..\bin\SeeBetterLogic_FX2-DAVIS240c.jed
