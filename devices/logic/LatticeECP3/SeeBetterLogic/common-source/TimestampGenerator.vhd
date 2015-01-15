library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.TIMESTAMP_WIDTH;

-- Generate the timestamp, as well as its overflow signal, which is
-- asserted for 1 cycle whenever the timestamp jumps back to zero.
-- Or, in other words, during the first cycle that the timestamp is
-- zero, the overflow signal goes high.
entity TimestampGenerator is
	port(
		Clock_CI             : in  std_logic;
		Reset_RI             : in  std_logic;

		TimestampInc_SI      : in  std_logic;
		TimestampReset_SI    : in  std_logic;

		TimestampOverflow_SO : out std_logic;
		Timestamp_DO         : out unsigned(TIMESTAMP_WIDTH - 1 downto 0));
end TimestampGenerator;

architecture Structural of TimestampGenerator is
begin
	timestampGenerator : entity work.ContinuousCounter
		generic map(
			SIZE                => TIMESTAMP_WIDTH,
			SHORT_OVERFLOW      => true,
			OVERFLOW_AT_ZERO    => true,
			OVERFLOW_OUT_BUFFER => true)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => TimestampReset_SI,
			Enable_SI    => TimestampInc_SI,
			DataLimit_DI => (others => '1'),
			Overflow_SO  => TimestampOverflow_SO,
			Data_DO      => Timestamp_DO);
end Structural;
