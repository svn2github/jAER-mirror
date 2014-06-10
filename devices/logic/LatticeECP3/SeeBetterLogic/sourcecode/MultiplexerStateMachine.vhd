library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.all;

entity MultiplexerStateMachine is
	port (
		Clock_CI   : in std_logic;
		Reset_RI   : in std_logic;
		FPGARun_SI : in std_logic;

		-- Timestamp related inputs.
		TimestampReset_SI	 : in std_logic;
		TimestampOverflow_SI : in std_logic;
		Timestamp_DI		 : in std_logic_vector(TIMESTAMP_WIDTH-1 downto 0);

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
	component BufferClear is
		generic (
			SIGNAL_POLARITY : std_logic := '1');
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
			RESET_ON_OVERFLOW : boolean := true);
		port (
			Clock_CI	 : in  std_logic;
			Reset_RI	 : in  std_logic;
			Clear_SI	 : in  std_logic;
			Enable_SI	 : in  std_logic;
			DataLimit_DI : in  unsigned(COUNTER_WIDTH-1 downto 0);
			Overflow_SO	 : out std_logic;
			Data_DO		 : out unsigned(COUNTER_WIDTH-1 downto 0));
	end component ContinuousCounter;

	type state is (stIdle, stTimestampReset, stTimestampWrap, stTimestamp, stDVSAER, stAPSADC, stIMU, stDrop);

	attribute syn_enum_encoding			 : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

	signal TimestampResetBufferClear_S : std_logic;
	signal TimestampResetBuffer_S	   : std_logic;

	constant OVERFLOW_WIDTH : integer := 12;

	signal TimestampOverflowBufferClear_S : std_logic;
	signal TimestampOverflowBuffer_D	  : unsigned(OVERFLOW_WIDTH-1 downto 0);

	constant CODE_Y_ADDR : std_logic_vector(2 downto 0) := "001";

	-- Buffer timestamp here so it's always in sync with the Overflow and Reset
	-- buffers, meaning exactly one cycle behind.
	signal TimestampBuffer_D : std_logic_vector(TIMESTAMP_WIDTH-1 downto 0);
begin
	resetBuffer : BufferClear
		port map (
			Clock_CI		=> Clock_CI,
			Reset_RI		=> Reset_RI,
			Clear_SI		=> TimestampResetBufferClear_S,
			InputSignal_SI	=> TimestampReset_SI,
			OutputSignal_SO => TimestampResetBuffer_S);

	overflowBuffer : ContinuousCounter
		generic map (
			COUNTER_WIDTH => OVERFLOW_WIDTH)
		port map (
			Clock_CI	 => Clock_CI,
			Reset_RI	 => Reset_RI,
			Clear_SI	 => TimestampOverflowBufferClear_S,
			Enable_SI	 => TimestampOverflow_SI,
			DataLimit_DI => (others => '1'),
			Overflow_SO	 => open,
			Data_DO		 => TimestampOverflowBuffer_D);

	p_memoryless : process (State_DP, FPGARun_SI, TimestampResetBuffer_S, TimestampOverflowBuffer_D, TimestampBuffer_D, OutFifoFull_SI, OutFifoAlmostFull_SI, DVSAERFifoEmpty_SI, DVSAERFifoAlmostEmpty_SI, DVSAERFifoData_DI)
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
					if OutFifoFull_SI = '1' then
						State_DN <= stDrop;
					elsif TimestampResetBuffer_S = '1' then
						State_DN <= stTimestampReset;
					elsif TimestampOverflowBuffer_D > 0 then
						State_DN <= stTimestampWrap;
					elsif DVSAERFifoAlmostEmpty_SI = '0' then
						State_DN		  <= stDVSAER;
						DVSAERFifoRead_SO <= '1';
					elsif DVSAERFifoEmpty_SI = '0' then
						State_DN		  <= stDVSAER;
						DVSAERFifoRead_SO <= '1';
					end if;
				end if;

			when stTimestampReset =>
				-- Send timestamp reset (back to zero) event to host.

			when stTimestampWrap =>
				-- Send timestamp wrap (add 15 bits) event to host.

			when stTimestamp =>
				-- Write a timestamp AFTER the event it refers to.
				-- This way the state machine can jump from any event-passing
				-- state to this one, and then back to stIdle. The other way
				-- around requires either more memory to remember what kind of
				-- data we wanted to forward, or one state for each event
				-- needing a timestamp (like old code did).
				if TimestampOverflowBuffer_D > 1 then
					-- The timestamp wrapped around! This means the current
					-- Timestamp_DI is zero. But since we're here, we didn't
					-- yet have time to handle this and send a TS_WRAP event.
					-- So we use a hard-coded timestamp of all ones, the
					-- biggest possible one before a TS_WRAP event happens.
					OutFifoData_DO <= (others => '1');
				else
					-- Use current timestamp.
					OutFifoData_DO <= "1" & TimestampBuffer_D;
				end if;

				OutFifoWrite_SO <= '1';
				State_DN		<= stIdle;

			when stDVSAER =>
				-- The next event on the DVS AER fifo has just been read and
				-- the data is available on the output bus. First, let's
				-- examine it and see if we need to inject a timestamp,
				-- if it's an Y (row) address.
				if DVSAERFifoData_DI(EVENT_WIDTH-1 downto EVENT_WIDTH-3) = CODE_Y_ADDR then
					State_DN <= stTimestamp;
				else
					State_DN <= stIdle;
				end if;

				--
				OutFifoData_DO	<= "0" & DVSAERFifoData_DI;
				OutFifoWrite_SO <= '1';

			when stAPSADC =>

			when stIMU =>

			when stDrop =>
				-- Drop events while the output fifo is full. This guarantees
				-- a continuous flow of events from the data producers and
				-- disallows a backlog of old events to remain around, which
				-- would be timestamped incorrectly after long delays.


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
			TimestampBuffer_D <= Timestamp_DI;
		end if;
	end process p_memoryzing;
end Behavioral;
