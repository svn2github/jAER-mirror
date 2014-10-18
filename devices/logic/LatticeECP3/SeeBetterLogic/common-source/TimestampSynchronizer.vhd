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
	signal SyncClockRisingEdge_S, SyncClockFallingEdge_S : std_logic;

	constant MASTER_TIMEOUT : integer := 500; -- in microseconds

	constant CLOCK_PULSE_TIME    : integer := 100; -- in microseconds
	constant CLOCK_RISEFALL_TIME : integer := CLOCK_PULSE_TIME / 2;

	constant RESET_PULSE_TIME        : integer := 200; -- in microseconds.
	constant RESET_PULSE_CYCLES      : integer := RESET_PULSE_TIME * LOGIC_CLOCK_FREQ;
	constant RESET_PULSE_CYCLES_SIZE : integer := integer(ceil(log2(real(RESET_PULSE_CYCLES + 1))));

	signal SyncClockResetPulse_S : std_logic;
	
		-- http://stackoverflow.com/questions/15244992 explains a better way to slow down a process
	-- using a clock enable instead of creating gated clocks with a clock divider, which avoids
	-- any issues of clock domain crossing and resource utilization.
	-- The ContinuousCounter already has an enable signal, which we can use in this fashion directly.
	signal TimestampEnable1MHz_S : std_logic;

	-- Wire the enable signal together with the TimestampRun signal, so that when we stop the logic,
	-- the timestamp counter will not increase anymore.
	signal TimestampEnable_S : std_logic;

	constant LOGIC_CLOCK_FREQ_SIZE : integer := integer(ceil(log2(real(LOGIC_CLOCK_FREQ))));
begin
	timestampEnableGenerate : entity work.PulseGenerator
		generic map(
			SIZE => LOGIC_CLOCK_FREQ_SIZE)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			PulsePolarity_SI => '1',
			PulseInterval_DI => to_unsigned(LOGIC_CLOCK_FREQ - 1, LOGIC_CLOCK_FREQ_SIZE),
			PulseLength_DI   => to_unsigned(1, LOGIC_CLOCK_FREQ_SIZE),
			Zero_SI          => TimestampReset_SI,
			PulseOut_SO      => TimestampEnable1MHz_S);

	clockEdgeDetector : entity work.EdgeDetector
		port map(
			Clock_CI               => Clock_CI,
			Reset_RI               => Reset_RI,
			InputSignal_SI         => SyncInClock_CI,
			RisingEdgeDetected_SO  => SyncClockRisingEdge_S,
			FallingEdgeDetected_SO => SyncClockFallingEdge_S);

	clockResetPulseDetector : entity work.PulseDetector
		generic map(
			SIZE => RESET_PULSE_CYCLES_SIZE)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			PulsePolarity_SI => '1',
			PulseLength_DI   => to_unsigned(RESET_PULSE_CYCLES, RESET_PULSE_CYCLES_SIZE),
			InputSignal_SI   => SyncInClock_CI,
			PulseDetected_SO => SyncClockResetPulse_S);

end architecture Behavioral;
