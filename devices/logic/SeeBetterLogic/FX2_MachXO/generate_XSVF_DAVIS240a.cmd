@echo Converting SVF file to XSVF format ...

..\..\..\svf2xsvf\svf2xsvf502.exe -extensions -w -i SeeBetterLogic_FX2_DAVIS240a\SeeBetterLogic_FX2_DAVIS240a.svf -o SeeBetterLogic_FX2_DAVIS240a\SeeBetterLogic_FX2_DAVIS240a.xsvf

copy /Y SeeBetterLogic_FX2_DAVIS240a\SeeBetterLogic_FX2_DAVIS240a.xsvf ..\bin\SeeBetterLogic_FX2-DAVIS240a.xsvf
copy /Y SeeBetterLogic_FX2_DAVIS240a\SeeBetterLogic_FX2_DAVIS240a_SeeBetterLogic_FX2_DAVIS240a.jed ..\bin\SeeBetterLogic_FX2-DAVIS240a.jed
