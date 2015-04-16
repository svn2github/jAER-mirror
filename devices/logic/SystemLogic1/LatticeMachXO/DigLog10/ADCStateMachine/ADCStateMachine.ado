setenv SIM_WORKING_FOLDER .
set newDesign 0
if {![file exists "E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine/ADCStateMachine.adf"]} { 
	design create ADCStateMachine "E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20"
  set newDesign 1
}
design open "E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine"
cd "E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20"
designverincludedir -clear
designverlibrarysim -PL -clear
designverlibrarysim -L -clear
designverlibrarysim -PL pmi_work
designverlibrarysim ovi_machxo
designverdefinemacro -clear
if {$newDesign == 0} { 
  removefile -Y -D *
}
addfile "E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCvalueReady.vhd"
addfile "E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCStateMachine.vhd"
addfile "E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine_tb.vhd"
vlib "E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine/work"
set worklib work
adel -all
vcom -work work "E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCvalueReady.vhd"
vcom -work work "E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCStateMachine.vhd"
vcom -work work "E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine_tb.vhd"
entity ADCStateMachine_tb
