setenv SIM_WORKING_FOLDER .
set newDesign 0
if {![file exists "E:/FX3/ApproachSensitivity/ApproachSensitivity.adf"]} { 
	design create ApproachSensitivity "E:/FX3"
  set newDesign 1
}
design open "E:/FX3/ApproachSensitivity"
cd "E:/FX3"
designverincludedir -clear
designverlibrarysim -PL -clear
designverlibrarysim -L -clear
designverlibrarysim -PL pmi_work
designverlibrarysim ovi_ecp3
designverlibrarysim pcsd_work
designverdefinemacro -clear
if {$newDesign == 0} { 
  removefile -Y -D *
}
addfile "E:/FX3/ApproachSensitivity/source/ApproachCell.vhd"
addfile "E:/FX3/ApproachSensitivity/source/ApproachCell_tb.vhd"
vlib "E:/FX3/ApproachSensitivity/work"
set worklib work
adel -all
vcom -dbg -work work "E:/FX3/ApproachSensitivity/source/ApproachCell.vhd"
vcom -dbg -work work "E:/FX3/ApproachSensitivity/source/ApproachCell_tb.vhd"
entity ApproachCell_tb
vsim +access +r ApproachCell_tb   -PL pmi_work -L ovi_ecp3 -L pcsd_work
add wave *
run 1000ns
