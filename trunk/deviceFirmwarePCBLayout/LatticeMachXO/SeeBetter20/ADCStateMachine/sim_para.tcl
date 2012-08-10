lappend auto_path "C:/Program Files/Lattice/diamond/1.3/data/script"
package require simulation_generation
set ::bali::simulation::Para(PROJECT) {ADCStateMachine}
set ::bali::simulation::Para(PROJECTPATH) {C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20}
set ::bali::simulation::Para(FILELIST) {"C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCvalueReady.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCStateMachine.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine_tb.vhd" }
set ::bali::simulation::Para(GLBINCLIST) {}
set ::bali::simulation::Para(INCLIST) {"none" "none" "none"}
set ::bali::simulation::Para(WORKLIBLIST) {"work" "work" "work" }
set ::bali::simulation::Para(COMPLIST) {"VHDL" "VHDL" "VHDL" }
set ::bali::simulation::Para(SIMLIBLIST) {pmi_work ovi_machxo}
set ::bali::simulation::Para(MACROLIST) {}
set ::bali::simulation::Para(SIMULATIONTOPMODULE) {ADCStateMachine_tb}
set ::bali::simulation::Para(SIMULATIONINSTANCE) {}
set ::bali::simulation::Para(LANGUAGE) {VHDL}
set ::bali::simulation::Para(SDFPATH)  {}
::bali::simulation::ActiveHDL_Run
