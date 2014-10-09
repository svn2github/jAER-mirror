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
set_option -dup 1

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
set_option -include_path {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC}
add_file -verilog {C:/lscc/diamond/3.2_x64/cae_library/synthesis/verilog/pmi_def.v}
add_file -verilog {C:/lscc/diamond/3.2_x64/module/reveal/src/ertl/ertl.v}
add_file -verilog {C:/lscc/diamond/3.2_x64/module/reveal/src/rvl_j2w_module/rvl_j2w_module.v}
add_file -verilog {C:/lscc/diamond/3.2_x64/module/reveal/src/rvl_j2w_module/wb2sci.v}
add_file -verilog {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC/SeeBetterLogic_FX3/reveal_workspace/tmpreveal/toplevel_la0_trig_gen.v}
add_file -verilog {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC/SeeBetterLogic_FX3/reveal_workspace/tmpreveal/toplevel_la0_gen.v}
add_file -vhdl -lib "work" {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC/SeeBetterLogic_FX3/reveal_workspace/tmpreveal/TopLevel_rvl_top.vhd}

#-- top module name
set_option -top_module TopLevel

#-- set result format/file last
project -result_file {E:/JAER_SVN/devices/logic/LatticeECP3/SeeBetterLogic/FX3_OMC/SeeBetterLogic_FX3/SeeBetterLogic_FX3_SeeBetterLogic_FX3.edi}

#-- error message log file
project -log_file {SeeBetterLogic_FX3_SeeBetterLogic_FX3.srf}

#-- set any command lines input by customer


#-- run Synplify with 'arrange HDL file'
project -run hdl_info_gen -fileorder
project -run
