#!/bin/sh

echo "Converting SVF file to XSVF format ..."

../../svf2xsvf/svf2xsvf502 -extensions -w -i SeeBetterLogic_FX2_MachXO_DAVIS240b/SeeBetterLogic_FX2_MachXO_DAVIS240b.svf -o SeeBetterLogic_FX2_MachXO_DAVIS240b/SeeBetterLogic_FX2_MachXO_DAVIS240b.xsvf

cp -f SeeBetterLogic_FX2_MachXO_DAVIS240b/SeeBetterLogic_FX2_MachXO_DAVIS240b.xsvf ../bin/SeeBetterLogic_FX2_MachXO-DAVIS240b.xsvf
cp -f SeeBetterLogic_FX2_MachXO_DAVIS240b/SeeBetterLogic_FX2_MachXO_DAVIS240b_SeeBetterLogic_FX2_MachXO_DAVIS240b.jed ../bin/SeeBetterLogic_FX2_MachXO-DAVIS240b.jed
