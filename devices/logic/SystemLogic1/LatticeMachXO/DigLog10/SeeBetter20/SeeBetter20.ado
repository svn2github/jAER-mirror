setenv SIM_WORKING_FOLDER .
set newDesign 0
if {![file exists "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/SeeBetter20/SeeBetter20.adf"]} { 
	design create SeeBetter20 "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20"
  set newDesign 1
}
design open "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/SeeBetter20"
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
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/wordRegister.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/AERfifo.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/clockgen.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/earlyPaketTimer.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/EventBeforeOverflow.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/eventCounter.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/fifoStatemachine.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/monitorStateMachine.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/synchronizerStateMachine.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/timestampCounter.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/USBAER_top_level.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCvalueReady.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCStateMachine.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/cDVSResetStateMachine.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/shiftRegister.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine_tb.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/AERfifo.vhd"
addfile "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/clockgen.vhd"
vlib "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/SeeBetter20/work"
set worklib work
adel -all
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/wordRegister.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/AERfifo.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/clockgen.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/earlyPaketTimer.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/EventBeforeOverflow.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/eventCounter.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/fifoStatemachine.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/monitorStateMachine.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/synchronizerStateMachine.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/timestampCounter.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/USBAER_top_level.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCvalueReady.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCStateMachine.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/cDVSResetStateMachine.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/shiftRegister.vhd"
vcom -work work "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine_tb.vhd"
vcom "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/AERfifo.vhd"
vcom "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/clockgen.vhd"
entity EventBeforeOverflow
