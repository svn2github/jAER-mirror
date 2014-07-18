library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity EdgeDetector_tb is
end entity EdgeDetector_tb;

-------------------------------------------------------------------------------

architecture Testbench of EdgeDetector_tb is
	-- component generics
	constant SIGNAL_START_POLARITY : std_logic := '0';

	-- component ports
	signal Clock_C               : std_logic;
	signal Reset_R               : std_logic;
	signal InputSignal_S         : std_logic;
	signal RisingEdgeDetected_S  : std_logic;
	signal FallingEdgeDetected_S : std_logic;

	-- clock
	signal Clk : std_logic := '1';
begin                                   -- architecture Testbench
	-- component instantiation
	DUT : entity work.EdgeDetector
		generic map(
			SIGNAL_START_POLARITY => SIGNAL_START_POLARITY)
		port map(
			Clock_CI               => Clock_C,
			Reset_RI               => Reset_R,
			InputSignal_SI         => InputSignal_S,
			RisingEdgeDetected_SO  => RisingEdgeDetected_S,
			FallingEdgeDetected_SO => FallingEdgeDetected_S);

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

		-- generate various up and down signals
		wait for 2 ns;
		InputSignal_S <= '1';
		wait for 2 ns;
		InputSignal_S <= '0';

		wait for 5 ns;
		InputSignal_S <= '1';
		wait for 15 ns;
		InputSignal_S <= '0';

		wait for 15 ns;
		InputSignal_S <= '1';
		wait for 5 ns;
		InputSignal_S <= '0';

		wait for 8 ns;
		InputSignal_S <= '1';
		wait for 8 ns;
		InputSignal_S <= '0';

		wait for 1 ns;
		InputSignal_S <= '1';
		wait for 5 ns;
		InputSignal_S <= '0';

		wait for 5 ns;
		InputSignal_S <= '1';
		wait for 1 ns;
		InputSignal_S <= '0';

		wait;
	end process WaveGen_Proc;
end architecture Testbench;
