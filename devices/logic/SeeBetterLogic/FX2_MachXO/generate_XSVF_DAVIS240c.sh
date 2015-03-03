#!/bin/sh

echo "Converting SVF file to XSVF format ..."

../../svf2xsvf/svf2xsvf502 -extensions -w -i SeeBetterLogic_FX2_MachXO_DAVIS240c/SeeBetterLogic_FX2_MachXO_DAVIS240c.svf -o SeeBetterLogic_FX2_MachXO_DAVIS240c/SeeBetterLogic_FX2_MachXO_DAVIS240c.xsvf

cp -f SeeBetterLogic_FX2_MachXO_DAVIS240c/SeeBetterLogic_FX2_MachXO_DAVIS240c.xsvf ../bin/SeeBetterLogic_FX2_MachXO-DAVIS240c.xsvf
cp -f SeeBetterLogic_FX2_MachXO_DAVIS240c/SeeBetterLogic_FX2_MachXO_DAVIS240c_SeeBetterLogic_FX2_MachXO_DAVIS240c.jed ../bin/SeeBetterLogic_FX2_MachXO-DAVIS240c.jed
