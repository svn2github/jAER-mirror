library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity PulseGenerator_tb is

end entity PulseGenerator_tb;

-------------------------------------------------------------------------------

architecture Test of PulseGenerator_tb is

	-- component generics
	constant PULSE_EVERY_CYCLES : integer	:= 100;
	constant PULSE_POLARITY		: std_logic := '1';

	-- component ports
	signal Clock_C	  : std_logic;
	signal Reset_R	  : std_logic;
	signal Clear_S	  : std_logic;
	signal PulseOut_S : std_logic;

	-- clock
	signal Clk : std_logic := '1';

begin  -- architecture Test

	-- component instantiation
	DUT: entity work.PulseGenerator
		generic map (
			PULSE_EVERY_CYCLES => PULSE_EVERY_CYCLES,
			PULSE_POLARITY	   => PULSE_POLARITY)
		port map (
			Clock_CI	=> Clock_C,
			Reset_RI	=> Reset_R,
			Clear_SI	=> Clear_S,
			PulseOut_SO => PulseOut_S);

	-- clock generation
	Clk <= not Clk after 10 ns;

	-- waveform generation
	WaveGen_Proc: process
	begin
		Clock_C <= Clk;
		Reset_R <= '0';
		Clear_S <= '0';
		PulseOut_S <= '0';

		wait until Clk = '1';
	end process WaveGen_Proc;



end architecture Test;

-------------------------------------------------------------------------------

configuration PulseGenerator_tb_Test_cfg of PulseGenerator_tb is
	for Test
	end for;
end PulseGenerator_tb_Test_cfg;

-------------------------------------------------------------------------------
