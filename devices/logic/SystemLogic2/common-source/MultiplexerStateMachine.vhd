library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.MultiplexerConfigRecords.all;

entity MultiplexerStateMachine is
	port(
		Clock_CI             : in  std_logic;
		Reset_RI             : in  std_logic;

		-- Multiple devices synchronization support.
		SyncInClock_CI       : in  std_logic;
		SyncOutClock_CO      : out std_logic;

		DeviceIsMaster_SO    : out std_logic;

		-- Fifo output (to USB)
		OutFifoControl_SI    : in  tFromFifoWriteSide;
		OutFifoControl_SO    : out tToFifoWriteSide;
		OutFifoData_DO       : out std_logic_vector(FULL_EVENT_WIDTH - 1 downto 0);

		-- Fifo input (from Input1)
		In1FifoControl_SI    : in  tFromFifoReadSide;
		In1FifoControl_SO    : out tToFifoReadSide;
		In1FifoData_DI       : in  std_logic_vector(EVENT_WIDTH - 1 downto 0);
		In1Timestamp_SI      : in  std_logic;

		-- Fifo input (from Input2)
		In2FifoControl_SI    : in  tFromFifoReadSide;
		In2FifoControl_SO    : out tToFifoReadSide;
		In2FifoData_DI       : in  std_logic_vector(EVENT_WIDTH - 1 downto 0);
		In2Timestamp_SI      : in  std_logic;

		-- Fifo input (from Input3)
		In3FifoControl_SI    : in  tFromFifoReadSide;
		In3FifoControl_SO    : out tToFifoReadSide;
		In3FifoData_DI       : in  std_logic_vector(EVENT_WIDTH - 1 downto 0);
		In3Timestamp_SI      : in  std_logic;

		-- Fifo input (from Input4)
		In4FifoControl_SI    : in  tFromFifoReadSide;
		In4FifoControl_SO    : out tToFifoReadSide;
		In4FifoData_DI       : in  std_logic_vector(EVENT_WIDTH - 1 downto 0);
		In4Timestamp_SI      : in  std_logic;

		-- Configuration input
		MultiplexerConfig_DI : in  tMultiplexerConfig);
end MultiplexerStateMachine;

architecture Behavioral of MultiplexerStateMachine is
	attribute syn_enum_encoding : string;

	type tState is (stIdle, stTimestampReset, stTimestampWrap, stTimestamp, stPrepareInput1, stInput1, stPrepareInput2, stInput2, stPrepareInput3, stInput3, stPrepareInput4, stInput4, stDropData);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- present and next state
	signal State_DP, State_DN                           : tState;
	signal StateTimestampNext_DP, StateTimestampNext_DN : tState;

	signal TimestampOverflow_S : std_logic;
	signal Timestamp_D         : unsigned(TIMESTAMP_WIDTH - 1 downto 0);

	-- Communication between TS synchronizer and generator.
	signal TimestampInc_S, TimestampReset_S : std_logic;

	-- Timestamp reset support. Either external (host) or internal (ovreflow counter overflow).
	signal TimestampResetExternalDetected_S : std_logic;
	signal TimestampResetBufferClear_S      : std_logic;
	signal TimestampResetBuffer_S           : std_logic;

	signal TimestampOverflowBufferClear_S    : std_logic;
	signal TimestampOverflowBufferOverflow_S : std_logic;
	signal TimestampOverflowBuffer_D         : unsigned(OVERFLOW_WIDTH - 1 downto 0);

	-- Buffer timestamp here so it's always in sync with the Overflow and Reset
	-- buffers, meaning delayed by one cycle.
	signal TimestampBuffer_D : unsigned(TIMESTAMP_WIDTH - 1 downto 0);

	signal TimestampChanged_S, TimestampSent_S : std_logic;

	signal HighestTimestampSent_SP, HighestTimestampSent_SN : std_logic;

	signal MultiplexerConfigReg_D : tMultiplexerConfig;
begin
	tsSynchronizer : entity work.TimestampSynchronizer
		port map(
			Clock_CI          => Clock_CI,
			Reset_RI          => Reset_RI,
			SyncInClock_CI    => SyncInClock_CI,
			SyncOutClock_CO   => SyncOutClock_CO,
			DeviceIsMaster_SO => DeviceIsMaster_SO,
			TimestampRun_SI   => MultiplexerConfigReg_D.TimestampRun_S,
			TimestampReset_SI => TimestampResetExternalDetected_S or TimestampOverflowBufferOverflow_S,
			TimestampInc_SO   => TimestampInc_S,
			TimestampReset_SO => TimestampReset_S);

	tsGenerator : entity work.TimestampGenerator
		port map(
			Clock_CI             => Clock_CI,
			Reset_RI             => Reset_RI,
			TimestampInc_SI      => TimestampInc_S,
			TimestampReset_SI    => TimestampResetBufferClear_S,
			TimestampOverflow_SO => TimestampOverflow_S,
			Timestamp_DO         => Timestamp_D);

	tsResetExternalDetector : entity work.PulseDetector
		generic map(
			SIZE => 2)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			PulsePolarity_SI => '1',
			PulseLength_DI   => to_unsigned(2, 2),
			InputSignal_SI   => MultiplexerConfigReg_D.TimestampReset_S,
			PulseDetected_SO => TimestampResetExternalDetected_S);

	tsResetBuffer : entity work.BufferClear
		port map(
			Clock_CI        => Clock_CI,
			Reset_RI        => Reset_RI,
			Clear_SI        => TimestampResetBufferClear_S,
			InputSignal_SI  => TimestampReset_S,
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
	tsOverflowBuffer : entity work.ContinuousCounter
		generic map(
			SIZE                => OVERFLOW_WIDTH,
			SHORT_OVERFLOW      => true,
			OVERFLOW_AT_ZERO    => true,
			OVERFLOW_OUT_BUFFER => true)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => TimestampOverflowBufferClear_S,
			Enable_SI    => TimestampOverflow_S,
			DataLimit_DI => (others => '1'),
			Overflow_SO  => TimestampOverflowBufferOverflow_S,
			Data_DO      => TimestampOverflowBuffer_D);

	timestampChangeDetector : entity work.ChangeDetector
		generic map(
			SIZE => TIMESTAMP_WIDTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => std_logic_vector(Timestamp_D),
			ChangeDetected_SO     => TimestampChanged_S,
			ChangeAcknowledged_SI => TimestampSent_S);

	p_memoryless : process(State_DP, StateTimestampNext_DP, TimestampResetBuffer_S, TimestampOverflowBuffer_D, TimestampBuffer_D, HighestTimestampSent_SP, TimestampChanged_S, OutFifoControl_SI, In1FifoControl_SI, In1FifoData_DI, In2FifoControl_SI, In2FifoData_DI, In3FifoControl_SI, In3FifoData_DI, In4FifoControl_SI, In4FifoData_DI, MultiplexerConfigReg_D, In1Timestamp_SI, In2Timestamp_SI, In3Timestamp_SI, In4Timestamp_SI)
	begin
		State_DN              <= State_DP; -- Keep current state by default.
		StateTimestampNext_DN <= stTimestamp;

		HighestTimestampSent_SN <= HighestTimestampSent_SP;

		TimestampResetBufferClear_S    <= '0';
		TimestampOverflowBufferClear_S <= '0';
		TimestampSent_S                <= '0';

		OutFifoControl_SO.Write_S <= '0';
		OutFifoData_DO            <= (others => '0');

		In1FifoControl_SO.Read_S <= '0';
		In2FifoControl_SO.Read_S <= '0';
		In3FifoControl_SO.Read_S <= '0';
		In4FifoControl_SO.Read_S <= '0';

		case State_DP is
			when stIdle =>
				-- Only exit idle state if logic is running.
				if MultiplexerConfigReg_D.Run_S = '1' then
					-- Now check various flags and see what data to forward.
					-- Timestamp-related flags have priority over data.
					if OutFifoControl_SI.Full_S = '0' then
						if TimestampResetBuffer_S = '1' then
							State_DN <= stTimestampReset;
						elsif TimestampOverflowBuffer_D > 0 then
							State_DN <= stTimestampWrap;
						elsif OutFifoControl_SI.AlmostFull_S = '0' then
							-- Use the AlmostEmpty flags as markers to see if
							-- there is lots of data in the FIFOs and
							-- prioritize emptying these over others.
							-- First check the AlmostEmpty flags, which are set
							-- to indicate a higher fullness level.
							if In1FifoControl_SI.AlmostEmpty_S = '0' then
								State_DN <= stPrepareInput1;
							elsif In2FifoControl_SI.AlmostEmpty_S = '0' then
								State_DN <= stPrepareInput2;
							elsif In3FifoControl_SI.AlmostEmpty_S = '0' then
								State_DN <= stPrepareInput3;
							elsif In4FifoControl_SI.AlmostEmpty_S = '0' then
								State_DN <= stPrepareInput4;
							elsif In1FifoControl_SI.Empty_S = '0' then
								State_DN <= stPrepareInput1;
							elsif In2FifoControl_SI.Empty_S = '0' then
								State_DN <= stPrepareInput2;
							elsif In3FifoControl_SI.Empty_S = '0' then
								State_DN <= stPrepareInput3;
							elsif In4FifoControl_SI.Empty_S = '0' then
								State_DN <= stPrepareInput4;
							end if;
						else
							-- No space for an event and its timestamp, drop it.
							State_DN <= stDropData;
						end if;
					else
						-- No space for even timestamp flags, drop data to
						-- ensure flow continues.
						State_DN <= stDropData;
					end if;
				else
					-- If not running, just drain the FIFOs.
					if In1FifoControl_SI.Empty_S = '0' then
						In1FifoControl_SO.Read_S <= '1';
					end if;

					if In2FifoControl_SI.Empty_S = '0' then
						In2FifoControl_SO.Read_S <= '1';
					end if;

					if In3FifoControl_SI.Empty_S = '0' then
						In3FifoControl_SO.Read_S <= '1';
					end if;

					if In4FifoControl_SI.Empty_S = '0' then
						In4FifoControl_SO.Read_S <= '1';
					end if;
				end if;

			when stTimestampReset =>
				-- Send timestamp reset (back to zero) event to host.
				OutFifoData_DO                 <= EVENT_CODE_EVENT & EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_TIMESTAMP_RESET;
				TimestampResetBufferClear_S    <= '1';
				-- Also clean overflow counter, since a timestamp reset event
				-- has higher priority and invalidates all previous time
				-- information by restarting from zero at this point.
				TimestampOverflowBufferClear_S <= '1';
				HighestTimestampSent_SN        <= '0';

				OutFifoControl_SO.Write_S <= '1';
				State_DN                  <= stIdle;

			when stTimestampWrap =>
				-- Send timestamp wrap (add 15 bits) event to host.
				OutFifoData_DO                 <= EVENT_CODE_EVENT & EVENT_CODE_TIMESTAMP_WRAP & std_logic_vector(TimestampOverflowBuffer_D);
				TimestampOverflowBufferClear_S <= '1';
				HighestTimestampSent_SN        <= '0';

				OutFifoControl_SO.Write_S <= '1';
				State_DN                  <= stIdle;

			when stTimestamp =>
				if TimestampChanged_S = '1' then
					-- Timestamp changed from the last time we tried to send one, so
					-- this time we really send one and acknowledge the change.
					TimestampSent_S <= '1';

					-- Write a timestamp before the event it refers to.
					if TimestampOverflowBuffer_D > 0 and HighestTimestampSent_SP = '0' then
						-- The timestamp wrapped around! This means the current
						-- TimestampBuffer_D is zero. But since we're here, we didn't
						-- yet have time to handle this and send a TS_WRAP event.
						-- So we use a hard-coded timestamp of all ones, the
						-- biggest possible timestamp, right before a TS_WRAP
						-- event actually happens.
						OutFifoData_DO            <= (EVENT_CODE_TIMESTAMP, others => '1');
						OutFifoControl_SO.Write_S <= '1';
					elsif TimestampBuffer_D /= 0 then
						-- Use current timestamp.
						-- Ensure that no zero timestamps are ever sent. This further
						-- reduces traffic, as zero can always be inferred.
						-- This is also fine if a timestamp reset is pending, since
						-- in that case timestamps are still valid until the reset
						-- itself happens.
						OutFifoData_DO            <= EVENT_CODE_TIMESTAMP & std_logic_vector(TimestampBuffer_D);
						OutFifoControl_SO.Write_S <= '1';

						-- Check if the timestamp we're just sending is the highest possible one (all 1s).
						-- If it is, we keep that in mind, so that we can ensure it isn't sent a second
						-- time when the above case of "overflow while timestamping" happens. This way
						-- we can actually guarantee strict monotonicity of timestamps.
						if TimestampBuffer_D = (TimestampBuffer_D'range => '1') then
							HighestTimestampSent_SN <= '1';
						end if;
					end if;
				end if;

				State_DN <= StateTimestampNext_DP;

			when stPrepareInput1 =>
				-- Decide if event needs to be timestamped.
				if In1Timestamp_SI = '1' then
					State_DN              <= stTimestamp;
					StateTimestampNext_DN <= stInput1;
				else
					State_DN <= stInput1;
				end if;

			when stInput1 =>
				-- Write out current event.
				OutFifoData_DO            <= EVENT_CODE_EVENT & In1FifoData_DI;
				OutFifoControl_SO.Write_S <= '1';

				In1FifoControl_SO.Read_S <= '1';
				State_DN                 <= stIdle;

			when stPrepareInput2 =>
				-- Decide if event needs to be timestamped.
				if In2Timestamp_SI = '1' then
					State_DN              <= stTimestamp;
					StateTimestampNext_DN <= stInput2;
				else
					State_DN <= stInput2;
				end if;

			when stInput2 =>
				-- Write out current event.
				OutFifoData_DO            <= EVENT_CODE_EVENT & In2FifoData_DI;
				OutFifoControl_SO.Write_S <= '1';

				In2FifoControl_SO.Read_S <= '1';
				State_DN                 <= stIdle;

			when stPrepareInput3 =>
				-- Decide if event needs to be timestamped.
				if In3Timestamp_SI = '1' then
					State_DN              <= stTimestamp;
					StateTimestampNext_DN <= stInput3;
				else
					State_DN <= stInput3;
				end if;

			when stInput3 =>
				-- Write out current event.
				OutFifoData_DO            <= EVENT_CODE_EVENT & In3FifoData_DI;
				OutFifoControl_SO.Write_S <= '1';

				In3FifoControl_SO.Read_S <= '1';
				State_DN                 <= stIdle;

			when stPrepareInput4 =>
				-- Decide if event needs to be timestamped.
				if In4Timestamp_SI = '1' then
					State_DN              <= stTimestamp;
					StateTimestampNext_DN <= stInput4;
				else
					State_DN <= stInput4;
				end if;

			when stInput4 =>
				-- Write out current event.
				OutFifoData_DO            <= EVENT_CODE_EVENT & In4FifoData_DI;
				OutFifoControl_SO.Write_S <= '1';

				In4FifoControl_SO.Read_S <= '1';
				State_DN                 <= stIdle;

			when stDropData =>
				-- Drop events while the output fifo is full. This guarantees
				-- a continuous flow of events from the data producers and
				-- disallows a backlog of old events to remain around, which
				-- would be timestamped incorrectly after long delays.
				-- This is fully configurable from the host.
				if MultiplexerConfigReg_D.DropInput1OnTransferStall_S = '1' and In1FifoControl_SI.Empty_S = '0' then
					In1FifoControl_SO.Read_S <= '1';
				end if;

				if MultiplexerConfigReg_D.DropInput2OnTransferStall_S = '1' and In2FifoControl_SI.Empty_S = '0' then
					In2FifoControl_SO.Read_S <= '1';
				end if;

				if MultiplexerConfigReg_D.DropInput3OnTransferStall_S = '1' and In3FifoControl_SI.Empty_S = '0' then
					In3FifoControl_SO.Read_S <= '1';
				end if;

				if MultiplexerConfigReg_D.DropInput4OnTransferStall_S = '1' and In4FifoControl_SI.Empty_S = '0' then
					In4FifoControl_SO.Read_S <= '1';
				end if;

				State_DN <= stIdle;

			when others => null;
		end case;
	end process p_memoryless;

	-- Change state on clock edge (synchronous).
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP              <= stIdle;
			StateTimestampNext_DP <= stTimestamp;

			HighestTimestampSent_SP <= '0';
			TimestampBuffer_D       <= (others => '0');

			MultiplexerConfigReg_D <= tMultiplexerConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP              <= State_DN;
			StateTimestampNext_DP <= StateTimestampNext_DN;

			HighestTimestampSent_SP <= HighestTimestampSent_SN;
			TimestampBuffer_D       <= Timestamp_D;

			MultiplexerConfigReg_D <= MultiplexerConfig_DI;
		end if;
	end process p_memoryzing;
end Behavioral;
