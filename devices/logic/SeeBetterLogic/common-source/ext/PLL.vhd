library ieee;
use ieee.std_logic_1164.all;
use work.Settings.DEVICE_FAMILY;

entity PLL is
	generic(
		CLOCK_FREQ     : integer;
		OUT_CLOCK_FREQ : integer);
	port(
		Clock_CI    : in  std_logic;
		Reset_RI    : in  std_logic;
		OutClock_CO : out std_logic);
end entity PLL;

architecture Structural of PLL is
	signal OutClock_C : std_logic;
begin
	pll : component work.pmi_components.pmi_pll
		generic map(
			pmi_freq_clki    => CLOCK_FREQ,
			pmi_freq_clkfb   => OUT_CLOCK_FREQ,
			pmi_freq_clkop   => OUT_CLOCK_FREQ,
			pmi_freq_clkos   => OUT_CLOCK_FREQ,
			pmi_freq_clkok   => OUT_CLOCK_FREQ,
			pmi_family       => DEVICE_FAMILY,
			pmi_phase_adj    => 0,
			pmi_duty_cycle   => 50,
			pmi_clkfb_source => "CLKOP",
			pmi_fdel         => "off",
			pmi_fdel_val     => 0)
		port map(
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
