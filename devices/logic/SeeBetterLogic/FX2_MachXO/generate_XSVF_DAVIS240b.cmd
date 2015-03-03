@echo Converting SVF file to XSVF format ...

..\..\..\svf2xsvf\svf2xsvf502.exe -extensions -w -i SeeBetterLogic_FX2_DAVIS240b\SeeBetterLogic_FX2_DAVIS240b.svf -o SeeBetterLogic_FX2_DAVIS240b\SeeBetterLogic_FX2_DAVIS240b.xsvf

copy /Y SeeBetterLogic_FX2_DAVIS240b\SeeBetterLogic_FX2_DAVIS240b.xsvf ..\bin\SeeBetterLogic_FX2-DAVIS240b.xsvf
copy /Y SeeBetterLogic_FX2_DAVIS240b\SeeBetterLogic_FX2_DAVIS240b_SeeBetterLogic_FX2_DAVIS240b.jed ..\bin\SeeBetterLogic_FX2-DAVIS240b.jed
