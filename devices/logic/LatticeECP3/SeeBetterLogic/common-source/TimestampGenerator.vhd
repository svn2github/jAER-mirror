library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.Settings.LOGIC_CLOCK_FREQ;

entity TimestampGenerator is
	port(
		Clock_CI             : in  std_logic;
		Reset_RI             : in  std_logic;
		TimestampRun_SI      : in  std_logic;
		TimestampReset_SI    : in  std_logic;
		TimestampOverflow_SO : out std_logic;
		Timestamp_DO         : out unsigned(TIMESTAMP_WIDTH - 1 downto 0));
end TimestampGenerator;

architecture Structural of TimestampGenerator is
	-- http://stackoverflow.com/questions/15244992 explains a better way to slow down a process
	-- using a clock enable instead of creating gated clocks with a clock divider, which avoids
	-- any issues of clock domain crossing and resource utilization.
	-- The ContinuousCounter already has an enable signal, which we can use in this fashion directly.
	signal TimestampEnable1MHz_S : std_logic;

	-- Wire the enable signal together with the TimestampRun signal, so that when we stop the logic,
	-- the timestamp counter will not increase anymore.
	signal TimestampEnable_S : std_logic;
begin
	timestampEnableGenerate : entity work.PulseGenerator
		generic map(
			PULSE_EVERY_CYCLES => LOGIC_CLOCK_FREQ)
		port map(
			Clock_CI    => Clock_CI,
			Reset_RI    => Reset_RI,
			Clear_SI    => TimestampReset_SI,
			PulseOut_SO => TimestampEnable1MHz_S);

	TimestampEnable_S <= TimestampEnable1MHz_S and TimestampRun_SI;

	timestampGenerator : entity work.ContinuousCounter
		generic map(
			SIZE             => TIMESTAMP_WIDTH,
			SHORT_OVERFLOW   => true,
			OVERFLOW_AT_ZERO => true)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => TimestampReset_SI,
			Enable_SI    => TimestampEnable_S,
			DataLimit_DI => (others => '1'),
			Overflow_SO  => TimestampOverflow_SO,
			Data_DO      => Timestamp_DO);
end Structural;
