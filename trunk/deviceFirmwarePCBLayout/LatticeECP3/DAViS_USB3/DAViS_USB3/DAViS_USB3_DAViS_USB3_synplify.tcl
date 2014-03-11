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
add_file -vhdl {C:/Lattice/Diamond3/diamond/3.0_x64/cae_library/synthesis/vhdl/ecp3.vhd}
add_file -vhdl -lib "work" {C:/3jAER/deviceFirmwarePCBLayout/LatticeECP3/DAViS_USB3/DAViS_USB3/source/synchronizerStateMachine.vhd}
add_file -vhdl -lib "work" {C:/3jAER/deviceFirmwarePCBLayout/LatticeECP3/DAViS_USB3/DAViS_USB3/source/USBAER_top_level.vhd}
add_file -vhdl -lib "work" {C:/3jAER/deviceFirmwarePCBLayout/LatticeECP3/DAViS_USB3/DAViS_USB3/source/ADCStateMachine.vhd}
add_file -vhdl -lib "work" {C:/3jAER/deviceFirmwarePCBLayout/LatticeECP3/DAViS_USB3/DAViS_USB3/source/AERfifo.vhd}
add_file -vhdl -lib "work" {C:/3jAER/deviceFirmwarePCBLayout/LatticeECP3/DAViS_USB3/DAViS_USB3/source/cDVSResetStateMachine.vhd}
add_file -vhdl -lib "work" {C:/3jAER/deviceFirmwarePCBLayout/LatticeECP3/DAViS_USB3/DAViS_USB3/source/clockgen.vhd}
add_file -vhdl -lib "work" {C:/3jAER/deviceFirmwarePCBLayout/LatticeECP3/DAViS_USB3/DAViS_USB3/source/earlyPaketTimer.vhd}
add_file -vhdl -lib "work" {C:/3jAER/deviceFirmwarePCBLayout/LatticeECP3/DAViS_USB3/DAViS_USB3/source/eventCounter.vhd}
add_file -vhdl -lib "work" {C:/3jAER/deviceFirmwarePCBLayout/LatticeECP3/DAViS_USB3/DAViS_USB3/source/fifoStatemachine.vhd}
add_file -vhdl -lib "work" {C:/3jAER/deviceFirmwarePCBLayout/LatticeECP3/DAViS_USB3/DAViS_USB3/source/monitorStateMachine.vhd}
add_file -vhdl -lib "work" {C:/3jAER/deviceFirmwarePCBLayout/LatticeECP3/DAViS_USB3/DAViS_USB3/source/timestampCounter.vhd}

#-- top module name
set_option -top_module timestampCounter

#-- set result format/file last
project -result_file {C:/3jAER/deviceFirmwarePCBLayout/LatticeECP3/DAViS_USB3/DAViS_USB3/DAViS_USB3_DAViS_USB3.edi}

#-- error message log file
project -log_file {DAViS_USB3_DAViS_USB3.srf}

#-- set any command lines input by customer


#-- run Synplify with 'arrange HDL file'
project -run hdl_info_gen -fileorder
project -run
