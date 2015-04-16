lappend auto_path "E:/LatticeDiamond/diamond/2.0/data/script"
package require simulation_generation
set ::bali::simulation::Para(PROJECT) {ADCStateMachine}
set ::bali::simulation::Para(PROJECTPATH) {E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20}
set ::bali::simulation::Para(FILELIST) {"E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCvalueReady.vhd" "E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/sourcecode/ADCStateMachine.vhd" "E:/jaer/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter20/ADCStateMachine_tb.vhd" }
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
