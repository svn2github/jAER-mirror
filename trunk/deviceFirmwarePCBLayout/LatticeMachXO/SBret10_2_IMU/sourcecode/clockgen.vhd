-- VHDL netlist generated by SCUBA Diamond (64-bit) 3.2.0.134
-- Module  Version: 5.6
--C:\lscc\diamond\3.2_x64\ispfpga\bin\nt64\scuba.exe -w -n clockgen -lang vhdl -synth synplify -arch mj5g00 -type pll -fin 30 -fclkop 60 -fclkop_tol 0.0 -delay_cntl STATIC -fdel 0 -fb_mode CLOCKTREE -noclkos 

-- Mon Oct 06 19:04:15 2014

library IEEE;
use IEEE.std_logic_1164.all;
-- synopsys translate_off
library MACHXO;
use MACHXO.components.all;
-- synopsys translate_on

entity clockgen is
    port (
        CLK: in std_logic; 
        RESET: in std_logic; 
        CLKOP: out std_logic; 
        LOCK: out std_logic);
 attribute dont_touch : boolean;
 attribute dont_touch of clockgen : entity is true;
end clockgen;

architecture Structure of clockgen is

    -- internal signal declarations
    signal scuba_vlo: std_logic;
    signal CLKOP_t: std_logic;

    -- local component declarations
    component VLO
        port (Z: out std_logic);
    end component;
    component EHXPLLC
    -- synopsys translate_off
        generic (DUTY : in Integer; PHASEADJ : in Integer; 
                DELAY_CNTL : in String; CLKOK_DIV : in Integer; 
                FDEL : in Integer; CLKFB_DIV : in Integer; 
                CLKOP_DIV : in Integer; CLKI_DIV : in Integer);
    -- synopsys translate_on
        port (CLKI: in std_logic; CLKFB: in std_logic; RST: in std_logic; 
            DDAMODE: in std_logic; DDAIZR: in std_logic; DDAILAG: in std_logic; 
            DDAIDEL0: in std_logic; DDAIDEL1: in std_logic; DDAIDEL2: in std_logic; 
            CLKOP: out std_logic; CLKOS: out std_logic; CLKOK: out std_logic; 
            CLKINTFB: out std_logic; LOCK: out std_logic);
    end component;
    attribute DELAY_CNTL : string; 
    attribute FDEL : string; 
    attribute DUTY : string; 
    attribute PHASEADJ : string; 
    attribute CLKOK_DIV : string; 
    attribute FREQUENCY_PIN_CLKOP : string; 
    attribute FREQUENCY_PIN_CLKI : string; 
    attribute CLKOP_DIV : string; 
    attribute CLKFB_DIV : string; 
    attribute CLKI_DIV : string; 
    attribute FIN : string; 
    attribute DELAY_CNTL of PLLCInst_0 : label is "STATIC";
    attribute FDEL of PLLCInst_0 : label is "0";
    attribute DUTY of PLLCInst_0 : label is "4";
    attribute PHASEADJ of PLLCInst_0 : label is "0";
    attribute CLKOK_DIV of PLLCInst_0 : label is "2";
    attribute FREQUENCY_PIN_CLKOP of PLLCInst_0 : label is "60.000000";
    attribute FREQUENCY_PIN_CLKI of PLLCInst_0 : label is "30.000000";
    attribute CLKOP_DIV of PLLCInst_0 : label is "14";
    attribute CLKFB_DIV of PLLCInst_0 : label is "2";
    attribute CLKI_DIV of PLLCInst_0 : label is "1";
    attribute FIN of PLLCInst_0 : label is "30.000000";
    attribute syn_keep : boolean;
    attribute syn_noprune : boolean;
    attribute syn_noprune of Structure : architecture is true;
    attribute NGD_DRC_MASK : integer;
    attribute NGD_DRC_MASK of Structure : architecture is 1;

begin
    -- component instantiation statements
    scuba_vlo_inst: VLO
        port map (Z=>scuba_vlo);

    PLLCInst_0: EHXPLLC
        -- synopsys translate_off
        generic map (DELAY_CNTL=> "STATIC", FDEL=>  0, DUTY=>  4, 
        PHASEADJ=>  0, CLKOK_DIV=>  2, CLKOP_DIV=>  14, CLKFB_DIV=>  2, 
        CLKI_DIV=>  1)
        -- synopsys translate_on
        port map (CLKI=>CLK, CLKFB=>CLKOP_t, RST=>RESET, 
            DDAMODE=>scuba_vlo, DDAIZR=>scuba_vlo, DDAILAG=>scuba_vlo, 
            DDAIDEL0=>scuba_vlo, DDAIDEL1=>scuba_vlo, 
            DDAIDEL2=>scuba_vlo, CLKOP=>CLKOP_t, CLKOS=>open, 
            CLKOK=>open, CLKINTFB=>open, LOCK=>LOCK);

    CLKOP <= CLKOP_t;
end Structure;

-- synopsys translate_off
library MACHXO;
configuration Structure_CON of clockgen is
    for Structure
        for all:VLO use entity MACHXO.VLO(V); end for;
        for all:EHXPLLC use entity MACHXO.EHXPLLC(V); end for;
    end for;
end Structure_CON;

-- synopsys translate_on
