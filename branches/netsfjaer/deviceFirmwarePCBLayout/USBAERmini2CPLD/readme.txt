contents:

sourcecode: vhdl-sourcecode files
USBAERmini2: xilinx project that uses ModelSim

possibilities to speed up the design:
-change state-machines, in fifoSM use runMonitor and runSequencer inputs to decide if 
   it is necessary to go to idle state
-add second register for sequencer to speed up communication between fifoSM and sequencerSM