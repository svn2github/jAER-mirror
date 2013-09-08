[ActiveSupport MAP]
Device = LCMXO2280C;
Package = FTBGA256;
Speed = 3;
LUTS_avail = 2280;
LUTS_used = 628;
FF_avail = 2280;
FF_used = 418;
INPUT_LVCMOS33 = 36;
OUTPUT_LVCMOS33 = 55;
IO_avail = 211;
IO_used = 91;
PLL_avail = 2;
PLL_used = 1;
EBR_avail = 3;
EBR_used = 2;
; Begin EBR Section
Instance_Name = uFifo/AERfifo_0_1;
Type = FIFO8KA;
Width = 9;
REGMODE = NOREG;
RESETMODE = ASYNC;
GSR = DISABLED;
Instance_Name = uFifo/AERfifo_1_0;
Type = FIFO8KA;
Width = 7;
REGMODE = NOREG;
RESETMODE = ASYNC;
GSR = DISABLED;
; End EBR Section
; Begin PLL Section
Instance_Name = uClockGen/PLLCInst_0;
Type = EHXPLLC;
CLKI_Divider = 1;
CLKFB_Divider = 3;
CLKOP_Divider = 8;
CLKOK_Divider = 2;
PLL_Delay_Factor_(*250ps) = 0;
CLKOS_Phaseadj_(degree) = 0;
CLKOS_Duty_Cycle_(*1/8) = 4;
Delay_Control = STATIC;
; End PLL Section
