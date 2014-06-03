library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity clockgen is
	port (
		CLK : in std_logic; 
		RESET : in std_logic; 
		CLKOP : out std_logic; 
		LOCK : out std_logic);
end clockgen;

architecture Structural of clockgen is
	constant INPUT_CLOCK_FREQ : integer := 30;
	constant OUTPUT_CLOCK_FREQ : integer := 90;

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
		module_type : string := "pmi_pll" );
	port (
		CLKI: in std_logic;
		CLKFB: in std_logic;
		RESET: in std_logic;
		CLKOP: out std_logic;
		CLKOS: out std_logic;
		CLKOK: out std_logic;
		CLKOK2: out std_logic;
		LOCK: out std_logic);
	end component pmi_pll;
	
	signal CLKOP_t : std_logic;
begin
	uPLLSlowDown: pmi_pll
	generic map (
		pmi_freq_clki => INPUT_CLOCK_FREQ,
		pmi_freq_clkfb => OUTPUT_CLOCK_FREQ,
		pmi_freq_clkop => OUTPUT_CLOCK_FREQ,
		pmi_freq_clkos => OUTPUT_CLOCK_FREQ,
		pmi_freq_clkok => OUTPUT_CLOCK_FREQ,
		pmi_family => "ECP3",
		pmi_phase_adj => 0,
		pmi_duty_cycle => 50,
		pmi_clkfb_source => "CLKOP",
		pmi_fdel => "off",
		pmi_fdel_val => 0)
	port map (
		CLKI => CLK,
		CLKFB => CLKOP_t,
		RESET => RESET,
		CLKOP => CLKOP_t,
		CLKOS => open,
		CLKOK => open,
		CLKOK2 => open,
		LOCK => LOCK);

	CLKOP <= CLKOP_t;
end Structural;
