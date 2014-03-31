[ActiveSupport MAP]
Device = LFE3-17EA;
Package = FTBGA256;
Performance = 7;
LUTS_avail = 17280;
LUTS_used = 752;
FF_avail = 13093;
FF_used = 478;
INPUT_LVCMOS33 = 36;
OUTPUT_LVCMOS33 = 56;
IO_avail = 133;
IO_used = 92;
Serdes_avail = 1;
Serdes_used = 0;
PLL_avail = 2;
PLL_used = 1;
EBR_avail = 38;
EBR_used = 0;
;
; start of DSP statistics
MULT18X18C = 0;
MULT9X9C = 0;
ALU54A = 0;
ALU24A = 0;
DSP_MULT_avail = 48;
DSP_MULT_used = 0;
DSP_ALU_avail = 24;
DSP_ALU_used = 0;
; end of DSP statistics
;
; Begin PLL Section
Instance_Name = uClockGen/PLLCInst_0/PLLInst_0;
Type = EHXPLLF;
Output_Clock(P)_Actual_Frequency = 90.0000;
CLKOP_BYPASS = DISABLED;
CLKOS_BYPASS = DISABLED;
CLKOK_BYPASS = DISABLED;
CLKOK_Input = CLKOP;
FB_MODE = CLKOP;
CLKI_Divider = 1;
CLKFB_Divider = 3;
CLKOP_Divider = 8;
CLKOK_Divider = 2;
Phase_Duty_Control = STATIC;
CLKOS_Phase_Shift_(degree) = 0.0;
CLKOS_Duty_Cycle = 4;
CLKOS_Delay_Adjust_Power_Down = DISABLED;
CLKOS_Delay_Adjust_Static_Delay_(ps) = 0;
CLKOP_Duty_Trim_Polarity = RISING;
CLKOP_Duty_Trim_Polarity_Delay_(ps) = 0;
CLKOS_Duty_Trim_Polarity = RISING;
CLKOS_Duty_Trim_Polarity_Delay_(ps) = 0;
; End PLL Section
