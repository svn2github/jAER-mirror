setenv SIM_WORKING_FOLDER .
set newDesign 0
if {![file exists "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/test_tb/test_tb.adf"]} { 
	design create test_tb "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2"
  set newDesign 1
}
design open "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/test_tb"
cd "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2"
designverincludedir -clear
designverlibrarysim -PL -clear
designverlibrarysim -L -clear
designverlibrarysim -PL pmi_work
designverlibrarysim ovi_machxo
designverdefinemacro -clear
if {$newDesign == 0} { 
  removefile -Y -D *
}
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/EventBeforeOverflow.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/cDVSResetStateMachine.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/ADCvalueReady.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/ADCStateMachine.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/monitorStateMachine.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/fifoStatemachine.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/synchronizerStateMachine.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/timestampCounter.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/eventCounter.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/earlyPaketTimer.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/wordRegister.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/AERfifo.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/shiftRegister.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/clockgen.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/USBAER_top_level.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/ADCStateMachine_tb.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_delay.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_SS_Blk.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_INT_Blk.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Arb_Blk.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Cnt_Blk.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Clk_Blk.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Synch_Blk.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Main_Blk.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Mpu_Blk.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Top.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/AERfifo.vhd"
addfile "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/clockgen.vhd"
vlib "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/test_tb/work"
set worklib work
adel -all
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/EventBeforeOverflow.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/cDVSResetStateMachine.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/ADCvalueReady.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/ADCStateMachine.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/monitorStateMachine.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/fifoStatemachine.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/synchronizerStateMachine.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/timestampCounter.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/eventCounter.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/earlyPaketTimer.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/wordRegister.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/AERfifo.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/shiftRegister.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/clockgen.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/USBAER_top_level.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/ADCStateMachine_tb.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_delay.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_SS_Blk.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_INT_Blk.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Arb_Blk.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Cnt_Blk.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Clk_Blk.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Synch_Blk.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Main_Blk.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Mpu_Blk.vhd"
vcom -dbg -work work "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/D:/Dropbox/IMU/I2C Bus Master - Downloads/i2cmastercontrollersourcecodeformachxo/I2C_xo/I2C_xo/I2C_Master/Source/I2C_Top.vhd"
vcom -dbg "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/AERfifo.vhd"
vcom -dbg "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2/sourcecode/clockgen.vhd"
entity USBAER_top_level
vsim +access +r USBAER_top_level   -PL pmi_work -L ovi_machxo
add wave *
run 1000ns
