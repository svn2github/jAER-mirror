#!/bin/sh

echo "Converting SVF file to XSVF format ..."

../../../svf2xsvf/svf2xsvf502 -extensions -w -i SeeBetterLogic_FX2_DAVIS240a/SeeBetterLogic_FX2_DAVIS240a.svf -o SeeBetterLogic_FX2_DAVIS240a/SeeBetterLogic_FX2_DAVIS240a.xsvf

cp -f SeeBetterLogic_FX2_DAVIS240a/SeeBetterLogic_FX2_DAVIS240a.xsvf ../bin/SeeBetterLogic_FX2-DAVIS240a.xsvf
cp -f SeeBetterLogic_FX2_DAVIS240a/SeeBetterLogic_FX2_DAVIS240a_SeeBetterLogic_FX2_DAVIS240a.jed ../bin/SeeBetterLogic_FX2-DAVIS240a.jed
