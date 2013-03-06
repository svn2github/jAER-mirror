setenv SIM_WORKING_FOLDER .
set newDesign 0
if {![file exists "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/SeeBetter30/SeeBetter30.adf"]} { 
	design create SeeBetter30 "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30"
  set newDesign 1
}
design open "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/SeeBetter30"
cd "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30"
designverincludedir -clear
designverlibrarysim -PL -clear
designverlibrarysim -L -clear
designverlibrarysim -PL pmi_work
designverlibrarysim ovi_machxo
designverdefinemacro -clear
if {$newDesign == 0} { 
  removefile -Y -D *
}
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/wordRegister.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/AERfifo.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/clockgen.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/earlyPaketTimer.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/EventBeforeOverflow.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/eventCounter.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/fifoStatemachine.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/monitorStateMachine.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/synchronizerStateMachine.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/timestampCounter.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/USBAER_top_level.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/ADCvalueReady.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/ADCStateMachine.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/cDVSResetStateMachine.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/shiftRegister.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/ADCStateMachine_tb.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/AERfifo.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/clockgen.vhd"
vlib "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/SeeBetter30/work"
set worklib work
adel -all
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/wordRegister.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/AERfifo.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/clockgen.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/earlyPaketTimer.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/EventBeforeOverflow.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/eventCounter.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/fifoStatemachine.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/monitorStateMachine.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/synchronizerStateMachine.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/timestampCounter.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/USBAER_top_level.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/ADCvalueReady.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/ADCStateMachine.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/cDVSResetStateMachine.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/shiftRegister.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/ADCStateMachine_tb.vhd"
vcom "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/AERfifo.vhd"
vcom "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/clockgen.vhd"
entity EventBeforeOverflow
