setenv SIM_WORKING_FOLDER .
set newDesign 0
if {![file exists "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sbret10adcStateMachine/sbret10adcStateMachine.adf"]} { 
	design create sbret10adcStateMachine "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10"
  set newDesign 1
}
design open "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sbret10adcStateMachine"
cd "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10"
designverincludedir -clear
designverlibrarysim -PL -clear
designverlibrarysim -L -clear
designverlibrarysim -PL pmi_work
designverlibrarysim ovi_machxo
designverdefinemacro -clear
if {$newDesign == 0} { 
  removefile -Y -D *
}
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/wordRegister.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/AERfifo.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/clockgen.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/earlyPaketTimer.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/EventBeforeOverflow.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/eventCounter.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/fifoStatemachine.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/monitorStateMachine.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/synchronizerStateMachine.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/timestampCounter.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/USBAER_top_level.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/ADCvalueReady.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/cDVSResetStateMachine.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/shiftRegister.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/ADCStateMachine_tb.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/ADCStateMachine.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/AERfifo.vhd"
addfile "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/clockgen.vhd"
vlib "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sbret10adcStateMachine/work"
set worklib work
adel -all
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/wordRegister.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/AERfifo.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/clockgen.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/earlyPaketTimer.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/EventBeforeOverflow.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/eventCounter.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/fifoStatemachine.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/monitorStateMachine.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/synchronizerStateMachine.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/timestampCounter.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/USBAER_top_level.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/ADCvalueReady.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/cDVSResetStateMachine.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/shiftRegister.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/ADCStateMachine_tb.vhd"
vcom -work work "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/ADCStateMachine.vhd"
vcom "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/AERfifo.vhd"
vcom "C:/PROJ/jAER/trunk/deviceFirmwarePCBLayout/LatticeMachXO/SBret10/sourcecode/clockgen.vhd"
entity ADCStateMachine_tb
