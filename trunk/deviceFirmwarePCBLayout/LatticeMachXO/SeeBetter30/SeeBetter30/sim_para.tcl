lappend auto_path "C:/Program Files/Lattice/diamond/1.3/data/script"
package require simulation_generation
set ::bali::simulation::Para(PROJECT) {SeeBetter30}
set ::bali::simulation::Para(PROJECTPATH) {C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30}
set ::bali::simulation::Para(FILELIST) {"C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/wordRegister.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/AERfifo.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/clockgen.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/earlyPaketTimer.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/EventBeforeOverflow.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/eventCounter.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/fifoStatemachine.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/monitorStateMachine.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/synchronizerStateMachine.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/timestampCounter.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/USBAER_top_level.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/ADCvalueReady.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/ADCStateMachine.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/cDVSResetStateMachine.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/shiftRegister.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/ADCStateMachine_tb.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/AERfifo.vhd" "C:/PROJ/jAER/deviceFirmwarePCBLayout/LatticeMachXO/SeeBetter30/sourcecode/clockgen.vhd" }
set ::bali::simulation::Para(GLBINCLIST) {}
set ::bali::simulation::Para(INCLIST) {"none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none"}
set ::bali::simulation::Para(WORKLIBLIST) {"work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "" "" }
set ::bali::simulation::Para(COMPLIST) {"VHDL" "VHDL" "VHDL" "VHDL" "VHDL" "VHDL" "VHDL" "VHDL" "VHDL" "VHDL" "VHDL" "VHDL" "VHDL" "VHDL" "VHDL" "VHDL" "VHDL" "VHDL" }
set ::bali::simulation::Para(SIMLIBLIST) {pmi_work ovi_machxo}
set ::bali::simulation::Para(MACROLIST) {}
set ::bali::simulation::Para(SIMULATIONTOPMODULE) {EventBeforeOverflow}
set ::bali::simulation::Para(SIMULATIONINSTANCE) {}
set ::bali::simulation::Para(LANGUAGE) {VHDL}
set ::bali::simulation::Para(SDFPATH)  {}
::bali::simulation::ActiveHDL_Run
