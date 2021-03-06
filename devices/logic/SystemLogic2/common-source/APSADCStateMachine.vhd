library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.APSADCConfigRecords.all;
use work.Settings.ADC_CLOCK_FREQ;
use work.Settings.APS_ADC_BUS_WIDTH;
use work.Settings.CHIP_APS_SIZE_COLUMNS;
use work.Settings.CHIP_APS_SIZE_ROWS;
use work.Settings.CHIP_APS_STREAM_START;
use work.Settings.CHIP_APS_HAS_GLOBAL_SHUTTER;
use work.Settings.CHIP_APS_HAS_INTEGRATED_ADC;

-- Rolling shutter considerations: since the exposure is given by the
-- difference in time between the reset/reset read and the signal read (integration happens
-- while they are carried out), each pass of Reset->ResetRead->SignalRead must have exactly
-- the same timing characteristics, across all columns. This implies that the SignalRead must
-- always happen, so that there is no sudden offset introduced later when the SignalRead is
-- actually sampling values. A 'fake' SignalRead needs thus to be done to provide correct 'time
-- spacing', even when it has not yet been clocked into the column shift register itself.

-- Region Of Interest (ROI) support: both global and rolling shutter modes support specifying
-- a region of the full image to be scanned, instead of the full image. This enables skipping
-- certain sources of delay for pixels outside this given region, which makes for faster scan
-- times, and thus smaller delays and higher frame-rates.
-- In global shutter mode, since the reads are separated from each-other, from reset and from
-- integration, all pixels that are outside an interest region can be easily skipped. The
-- overall timing of the reset and signal reads will be the same.
-- In rolling shutter mode, things get more complex, given the precise 'time spacing' that must
-- be ovserved between the ResetRead and the SignalRead (see 'Rolling shutter considerations'
-- above). To guarantee this, all columns must take the same amount of time to be processed,
-- because if columns that are completely outside of the region of interest would take less time
-- (by just skipping them for example), then you have regions of the image that are traversed at
-- different speeds by the ResetReads and the successive SignalReads, since the SignalReads may
-- overlap with the ResetReads, and then could not just quickly advance the column shift register
-- like the ResetReads did, resulting in timing differences. An easy way to overcome this is by
-- just having all columns go through the same readout process, like if the region of interest
-- were always expanded to fit across all columns equally. This slightly mitigates the
-- advantages of ROI stated above, but is unavoidable with the current scheme.

entity APSADCStateMachine is
	generic(
		ENABLE_QUAD_ROI : boolean := false);
	port(
		Clock_CI                    : in  std_logic; -- This clock must be 30MHz, use PLL to generate.
		Reset_RI                    : in  std_logic; -- This reset must be synchronized to the above clock.

		-- Fifo output (to Multiplexer, must be a dual-clock FIFO)
		OutFifoControl_SI           : in  tFromFifoWriteSide;
		OutFifoControl_SO           : out tToFifoWriteSide;
		OutFifoData_DO              : out std_logic_vector(EVENT_WIDTH - 1 downto 0);

		APSChipColSRClock_CO        : out std_logic;
		APSChipColSRIn_SO           : out std_logic;
		APSChipRowSRClock_CO        : out std_logic;
		APSChipRowSRIn_SO           : out std_logic;
		APSChipColMode_DO           : out std_logic_vector(1 downto 0);
		APSChipTXGate_SBO           : out std_logic;

		ExternalADCData_DI          : in  std_logic_vector(APS_ADC_BUS_WIDTH - 1 downto 0);
		ExternalADCClock_CO         : out std_logic;
		ExternalADCOutputEnable_SBO : out std_logic;
		ExternalADCStandby_SO       : out std_logic;

		ChipADCData_DI              : in  std_logic_vector(APS_ADC_BUS_WIDTH - 1 downto 0);
		ChipADCRampClear_SO         : out std_logic;
		ChipADCRampClock_CO         : out std_logic;
		ChipADCRampBitIn_SO         : out std_logic;
		ChipADCScanClock_CO         : out std_logic;
		ChipADCScanControl_SO       : out std_logic;
		ChipADCSample_SO            : out std_logic;
		ChipADCGrayCounter_DO       : out std_logic_vector(APS_ADC_BUS_WIDTH - 1 downto 0);

		-- Configuration input
		APSADCConfig_DI             : in  tAPSADCConfig);
end entity APSADCStateMachine;

architecture Behavioral of APSADCStateMachine is
	attribute syn_enum_encoding : string;

	type tColumnState is (stIdle, stWaitADCStartup, stStartFrame, stEndFrame, stWaitFrameDelay, stColSRFeedA0, stColSRFeedA0Tick, stColSRFeedA1, stColSRFeedA1Tick, stRSFeedTick, stRSReset, stRSSwitchToReadA, stRSReadA, stRSSwitchToReadB, stRSReadB, stGSReset, stGSReadA, stGSReadB, stGSSwitchToReadA,
		                  stGSSwitchToReadB, stGSStartExposure, stGSEndExposure, stGSReadAFeedTick, stGSReadBFeedTick, stGSColSRFeedB1, stGSColSRFeedB1Tick, stGSColSRFeedB0, stGSColSRFeedB0Tick, stGSSwitchToExposure, stRSSwitchToReset, stGSSwitchToReset, stRSColSRFeedB, stRSColSRFeedBTick, stGSResetClose);
	attribute syn_enum_encoding of tColumnState : type is "onehot";

	-- present and next state
	signal ColState_DP, ColState_DN : tColumnState;

	type tExtRowState is (stIdle, stRowDone, stRowStart, stRowSRFeedInit, stRowSRFeedInitTick, stRowSRFeedTick, stColSettleWait, stRowSettleWait, stRowWriteEvent, stRowFastJump);
	attribute syn_enum_encoding of tExtRowState : type is "onehot";

	-- present and next state
	signal ExtRowState_DP, ExtRowState_DN : tExtRowState;

	constant EXTERNAL_ADC_STARTUP_CYCLES      : integer := 30 * 15; -- At 30MHz, wait 15 microseconds.
	constant EXTERNAL_ADC_STARTUP_CYCLES_SIZE : integer := integer(ceil(log2(real(EXTERNAL_ADC_STARTUP_CYCLES))));

	constant COLMODE_NULL   : std_logic_vector(1 downto 0) := "00";
	constant COLMODE_READA  : std_logic_vector(1 downto 0) := "01";
	constant COLMODE_READB  : std_logic_vector(1 downto 0) := "10";
	constant COLMODE_RESETA : std_logic_vector(1 downto 0) := "11";

	-- Keep track of what type of timing-only (fake) read is happening.
	signal TimingRead_DP, TimingRead_DN : std_logic_vector(1 downto 0);

	-- Take note if the ADC is running already or not. If not, it has to be started.
	signal ExternalADCRunning_SP, ExternalADCRunning_SN : std_logic;

	signal ExternalADCStartupCount_S, ExternalADCStartupDone_S : std_logic;

	-- Exposure time counter.
	signal ExposureClear_S, ExposureDone_S : std_logic;

	-- Frame delay (between consecutive frames) counter.
	signal FrameDelayCount_S, FrameDelayDone_S : std_logic;

	-- Reset time counter (make bigger to allow for long resets if needed).
	signal ResetTimeCount_S, ResetTimeDone_S : std_logic;

	-- Lengthen the NULL states between different, active column states.
	signal NullTimeCount_S, NullTimeDone_S : std_logic;

	-- Column settle time (before first row is read, like an additional offset).
	signal ColSettleTimeCount_S, ColSettleTimeCountChip_S, ColSettleTimeDone_S : std_logic;

	-- Row settle time counter.
	signal RowSettleTimeCount_S, RowSettleTimeDone_S : std_logic;

	-- Column and row read counters.
	signal ColumnReadAPositionZero_S, ColumnReadAPositionInc_S : std_logic;
	signal ColumnReadAPosition_D                               : unsigned(CHIP_APS_SIZE_COLUMNS'range);
	signal ColumnReadBPositionZero_S, ColumnReadBPositionInc_S : std_logic;
	signal ColumnReadBPosition_D                               : unsigned(CHIP_APS_SIZE_COLUMNS'range);
	signal RowReadPositionZero_S, RowReadPositionInc_S         : std_logic;
	signal RowReadPositionZeroChip_S, RowReadPositionIncChip_S : std_logic;
	signal RowReadPosition_D                                   : unsigned(CHIP_APS_SIZE_ROWS'range);

	-- Communication between column and row state machines. Done through a register for full decoupling.
	signal RowReadInProgress_SP, RowReadStart_SN, RowReadDone_SN : std_logic;
	signal RowReadDoneExternal_SN, RowReadDoneChip_SN            : std_logic;

	-- Wait for all row-read parts to be done before sending end-of-frame (EOF) event.
	signal RowReadsAllDone_S : std_logic;

	-- RS: the B read has several very special considerations that must be taken into account.
	-- First, it has to be done only after exposure time expires, before that, it must be faked
	-- to not throw off timing. Secondly, the B read binary pattern is a 1 with a 0 on either
	-- side, which means that it cannot come right after the A pattern; at least one 0 must be
	-- first shifted in. Also, it needs a further 0 to be shifted in after the 1, before B
	-- reads can really begin. We use the following two registers to control this.
	signal ReadBSRStatus_DP, ReadBSRStatus_DN : std_logic_vector(1 downto 0);

	constant RBSTAT_NEED_ZERO_ONE : std_logic_vector(1 downto 0) := "00";
	constant RBSTAT_NEED_ONE      : std_logic_vector(1 downto 0) := "01";
	constant RBSTAT_NEED_ZERO_TWO : std_logic_vector(1 downto 0) := "10";
	constant RBSTAT_NORMAL        : std_logic_vector(1 downto 0) := "11";

	-- Check column and row validity. Used for faster ROI.
	signal CurrentColumnAValid_S, CurrentColumnBValid_S : std_logic;
	signal CurrentRowValid_S                            : std_logic;

	-- Register outputs to FIFO.
	signal OutFifoWriteReg_S, OutFifoWriteRegCol_S, OutFifoWriteRegRow_S                : std_logic;
	signal OutFifoDataRegEnable_S, OutFifoDataRegColEnable_S, OutFifoDataRegRowEnable_S : std_logic;
	signal OutFifoDataReg_D, OutFifoDataRegCol_D, OutFifoDataRegRow_D                   : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	-- Support both external and internal ADCs at the same time (switch at run-time).
	signal OutFifoWriteRegRowExternal_S, OutFifoWriteRegRowChip_S           : std_logic;
	signal OutFifoDataRegRowExternalEnable_S, OutFifoDataRegRowChipEnable_S : std_logic;
	signal OutFifoDataRegRowExternal_D, OutFifoDataRegRowChip_D             : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	-- Register all outputs to chip APS control for clean transitions.
	signal APSChipColSRClockReg_C, APSChipColSRInReg_S : std_logic;
	signal APSChipRowSRClockReg_C, APSChipRowSRInReg_S : std_logic;
	signal APSChipColModeReg_DP, APSChipColModeReg_DN  : std_logic_vector(1 downto 0);
	signal APSChipTXGateReg_SP, APSChipTXGateReg_SN    : std_logic;

	-- Double register configuration input, since it comes from a different clock domain (LogicClock), it
	-- needs to go through a double-flip-flop synchronizer to guarantee correctness.
	signal APSADCConfigSyncReg_D, APSADCConfigReg_D : tAPSADCConfig;
	signal APSADCConfigRegEnable_S                  : std_logic;
begin
	-- Forward 30MHz clock directly to external ADC, if Clock_CI is 30MHz.
	-- Else generate it using a PLL, for when we drive internal ADC faster.
	externalADCClockForward : if ADC_CLOCK_FREQ = 30 generate
	begin
		ExternalADCClock_CO <= Clock_CI;
	end generate externalADCClockForward;

	externalADCClockGenerate : if ADC_CLOCK_FREQ /= 30 generate
	begin
		externalADCClockPLL : entity work.PLL
			generic map(
				CLOCK_FREQ     => ADC_CLOCK_FREQ,
				OUT_CLOCK_FREQ => 30)
			port map(
				Clock_CI    => Clock_CI,
				Reset_RI    => Reset_RI,
				OutClock_CO => ExternalADCClock_CO);
	end generate externalADCClockGenerate;

	adcStartupCounter : entity work.ContinuousCounter
		generic map(
			SIZE => EXTERNAL_ADC_STARTUP_CYCLES_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => ExternalADCStartupCount_S,
			DataLimit_DI => to_unsigned(EXTERNAL_ADC_STARTUP_CYCLES - 1, EXTERNAL_ADC_STARTUP_CYCLES_SIZE),
			Overflow_SO  => ExternalADCStartupDone_S,
			Data_DO      => open);

	colReadAPosition : entity work.ContinuousCounter
		generic map(
			SIZE              => CHIP_APS_SIZE_COLUMNS'length,
			RESET_ON_OVERFLOW => false,
			GENERATE_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => ColumnReadAPositionZero_S,
			Enable_SI    => ColumnReadAPositionInc_S,
			DataLimit_DI => CHIP_APS_SIZE_COLUMNS,
			Overflow_SO  => open,
			Data_DO      => ColumnReadAPosition_D);

	colReadBPosition : entity work.ContinuousCounter
		generic map(
			SIZE              => CHIP_APS_SIZE_COLUMNS'length,
			RESET_ON_OVERFLOW => false,
			GENERATE_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => ColumnReadBPositionZero_S,
			Enable_SI    => ColumnReadBPositionInc_S,
			DataLimit_DI => CHIP_APS_SIZE_COLUMNS,
			Overflow_SO  => open,
			Data_DO      => ColumnReadBPosition_D);

	exposureCounter : entity work.ContinuousCounter
		generic map(
			SIZE              => APS_EXPOSURE_SIZE,
			RESET_ON_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => ExposureClear_S,
			Enable_SI    => '1',
			DataLimit_DI => APSADCConfigReg_D.Exposure_D,
			Overflow_SO  => ExposureDone_S,
			Data_DO      => open);

	frameDelayCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_FRAMEDELAY_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => FrameDelayCount_S,
			DataLimit_DI => APSADCConfigReg_D.FrameDelay_D,
			Overflow_SO  => FrameDelayDone_S,
			Data_DO      => open);

	nullTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_NULLTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => NullTimeCount_S,
			DataLimit_DI => APSADCConfigReg_D.NullSettle_D,
			Overflow_SO  => NullTimeDone_S,
			Data_DO      => open);

	resetTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_RESETTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => ResetTimeCount_S,
			DataLimit_DI => APSADCConfigReg_D.ResetSettle_D,
			Overflow_SO  => ResetTimeDone_S,
			Data_DO      => open);

	columnMainStateMachine : process(ColState_DP, OutFifoControl_SI, ExternalADCRunning_SP, ExternalADCStartupDone_S, APSADCConfigReg_D, RowReadInProgress_SP, NullTimeDone_S, ResetTimeDone_S, APSChipTXGateReg_SP, ColumnReadAPosition_D, ColumnReadBPosition_D, ReadBSRStatus_DP, CurrentColumnAValid_S, CurrentColumnBValid_S, ExposureDone_S, FrameDelayDone_S, RowReadsAllDone_S)
	begin
		ColState_DN <= ColState_DP;     -- Keep current state by default.

		OutFifoWriteRegCol_S      <= '0';
		OutFifoDataRegColEnable_S <= '0';
		OutFifoDataRegCol_D       <= (others => '0');

		ExternalADCRunning_SN     <= ExternalADCRunning_SP;
		ExternalADCStartupCount_S <= '0';

		APSChipColSRClockReg_C <= '0';
		APSChipColSRInReg_S    <= '0';

		APSChipColModeReg_DN <= COLMODE_NULL;
		TimingRead_DN        <= COLMODE_NULL;
		APSChipTXGateReg_SN  <= APSChipTXGateReg_SP;

		ExposureClear_S <= '0';

		FrameDelayCount_S <= '0';

		-- Colum counters.
		ColumnReadAPositionZero_S <= '0';
		ColumnReadAPositionInc_S  <= '0';
		ColumnReadBPositionZero_S <= '0';
		ColumnReadBPositionInc_S  <= '0';

		-- Reset time counter.
		ResetTimeCount_S <= '0';

		-- Null time counter.
		NullTimeCount_S <= '0';

		-- Row SM communication.
		RowReadStart_SN <= '0';

		-- Keep value by default.
		ReadBSRStatus_DN <= ReadBSRStatus_DP;

		-- Only update configuration when in Idle state. Doing so while the frame is being read out
		-- would cause different timing, exposure and read out types, resulting in corrupted frames.
		APSADCConfigRegEnable_S <= '0';

		case ColState_DP is
			when stIdle =>
				if APSADCConfigReg_D.Run_S = '1' then
					-- We want to take samples, so ensure the wanted ADC is working.
					if CHIP_APS_HAS_INTEGRATED_ADC = '1' and APSADCConfigReg_D.UseInternalADC_S = '1' then
						-- Turn off external ADC, if internal is wanted.
						ExternalADCRunning_SN <= '0';

						ColState_DN <= stStartFrame;
					else
						if ExternalADCRunning_SP = '1' then
							-- External ADC wanted and already running, start right away.
							ColState_DN <= stStartFrame;
						else
							-- External ADC wanted but not running, start and then wait.
							ExternalADCRunning_SN <= '1';

							ColState_DN <= stWaitADCStartup;
						end if;
					end if;
				else
					-- Turn external ADC off when not running to reduce current consumption.
					ExternalADCRunning_SN <= '0';

					-- Update config, so that we get changes to Run_S especially.
					APSADCConfigRegEnable_S <= '1';
				end if;

			when stWaitADCStartup =>
				-- Wait 15 microseconds for ADC to start up and be ready for precise conversions.
				if ExternalADCStartupDone_S = '1' then
					ColState_DN <= stStartFrame;
				end if;

				ExternalADCStartupCount_S <= '1';

			when stStartFrame =>
				-- Write out start of frame marker. This and the end of frame marker are the only
				-- two events from this SM that always have to be committed and are never dropped.
				if OutFifoControl_SI.AlmostFull_S = '0' then
					if CHIP_APS_HAS_GLOBAL_SHUTTER = '1' and APSADCConfigReg_D.GlobalShutter_S = '1' then
						if APSADCConfigReg_D.ResetRead_S = '1' then
							OutFifoDataRegCol_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTFRAME_GS;
						else
							OutFifoDataRegCol_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTFRAME_GS_NORST;
						end if;
					else
						if APSADCConfigReg_D.ResetRead_S = '1' then
							OutFifoDataRegCol_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTFRAME_RS;
						else
							OutFifoDataRegCol_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTFRAME_RS_NORST;
						end if;
					end if;

					OutFifoDataRegColEnable_S <= '1';
					OutFifoWriteRegCol_S      <= '1';

					ColState_DN <= stColSRFeedA0;
				end if;

			when stColSRFeedA0 =>
				APSChipColSRClockReg_C <= '0';
				APSChipColSRInReg_S    <= '1';

				ColState_DN <= stColSRFeedA0Tick;

			when stColSRFeedA0Tick =>
				APSChipColSRClockReg_C <= '1';
				APSChipColSRInReg_S    <= '1';

				ColState_DN <= stColSRFeedA1;

			when stColSRFeedA1 =>
				APSChipColSRClockReg_C <= '0';
				APSChipColSRInReg_S    <= '1';

				ColState_DN <= stColSRFeedA1Tick;

			when stColSRFeedA1Tick =>
				APSChipColSRClockReg_C <= '1';
				APSChipColSRInReg_S    <= '1';

				-- RS: open APS TXGate before first reset.
				-- GS: TXGate must be open during reset, or the APS
				-- voltage won't go back up to high as expected.
				APSChipTXGateReg_SN <= '1';

				if CHIP_APS_HAS_GLOBAL_SHUTTER = '1' and APSADCConfigReg_D.GlobalShutter_S = '1' then
					-- Only switch to global shutter on chips supporting it.
					ColState_DN <= stGSSwitchToReset;
				else
					ColState_DN <= stRSSwitchToReset;
				end if;

			when stRSColSRFeedB =>
				APSChipColSRClockReg_C <= '0';
				APSChipColSRInReg_S    <= '1';

				ColState_DN <= stRSColSRFeedBTick;

			when stRSColSRFeedBTick =>
				APSChipColSRClockReg_C <= '1';
				APSChipColSRInReg_S    <= '1';

				ColState_DN <= stRSSwitchToReset;

			when stRSFeedTick =>
				APSChipColSRClockReg_C <= '1';
				APSChipColSRInReg_S    <= '0';

				-- A first zero has just been shifted in.
				if ReadBSRStatus_DP = RBSTAT_NEED_ZERO_ONE then
					ReadBSRStatus_DN <= RBSTAT_NEED_ONE;
				end if;

				-- Check if we're done (read B ended).
				if ColumnReadBPosition_D = CHIP_APS_SIZE_COLUMNS then
					ColState_DN <= stEndFrame;

					-- Close APS TXGate after last read.
					APSChipTXGateReg_SN <= '0';

					-- Reset ReadB status to initial (need at least a zero), for next frame.
					ReadBSRStatus_DN <= RBSTAT_NEED_ZERO_ONE;
				else
					ColState_DN <= stRSSwitchToReset;
				end if;

			when stRSSwitchToReset =>
				-- Ensure we go through another NULL state.
				APSChipColModeReg_DN <= COLMODE_NULL;

				if NullTimeDone_S = '1' then
					ColState_DN <= stRSReset;
				end if;

				NullTimeCount_S <= '1';

			when stRSReset =>
				if ColumnReadAPosition_D = CHIP_APS_SIZE_COLUMNS then
					APSChipColModeReg_DN <= COLMODE_NULL;
					TimingRead_DN        <= COLMODE_RESETA;
				else
					-- Do reset.
					APSChipColModeReg_DN <= COLMODE_RESETA;
				end if;

				if ResetTimeDone_S = '1' then
					APSChipColModeReg_DN <= COLMODE_NULL;

					-- Support not doing the reset read. Halves the traffic and time
					-- requirements, at the expense of image quality.
					if APSADCConfigReg_D.ResetRead_S = '1' then
						ColState_DN <= stRSSwitchToReadA;
					else
						ColState_DN <= stRSSwitchToReadB;

						-- In this case, we must do the things the read A state would
						-- normally do: increase read A position (used for resets).
						ColumnReadAPositionInc_S <= '1';
					end if;

					-- If this is the first A reset, we start exposure.
					-- Exposure starts right as reset is released.
					if ColumnReadAPosition_D = 0 then
						ExposureClear_S <= '1';
					end if;
				end if;

				ResetTimeCount_S <= '1';

			when stRSSwitchToReadA =>
				APSChipColModeReg_DN <= COLMODE_NULL;

				if NullTimeDone_S = '1' then
					-- Start off the Row SM.
					RowReadStart_SN <= '1';
					ColState_DN     <= stRSReadA;
				end if;

				NullTimeCount_S <= '1';

			when stRSReadA =>
				if ColumnReadAPosition_D = CHIP_APS_SIZE_COLUMNS or CurrentColumnAValid_S = '0' then
					APSChipColModeReg_DN <= COLMODE_NULL;
					TimingRead_DN        <= COLMODE_READA;
				else
					-- Do column read A.
					APSChipColModeReg_DN <= COLMODE_READA;
				end if;

				-- Wait for the Row SM to complete its readout.
				if RowReadInProgress_SP = '0' then
					APSChipColModeReg_DN <= COLMODE_NULL;

					ColState_DN              <= stRSSwitchToReadB;
					ColumnReadAPositionInc_S <= '1';
				end if;

			when stRSSwitchToReadB =>
				APSChipColModeReg_DN <= COLMODE_NULL;

				if NullTimeDone_S = '1' then
					-- Start off the Row SM.
					RowReadStart_SN <= '1';
					ColState_DN     <= stRSReadB;
				end if;

				NullTimeCount_S <= '1';

			when stRSReadB =>
				if ReadBSRStatus_DP /= RBSTAT_NORMAL or CurrentColumnBValid_S = '0' then
					APSChipColModeReg_DN <= COLMODE_NULL;
					TimingRead_DN        <= COLMODE_READB;
				else
					-- Do column read B.
					APSChipColModeReg_DN <= COLMODE_READB;
				end if;

				-- Wait for the Row SM to complete its readout.
				if RowReadInProgress_SP = '0' then
					APSChipColModeReg_DN <= COLMODE_NULL;

					-- If exposure time hasn't expired or we haven't yet even shifted in one
					-- 0 into the column SR, we first do that.
					if ExposureDone_S = '1' and ReadBSRStatus_DP /= RBSTAT_NEED_ZERO_ONE then
						if ReadBSRStatus_DP = RBSTAT_NEED_ONE then
							-- If the 1 that represents the B read hasn't yet been shifted
							-- in, do so now.
							ColState_DN      <= stRSColSRFeedB;
							ReadBSRStatus_DN <= RBSTAT_NEED_ZERO_TWO;
						elsif ReadBSRStatus_DP = RBSTAT_NEED_ZERO_TWO then
							-- Shift in the second 0 (the one after the 1) that is needed
							-- for a B read of the very first column to work.
							ColState_DN      <= stRSFeedTick;
							ReadBSRStatus_DN <= RBSTAT_NORMAL;
						else
							-- Finally, B reads are happening, their position is increasing.
							ColState_DN              <= stRSFeedTick;
							ColumnReadBPositionInc_S <= '1';
						end if;
					else
						-- Just shift in a zero.
						ColState_DN <= stRSFeedTick;
					end if;
				end if;

			when stGSSwitchToReset =>
				-- Ensure we go through another NULL state.
				APSChipColModeReg_DN <= COLMODE_NULL;

				if NullTimeDone_S = '1' then
					ColState_DN <= stGSReset;
				end if;

				NullTimeCount_S <= '1';

			when stGSReset =>
				-- Do reset.
				APSChipColModeReg_DN <= COLMODE_RESETA;

				if ResetTimeDone_S = '1' then
					APSChipColModeReg_DN <= COLMODE_NULL;

					-- Close TXGate again after reset.
					APSChipTXGateReg_SN <= '0';

					ColState_DN <= stGSResetClose;
				end if;

				ResetTimeCount_S <= '1';

			when stGSResetClose =>
				APSChipColModeReg_DN <= COLMODE_NULL;

				if NullTimeDone_S = '1' then
					if APSADCConfigReg_D.ResetRead_S = '1' then
						ColState_DN <= stGSSwitchToReadA;
					else
						ColState_DN <= stGSSwitchToExposure;
					end if;
				end if;

				NullTimeCount_S <= '1';

			when stGSSwitchToReadA =>
				APSChipColModeReg_DN <= COLMODE_RESETA;

				if CurrentColumnAValid_S = '1' then
					-- Start off the Row SM.
					RowReadStart_SN <= '1';
					ColState_DN     <= stGSReadA;
				else
					ColState_DN              <= stGSReadAFeedTick;
					ColumnReadAPositionInc_S <= '1';
				end if;

			when stGSReadA =>
				APSChipColModeReg_DN <= COLMODE_READA;

				if RowReadInProgress_SP = '0' then
					APSChipColModeReg_DN <= COLMODE_NULL;

					ColState_DN              <= stGSReadAFeedTick;
					ColumnReadAPositionInc_S <= '1';
				end if;

			when stGSReadAFeedTick =>
				APSChipColSRClockReg_C <= '1';
				APSChipColSRInReg_S    <= '0';

				if ColumnReadAPosition_D = CHIP_APS_SIZE_COLUMNS then
					-- Done with reset read.
					ColState_DN <= stGSStartExposure;
				else
					ColState_DN <= stGSSwitchToReadA;
				end if;

			when stGSSwitchToExposure =>
				-- When not doing any reset read, we need this state to clock in
				-- one zero into the column SR, so that the B pattern is present.
				APSChipColSRClockReg_C <= '1';
				APSChipColSRInReg_S    <= '0';

				ColState_DN <= stGSStartExposure;

			when stGSStartExposure =>
				APSChipColModeReg_DN <= COLMODE_NULL;

				-- TXGate must be open during exposure.
				APSChipTXGateReg_SN <= '1';

				-- Start exposure.
				ExposureClear_S <= '1';
				ColState_DN     <= stGSEndExposure;

			when stGSEndExposure =>
				APSChipColModeReg_DN <= COLMODE_NULL;

				if ExposureDone_S = '1' then
					-- Exposure completed, close TXGate and shift in read pattern.
					APSChipTXGateReg_SN <= '0';
					ColState_DN         <= stGSColSRFeedB1;
				end if;

			when stGSColSRFeedB1 =>
				APSChipColSRClockReg_C <= '0';
				APSChipColSRInReg_S    <= '1';

				ColState_DN <= stGSColSRFeedB1Tick;

			when stGSColSRFeedB1Tick =>
				APSChipColSRClockReg_C <= '1';
				APSChipColSRInReg_S    <= '1';

				ColState_DN <= stGSColSRFeedB0;

			when stGSColSRFeedB0 =>
				APSChipColSRClockReg_C <= '0';
				APSChipColSRInReg_S    <= '0';

				ColState_DN <= stGSColSRFeedB0Tick;

			when stGSColSRFeedB0Tick =>
				APSChipColSRClockReg_C <= '1';
				APSChipColSRInReg_S    <= '0';

				ColState_DN <= stGSSwitchToReadB;

			when stGSSwitchToReadB =>
				APSChipColModeReg_DN <= COLMODE_NULL;

				if CurrentColumnBValid_S = '1' then
					-- Start off the Row SM.
					RowReadStart_SN <= '1';
					ColState_DN     <= stGSReadB;
				else
					ColState_DN              <= stGSReadBFeedTick;
					ColumnReadBPositionInc_S <= '1';
				end if;

			when stGSReadB =>
				APSChipColModeReg_DN <= COLMODE_READB;

				if RowReadInProgress_SP = '0' then
					APSChipColModeReg_DN <= COLMODE_NULL;

					ColState_DN              <= stGSReadBFeedTick;
					ColumnReadBPositionInc_S <= '1';
				end if;

			when stGSReadBFeedTick =>
				APSChipColSRClockReg_C <= '1';
				APSChipColSRInReg_S    <= '0';

				if ColumnReadBPosition_D = CHIP_APS_SIZE_COLUMNS then
					-- Done with signal read.
					ColState_DN <= stEndFrame;
				else
					ColState_DN <= stGSSwitchToReadB;
				end if;

			when stEndFrame =>
				-- Zero column counters too.
				ColumnReadAPositionZero_S <= '1';
				ColumnReadBPositionZero_S <= '1';

				-- Write out end of frame marker. This and the start of frame marker are the only
				-- two events from this SM that always have to be committed and are never dropped.
				if OutFifoControl_SI.AlmostFull_S = '0' and RowReadsAllDone_S = '1' then
					OutFifoDataRegCol_D       <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_ENDFRAME;
					OutFifoDataRegColEnable_S <= '1';
					OutFifoWriteRegCol_S      <= '1';

					ColState_DN <= stWaitFrameDelay;
				end if;

			when stWaitFrameDelay =>
				-- Wait until enough time has passed between frames.
				if FrameDelayDone_S = '1' then
					ColState_DN <= stIdle;

					-- Ensure config reg is up-to-date when entering Idle state.
					APSADCConfigRegEnable_S <= '1';
				end if;

				FrameDelayCount_S <= '1';

			when others => null;
		end case;
	end process columnMainStateMachine;

	apsStandardROI : if ENABLE_QUAD_ROI = false generate
	begin
		-- Concurrently calculate if the current column or row has to be read out or not.
		-- If not (like with ROI), we can just fast jump past it.
		apsColumnROI : if CHIP_APS_STREAM_START(1) = '0' generate
		begin
			CurrentColumnAValid_S <= '1' when (ColumnReadAPosition_D >= APSADCConfigReg_D.StartColumn0_D and ColumnReadAPosition_D <= APSADCConfigReg_D.EndColumn0_D) else '0';
			CurrentColumnBValid_S <= '1' when (ColumnReadBPosition_D >= APSADCConfigReg_D.StartColumn0_D and ColumnReadBPosition_D <= APSADCConfigReg_D.EndColumn0_D) else '0';
		end generate apsColumnROI;

		apsColumnROIInverted : if CHIP_APS_STREAM_START(1) = '1' generate
			signal StartColumn0Inverted_S : unsigned(CHIP_APS_SIZE_COLUMNS'range);
			signal EndColumn0Inverted_S   : unsigned(CHIP_APS_SIZE_COLUMNS'range);
		begin
			StartColumn0Inverted_S <= CHIP_APS_SIZE_COLUMNS - 1 - APSADCConfigReg_D.StartColumn0_D;
			EndColumn0Inverted_S   <= CHIP_APS_SIZE_COLUMNS - 1 - APSADCConfigReg_D.EndColumn0_D;

			CurrentColumnAValid_S <= '1' when (ColumnReadAPosition_D >= EndColumn0Inverted_S and ColumnReadAPosition_D <= StartColumn0Inverted_S) else '0';
			CurrentColumnBValid_S <= '1' when (ColumnReadBPosition_D >= EndColumn0Inverted_S and ColumnReadBPosition_D <= StartColumn0Inverted_S) else '0';
		end generate apsColumnROIInverted;

		apsRowROI : if CHIP_APS_STREAM_START(0) = '0' generate
		begin
			CurrentRowValid_S <= '1' when (RowReadPosition_D >= APSADCConfigReg_D.StartRow0_D and RowReadPosition_D <= APSADCConfigReg_D.EndRow0_D) else '0';
		end generate apsRowROI;

		apsRowROIInverted : if CHIP_APS_STREAM_START(0) = '1' generate
			signal StartRow0Inverted_S : unsigned(CHIP_APS_SIZE_ROWS'range);
			signal EndRow0Inverted_S   : unsigned(CHIP_APS_SIZE_ROWS'range);
		begin
			StartRow0Inverted_S <= CHIP_APS_SIZE_ROWS - 1 - APSADCConfigReg_D.StartRow0_D;
			EndRow0Inverted_S   <= CHIP_APS_SIZE_ROWS - 1 - APSADCConfigReg_D.EndRow0_D;

			CurrentRowValid_S <= '1' when (RowReadPosition_D >= EndRow0Inverted_S and RowReadPosition_D <= StartRow0Inverted_S) else '0';
		end generate apsRowROIInverted;
	end generate apsStandardROI;

	apsQuadROI : if ENABLE_QUAD_ROI = true generate
		signal ColumnA0Valid_S : boolean := false;
		signal ColumnA1Valid_S : boolean := false;
		signal ColumnA2Valid_S : boolean := false;
		signal ColumnA3Valid_S : boolean := false;

		signal ColumnB0Valid_S : boolean := false;
		signal ColumnB1Valid_S : boolean := false;
		signal ColumnB2Valid_S : boolean := false;
		signal ColumnB3Valid_S : boolean := false;

		signal Row0Valid_S : boolean := false;
		signal Row1Valid_S : boolean := false;
		signal Row2Valid_S : boolean := false;
		signal Row3Valid_S : boolean := false;
	begin
		-- Concurrently calculate if the current column or row has to be read out or not.
		-- If not (like with ROI), we can just fast jump past it.
		apsColumnROI : if CHIP_APS_STREAM_START(1) = '0' generate
		begin
			ColumnA0Valid_S <= ColumnReadAPosition_D >= APSADCConfigReg_D.StartColumn0_D and ColumnReadAPosition_D <= APSADCConfigReg_D.EndColumn0_D;
			ColumnB0Valid_S <= ColumnReadBPosition_D >= APSADCConfigReg_D.StartColumn0_D and ColumnReadBPosition_D <= APSADCConfigReg_D.EndColumn0_D;

			ColumnA1Valid_S <= ColumnReadAPosition_D >= APSADCConfigReg_D.StartColumn1_D and ColumnReadAPosition_D <= APSADCConfigReg_D.EndColumn1_D;
			ColumnB1Valid_S <= ColumnReadBPosition_D >= APSADCConfigReg_D.StartColumn1_D and ColumnReadBPosition_D <= APSADCConfigReg_D.EndColumn1_D;

			ColumnA2Valid_S <= ColumnReadAPosition_D >= APSADCConfigReg_D.StartColumn2_D and ColumnReadAPosition_D <= APSADCConfigReg_D.EndColumn2_D;
			ColumnB2Valid_S <= ColumnReadBPosition_D >= APSADCConfigReg_D.StartColumn2_D and ColumnReadBPosition_D <= APSADCConfigReg_D.EndColumn2_D;

			ColumnA3Valid_S <= ColumnReadAPosition_D >= APSADCConfigReg_D.StartColumn3_D and ColumnReadAPosition_D <= APSADCConfigReg_D.EndColumn3_D;
			ColumnB3Valid_S <= ColumnReadBPosition_D >= APSADCConfigReg_D.StartColumn3_D and ColumnReadBPosition_D <= APSADCConfigReg_D.EndColumn3_D;

			CurrentColumnAValid_S <= '1' when (ColumnA0Valid_S or ColumnA1Valid_S or ColumnA2Valid_S or ColumnA3Valid_S) else '0';
			CurrentColumnBValid_S <= '1' when (ColumnB0Valid_S or ColumnB1Valid_S or ColumnB2Valid_S or ColumnB3Valid_S) else '0';
		end generate apsColumnROI;

		apsColumnROIInverted : if CHIP_APS_STREAM_START(1) = '1' generate
			signal StartColumn0Inverted_S : unsigned(CHIP_APS_SIZE_COLUMNS'range);
			signal EndColumn0Inverted_S   : unsigned(CHIP_APS_SIZE_COLUMNS'range);

			signal StartColumn1Inverted_S : unsigned(CHIP_APS_SIZE_COLUMNS'range);
			signal EndColumn1Inverted_S   : unsigned(CHIP_APS_SIZE_COLUMNS'range);

			signal StartColumn2Inverted_S : unsigned(CHIP_APS_SIZE_COLUMNS'range);
			signal EndColumn2Inverted_S   : unsigned(CHIP_APS_SIZE_COLUMNS'range);

			signal StartColumn3Inverted_S : unsigned(CHIP_APS_SIZE_COLUMNS'range);
			signal EndColumn3Inverted_S   : unsigned(CHIP_APS_SIZE_COLUMNS'range);
		begin
			StartColumn0Inverted_S <= CHIP_APS_SIZE_COLUMNS - 1 - APSADCConfigReg_D.StartColumn0_D;
			EndColumn0Inverted_S   <= CHIP_APS_SIZE_COLUMNS - 1 - APSADCConfigReg_D.EndColumn0_D;

			ColumnA0Valid_S <= ColumnReadAPosition_D >= EndColumn0Inverted_S and ColumnReadAPosition_D <= StartColumn0Inverted_S;
			ColumnB0Valid_S <= ColumnReadBPosition_D >= EndColumn0Inverted_S and ColumnReadBPosition_D <= StartColumn0Inverted_S;

			StartColumn1Inverted_S <= CHIP_APS_SIZE_COLUMNS - 1 - APSADCConfigReg_D.StartColumn1_D;
			EndColumn1Inverted_S   <= CHIP_APS_SIZE_COLUMNS - 1 - APSADCConfigReg_D.EndColumn1_D;

			ColumnA1Valid_S <= ColumnReadAPosition_D >= EndColumn1Inverted_S and ColumnReadAPosition_D <= StartColumn1Inverted_S;
			ColumnB1Valid_S <= ColumnReadBPosition_D >= EndColumn1Inverted_S and ColumnReadBPosition_D <= StartColumn1Inverted_S;

			StartColumn2Inverted_S <= CHIP_APS_SIZE_COLUMNS - 1 - APSADCConfigReg_D.StartColumn2_D;
			EndColumn2Inverted_S   <= CHIP_APS_SIZE_COLUMNS - 1 - APSADCConfigReg_D.EndColumn2_D;

			ColumnA2Valid_S <= ColumnReadAPosition_D >= EndColumn2Inverted_S and ColumnReadAPosition_D <= StartColumn2Inverted_S;
			ColumnB2Valid_S <= ColumnReadBPosition_D >= EndColumn2Inverted_S and ColumnReadBPosition_D <= StartColumn2Inverted_S;

			StartColumn3Inverted_S <= CHIP_APS_SIZE_COLUMNS - 1 - APSADCConfigReg_D.StartColumn3_D;
			EndColumn3Inverted_S   <= CHIP_APS_SIZE_COLUMNS - 1 - APSADCConfigReg_D.EndColumn3_D;

			ColumnA3Valid_S <= ColumnReadAPosition_D >= EndColumn3Inverted_S and ColumnReadAPosition_D <= StartColumn3Inverted_S;
			ColumnB3Valid_S <= ColumnReadBPosition_D >= EndColumn3Inverted_S and ColumnReadBPosition_D <= StartColumn3Inverted_S;

			CurrentColumnAValid_S <= '1' when (ColumnA0Valid_S or ColumnA1Valid_S or ColumnA2Valid_S or ColumnA3Valid_S) else '0';
			CurrentColumnBValid_S <= '1' when (ColumnB0Valid_S or ColumnB1Valid_S or ColumnB2Valid_S or ColumnB3Valid_S) else '0';
		end generate apsColumnROIInverted;

		apsRowROI : if CHIP_APS_STREAM_START(0) = '0' generate
		begin
			Row0Valid_S <= RowReadPosition_D >= APSADCConfigReg_D.StartRow0_D and RowReadPosition_D <= APSADCConfigReg_D.EndRow0_D;
			Row1Valid_S <= RowReadPosition_D >= APSADCConfigReg_D.StartRow1_D and RowReadPosition_D <= APSADCConfigReg_D.EndRow1_D;
			Row2Valid_S <= RowReadPosition_D >= APSADCConfigReg_D.StartRow2_D and RowReadPosition_D <= APSADCConfigReg_D.EndRow2_D;
			Row3Valid_S <= RowReadPosition_D >= APSADCConfigReg_D.StartRow3_D and RowReadPosition_D <= APSADCConfigReg_D.EndRow3_D;

			CurrentRowValid_S <= '1' when (Row0Valid_S or Row1Valid_S or Row2Valid_S or Row3Valid_S) else '0';
		end generate apsRowROI;

		apsRowROIInverted : if CHIP_APS_STREAM_START(0) = '1' generate
			signal StartRow0Inverted_S : unsigned(CHIP_APS_SIZE_ROWS'range);
			signal EndRow0Inverted_S   : unsigned(CHIP_APS_SIZE_ROWS'range);

			signal StartRow1Inverted_S : unsigned(CHIP_APS_SIZE_ROWS'range);
			signal EndRow1Inverted_S   : unsigned(CHIP_APS_SIZE_ROWS'range);

			signal StartRow2Inverted_S : unsigned(CHIP_APS_SIZE_ROWS'range);
			signal EndRow2Inverted_S   : unsigned(CHIP_APS_SIZE_ROWS'range);

			signal StartRow3Inverted_S : unsigned(CHIP_APS_SIZE_ROWS'range);
			signal EndRow3Inverted_S   : unsigned(CHIP_APS_SIZE_ROWS'range);
		begin
			StartRow0Inverted_S <= CHIP_APS_SIZE_ROWS - 1 - APSADCConfigReg_D.StartRow0_D;
			EndRow0Inverted_S   <= CHIP_APS_SIZE_ROWS - 1 - APSADCConfigReg_D.EndRow0_D;

			Row0Valid_S <= RowReadPosition_D >= EndRow0Inverted_S and RowReadPosition_D <= StartRow0Inverted_S;

			StartRow1Inverted_S <= CHIP_APS_SIZE_ROWS - 1 - APSADCConfigReg_D.StartRow1_D;
			EndRow1Inverted_S   <= CHIP_APS_SIZE_ROWS - 1 - APSADCConfigReg_D.EndRow1_D;

			Row1Valid_S <= RowReadPosition_D >= EndRow1Inverted_S and RowReadPosition_D <= StartRow1Inverted_S;

			StartRow2Inverted_S <= CHIP_APS_SIZE_ROWS - 1 - APSADCConfigReg_D.StartRow2_D;
			EndRow2Inverted_S   <= CHIP_APS_SIZE_ROWS - 1 - APSADCConfigReg_D.EndRow2_D;

			Row2Valid_S <= RowReadPosition_D >= EndRow2Inverted_S and RowReadPosition_D <= StartRow2Inverted_S;

			StartRow3Inverted_S <= CHIP_APS_SIZE_ROWS - 1 - APSADCConfigReg_D.StartRow3_D;
			EndRow3Inverted_S   <= CHIP_APS_SIZE_ROWS - 1 - APSADCConfigReg_D.EndRow3_D;

			Row3Valid_S <= RowReadPosition_D >= EndRow3Inverted_S and RowReadPosition_D <= StartRow3Inverted_S;

			CurrentRowValid_S <= '1' when (Row0Valid_S or Row1Valid_S or Row2Valid_S or Row3Valid_S) else '0';
		end generate apsRowROIInverted;
	end generate apsQuadROI;

	rowReadPosition : entity work.ContinuousCounter
		generic map(
			SIZE              => CHIP_APS_SIZE_ROWS'length,
			RESET_ON_OVERFLOW => false,
			GENERATE_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => RowReadPositionZero_S or RowReadPositionZeroChip_S,
			Enable_SI    => RowReadPositionInc_S or RowReadPositionIncChip_S,
			DataLimit_DI => CHIP_APS_SIZE_ROWS,
			Overflow_SO  => open,
			Data_DO      => RowReadPosition_D);

	columnSettleTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_COLSETTLETIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => ColSettleTimeCount_S or ColSettleTimeCountChip_S,
			DataLimit_DI => APSADCConfigReg_D.ColumnSettle_D,
			Overflow_SO  => ColSettleTimeDone_S,
			Data_DO      => open);

	rowSettleTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_ROWSETTLETIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => RowSettleTimeCount_S,
			DataLimit_DI => APSADCConfigReg_D.RowSettle_D,
			Overflow_SO  => RowSettleTimeDone_S,
			Data_DO      => open);

	externalADCRowReadoutStateMachine : process(ExtRowState_DP, APSADCConfigReg_D, ExternalADCData_DI, OutFifoControl_SI, APSChipColModeReg_DP, CurrentRowValid_S, RowReadInProgress_SP, RowReadPosition_D, ColSettleTimeDone_S, RowSettleTimeDone_S)
	begin
		ExtRowState_DN <= ExtRowState_DP;

		OutFifoWriteRegRowExternal_S      <= '0';
		OutFifoDataRegRowExternalEnable_S <= '0';
		OutFifoDataRegRowExternal_D       <= (others => '0');

		APSChipRowSRClockReg_C <= '0';
		APSChipRowSRInReg_S    <= '0';

		-- Row counters.
		RowReadPositionZero_S <= '0';
		RowReadPositionInc_S  <= '0';

		-- Settle times counters (column and row).
		ColSettleTimeCount_S <= '0';
		RowSettleTimeCount_S <= '0';

		-- Column SM communication.
		RowReadDoneExternal_SN <= '0';

		case ExtRowState_DP is
			when stIdle =>
				-- Wait until the main column state machine signals us to do a row read.
				if (CHIP_APS_HAS_INTEGRATED_ADC = '0' or APSADCConfigReg_D.UseInternalADC_S = '0') and RowReadInProgress_SP = '1' then
					ExtRowState_DN <= stRowSRFeedInit;
				end if;

			when stRowSRFeedInit =>
				-- We first feed in the row register pattern, since the column settle time
				-- has to pass _after_ the first row has been selected.
				APSChipRowSRClockReg_C <= '0';
				APSChipRowSRInReg_S    <= '1';

				ExtRowState_DN <= stRowSRFeedInitTick;

			when stRowSRFeedInitTick =>
				APSChipRowSRClockReg_C <= '1';
				APSChipRowSRInReg_S    <= '1';

				ExtRowState_DN <= stColSettleWait;

			when stColSettleWait =>
				-- Additional wait for the column selection to be valid, once both the colum and
				-- the current row pattern have been shifted in. We do this here, because the row
				-- pattern also has to have been shifted in for this to be effective.
				if ColSettleTimeDone_S = '1' then
					ExtRowState_DN <= stRowStart;
				end if;

				ColSettleTimeCount_S <= '1';

			when stRowStart =>
				-- Write event only if FIFO has place, else wait.
				-- If fake read (COLMODE_NULL), don't write anything.
				if OutFifoControl_SI.AlmostFull_S = '0' and APSChipColModeReg_DP /= COLMODE_NULL then
					if APSChipColModeReg_DP = COLMODE_READA then
						OutFifoDataRegRowExternal_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTRESETCOL;
					else
						OutFifoDataRegRowExternal_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTSIGNALCOL;
					end if;
					OutFifoDataRegRowExternalEnable_S <= '1';
					OutFifoWriteRegRowExternal_S      <= '1';
				end if;

				if OutFifoControl_SI.AlmostFull_S = '0' or APSChipColModeReg_DP = COLMODE_NULL or APSADCConfigReg_D.WaitOnTransferStall_S = '0' then
					-- Same decision to do here as in stRowSRFeedTick.
					if CurrentRowValid_S = '1' then
						ExtRowState_DN <= stRowSettleWait;
					else
						ExtRowState_DN <= stRowFastJump;
					end if;
				end if;

			when stRowSRFeedTick =>
				APSChipRowSRClockReg_C <= '1';
				APSChipRowSRInReg_S    <= '0';

				-- Check if we're done. This means that we just clock the 1 in the RowSR out,
				-- leaving it clean at only zeros. Further, the row read position is at the
				-- maximum, so we can detect that, zero it and exit.
				if RowReadPosition_D = CHIP_APS_SIZE_ROWS then
					ExtRowState_DN        <= stRowDone;
					RowReadPositionZero_S <= '1';
				else
					if CurrentRowValid_S = '1' then
						ExtRowState_DN <= stRowSettleWait;
					else
						ExtRowState_DN <= stRowFastJump;
					end if;
				end if;

			when stRowSettleWait =>
				-- Wait for the row selection to be valid.
				if RowSettleTimeDone_S = '1' then
					ExtRowState_DN <= stRowWriteEvent;
				end if;

				RowSettleTimeCount_S <= '1';

			when stRowWriteEvent =>
				-- Write event only if FIFO has place, else wait.
				if OutFifoControl_SI.AlmostFull_S = '0' and APSChipColModeReg_DP /= COLMODE_NULL then
					OutFifoDataRegRowExternal_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_ADC_SAMPLE;
					OutFifoDataRegRowExternal_D(APS_ADC_BUS_WIDTH - 1 downto 0)         <= ExternalADCData_DI;

					OutFifoDataRegRowExternalEnable_S <= '1';
					OutFifoWriteRegRowExternal_S      <= '1';
				end if;

				if OutFifoControl_SI.AlmostFull_S = '0' or APSChipColModeReg_DP = COLMODE_NULL or APSADCConfigReg_D.WaitOnTransferStall_S = '0' then
					ExtRowState_DN       <= stRowSRFeedTick;
					RowReadPositionInc_S <= '1';
				end if;

			when stRowFastJump =>
				ExtRowState_DN       <= stRowSRFeedTick;
				RowReadPositionInc_S <= '1';

			when stRowDone =>
				-- Write event only if FIFO has place, else wait.
				if OutFifoControl_SI.AlmostFull_S = '0' and APSChipColModeReg_DP /= COLMODE_NULL then
					OutFifoDataRegRowExternal_D       <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_ENDCOL;
					OutFifoDataRegRowExternalEnable_S <= '1';
					OutFifoWriteRegRowExternal_S      <= '1';
				end if;

				if OutFifoControl_SI.AlmostFull_S = '0' or APSChipColModeReg_DP = COLMODE_NULL or APSADCConfigReg_D.WaitOnTransferStall_S = '0' then
					ExtRowState_DN         <= stIdle;
					RowReadDoneExternal_SN <= '1';
				end if;

			when others => null;
		end case;
	end process externalADCRowReadoutStateMachine;

	noChipADC : if CHIP_APS_HAS_INTEGRATED_ADC = '0' generate
	begin
		-- Assign all signals but disable them if no internal ADC is present.
		-- This is the case only with DAVIS 240a/b/c devices.
		ChipADCRampClear_SO   <= '0';
		ChipADCRampClock_CO   <= '0';
		ChipADCRampBitIn_SO   <= '0';
		ChipADCScanClock_CO   <= '0';
		ChipADCScanControl_SO <= '0';
		ChipADCSample_SO      <= '0';
		ChipADCGrayCounter_DO <= (others => '0');

		-- Disable control signals.
		ColSettleTimeCountChip_S  <= '0';
		RowReadPositionIncChip_S  <= '0';
		RowReadPositionZeroChip_S <= '0';

		-- The chip part of FIFO output doesn't contribute anything here.
		OutFifoWriteRegRowChip_S      <= '0';
		OutFifoDataRegRowChipEnable_S <= '0';
		OutFifoDataRegRowChip_D       <= (others => '0');

		-- Column SM communication (disabled for chip ADC part).
		RowReadDoneChip_SN <= '0';

		-- Signal when all row-reads are done and we can send EOF.
		RowReadsAllDone_S <= not RowReadInProgress_SP;
	end generate noChipADC;

	chipADCRowReadout : if CHIP_APS_HAS_INTEGRATED_ADC = '1' generate
		type tChipRowSampleState is (stIdle, stCaptureColMode, stColSettleWait, stRowSampleWait, stRowSample, stDone);
		attribute syn_enum_encoding of tChipRowSampleState : type is "onehot";

		-- present and next state (Sample&Hold)
		signal ChipRowSampleState_DP, ChipRowSampleState_DN : tChipRowSampleState;

		type tChipRowRampState is (stIdle, stRowRampFeed, stRowRampFeedTick, stRowRampResetSettle, stRowRampClockLow, stRowRampClockHigh, stRowScanWait, stRowScanSelect, stRowScanSelectTick, stDone);
		attribute syn_enum_encoding of tChipRowRampState : type is "onehot";

		-- present and next state (Ramp generation)
		signal ChipRowRampState_DP, ChipRowRampState_DN : tChipRowRampState;

		type tChipRowScanState is (stIdle, stRowStart, stRowScanReadValue, stRowScanJumpValue, stRowScanNextValue, stRowDone);
		attribute syn_enum_encoding of tChipRowScanState : type is "onehot";

		-- present and next state (Value scan-out)
		signal ChipRowScanState_DP, ChipRowScanState_DN : tChipRowScanState;

		-- On-chip ADC control.
		signal ChipADCRampClearReg_S                          : std_logic;
		signal ChipADCRampClockReg_C                          : std_logic;
		signal ChipADCRampBitInReg_S                          : std_logic;
		signal ChipADCScanClockReg1_C, ChipADCScanClockReg2_C : std_logic; -- Used from two SMs (Ramp, Scan) but never concurrently.
		signal ChipADCScanControlReg_S                        : std_logic;
		signal ChipADCSampleReg_S                             : std_logic;

		-- Ramp clock counter. Could be used to generate grey-code if needed too.
		signal RampTickCount_S, RampTickDone_S : std_logic;

		-- Sample time settle counter.
		signal SampleSettleTimeCount_S, SampleSettleTimeDone_S : std_logic;

		-- Ramp reset time counter.
		signal RampResetTimeCount_S, RampResetTimeDone_S : std_logic;

		-- Scan control constants.
		constant SCAN_CONTROL_COPY_OVER    : std_logic := '0';
		constant SCAN_CONTROL_SCAN_THROUGH : std_logic := '1';

		-- For pipelined internal ADC, we split the row-read into three small state machines.
		-- This means we must also pass down the pipe what kind of read (NULL, Reset, Signal)
		-- we are doing, since that information is needed not only during sample time to actually
		-- select the correct read type, but also during column-start-event writeout, which would
		-- happen in the last of the three SMs, and so we need two additional registers to pass
		-- that information down and one more to store it at the end.
		signal APSChipColModeRegSample_DP, APSChipColModeRegSample_DN : std_logic_vector(1 downto 0);
		signal APSChipColModeRegRamp_DP, APSChipColModeRegRamp_DN     : std_logic_vector(1 downto 0);
		signal APSChipColModeRegScan_DP, APSChipColModeRegScan_DN     : std_logic_vector(1 downto 0);

		-- Do the same to keep track of type of timing-only (fake) reads, information which is needed
		-- to shorten the ramp during reset reads in RS mode. The main ColMode registers only show
		-- type NULL then, so we need additional information to determine this.
		signal TimingReadSample_DP, TimingReadSample_DN : std_logic_vector(1 downto 0);
		signal TimingReadRamp_DP, TimingReadRamp_DN     : std_logic_vector(1 downto 0);

		-- We also need two additional registers for the two new SMs to notify when they
		-- are actually running and control them.
		signal RampInProgress_SP, RampStart_SN, RampDone_SN : std_logic;
		signal ScanInProgress_SP, ScanStart_SN, ScanDone_SN : std_logic;

		-- Variable ramp length.
		signal RampIsResetRead_S : std_logic;
		signal RampLimit_D       : unsigned(APS_ADC_BUS_WIDTH - 1 downto 0);
	begin
		-- Don't generate any external gray-code. Internal gray-counter works.
		ChipADCGrayCounter_DO <= (others => '0');

		-- Signal when all row-reads are done and we can send EOF.
		-- For pipelined ADC, this needs to make sure all three phases are completed.
		RowReadsAllDone_S <= not RowReadInProgress_SP and not RampInProgress_SP and not ScanInProgress_SP;

		-- Don't do the full ramp on reset reads. The value must be pretty high
		-- anyway, near AdcHigh, so just half the ramp should always be enough
		-- to hit a good value.
		RampIsResetRead_S <= '1' when (APSChipColModeRegRamp_DP = COLMODE_READA or TimingReadRamp_DP = COLMODE_READA) else '0';
		RampLimit_D       <= to_unsigned(511, APS_ADC_BUS_WIDTH) when (APSADCConfigReg_D.RampShortReset_S = '1' and RampIsResetRead_S = '1') else to_unsigned(1021, APS_ADC_BUS_WIDTH);

		rampTickCounter : entity work.ContinuousCounter
			generic map(
				SIZE => APS_ADC_BUS_WIDTH)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Clear_SI     => '0',
				Enable_SI    => RampTickCount_S,
				DataLimit_DI => RampLimit_D,
				Overflow_SO  => RampTickDone_S,
				Data_DO      => open);

		sampleSettleTimeCounter : entity work.ContinuousCounter
			generic map(
				SIZE => APS_SAMPLESETTLETIME_SIZE)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Clear_SI     => '0',
				Enable_SI    => SampleSettleTimeCount_S,
				DataLimit_DI => APSADCConfigReg_D.SampleSettle_D,
				Overflow_SO  => SampleSettleTimeDone_S,
				Data_DO      => open);

		rampResetTimeCounter : entity work.ContinuousCounter
			generic map(
				SIZE => APS_RAMPRESETTIME_SIZE)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Clear_SI     => '0',
				Enable_SI    => RampResetTimeCount_S,
				DataLimit_DI => APSADCConfigReg_D.RampReset_D,
				Overflow_SO  => RampResetTimeDone_S,
				Data_DO      => open);

		chipADCRowReadoutSampleStateMachine : process(ChipRowSampleState_DP, APSADCConfigReg_D, ColSettleTimeDone_S, RampInProgress_SP, RowReadInProgress_SP, SampleSettleTimeDone_S, APSChipColModeRegSample_DP, APSChipColModeReg_DP, TimingReadSample_DP, TimingRead_DP)
		begin
			ChipRowSampleState_DN <= ChipRowSampleState_DP;

			-- Settle times counters.
			ColSettleTimeCountChip_S <= '0';
			SampleSettleTimeCount_S  <= '0';

			-- Column SM communication.
			RowReadDoneChip_SN <= '0';

			-- Ramp SM communication.
			RampStart_SN <= '0';

			-- Keep track of current readout type.
			APSChipColModeRegSample_DN <= APSChipColModeRegSample_DP;
			TimingReadSample_DN        <= TimingReadSample_DP;

			-- On-chip ADC.
			ChipADCSampleReg_S <= '0';

			case ChipRowSampleState_DP is
				when stIdle =>
					-- Wait until the main column state machine signals us to do a row read.
					if APSADCConfigReg_D.UseInternalADC_S = '1' and RowReadInProgress_SP = '1' then
						ChipRowSampleState_DN <= stCaptureColMode;
					end if;

				when stCaptureColMode =>
					-- Update the readout type register, which is used to pass this value down to the other SMs.
					-- This is done here because APSChipColModeReg_DP is not yet set in stIdle above.
					APSChipColModeRegSample_DN <= APSChipColModeReg_DP;
					TimingReadSample_DN        <= TimingRead_DP;

					ChipRowSampleState_DN <= stColSettleWait;

				when stColSettleWait =>
					-- Additional wait for the column selection to be valid.
					if ColSettleTimeDone_S = '1' then
						ChipRowSampleState_DN <= stRowSampleWait;
					end if;

					ColSettleTimeCountChip_S <= '1';

				when stRowSampleWait =>
					-- Wait for old ramp to be finished before sampling the new value.
					if RampInProgress_SP = '0' then
						ChipRowSampleState_DN <= stRowSample;
					end if;

				when stRowSample =>
					-- Do sample now!
					ChipADCSampleReg_S <= '1';

					if SampleSettleTimeDone_S = '1' then
						ChipRowSampleState_DN <= stDone;
					end if;

					SampleSettleTimeCount_S <= '1';

				when stDone =>
					ChipRowSampleState_DN <= stIdle;

					-- Notify main SM that we're done with sampling. It can proceed
					-- to select the next column.
					RowReadDoneChip_SN <= '1';

					-- Also, ramp can start. We know there is none in progress since we
					-- checked in stIdle at the start. The two are mutually exclusive.
					RampStart_SN <= '1';

				when others => null;
			end case;
		end process chipADCRowReadoutSampleStateMachine;

		chipADCRowReadoutRampStateMachine : process(ChipRowRampState_DP, RampInProgress_SP, RampResetTimeDone_S, RampTickDone_S, ScanInProgress_SP, APSChipColModeRegRamp_DP, APSChipColModeRegSample_DP, TimingReadRamp_DP, TimingReadSample_DP)
		begin
			ChipRowRampState_DN <= ChipRowRampState_DP;

			-- ADC clock counter.
			RampTickCount_S <= '0';

			-- Settle times counters.
			RampResetTimeCount_S <= '0';

			-- Ramp SM communication.
			RampDone_SN <= '0';

			-- Scan SM communication.
			ScanStart_SN <= '0';

			-- Keep track of current readout type.
			APSChipColModeRegRamp_DN <= APSChipColModeRegRamp_DP;
			TimingReadRamp_DN        <= TimingReadRamp_DP;

			-- On-chip ADC.
			ChipADCRampClearReg_S   <= '1'; -- Clear ramp by default.
			ChipADCRampClockReg_C   <= '0';
			ChipADCRampBitInReg_S   <= '0';
			ChipADCScanClockReg1_C  <= '0';
			ChipADCScanControlReg_S <= SCAN_CONTROL_SCAN_THROUGH; -- Scan by default.
			-- Scan control is done here, because once a ramp is done, we can't do the next one
			-- until the values are copied to the scan registers, and the previous scan also has
			-- to be finished before we do that, or we'd destroy the values it's reading out.
			-- So we do those checks here, as well as the copy control.

			case ChipRowRampState_DP is
				when stIdle =>
					-- Wait until the sample state machine signals us to start the ramp.
					if RampInProgress_SP = '1' then
						ChipRowRampState_DN <= stRowRampFeed;

						-- Update the readout type register, which is used to pass this value down to the other SMs.
						APSChipColModeRegRamp_DN <= APSChipColModeRegSample_DP;
						TimingReadRamp_DN        <= TimingReadSample_DP;
					end if;

				when stRowRampFeed =>
					-- Do not clear Ramp while in use!
					ChipADCRampClearReg_S <= '0';

					ChipADCRampClockReg_C <= '0'; -- Set BitIn one cycle before to ensure the value is stable.
					ChipADCRampBitInReg_S <= '1';

					ChipRowRampState_DN <= stRowRampFeedTick;

				when stRowRampFeedTick =>
					-- Do not clear Ramp while in use!
					ChipADCRampClearReg_S <= '0';

					ChipADCRampClockReg_C <= '1';
					ChipADCRampBitInReg_S <= '1';

					ChipRowRampState_DN <= stRowRampResetSettle;

				when stRowRampResetSettle =>
					-- Do not clear Ramp while in use!
					ChipADCRampClearReg_S <= '0';

					if RampResetTimeDone_S = '1' then
						ChipRowRampState_DN <= stRowRampClockLow;
					end if;

					RampResetTimeCount_S <= '1';

				when stRowRampClockLow =>
					ChipADCRampClockReg_C <= '0';

					-- Do not clear Ramp while in use!
					ChipADCRampClearReg_S <= '0';

					ChipRowRampState_DN <= stRowRampClockHigh;

				when stRowRampClockHigh =>
					ChipADCRampClockReg_C <= '1';

					-- Do not clear Ramp while in use!
					ChipADCRampClearReg_S <= '0';

					-- Increase counter and stop ramping when maximum reached.
					RampTickCount_S <= '1';

					if RampTickDone_S = '1' then
						ChipRowRampState_DN <= stRowScanWait;
					else
						ChipRowRampState_DN <= stRowRampClockLow;
					end if;

				when stRowScanWait =>
					-- Do not clear Ramp while in use!
					ChipADCRampClearReg_S <= '0';

					-- Wait for old scan to be finished before copying over the new value.
					if ScanInProgress_SP = '0' then
						ChipRowRampState_DN <= stRowScanSelect;
					end if;

				when stRowScanSelect =>
					-- Do not clear Ramp while in use!
					ChipADCRampClearReg_S <= '0';

					ChipADCScanClockReg1_C  <= '0';
					ChipADCScanControlReg_S <= SCAN_CONTROL_COPY_OVER;

					ChipRowRampState_DN <= stRowScanSelectTick;

				when stRowScanSelectTick =>
					-- Do not clear Ramp while in use!
					ChipADCRampClearReg_S <= '0';

					ChipADCScanClockReg1_C  <= '1';
					ChipADCScanControlReg_S <= SCAN_CONTROL_COPY_OVER;

					ChipRowRampState_DN <= stDone;

				when stDone =>
					ChipRowRampState_DN <= stIdle;

					-- Notify sample SM that we're done with the ramp. It can proceed
					-- to take the next sample.
					RampDone_SN <= '1';

					-- Also, scan can start, since we know the previous one already finished.
					ScanStart_SN <= '1';

				when others => null;
			end case;
		end process chipADCRowReadoutRampStateMachine;

		chipADCRowReadoutScanStateMachine : process(ChipRowScanState_DP, APSADCConfigReg_D, OutFifoControl_SI, ChipADCData_DI, RowReadPosition_D, CurrentRowValid_S, ScanInProgress_SP, APSChipColModeRegRamp_DP, APSChipColModeRegScan_DP)
		begin
			ChipRowScanState_DN <= ChipRowScanState_DP;

			OutFifoWriteRegRowChip_S      <= '0';
			OutFifoDataRegRowChipEnable_S <= '0';
			OutFifoDataRegRowChip_D       <= (others => '0');

			-- Row counters.
			RowReadPositionZeroChip_S <= '0';
			RowReadPositionIncChip_S  <= '0';

			-- Ramp SM communication.
			ScanDone_SN <= '0';

			-- Keep track of current readout type.
			APSChipColModeRegScan_DN <= APSChipColModeRegScan_DP;

			-- On-chip ADC.
			ChipADCScanClockReg2_C <= '0';

			case ChipRowScanState_DP is
				when stIdle =>
					-- Wait until the ramp state machine signals us to start the scan.
					if ScanInProgress_SP = '1' then
						ChipRowScanState_DN <= stRowStart;

						-- Update the readout type register, which is used to decide the type of events to output.
						APSChipColModeRegScan_DN <= APSChipColModeRegRamp_DP;
					end if;

				when stRowStart =>
					-- Write event only if FIFO has place, else wait.
					-- If fake read (COLMODE_NULL), don't write anything.
					if OutFifoControl_SI.AlmostFull_S = '0' and APSChipColModeRegScan_DP /= COLMODE_NULL then
						if APSChipColModeRegScan_DP = COLMODE_READA then
							OutFifoDataRegRowChip_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTRESETCOL;
						else
							OutFifoDataRegRowChip_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTSIGNALCOL;
						end if;
						OutFifoDataRegRowChipEnable_S <= '1';
						OutFifoWriteRegRowChip_S      <= '1';
					end if;

					if OutFifoControl_SI.AlmostFull_S = '0' or APSChipColModeRegScan_DP = COLMODE_NULL or APSADCConfigReg_D.WaitOnTransferStall_S = '0' then
						-- Same check as in stRowScanNextValue needed here.
						if CurrentRowValid_S = '1' then
							ChipRowScanState_DN <= stRowScanReadValue;
						else
							ChipRowScanState_DN <= stRowScanJumpValue;
						end if;
					end if;

				when stRowScanReadValue =>
					-- Write event only if FIFO has place, else wait.
					if OutFifoControl_SI.AlmostFull_S = '0' and APSChipColModeRegScan_DP /= COLMODE_NULL then
						OutFifoDataRegRowChip_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_ADC_SAMPLE;

						-- Convert from gray-code to binary. This uses a direct algorithm instead of using the previously stored binary
						-- value at each step. Lastly, the output is negated so that the range 0-1023 is properly inverted to be the same
						-- as for external ADC, where 0 represents lowest voltage and 1023 highest voltage.
						OutFifoDataRegRowChip_D(9) <= not (ChipADCData_DI(9));
						OutFifoDataRegRowChip_D(8) <= not (ChipADCData_DI(8) xor ChipADCData_DI(9));
						OutFifoDataRegRowChip_D(7) <= not (ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
						OutFifoDataRegRowChip_D(6) <= not (ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
						OutFifoDataRegRowChip_D(5) <= not (ChipADCData_DI(5) xor ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
						OutFifoDataRegRowChip_D(4) <= not (ChipADCData_DI(4) xor ChipADCData_DI(5) xor ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
						OutFifoDataRegRowChip_D(3) <= not (ChipADCData_DI(3) xor ChipADCData_DI(4) xor ChipADCData_DI(5) xor ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
						OutFifoDataRegRowChip_D(2) <= not (ChipADCData_DI(2) xor ChipADCData_DI(3) xor ChipADCData_DI(4) xor ChipADCData_DI(5) xor ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
						OutFifoDataRegRowChip_D(1) <= not (ChipADCData_DI(1) xor ChipADCData_DI(2) xor ChipADCData_DI(3) xor ChipADCData_DI(4) xor ChipADCData_DI(5) xor ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
						OutFifoDataRegRowChip_D(0) <= not (ChipADCData_DI(0) xor ChipADCData_DI(1) xor ChipADCData_DI(2) xor ChipADCData_DI(3) xor ChipADCData_DI(4) xor ChipADCData_DI(5) xor ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));

						OutFifoDataRegRowChipEnable_S <= '1';
						OutFifoWriteRegRowChip_S      <= '1';
					end if;

					if OutFifoControl_SI.AlmostFull_S = '0' or APSChipColModeRegScan_DP = COLMODE_NULL or APSADCConfigReg_D.WaitOnTransferStall_S = '0' then
						ChipRowScanState_DN      <= stRowScanNextValue;
						RowReadPositionIncChip_S <= '1';
					end if;

				when stRowScanJumpValue =>
					ChipRowScanState_DN      <= stRowScanNextValue;
					RowReadPositionIncChip_S <= '1';

				when stRowScanNextValue =>
					ChipADCScanClockReg2_C <= '1';

					-- Check if we're done. The row read position is at the
					-- maximum, so we can detect that, zero it and exit.
					if RowReadPosition_D = CHIP_APS_SIZE_ROWS then
						ChipRowScanState_DN       <= stRowDone;
						RowReadPositionZeroChip_S <= '1';
					else
						if CurrentRowValid_S = '1' then
							ChipRowScanState_DN <= stRowScanReadValue;
						else
							ChipRowScanState_DN <= stRowScanJumpValue;
						end if;
					end if;

				when stRowDone =>
					-- Write event only if FIFO has place, else wait.
					if OutFifoControl_SI.AlmostFull_S = '0' and APSChipColModeRegScan_DP /= COLMODE_NULL then
						OutFifoDataRegRowChip_D       <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_ENDCOL;
						OutFifoDataRegRowChipEnable_S <= '1';
						OutFifoWriteRegRowChip_S      <= '1';
					end if;

					if OutFifoControl_SI.AlmostFull_S = '0' or APSChipColModeRegScan_DP = COLMODE_NULL or APSADCConfigReg_D.WaitOnTransferStall_S = '0' then
						ChipRowScanState_DN <= stIdle;

						-- Notify ramp SM that we're done with the scan. It can proceed
						-- with the next ramp.
						ScanDone_SN <= '1';
					end if;

				when others => null;
			end case;
		end process chipADCRowReadoutScanStateMachine;

		chipADCRegisterUpdate : process(Clock_CI, Reset_RI) is
		begin
			if Reset_RI = '1' then
				ChipRowSampleState_DP <= stIdle;
				ChipRowRampState_DP   <= stIdle;
				ChipRowScanState_DP   <= stIdle;

				RampInProgress_SP <= '0';
				ScanInProgress_SP <= '0';

				APSChipColModeRegSample_DP <= COLMODE_NULL;
				APSChipColModeRegRamp_DP   <= COLMODE_NULL;
				APSChipColModeRegScan_DP   <= COLMODE_NULL;

				TimingReadSample_DP <= COLMODE_NULL;
				TimingReadRamp_DP   <= COLMODE_NULL;

				ChipADCRampClear_SO   <= '1'; -- Clear ramp by default.
				ChipADCRampClock_CO   <= '0';
				ChipADCRampBitIn_SO   <= '0';
				ChipADCScanClock_CO   <= '0';
				ChipADCScanControl_SO <= SCAN_CONTROL_SCAN_THROUGH;
				ChipADCSample_SO      <= '0';
			elsif rising_edge(Clock_CI) then
				ChipRowSampleState_DP <= ChipRowSampleState_DN;
				ChipRowRampState_DP   <= ChipRowRampState_DN;
				ChipRowScanState_DP   <= ChipRowScanState_DN;

				RampInProgress_SP <= RampInProgress_SP xor (RampStart_SN or RampDone_SN);
				ScanInProgress_SP <= ScanInProgress_SP xor (ScanStart_SN or ScanDone_SN);

				APSChipColModeRegSample_DP <= APSChipColModeRegSample_DN;
				APSChipColModeRegRamp_DP   <= APSChipColModeRegRamp_DN;
				APSChipColModeRegScan_DP   <= APSChipColModeRegScan_DN;

				TimingReadSample_DP <= TimingReadSample_DN;
				TimingReadRamp_DP   <= TimingReadRamp_DN;

				ChipADCRampClear_SO   <= ChipADCRampClearReg_S;
				ChipADCRampClock_CO   <= ChipADCRampClockReg_C;
				ChipADCRampBitIn_SO   <= ChipADCRampBitInReg_S;
				ChipADCScanClock_CO   <= ChipADCScanClockReg1_C or ChipADCScanClockReg2_C;
				ChipADCScanControl_SO <= ChipADCScanControlReg_S;
				ChipADCSample_SO      <= APSADCConfigReg_D.SampleEnable_S and (ChipADCSampleReg_S or not APSADCConfigReg_D.UseInternalADC_S);
			end if;
		end process chipADCRegisterUpdate;
	end generate chipADCRowReadout;

	-- FIFO output can be driven by both the column or the row state machines.
	-- Care must be taken to never have both at the same time output meaningful data.
	OutFifoWriteReg_S      <= OutFifoWriteRegCol_S or OutFifoWriteRegRow_S;
	OutFifoDataRegEnable_S <= OutFifoDataRegColEnable_S or OutFifoDataRegRowEnable_S;
	OutFifoDataReg_D       <= OutFifoDataRegCol_D or OutFifoDataRegRow_D;

	-- The row FIFO output can come from either the external or the internal ADC state machine.
	OutFifoWriteRegRow_S      <= OutFifoWriteRegRowExternal_S or OutFifoWriteRegRowChip_S;
	OutFifoDataRegRowEnable_S <= OutFifoDataRegRowExternalEnable_S or OutFifoDataRegRowChipEnable_S;
	OutFifoDataRegRow_D       <= OutFifoDataRegRowExternal_D or OutFifoDataRegRowChip_D;

	-- Acknowledgement of having read out a full column can come from both ADC SMs.
	RowReadDone_SN <= RowReadDoneExternal_SN or RowReadDoneChip_SN;

	outputDataRegister : entity work.SimpleRegister
		generic map(
			SIZE => EVENT_WIDTH)
		port map(
			Clock_CI  => Clock_CI,
			Reset_RI  => Reset_RI,
			Enable_SI => OutFifoDataRegEnable_S,
			Input_SI  => OutFifoDataReg_D,
			Output_SO => OutFifoData_DO);

	-- Change state on clock edge (synchronous).
	registerUpdate : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			ColState_DP    <= stIdle;
			ExtRowState_DP <= stIdle;

			ExternalADCRunning_SP <= '0';

			RowReadInProgress_SP <= '0';

			ReadBSRStatus_DP <= RBSTAT_NEED_ZERO_ONE;
			TimingRead_DP    <= COLMODE_NULL;

			OutFifoControl_SO.Write_S <= '0';

			APSChipColSRClock_CO <= '0';
			APSChipColSRIn_SO    <= '0';
			APSChipRowSRClock_CO <= '0';
			APSChipRowSRIn_SO    <= '0';
			APSChipColModeReg_DP <= COLMODE_NULL;
			APSChipTXGateReg_SP  <= '0';

			-- APS ADC config from another clock domain.
			APSADCConfigReg_D     <= tAPSADCConfigDefault;
			APSADCConfigSyncReg_D <= tAPSADCConfigDefault;
		elsif rising_edge(Clock_CI) then
			ColState_DP    <= ColState_DN;
			ExtRowState_DP <= ExtRowState_DN;

			ExternalADCRunning_SP <= ExternalADCRunning_SN;

			RowReadInProgress_SP <= RowReadInProgress_SP xor (RowReadStart_SN or RowReadDone_SN);

			ReadBSRStatus_DP <= ReadBSRStatus_DN;
			TimingRead_DP    <= TimingRead_DN;

			OutFifoControl_SO.Write_S <= OutFifoWriteReg_S;

			APSChipColSRClock_CO <= APSChipColSRClockReg_C;
			APSChipColSRIn_SO    <= APSChipColSRInReg_S;
			APSChipRowSRClock_CO <= APSChipRowSRClockReg_C;
			APSChipRowSRIn_SO    <= APSChipRowSRInReg_S;
			APSChipColModeReg_DP <= APSChipColModeReg_DN;
			APSChipTXGateReg_SP  <= APSChipTXGateReg_SN;

			-- APS ADC config from another clock domain.
			if APSADCConfigRegEnable_S = '1' then
				APSADCConfigReg_D <= APSADCConfigSyncReg_D;
			end if;
			APSADCConfigSyncReg_D <= APSADCConfig_DI;
		end if;
	end process registerUpdate;

	-- The output of this register goes to an intermediate signal, since we need to access it
	-- inside this module. That's not possible with 'out' signal directly.
	APSChipColMode_DO <= APSChipColModeReg_DP;
	APSChipTXGate_SBO <= not APSChipTXGateReg_SP;

	-- Enabling the external ADC depends on wheter we want to run it or not.
	ExternalADCOutputEnable_SBO <= not ExternalADCRunning_SP;
	ExternalADCStandby_SO       <= not ExternalADCRunning_SP;
end architecture Behavioral;
