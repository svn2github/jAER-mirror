#-- Lattice Semiconductor Corporation Ltd.
#-- Synplify OEM project file

#device options
set_option -technology LATTICE-ECP3
set_option -part LFE3_70E
set_option -package FN484I
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
set_option -vhdl2008 1

#-- add_file options
add_file -vhdl {C:/lscc/diamond/3.2_x64/cae_library/synthesis/vhdl/ecp3.vhd}
add_file -vhdl -lib "work" {C:/lscc/diamond/3.2_x64/cae_library/synthesis/vhdl/pmi_def.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/ext/FIFORecords.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/ext/FIFODualClock.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/ext/FIFO.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/ext/PLL.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/support/ChangeDetector.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/support/DFFSynchronizer.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/support/ResetSynchronizer.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/support/SimpleRegister.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/support/BufferClear.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/support/ContinuousCounter.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/support/ShiftRegister.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/support/ShiftRegisterModes.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/support/EdgeDetector.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/support/PulseGenerator.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/support/PulseDetector.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/private-source/TopLevel.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/private-source/Settings.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/private-source/LogicClockSynchronizer.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/fx3/FX3USBClockSynchronizer.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/fx3/FX3StateMachine.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/MultiplexerStateMachine.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/MultiplexerConfigRecords.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/MultiplexerSPIConfig.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/TimestampGenerator.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/DVSAERStateMachine.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/DVSAERConfigRecords.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/DVSAERSPIConfig.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/APSADCStateMachine.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/APSADCConfigRecords.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/APSADCSPIConfig.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/IMUStateMachine.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/IMUConfigRecords.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/IMUSPIConfig.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/EventCodes.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/ExtTriggerSPIConfig.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/ExtTriggerConfigRecords.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/ExtTriggerStateMachine.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/SPIConfig.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/ChipBiasConfigRecords.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/ChipBiasStateMachine.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/ChipBiasSPIConfig.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/private-source/WSAER2CAVIAR2.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/private-source/CAVIAR2WSAER.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/private-source/latch3.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/support/FifoMerger.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/MullerCelement.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/ObjectMotionCell.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/ObjectMotionCell_tb.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/ObjectMotionCellConfigRecords.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/ObjectMotionCellSPIConfig.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/fx3/FX3ConfigRecords.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/../common-source/fx3/FX3SPIConfig.vhd}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/private-source/MISCAERStateMachine.vhd}

#-- top module name
set_option -top_module TopLevel

#-- set result format/file last
project -result_file {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC - Pipelined/SeeBetterLogic_FX3/SeeBetterLogic_FX3_SeeBetterLogic_FX3.edi}

#-- error message log file
project -log_file {SeeBetterLogic_FX3_SeeBetterLogic_FX3.srf}

#-- set any command lines input by customer


#-- run Synplify with 'arrange HDL file'
project -run hdl_info_gen -fileorder
project -run
