#!/bin/sh

echo "Converting SVF file to XSVF format ..."

../../svf2xsvf/svf2xsvf502 -extensions -w -i SystemLogic2_MachXO_DAVIS240c/SystemLogic2_MachXO_DAVIS240c.svf -o SystemLogic2_MachXO_DAVIS240c/SystemLogic2_MachXO_DAVIS240c.xsvf

cp -f SystemLogic2_MachXO_DAVIS240c/SystemLogic2_MachXO_DAVIS240c.xsvf ../bin/MachXO_DAVIS/SystemLogic2_MachXO_DAVIS240c.xsvf
cp -f SystemLogic2_MachXO_DAVIS240c/SystemLogic2_MachXO_DAVIS240c_SystemLogic2_MachXO_DAVIS240c.jed ../bin/MachXO_DAVIS/SystemLogic2_MachXO_DAVIS240c.jed
