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
set_option -frequency 200
set_option -fanout_limit 100
set_option -auto_constrain_io true
set_option -disable_io_insertion false
set_option -retiming false; set_option -pipe false
set_option -force_gsr false
set_option -compiler_compatible true
set_option -dup false
set_option -frequency 1
set_option -default_enum_encoding default

#simulation options


#timing analysis options
set_option -num_critical_paths 3
set_option -num_startend_points 0

#automatic place and route (vendor) options
set_option -write_apr_constraint 0

#synplifyPro options
set_option -fixgatedclocks 3
set_option -fixgeneratedclocks 3
set_option -update_models_cp 0
set_option -resolve_multiple_driver 1

#-- add_file options
add_file -vhdl {E:/LatticeDiamond/diamond/2.0/cae_library/synthesis/vhdl/machxo.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/ADCStateMachineABC.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/ADCvalueReady.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/AERfifo.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/AERfifo.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/cDVSResetStateMachine.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/clockgen.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/clockgen.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/clockgen.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/earlyPaketTimer.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/EventBeforeOverflow.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/eventCounter.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/fifoStatemachine.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/monitorStateMachine.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/shiftRegister.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/synchronizerStateMachine.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/timestampCounter.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/USBAER_top_level.vhd}
add_file -vhdl -lib "work" {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/sourcecode/wordRegister.vhd}

#-- top module name
set_option -top_module USBAER_top_level

#-- set result format/file last
project -result_file {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/DigLog10/DigLog10/DigLog10_DigLog10.edi}

#-- error message log file
project -log_file {DigLog10_DigLog10.srf}

#-- set any command lines input by customer


#-- run Synplify with 'arrange HDL file'
project -run hdl_info_gen -fileorder
project -run
