library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use work.Settings.LOGIC_CLOCK_FREQ;

entity TimestampSynchronizer is
	port(
		Clock_CI          : in  std_logic;
		Reset_RI          : in  std_logic;
		SyncInClock_CI    : in  std_logic;
		SyncOutClock_CO   : out std_logic;
		TimestampReset_SO : out std_logic;
		TimestampInc_SO   : out std_logic);
end entity TimestampSynchronizer;

architecture Behavioral of TimestampSynchronizer is
	constant MASTER_TIMEOUT : integer := 500; -- in microseconds
	constant SLAVE_TIMEOUT  : integer := 10; -- in microseconds

	constant CLOCK_PERIOD_TIME   : integer := 100; -- in microseconds
	constant CLOCK_RISEFALL_TIME : integer := CLOCK_PERIOD_TIME / 2; -- in microseconds

	signal TimestampTickReset_S, TimestampTickEnable_S : std_logic;
	signal TimestampTick_S                             : std_logic;

	signal TimestampSynchronizerReset_S, TimestampSynchronizerEnable_S : std_logic;
	signal TimestampSynchronizer_D                                     : unsigned(7 downto 0);

	constant LOGIC_CLOCK_FREQ_SIZE : integer := integer(ceil(log2(real(LOGIC_CLOCK_FREQ))));

	signal MasterMode_SP, MasterMode_SN : std_logic;
begin
	timestampTickCounter : entity work.ContinuousCounter
		generic map(
			SIZE => LOGIC_CLOCK_FREQ_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => TimestampTickReset_S,
			Enable_SI    => TimestampTickEnable_S,
			DataLimit_DI => to_unsigned(LOGIC_CLOCK_FREQ - 1, LOGIC_CLOCK_FREQ_SIZE),
			Overflow_SO  => TimestampTick_S,
			Data_DO      => open);

	timestampSynchronizerCounter : entity work.ContinuousCounter
		generic map(
			SIZE              => 8,
			RESET_ON_OVERFLOW => false,
			GENERATE_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => TimestampSynchronizerReset_S,
			Enable_SI    => TimestampSynchronizerEnable_S,
			DataLimit_DI => (others => '1'),
			Overflow_SO  => open,
			Data_DO      => TimestampSynchronizer_D);

	masterMode : process(MasterMode_SP)
	begin
		MasterMode_SN <= MasterMode_SP;
	end process masterMode;

	timestampSynchronizer : process(MasterMode_SP)
	begin
	end process timestampSynchronizer;

	registerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then
			MasterMode_SP <= '1';
		elsif rising_edge(Clock_CI) then
			MasterMode_SP <= MasterMode_SN;
		end if;
	end process registerUpdate;
end architecture Behavioral;
