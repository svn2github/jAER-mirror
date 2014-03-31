#-- Lattice Semiconductor Corporation Ltd.
#-- Synplify OEM project file

#device options
set_option -technology LATTICE-ECP3
set_option -part LFE3_17EA
set_option -package FTN256I
set_option -speed_grade -7

#compilation/mapping options
set_option -symbolic_fsm_compiler true
set_option -resource_sharing true

#use verilog 2001 standard option
set_option -vlog_std v2001

#map options
set_option -frequency auto
set_option -maxfan 1000
set_option -auto_constrain_io 0
set_option -disable_io_insertion false
set_option -retiming false; set_option -pipe true
set_option -force_gsr false
set_option -compiler_compatible 0
set_option -dup false

set_option -default_enum_encoding default

#simulation options


#timing analysis options



#automatic place and route (vendor) options
set_option -write_apr_constraint 1

#synplifyPro options
set_option -fix_gated_and_generated_clocks 1
set_option -update_models_cp 0
set_option -resolve_multiple_driver 0


#-- add_file options
add_file -vhdl {C:/lscc/diamond/3.0_x64/cae_library/synthesis/vhdl/ecp3.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/wordRegister.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/AERfifo.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/clockgen.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/earlyPaketTimer.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/EventBeforeOverflow.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/eventCounter.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/fifoStatemachine.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/monitorStateMachine.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/synchronizerStateMachine.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/timestampCounter.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/USBAER_top_level.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/ADCvalueReady.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/cDVSResetStateMachine.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/shiftRegister.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/sourcecode/ADCStateMachine.vhd}
add_file -vhdl -lib "work" {C:/lscc/diamond/3.0_x64/cae_library/synthesis/vhdl/pmi_def.vhd}

#-- top module name
set_option -top_module USBAER_top_level

#-- set result format/file last
project -result_file {E:/JAER_SVN/trunk/deviceFirmwarePCBLayout/LatticeECP3/SBret20/SBret20/SBret20_SBret20.edi}

#-- error message log file
project -log_file {SBret20_SBret20.srf}

#-- set any command lines input by customer


#-- run Synplify with 'arrange HDL file'
project -run hdl_info_gen -fileorder
project -run
