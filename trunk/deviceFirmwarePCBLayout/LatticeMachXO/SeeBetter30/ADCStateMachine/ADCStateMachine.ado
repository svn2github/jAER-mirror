setenv SIM_WORKING_FOLDER .
set newDesign 0
if {![file exists "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine/ADCStateMachine.adf"]} { 
	design create ADCStateMachine "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20"
  set newDesign 1
}
design open "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine"
cd "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20"
designverincludedir -clear
designverlibrarysim -PL -clear
designverlibrarysim -L -clear
designverlibrarysim -PL pmi_work
designverlibrarysim ovi_machxo
designverdefinemacro -clear
if {$newDesign == 0} { 
  removefile -Y -D *
}
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCvalueReady.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCStateMachine.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine_tb.vhd"
vlib "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine/work"
set worklib work
adel -all
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCvalueReady.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCStateMachine.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine_tb.vhd"
entity ADCStateMachine_tb
