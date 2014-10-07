#-- Lattice Semiconductor Corporation Ltd.
#-- Synplify OEM project file C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/SBret10/launch_synplify.tcl
#-- Written on Fri May 16 10:59:10 2014

project -close
set filename "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/SBret10/SBret10_syn.prj"
if ([file exists "$filename"]) {
	project -load "$filename"
	project_file -remove *
} else {
	project -new "$filename"
}
set create_new 0

#device options
set_option -technology MACHXO
set_option -part LCMXO2280C
set_option -package FT256C
set_option -speed_grade -3

if {$create_new == 1} {
#-- add synthesis options
	set_option -symbolic_fsm_compiler true
	set_option -resource_sharing true
	set_option -vlog_std v2001
	set_option -frequency auto
	set_option -maxfan 1000
	set_option -auto_constrain_io 0
	set_option -disable_io_insertion false
	set_option -retiming false; set_option -pipe true
	set_option -force_gsr false
	set_option -compiler_compatible 0
	set_option -dup false
	
	set_option -default_enum_encoding default
	
	
	
	set_option -write_apr_constraint 1
	set_option -fix_gated_and_generated_clocks 1
	set_option -update_models_cp 0
	set_option -resolve_multiple_driver 0
	
	
}
#-- add_file options
add_file -vhdl "D:/lscc/diamond/2.2_x64/cae_library/synthesis/vhdl/machxo.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/wordRegister.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/AERfifo.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/clockgen.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/earlyPaketTimer.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/EventBeforeOverflow.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/eventCounter.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/fifoStatemachine.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/monitorStateMachine.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/synchronizerStateMachine.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/timestampCounter.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/USBAER_top_level.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/AERfifo.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/clockgen.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/ADCvalueReady.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/cDVSResetStateMachine.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/shiftRegister.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/ADCStateMachine_tb.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/ADCStateMachine.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/I2C_Arb_Blk.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/I2C_Clk_Blk.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/I2C_Cnt_Blk.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/I2C_delay.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/I2C_INT_Blk.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/I2C_Main_Blk.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/I2C_Mpu_Blk.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/I2C_SS_Blk.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/I2C_Synch_Blk.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/I2C_Top.vhd"
add_file -vhdl -lib "work" "C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/sourcecode/IMUStateMachine.vhd"
#-- top module name
set_option -top_module USBAER_top_level
project -result_file {C:/Users/Haza/Documents/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SBret10_2_IMU/SBret10/SBret10.edi}
project -save "$filename"
