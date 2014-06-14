library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.all;

entity MultiplexerStateMachine is
	port (
		Clock_CI			  : in std_logic;
		Reset_RI			  : in std_logic;
		FPGARun_SI			  : in std_logic;
		FPGATimestampReset_SI : in std_logic;

		-- Fifo output (to USB)
		OutFifoFull_SI		 : in  std_logic;
		OutFifoAlmostFull_SI : in  std_logic;
		OutFifoWrite_SO		 : out std_logic;
		OutFifoData_DO		 : out std_logic_vector(USB_FIFO_WIDTH-1 downto 0);

		-- Fifo input (from DVS AER)
		DVSAERFifoEmpty_SI		 : in  std_logic;
		DVSAERFifoAlmostEmpty_SI : in  std_logic;
		DVSAERFifoRead_SO		 : out std_logic;
		DVSAERFifoData_DI		 : in  std_logic_vector(EVENT_WIDTH-1 downto 0));
end MultiplexerStateMachine;

architecture Behavioral of MultiplexerStateMachine is
	component TimestampGenerator is
		port (
			Clock_CI			 : in  std_logic;
			Reset_RI			 : in  std_logic;
			TimestampRun_SI		 : in  std_logic;
			TimestampReset_SI	 : in  std_logic;
			TimestampOverflow_SO : out std_logic;
			Timestamp_DO		 : out std_logic_vector(TIMESTAMP_WIDTH-1 downto 0));
	end component TimestampGenerator;

	component BufferClear is
		generic (
			INPUT_SIGNAL_POLARITY : std_logic := '1');
		port (
			Clock_CI		: in  std_logic;
			Reset_RI		: in  std_logic;
			Clear_SI		: in  std_logic;
			InputSignal_SI	: in  std_logic;
			OutputSignal_SO : out std_logic);
	end component BufferClear;

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

	type state is (stIdle, stTimestampReset, stTimestampWrap, stTimestamp, stPrepareDVSAER, stDVSAER, stPrepareAPSADC, stAPSADC, stPrepareIMU, stIMU, stDrop);

	attribute syn_enum_encoding			 : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

	signal TimestampRun_S	   : std_logic;
	signal TimestampReset_S	   : std_logic;
	signal TimestampOverflow_S : std_logic;
	signal Timestamp_D		   : std_logic_vector(TIMESTAMP_WIDTH-1 downto 0);

	signal TimestampResetBufferClear_S : std_logic;
	signal TimestampResetBufferInput_S : std_logic;
	signal TimestampResetBuffer_S	   : std_logic;

	signal TimestampOverflowBufferClear_S	 : std_logic;
	signal TimestampOverflowBufferEnable_S	 : std_logic;
	signal TimestampOverflowBufferOverflow_S : std_logic;
	signal TimestampOverflowBuffer_D		 : unsigned(OVERFLOW_WIDTH-1 downto 0);

	-- Buffer timestamp here so it's always in sync with the Overflow and Reset
	-- buffers, meaning exactly one cycle behind.
	signal TimestampBuffer_D : std_logic_vector(TIMESTAMP_WIDTH-1 downto 0);
begin
	TimestampResetBufferInput_S		<= FPGATimestampReset_SI or TimestampOverflowBufferOverflow_S;
	TimestampReset_S				<= TimestampResetBufferClear_S;
	TimestampOverflowBufferEnable_S <= TimestampOverflow_S;
	TimestampRun_S					<= FPGARun_SI;

	tsGenerator : TimestampGenerator
		port map (
			Clock_CI			 => Clock_CI,
			Reset_RI			 => Reset_RI,
			TimestampRun_SI		 => TimestampRun_S,
			TimestampReset_SI	 => TimestampReset_S,
			TimestampOverflow_SO => TimestampOverflow_S,
			Timestamp_DO		 => Timestamp_D);

	resetBuffer : BufferClear
		port map (
			Clock_CI		=> Clock_CI,
			Reset_RI		=> Reset_RI,
			Clear_SI		=> TimestampResetBufferClear_S,
			InputSignal_SI	=> TimestampResetBufferInput_S,
			OutputSignal_SO => TimestampResetBuffer_S);

	-- The overflow counter keeps track of wrap events. While there usually
	-- will only be one which will be then sent out right away via USB, it is
	-- theoretically possible for USB to stall and thus for the OutFifo to not
	-- be able to accept new events anymore. In that case we start dropping
	-- data events, but we can't drop wrap events, or the time on the device
	-- will then drift significantly from the time on the host when USB
	-- communication resumes. To avoid this, we keep a count of wrap events and
	-- ensure the wrap event, with it's count, is the first thing sent over
	-- when USB communication resumes (only a timestamp reset event has higher
	-- priority). If communication is down for a very long period of time, we
	-- reach the limit of this counter, and it overflows, at which point it
	-- becomes impossible to maintain any kind of meaningful correspondence
	-- between the device and host time. The only correct solution at this
	-- point is to force a timestamp reset event to be sent, so that both
	-- device and host re-synchronize on zero.
	overflowBuffer : ContinuousCounter
		generic map (
			COUNTER_WIDTH	 => OVERFLOW_WIDTH,
			SHORT_OVERFLOW	 => true,
			OVERFLOW_AT_ZERO => true)
		port map (
			Clock_CI	 => Clock_CI,
			Reset_RI	 => Reset_RI,
			Clear_SI	 => TimestampOverflowBufferClear_S,
			Enable_SI	 => TimestampOverflowBufferEnable_S,
			DataLimit_DI => (others => '1'),
			Overflow_SO	 => TimestampOverflowBufferOverflow_S,
			Data_DO		 => TimestampOverflowBuffer_D);

	p_memoryless : process (State_DP, FPGARun_SI, TimestampResetBuffer_S, TimestampOverflowBuffer_D, TimestampBuffer_D, OutFifoAlmostFull_SI, DVSAERFifoEmpty_SI, DVSAERFifoAlmostEmpty_SI, DVSAERFifoData_DI)
	begin
		State_DN <= State_DP;			-- Keep current state by default.

		TimestampResetBufferClear_S	   <= '0';
		TimestampOverflowBufferClear_S <= '0';

		OutFifoWrite_SO <= '0';
		OutFifoData_DO	<= (others => '0');

		DVSAERFifoRead_SO <= '0';

		case State_DP is
			when stIdle =>
				-- Only exit idle state if FPGA is running.
				if FPGARun_SI = '1' then
					-- Now check various flags and see what data to forward.
					-- Timestamp-related flags have priority over data.
					if OutFifoAlmostFull_SI = '1' then
						-- No space for an event and its timestamp, drop it.
						State_DN <= stDrop;
					elsif TimestampResetBuffer_S = '1' then
						State_DN <= stTimestampReset;
					elsif TimestampOverflowBuffer_D > 0 then
						State_DN <= stTimestampWrap;
					elsif DVSAERFifoAlmostEmpty_SI = '0' then
						State_DN <= stPrepareDVSAER;
					elsif DVSAERFifoEmpty_SI = '0' then
						State_DN <= stPrepareDVSAER;
					end if;
				end if;

			when stTimestampReset =>
				-- Send timestamp reset (back to zero) event to host.
				OutFifoData_DO				   <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_TIMESTAMP_RESET;
				TimestampResetBufferClear_S	   <= '1';
				-- Also clean overflow counter, since a timestamp reset event
				-- has higher priority and invalidates all previous time
				-- information by restarting from zero at this point.
				TimestampOverflowBufferClear_S <= '1';

				OutFifoWrite_SO <= '1';
				State_DN		<= stIdle;

			when stTimestampWrap =>
				-- Send timestamp wrap (add 15 bits) event to host.
				OutFifoData_DO				   <= EVENT_CODE_TIMESTAMP_WRAP & std_logic_vector(TimestampOverflowBuffer_D);
				TimestampOverflowBufferClear_S <= '1';

				OutFifoWrite_SO <= '1';
				State_DN		<= stIdle;

			when stTimestamp =>
				-- Write a timestamp AFTER the event it refers to.
				-- This way the state machine can jump from any event-passing
				-- state to this one, and then back to stIdle. The other way
				-- around requires either more memory to remember what kind of
				-- data we wanted to forward, or one state for each event
				-- needing a timestamp (like old code did).
				if TimestampOverflowBuffer_D > 0 then
					-- The timestamp wrapped around! This means the current
					-- Timestamp_D is zero. But since we're here, we didn't
					-- yet have time to handle this and send a TS_WRAP event.
					-- So we use a hard-coded timestamp of all ones, the
					-- biggest possible timestamp, right before a TS_WRAP
					-- event actually happens.
					OutFifoData_DO <= (EVENT_CODE_TIMESTAMP, others => '1');
				else
					-- Use current timestamp.
					-- This is also fine if a timestamp reset is pending, since
					-- in that case timestamps are still valid until the reset
					-- itself happens.
					OutFifoData_DO <= EVENT_CODE_TIMESTAMP & TimestampBuffer_D;
				end if;

				OutFifoWrite_SO <= '1';
				State_DN		<= stIdle;

			when stPrepareDVSAER =>
				DVSAERFifoRead_SO <= '1';
				State_DN		  <= stDVSAER;

			when stDVSAER =>
				-- Write out current event.
				OutFifoData_DO	<= DVSAERFifoData_DI;
				OutFifoWrite_SO <= '1';

				-- The next event on the DVS AER fifo has just been read and
				-- the data is available on the output bus. First, let's
				-- examine it and see if we need to inject a timestamp,
				-- if it's an Y (row) address.
				if DVSAERFifoData_DI(EVENT_WIDTH-1 downto EVENT_WIDTH-4) = EVENT_CODE_Y_ADDR then
					State_DN <= stTimestamp;
				else
					State_DN <= stIdle;
				end if;

			when stPrepareAPSADC =>

			when stAPSADC =>

			when stPrepareIMU =>

			when stIMU =>

			when stDrop =>
				-- Drop events while the output fifo is full. This guarantees
				-- a continuous flow of events from the data producers and
				-- disallows a backlog of old events to remain around, which
				-- would be timestamped incorrectly after long delays.
				State_DN <= stIdle;

			when others => null;
		end case;
	end process p_memoryless;

	-- Change state on clock edge (synchronous).
	p_memoryzing : process (Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then	-- asynchronous reset (active-high for FPGAs)
			State_DP		  <= stIdle;
			TimestampBuffer_D <= (others => '0');
		elsif rising_edge(Clock_CI) then
			State_DP		  <= State_DN;
			TimestampBuffer_D <= Timestamp_D;
		end if;
	end process p_memoryzing;
end Behavioral;
