-- VHDL netlist generated by SCUBA Diamond_1.0_Production (529)
-- Module  Version: 5.2
--C:\LatticeDiamond\diamond\1.0\ispfpga\bin\nt\scuba.exe -w -n clockgen -lang vhdl -synth synplify -arch mj5g00 -type pll -fin 30 -fclkop 90 -fclkop_tol 0.0 -delay_cntl STATIC -fdel 0 -fb_mode CLOCKTREE -noclkos -e 

-- Thu Aug 26 09:53:23 2010

library IEEE;
use IEEE.std_logic_1164.all;

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
    signal CLKOP_t: std_logic;

    -- local component declarations
	component pmi_pll is
     generic (
       pmi_freq_clki : integer := 100; 
       pmi_freq_clkfb : integer := 100; 
       pmi_freq_clkop : integer := 100; 
       pmi_freq_clkos : integer := 100; 
       pmi_freq_clkok : integer := 50; 
       pmi_family : string := "EC"; 
       pmi_phase_adj : integer := 0; 
       pmi_duty_cycle : integer := 50; 
       pmi_clkfb_source : string := "CLKOP"; 
       pmi_fdel : string := "off"; 
       pmi_fdel_val : integer := 0; 
       module_type : string := "pmi_pll" 
    );
    port (
     CLKI: in std_logic;
     CLKFB: in std_logic;
     RESET: in std_logic;
     CLKOP: out std_logic;
     CLKOS: out std_logic;
     CLKOK: out std_logic;
     CLKOK2: out std_logic;
     LOCK: out std_logic
   );
  end component pmi_pll;

begin
    -- component instantiation statements
	PLLCInst_0: pmi_pll
    generic map(
       pmi_freq_clki => 25,
       pmi_freq_clkfb => 90,
       pmi_freq_clkop => 90,
       pmi_freq_clkos => 90,
       pmi_freq_clkok => 50,
       pmi_family => "ECP3",
       pmi_phase_adj => 0,
       pmi_duty_cycle => 25,
       pmi_clkfb_source => "CLKOP",
       pmi_fdel => "off",
       pmi_fdel_val => 0
    )
    port map (
     CLKI => CLK,
     CLKFB => CLKOP_t,
     RESET => RESET,
     CLKOP => CLKOP_t,
     CLKOS => open,
     CLKOK => open,
     CLKOK2 => open,
     LOCK => LOCK
   );

    CLKOP <= CLKOP_t;
end Structure;
