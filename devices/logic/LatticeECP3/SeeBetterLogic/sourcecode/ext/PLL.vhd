library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.Settings.all;

entity PLL is
	generic (
		CLOCK_FREQ	   : integer := 50;
		OUT_CLOCK_FREQ : integer := 100);
	port (
		Clock_CI	: in  std_logic;
		Reset_RI	: in  std_logic;
		OutClock_CO : out std_logic);
end entity PLL;

architecture Structural of PLL is
	component pmi_pll is
		generic (
			pmi_freq_clki	 : integer := 100;
			pmi_freq_clkfb	 : integer := 100;
			pmi_freq_clkop	 : integer := 100;
			pmi_freq_clkos	 : integer := 100;
			pmi_freq_clkok	 : integer := 50;
			pmi_family		 : string  := "EC";
			pmi_phase_adj	 : integer := 0;
			pmi_duty_cycle	 : integer := 50;
			pmi_clkfb_source : string  := "CLKOP";
			pmi_fdel		 : string  := "off";
			pmi_fdel_val	 : integer := 0;
			module_type		 : string  := "pmi_pll");
		port (
			CLKI   : in	 std_logic;
			CLKFB  : in	 std_logic;
			RESET  : in	 std_logic;
			CLKOP  : out std_logic;
			CLKOS  : out std_logic;
			CLKOK  : out std_logic;
			CLKOK2 : out std_logic;
			LOCK   : out std_logic);
	end component pmi_pll;

	signal OutClock_C : std_logic;
begin  -- architecture Structural
	pll : pmi_pll
		generic map (
			pmi_freq_clki	 => CLOCK_FREQ,
			pmi_freq_clkfb	 => OUT_CLOCK_FREQ,
			pmi_freq_clkop	 => OUT_CLOCK_FREQ,
			pmi_freq_clkos	 => OUT_CLOCK_FREQ,
			pmi_freq_clkok	 => OUT_CLOCK_FREQ,
			pmi_family		 => DEVICE_FAMILY,
			pmi_phase_adj	 => 0,
			pmi_duty_cycle	 => 50,
			pmi_clkfb_source => "CLKOP",
			pmi_fdel		 => "off",
			pmi_fdel_val	 => 0)
		port map (
			CLKI   => Clock_CI,
			CLKFB  => OutClock_C,
			RESET  => Reset_RI,
			CLKOP  => OutClock_C,
			CLKOS  => open,
			CLKOK  => open,
			CLKOK2 => open,
			LOCK   => open);

	OutClock_CO <= OutClock_C;
end architecture Structural;
