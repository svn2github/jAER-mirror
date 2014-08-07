library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.MultiplexerConfigRecords.all;

entity MultiplexerStateMachine is
	port(
		Clock_CI                 : in  std_logic;
		Reset_RI                 : in  std_logic;

		-- Fifo output (to USB)
		OutFifoControl_SI        : in  tFromFifoWriteSide;
		OutFifoControl_SO        : out tToFifoWriteSide;
		OutFifoData_DO           : out std_logic_vector(FULL_EVENT_WIDTH - 1 downto 0);

		-- Fifo input (from DVS AER)
		DVSAERFifoControl_SI     : in  tFromFifoReadSide;
		DVSAERFifoControl_SO     : out tToFifoReadSide;
		DVSAERFifoData_DI        : in  std_logic_vector(EVENT_WIDTH - 1 downto 0);

		-- Fifo input (from APS ADC)
		APSADCFifoControl_SI     : in  tFromFifoReadSide;
		APSADCFifoControl_SO     : out tToFifoReadSide;
		APSADCFifoData_DI        : in  std_logic_vector(EVENT_WIDTH - 1 downto 0);

		-- Fifo input (from IMU)
		IMUFifoControl_SI        : in  tFromFifoReadSide;
		IMUFifoControl_SO        : out tToFifoReadSide;
		IMUFifoData_DI           : in  std_logic_vector(EVENT_WIDTH - 1 downto 0);

		-- Fifo input (from External Trigger)
		ExtTriggerFifoControl_SI : in  tFromFifoReadSide;
		ExtTriggerFifoControl_SO : out tToFifoReadSide;
		ExtTriggerFifoData_DI    : in  std_logic_vector(EVENT_WIDTH - 1 downto 0);

		-- Configuration input
		MultiplexerConfig_DI     : in  tMultiplexerConfig);
end MultiplexerStateMachine;

architecture Behavioral of MultiplexerStateMachine is
	type state is (stIdle, stTimestampReset, stTimestampWrap, stTimestamp, stPrepareDVSAER, stDVSAER, stPrepareAPSADC, stAPSADC, stPrepareIMU, stIMU, stPrepareExtTrigger, stExtTrigger, stDropData);

	attribute syn_enum_encoding : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

	signal TimestampOverflow_S : std_logic;
	signal Timestamp_D         : std_logic_vector(TIMESTAMP_WIDTH - 1 downto 0);

	signal TimestampResetExternalDetected_S : std_logic;
	signal TimestampResetBufferClear_S      : std_logic;
	signal TimestampResetBufferInput_S      : std_logic;
	signal TimestampResetBuffer_S           : std_logic;

	signal TimestampOverflowBufferClear_S    : std_logic;
	signal TimestampOverflowBufferOverflow_S : std_logic;
	signal TimestampOverflowBuffer_D         : unsigned(OVERFLOW_WIDTH - 1 downto 0);

	-- Buffer timestamp here so it's always in sync with the Overflow and Reset
	-- buffers, meaning exactly one cycle behind.
	signal TimestampBuffer_D : std_logic_vector(TIMESTAMP_WIDTH - 1 downto 0);

	signal MultiplexerConfigReg_D : tMultiplexerConfig;
begin
	tsGenerator : entity work.TimestampGenerator
		port map(
			Clock_CI             => Clock_CI,
			Reset_RI             => Reset_RI,
			TimestampRun_SI      => MultiplexerConfigReg_D.TimestampRun_S,
			TimestampReset_SI    => TimestampResetBufferClear_S,
			TimestampOverflow_SO => TimestampOverflow_S,
			Timestamp_DO         => Timestamp_D);

	tsResetExternalDetector : entity work.PulseDetector
		generic map(
			PULSE_MINIMAL_LENGTH_CYCLES => 50)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			InputSignal_SI   => MultiplexerConfigReg_D.TimestampReset_S,
			PulseDetected_SO => TimestampResetExternalDetected_S);

	TimestampResetBufferInput_S <= TimestampResetExternalDetected_S or TimestampOverflowBufferOverflow_S;

	tsResetBuffer : entity work.BufferClear
		port map(
			Clock_CI        => Clock_CI,
			Reset_RI        => Reset_RI,
			Clear_SI        => TimestampResetBufferClear_S,
			InputSignal_SI  => TimestampResetBufferInput_S,
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
			SIZE    => OVERFLOW_WIDTH,
			SHORT_OVERFLOW   => true,
			OVERFLOW_AT_ZERO => true)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => TimestampOverflowBufferClear_S,
			Enable_SI    => TimestampOverflow_S,
			DataLimit_DI => (others => '1'),
			Overflow_SO  => TimestampOverflowBufferOverflow_S,
			Data_DO      => TimestampOverflowBuffer_D);

	p_memoryless : process(State_DP, TimestampResetBuffer_S, TimestampOverflowBuffer_D, TimestampBuffer_D, OutFifoControl_SI, DVSAERFifoControl_SI, DVSAERFifoData_DI, APSADCFifoControl_SI, APSADCFifoData_DI, IMUFifoControl_SI, IMUFifoData_DI, ExtTriggerFifoControl_SI, ExtTriggerFifoData_DI, MultiplexerConfigReg_D)
	begin
		State_DN <= State_DP;           -- Keep current state by default.

		TimestampResetBufferClear_S    <= '0';
		TimestampOverflowBufferClear_S <= '0';

		OutFifoControl_SO.Write_S <= '0';
		OutFifoData_DO            <= (others => '0');

		DVSAERFifoControl_SO.Read_S     <= '0';
		APSADCFifoControl_SO.Read_S     <= '0';
		IMUFifoControl_SO.Read_S        <= '0';
		ExtTriggerFifoControl_SO.Read_S <= '0';

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
							-- prioritize those over the others.
							if DVSAERFifoControl_SI.AlmostEmpty_S = '0' then
								State_DN <= stPrepareDVSAER;
							elsif DVSAERFifoControl_SI.Empty_S = '0' then
								State_DN <= stPrepareDVSAER;
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
				end if;

			when stTimestampReset =>
				-- Send timestamp reset (back to zero) event to host.
				OutFifoData_DO                 <= EVENT_CODE_EVENT & EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_TIMESTAMP_RESET;
				TimestampResetBufferClear_S    <= '1';
				-- Also clean overflow counter, since a timestamp reset event
				-- has higher priority and invalidates all previous time
				-- information by restarting from zero at this point.
				TimestampOverflowBufferClear_S <= '1';

				OutFifoControl_SO.Write_S <= '1';
				State_DN                  <= stIdle;

			when stTimestampWrap =>
				-- Send timestamp wrap (add 15 bits) event to host.
				OutFifoData_DO                 <= EVENT_CODE_EVENT & EVENT_CODE_TIMESTAMP_WRAP & std_logic_vector(TimestampOverflowBuffer_D);
				TimestampOverflowBufferClear_S <= '1';

				OutFifoControl_SO.Write_S <= '1';
				State_DN                  <= stIdle;

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

				OutFifoControl_SO.Write_S <= '1';
				State_DN                  <= stIdle;

			when stPrepareDVSAER =>
				DVSAERFifoControl_SO.Read_S <= '1';
				State_DN                    <= stDVSAER;

			when stDVSAER =>
				-- Write out current event.
				OutFifoData_DO            <= EVENT_CODE_EVENT & DVSAERFifoData_DI;
				OutFifoControl_SO.Write_S <= '1';

				-- The next event on the DVS AER fifo has just been read and
				-- the data is available on the output bus. First, let's
				-- examine it and see if we need to inject a timestamp,
				-- if it's an Y (row) address.
				if DVSAERFifoData_DI(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) = EVENT_CODE_Y_ADDR then
					State_DN <= stTimestamp;
				else
					State_DN <= stIdle;
				end if;

			when stPrepareAPSADC =>
				APSADCFifoControl_SO.Read_S <= '1';
				State_DN                    <= stAPSADC;

			when stAPSADC =>
				-- Write out current event.
				OutFifoData_DO            <= EVENT_CODE_EVENT & APSADCFifoData_DI;
				OutFifoControl_SO.Write_S <= '1';

				-- The next event on the APS ADC fifo has just been read and
				-- the data is available on the output bus. First, let's
				-- examine it and see if we need to inject a timestamp,
				-- if it's one of the special events (SOE, EOE, SOSRR, ...).
				if APSADCFifoData_DI(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) = EVENT_CODE_SPECIAL then
					State_DN <= stTimestamp;
				else
					State_DN <= stIdle;
				end if;

			when stPrepareIMU =>
				IMUFifoControl_SO.Read_S <= '1';
				State_DN                 <= stIMU;

			when stIMU =>
				-- Write out current event.
				OutFifoData_DO            <= EVENT_CODE_EVENT & IMUFifoData_DI;
				OutFifoControl_SO.Write_S <= '1';

				-- The next event on the IMU fifo has just been read and
				-- the data is available on the output bus. First, let's
				-- examine it and see if we need to inject a timestamp,
				-- if it's one of the special events (Gyro axes, Accel axes, ...).
				if IMUFifoData_DI(EVENT_DATA_WIDTH_MAX - 1 downto 0) = EVENT_CODE_SPECIAL_IMU_START6 then
					State_DN <= stTimestamp;
				else
					State_DN <= stIdle;
				end if;

			when stPrepareExtTrigger =>
				ExtTriggerFifoControl_SO.Read_S <= '1';
				State_DN                        <= stExtTrigger;

			when stExtTrigger =>
				-- Write out current event.
				OutFifoData_DO            <= EVENT_CODE_EVENT & ExtTriggerFifoData_DI;
				OutFifoControl_SO.Write_S <= '1';

				-- The next event on the APS ADC fifo has just been read and
				-- the data is available on the output bus. All external
				-- trigger events have to be timestamped.
				State_DN <= stTimestamp;

			when stDropData =>
				-- Drop events while the output fifo is full. This guarantees
				-- a continuous flow of events from the data producers and
				-- disallows a backlog of old events to remain around, which
				-- would be timestamped incorrectly after long delays.
				if DVSAERFifoControl_SI.Empty_S = '0' then
					DVSAERFifoControl_SO.Read_S <= '1';
				end if;
				if APSADCFifoControl_SI.Empty_S = '0' then
					APSADCFifoControl_SO.Read_S <= '1';
				end if;
				if IMUFifoControl_SI.Empty_S = '0' then
					IMUFifoControl_SO.Read_S <= '1';
				end if;
				if ExtTriggerFifoControl_SI.Empty_S = '0' then
					ExtTriggerFifoControl_SO.Read_S <= '1';
				end if;

				State_DN <= stIdle;

			when others => null;
		end case;
	end process p_memoryless;

	-- Change state on clock edge (synchronous).
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;

			TimestampBuffer_D <= (others => '0');

			MultiplexerConfigReg_D <= tMultiplexerConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			TimestampBuffer_D <= Timestamp_D;

			MultiplexerConfigReg_D <= MultiplexerConfig_DI;
		end if;
	end process p_memoryzing;
end Behavioral;
