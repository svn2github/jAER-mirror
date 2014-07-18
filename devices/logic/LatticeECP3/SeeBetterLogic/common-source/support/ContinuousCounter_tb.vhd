library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------

entity ContinuousCounter_tb is
end entity ContinuousCounter_tb;

-------------------------------------------------------------------------------

architecture Testbench of ContinuousCounter_tb is
	-- component generics
	constant COUNTER_WIDTH     : integer := 4;
	constant RESET_ON_OVERFLOW : boolean := true;
	constant SHORT_OVERFLOW    : boolean := false;
	constant OVERFLOW_AT_ZERO  : boolean := false;

	-- component ports
	signal Clock_C     : std_logic;
	signal Reset_R     : std_logic;
	signal Clear_S     : std_logic;
	signal Enable_S    : std_logic;
	signal DataLimit_D : unsigned(COUNTER_WIDTH - 1 downto 0);
	signal Overflow_S  : std_logic;
	signal Data_D      : unsigned(COUNTER_WIDTH - 1 downto 0);

	-- clock
	signal Clk : std_logic := '1';
begin                                   -- architecture Testbench
	-- component instantiation
	DUT : entity work.ContinuousCounter
		generic map(
			COUNTER_WIDTH     => COUNTER_WIDTH,
			RESET_ON_OVERFLOW => RESET_ON_OVERFLOW,
			SHORT_OVERFLOW    => SHORT_OVERFLOW,
			OVERFLOW_AT_ZERO  => OVERFLOW_AT_ZERO)
		port map(
			Clock_CI     => Clock_C,
			Reset_RI     => Reset_R,
			Clear_SI     => Clear_S,
			Enable_SI    => Enable_S,
			DataLimit_DI => DataLimit_D,
			Overflow_SO  => Overflow_S,
			Data_DO      => Data_D);

	-- clock generation
	Clk     <= not Clk after 0.5 ns;
	Clock_C <= Clk;

	-- waveform generation
	WaveGen_Proc : process
	begin
		Reset_R     <= '0';
		Clear_S     <= '0';
		Enable_S    <= '0';
		DataLimit_D <= to_unsigned(14, COUNTER_WIDTH);

		-- pulse reset
		wait for 2 ns;
		Reset_R <= '1';
		wait for 3 ns;
		Reset_R <= '0';

		-- should remain at zero for 5 cycles
		wait for 5 ns;

		-- count up for 10 cycles, now it's 10
		Enable_S <= '1';
		wait for 10 ns;
		Enable_S <= '0';

		-- keep at 10 for 5 cycles
		wait for 5 ns;

		-- count up for 10 cycles (should wrap around), now it's 5
		Enable_S <= '1';
		wait for 10 ns;
		Enable_S <= '0';

		-- clear goes back to 0
		wait for 5 ns;
		Clear_S <= '1';
		wait for 1 ns;
		Clear_S <= '0';

		-- now count up to exactly 14, should wrap and be 0
		wait for 5 ns;
		Enable_S <= '1';
		wait for 14 ns;
		Enable_S <= '0';

		-- now count up to 14 again, but with an intermittent enable, and then
		-- four more, up to 3
		delayedEnableLoop : for i in 1 to 18 loop
			wait for 5 ns;
			Enable_S <= '1';
			wait for 1 ns;
			Enable_S <= '0';
		end loop;                       -- i

		-- just count up and up
		wait for 5 ns;
		Enable_S <= '1';

		wait;
	end process WaveGen_Proc;
end architecture Testbench;
