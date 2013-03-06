#-- Lattice Semiconductor Corporation Ltd.
#-- Synplify OEM project file

#device options
set_option -technology MACHXO
set_option -part LCMXO2280C
set_option -package FT256C
set_option -speed_grade -3

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
add_file -vhdl {C:/Program Files (x86)/Lattice/diamond/2.1_x64/cae_library/synthesis/vhdl/machxo.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/wordRegister.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/AERfifo.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/clockgen.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/earlyPaketTimer.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/EventBeforeOverflow.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/eventCounter.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/fifoStatemachine.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/monitorStateMachine.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/synchronizerStateMachine.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/timestampCounter.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/USBAER_top_level.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/AERfifo.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/clockgen.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/ADCvalueReady.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/ADCStateMachine.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/cDVSResetStateMachine.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/shiftRegister.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/ADCStateMachine_tb.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/ADCStateMachineAB.vhd}
add_file -vhdl -lib "work" {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/ADCStateMachineABC.vhd}

#-- top module name
set_option -top_module USBAER_top_level

#-- set result format/file last
project -result_file {C:/Users/Minhao/Documents/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/SeeBetter30/SeeBetter30_SeeBetter30.edi}

#-- error message log file
project -log_file {SeeBetter30_SeeBetter30.srf}

#-- set any command lines input by customer


#-- run Synplify with 'arrange HDL file'
project -run hdl_info_gen -fileorder
project -run -clean
