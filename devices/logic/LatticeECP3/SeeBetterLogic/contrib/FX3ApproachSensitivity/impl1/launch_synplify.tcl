#-- Lattice Semiconductor Corporation Ltd.
#-- Synplify OEM project file E:/code/devices/logic/LatticeECP3/SeeBetterLogic/contrib/FX3ApproachSensitivity/impl1/launch_synplify.tcl
#-- Written on Mon Feb 16 17:01:50 2015

project -close
set filename "E:/code/devices/logic/LatticeECP3/SeeBetterLogic/contrib/FX3ApproachSensitivity/impl1/impl1_syn.prj"
if ([file exists "$filename"]) {
	project -load "$filename"
	project_file -remove *
} else {
	project -new "$filename"
}
set create_new 0

#device options
set_option -technology LATTICE-ECP3
set_option -part LFE3_17EA
set_option -package FTN256C
set_option -speed_grade -6

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
add_file -vhdl "C:/lscc/diamond/3.4_x64/cae_library/synthesis/vhdl/ecp3.vhd"
add_file -vhdl -lib "work" "E:/code/devices/logic/LatticeECP3/SeeBetterLogic/contrib/FX3ApproachSensitivity/ApproachSensitivity/source/ApproachCellBudgeting.vhd"
project -result_file {E:/code/devices/logic/LatticeECP3/SeeBetterLogic/contrib/FX3ApproachSensitivity/impl1/impl1.edi}
project -save "$filename"
