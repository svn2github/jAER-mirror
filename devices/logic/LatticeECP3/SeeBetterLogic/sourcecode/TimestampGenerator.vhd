library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.all;

entity TimestampGenerator is
	port (
		Clock_CI			  : in	std_logic;
		Reset_RI			  : in	std_logic;
		FPGARun_SI			  : in	std_logic;
		FPGATimestampReset_SI : in	std_logic;
		TimestampReset_SO	  : out std_logic;
		TimestampOverflow_SO  : out std_logic;
		Timestamp_DO		  : out std_logic_vector(TIMESTAMP_WIDTH-1 downto 0));
end TimestampGenerator;

architecture Structural of TimestampGenerator is
	component ContinuousCounter is
		generic (
			COUNTER_WIDTH	  : integer := 16;
			RESET_ON_OVERFLOW : boolean := true;
			SHORT_OVERFLOW	  : boolean := false;
			OVERFLOW_AT_ZERO  : boolean := false);
		port (
			Clock_CI	 : in  std_logic;
			Reset_RI	 : in  std_logic;
			Clear_SI	 : in  std_logic;
			Enable_SI	 : in  std_logic;
			DataLimit_DI : in  unsigned(COUNTER_WIDTH-1 downto 0);
			Overflow_SO	 : out std_logic;
			Data_DO		 : out unsigned(COUNTER_WIDTH-1 downto 0));
	end component ContinuousCounter;

	component PulseGenerator is
		generic (
			PULSE_EVERY_CYCLES : integer   := 100;
			PULSE_POLARITY	   : std_logic := '1');
		port (
			Clock_CI	: in  std_logic;
			Reset_RI	: in  std_logic;
			Clear_SI	: in  std_logic;
			PulseOut_SO : out std_logic);
	end component PulseGenerator;

	component PulseDetector is
		generic (
			PULSE_MINIMAL_LENGTH_CYCLES : integer	:= 50;
			PULSE_POLARITY				: std_logic := '1');
		port (
			Clock_CI		 : in  std_logic;
			Reset_RI		 : in  std_logic;
			InputSignal_SI	 : in  std_logic;
			PulseDetected_SO : out std_logic);
	end component PulseDetector;

	-- Detect resets from the host and pulse this once to reset the Timestamp Generator and anybody
	-- outside listening to the TimestampReset_SO output.
	signal TimestampReset_S : std_logic;

	-- http://stackoverflow.com/questions/15244992 explains a better way to slow down a process
	-- using a clock enable instead of creating gated clocks with a clock divider, which avoids
	-- any issues of clock domain crossing and resource utilization.
	-- The ContinuousCounter already has an enable signal, which we can use in this fashion directly.
	signal TimestampEnable1MHz_S : std_logic;

	-- Wire the enable signal together with the FPGARun signal, so that when we stop the FPGA,
	-- the timestamp counter will not increase anymore.
	signal TimestampEnable_S : std_logic;
begin
	timestampEnableGenerate : PulseGenerator
		generic map (
			PULSE_EVERY_CYCLES => LOGIC_CLOCK_FREQ)
		port map (
			Clock_CI	=> Clock_CI,
			Reset_RI	=> Reset_RI,
			Clear_SI	=> TimestampReset_S,
			PulseOut_SO => TimestampEnable1MHz_S);

	TimestampEnable_S <= TimestampEnable1MHz_S and FPGARun_SI;

	-- Detect FPGATimestampReset_SI pulse from host and then generate just one
	-- quick reset pulse to the counter and pulse generator.
	timestampResetDetect : PulseDetector
		generic map (
			PULSE_MINIMAL_LENGTH_CYCLES => LOGIC_CLOCK_FREQ / 2)
		port map (
			Clock_CI		 => Clock_CI,
			Reset_RI		 => Reset_RI,
			InputSignal_SI	 => FPGATimestampReset_SI,
			PulseDetected_SO => TimestampReset_S);

	timestampGenerator : ContinuousCounter
		generic map (
			COUNTER_WIDTH	 => TIMESTAMP_WIDTH,
			SHORT_OVERFLOW	 => true,
			OVERFLOW_AT_ZERO => true)
		port map (
			Clock_CI				  => Clock_CI,
			Reset_RI				  => Reset_RI,
			Clear_SI				  => TimestampReset_S,
			Enable_SI				  => TimestampEnable_S,
			DataLimit_DI			  => (others => '1'),
			Overflow_SO				  => TimestampOverflow_SO,
			std_logic_vector(Data_DO) => Timestamp_DO);

	-- Notify outside world about timestamp reset.
	TimestampReset_SO <= TimestampReset_S;
end Structural;
