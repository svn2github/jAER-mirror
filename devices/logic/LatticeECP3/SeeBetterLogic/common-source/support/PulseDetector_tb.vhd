library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------

entity PulseDetector_tb is
end entity PulseDetector_tb;

-------------------------------------------------------------------------------

architecture Testbench of PulseDetector_tb is
	-- component generics
	constant PULSE_MINIMAL_LENGTH_CYCLES : integer   := 20;
	constant PULSE_POLARITY              : std_logic := '1';

	-- component ports
	signal Clock_C         : std_logic;
	signal Reset_R         : std_logic;
	signal InputSignal_S   : std_logic;
	signal PulseDetected_S : std_logic;

	-- clock
	signal Clk : std_logic := '1';
begin                                   -- architecture Testbench
	-- component instantiation
	DUT : entity work.PulseDetector
		generic map(
			SIZE => 5)
		port map(
			Clock_CI         => Clock_C,
			Reset_RI         => Reset_R,
			PulsePolarity_SI => PULSE_POLARITY,
			PulseLength_DI   => to_unsigned(PULSE_MINIMAL_LENGTH_CYCLES, 5),
			InputSignal_SI   => InputSignal_S,
			PulseDetected_SO => PulseDetected_S);

	-- clock generation
	Clk     <= not Clk after 0.5 ns;
	Clock_C <= Clk;

	-- waveform generation
	WaveGen_Proc : process
	begin
		Reset_R       <= '0';
		InputSignal_S <= '0';

		-- pulse reset
		wait for 2 ns;
		Reset_R <= '1';
		wait for 3 ns;
		Reset_R <= '0';

		-- generate too short signal (5 cycles)
		wait for 5 ns;
		InputSignal_S <= '1';
		wait for 5 ns;
		InputSignal_S <= '0';

		-- generate too short signal by one (19 cycles)
		wait for 5 ns;
		InputSignal_S <= '1';
		wait for 19 ns;
		InputSignal_S <= '0';

		-- generate exact signal (20 cycles, to be detected)
		wait for 5 ns;
		InputSignal_S <= '1';
		wait for 20 ns;
		InputSignal_S <= '0';

		-- generate long signal by one (21 cycles, to be detected)
		wait for 5 ns;
		InputSignal_S <= '1';
		wait for 21 ns;
		InputSignal_S <= '0';

		-- generate long signal (35 cycles)
		wait for 5 ns;
		InputSignal_S <= '1';
		wait for 35 ns;
		InputSignal_S <= '0';

		-- generate exact signal again (20 cycles)
		wait for 5 ns;
		InputSignal_S <= '1';
		wait for 20 ns;
		InputSignal_S <= '0';

		wait;
	end process WaveGen_Proc;
end architecture Testbench;
