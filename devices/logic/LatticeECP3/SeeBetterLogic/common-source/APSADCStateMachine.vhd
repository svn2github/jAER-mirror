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
use work.Settings.CHIP_HAS_GLOBAL_SHUTTER;

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
		Clock_CI               : in  std_logic; -- This clock must be 30MHz, use PLL to generate.
		Reset_RI               : in  std_logic; -- This reset must be synchronized to the above clock.

		-- Fifo output (to Multiplexer, must be a dual-clock FIFO)
		OutFifoControl_SI      : in  tFromFifoWriteSide;
		OutFifoControl_SO      : out tToFifoWriteSide;
		OutFifoData_DO         : out std_logic_vector(EVENT_WIDTH - 1 downto 0);

		APSChipRowSRClock_SO   : out std_logic;
		APSChipRowSRIn_SO      : out std_logic;
		APSChipColSRClock_SO   : out std_logic;
		APSChipColSRIn_SO      : out std_logic;
		APSChipColMode_DO      : out std_logic_vector(1 downto 0);
		APSChipTXGate_SBO      : out std_logic;

		APSADCData_DI          : in  std_logic_vector(APS_ADC_BUS_WIDTH - 1 downto 0);
		APSADCClock_CO         : out std_logic;
		APSADCOutputEnable_SBO : out std_logic;
		APSADCStandby_SO       : out std_logic;

		-- Configuration input
		APSADCConfig_DI        : in  tAPSADCConfig);
end entity APSADCStateMachine;

architecture Behavioral of APSADCStateMachine is
	attribute syn_enum_encoding : string;

	type tColumnState is (stIdle, stWaitADCStartup, stStartFrame, stEndFrame, stWaitFrameDelay, stColSRFeedA, stColSRFeedATick, stColSRFeedB, stColSRFeedBTick, stRSFeedTick, stRSReset, stRSSwitchToReadA, stRSReadA, stRSSwitchToReadB, stRSReadB, stGSReset, stGSReadA, stGSReadB, stGSSwitchToReadA,
		                  stGSSwitchToReadB, stGSStartExposure, stGSEndExposure, stGSReadAFeedTick, stGSReadBFeedTick, stGSColSRFeedB1, stGSColSRFeedB1Tick, stGSColSRFeedB0, stGSColSRFeedB0Tick);
	attribute syn_enum_encoding of tColumnState : type is "onehot";

	-- present and next state
	signal ColState_DP, ColState_DN : tColumnState;

	type tRowState is (stIdle, stRowDone, stRowSRInit, stRowSRInitTick, stRowSRFeedTick, stColSettleWait, stRowSettleWait, stRowWriteEvent, stRowFastJump);
	attribute syn_enum_encoding of tRowState : type is "onehot";

	-- present and next state
	signal RowState_DP, RowState_DN : tRowState;

	constant ADC_STARTUP_CYCLES      : integer := ADC_CLOCK_FREQ * 20; -- At 30MHz, wait 20 microseconds.
	constant ADC_STARTUP_CYCLES_SIZE : integer := integer(ceil(log2(real(ADC_STARTUP_CYCLES))));

	constant COLMODE_NULL   : std_logic_vector(1 downto 0) := "00";
	constant COLMODE_READA  : std_logic_vector(1 downto 0) := "01";
	constant COLMODE_READB  : std_logic_vector(1 downto 0) := "10";
	constant COLMODE_RESETA : std_logic_vector(1 downto 0) := "11";

	-- Take note if the ADC is running already or not. If not, it has to be started.
	signal ADCRunning_SP, ADCRunning_SN : std_logic;

	signal ADCStartupCount_S, ADCStartupDone_S : std_logic;

	-- Use one counter for both exposure and frame delay times, they cannot happen at the same time.
	signal ExposureDelayClear_S, ExposureDelayDone_S : std_logic;
	signal ExposureDelayLimit_D                      : unsigned(EXPOSUREDELAY_SIZE - 1 downto 0);

	-- Reset time counter (bigger to allow for long resets if needed).
	signal ResetTimeCount_S, ResetTimeDone_S : std_logic;

	-- Use one counter for both column and row settle times, they cannot happen at the same time.
	signal SettleTimesCount_S, SettleTimesDone_S : std_logic;
	signal SettleTimesLimit_D                    : unsigned(SETTLETIMES_SIZE - 1 downto 0);

	-- Column and row read counters.
	signal ColumnReadAPositionZero_S, ColumnReadAPositionInc_S : std_logic;
	signal ColumnReadAPosition_D                               : unsigned(CHIP_APS_SIZE_COLUMNS'range);
	signal ColumnReadBPositionZero_S, ColumnReadBPositionInc_S : std_logic;
	signal ColumnReadBPosition_D                               : unsigned(CHIP_APS_SIZE_COLUMNS'range);
	signal RowReadPositionZero_S, RowReadPositionInc_S         : std_logic;
	signal RowReadPosition_D                                   : unsigned(CHIP_APS_SIZE_ROWS'range);

	-- Communication between column and row state machines. Done through a register for full decoupling.
	signal RowReadStart_SP, RowReadStart_SN : std_logic;
	signal RowReadDone_SP, RowReadDone_SN   : std_logic;

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

	-- Register all outputs to ADC and chip for clean transitions.
	signal APSChipRowSRClockReg_S, APSChipRowSRInReg_S  : std_logic;
	signal APSChipColSRClockReg_S, APSChipColSRInReg_S  : std_logic;
	signal APSChipColModeReg_DP, APSChipColModeReg_DN   : std_logic_vector(1 downto 0);
	signal APSChipTXGateReg_SP, APSChipTXGateReg_SN     : std_logic;
	signal APSADCOutputEnableReg_SB, APSADCStandbyReg_S : std_logic;

	-- Double register configuration input, since it comes from a different clock domain (LogicClock), it
	-- needs to go through a double-flip-flop synchronizer to guarantee correctness.
	signal APSADCConfigSyncReg_D, APSADCConfigReg_D : tAPSADCConfig;
	signal APSADCConfigRegEnable_S                  : std_logic;
begin
	-- Forward 30MHz clock directly to external ADC.
	APSADCClock_CO <= Clock_CI;

	adcStartupCounter : entity work.ContinuousCounter
		generic map(
			SIZE => ADC_STARTUP_CYCLES_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => ADCStartupCount_S,
			DataLimit_DI => to_unsigned(ADC_STARTUP_CYCLES - 1, ADC_STARTUP_CYCLES_SIZE),
			Overflow_SO  => ADCStartupDone_S,
			Data_DO      => open);

	exposureDelayCounter : entity work.ContinuousCounter
		generic map(
			SIZE              => EXPOSUREDELAY_SIZE,
			RESET_ON_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => ExposureDelayClear_S,
			Enable_SI    => '1',
			DataLimit_DI => ExposureDelayLimit_D,
			Overflow_SO  => ExposureDelayDone_S,
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

	rowReadPosition : entity work.ContinuousCounter
		generic map(
			SIZE              => CHIP_APS_SIZE_ROWS'length,
			RESET_ON_OVERFLOW => false,
			GENERATE_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => RowReadPositionZero_S,
			Enable_SI    => RowReadPositionInc_S,
			DataLimit_DI => CHIP_APS_SIZE_ROWS,
			Overflow_SO  => open,
			Data_DO      => RowReadPosition_D);

	resetTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => RESETTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => ResetTimeCount_S,
			DataLimit_DI => APSADCConfigReg_D.ResetSettle_D,
			Overflow_SO  => ResetTimeDone_S,
			Data_DO      => open);

	settleTimesCounter : entity work.ContinuousCounter
		generic map(
			SIZE => SETTLETIMES_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => SettleTimesCount_S,
			DataLimit_DI => SettleTimesLimit_D,
			Overflow_SO  => SettleTimesDone_S,
			Data_DO      => open);

	columnMainStateMachine : process(ColState_DP, OutFifoControl_SI, ADCRunning_SP, ADCStartupDone_S, APSADCConfigReg_D, ExposureDelayDone_S, RowReadDone_SP, ResetTimeDone_S, APSChipTXGateReg_SP, ColumnReadAPosition_D, ColumnReadBPosition_D, ReadBSRStatus_DP, CurrentColumnAValid_S, CurrentColumnBValid_S)
	begin
		ColState_DN <= ColState_DP;     -- Keep current state by default.

		OutFifoWriteRegCol_S      <= '0';
		OutFifoDataRegColEnable_S <= '0';
		OutFifoDataRegCol_D       <= (others => '0');

		ADCRunning_SN     <= ADCRunning_SP;
		ADCStartupCount_S <= '0';

		-- Keep ADC powered and OE by default, the Idle (start) state will
		-- then negotiate the necessary settings, and when we're out of Idle,
		-- they are always on anyway.
		APSADCOutputEnableReg_SB <= '0';
		APSADCStandbyReg_S       <= '0';

		APSChipColSRClockReg_S <= '0';
		APSChipColSRInReg_S    <= '0';

		APSChipColModeReg_DN <= COLMODE_NULL;
		APSChipTXGateReg_SN  <= APSChipTXGateReg_SP;

		-- By default keep exposure/frame delay counter cleared and inactive.
		ExposureDelayClear_S <= '0';
		ExposureDelayLimit_D <= APSADCConfigReg_D.Exposure_D;

		-- Colum counters.
		ColumnReadAPositionZero_S <= '0';
		ColumnReadAPositionInc_S  <= '0';
		ColumnReadBPositionZero_S <= '0';
		ColumnReadBPositionInc_S  <= '0';

		-- Reset time counter.
		ResetTimeCount_S <= '0';

		-- Row SM communication.
		RowReadStart_SN <= '0';

		-- Keep value by default.
		ReadBSRStatus_DN <= ReadBSRStatus_DP;

		-- Only update configuration when in Idle state. Doing so while the frame is being read out
		-- would cause different timing, exposure and read out types, resulting in corrupted frames.
		APSADCConfigRegEnable_S <= '0';

		case ColState_DP is
			when stIdle =>
				APSADCConfigRegEnable_S <= '1';

				if APSADCConfigReg_D.Run_S = '1' then
					-- We want to take samples (picture or video), so the ADC has to be running.
					if ADCRunning_SP = '0' then
						ColState_DN <= stWaitADCStartup;
					else
						ColState_DN <= stStartFrame;
					end if;
				else
					-- Turn ADC off when not running, unless told otherwise.
					if APSADCConfigReg_D.ForceADCRunning_S = '0' then
						APSADCOutputEnableReg_SB <= '1';
						APSADCStandbyReg_S       <= '1';
						ADCRunning_SN            <= '0';
					end if;
				end if;

			when stWaitADCStartup =>
				-- Wait 1.5 microseconds for ADC to start up and be ready for precise conversions.
				if ADCStartupDone_S = '1' then
					ColState_DN   <= stStartFrame;
					ADCRunning_SN <= '1';
				end if;

				ADCStartupCount_S <= '1';

			when stStartFrame =>
				-- Write out start of frame marker. This and the end of frame marker are the only
				-- two events from this SM that always have to be committed and are never dropped.
				if OutFifoControl_SI.Full_S = '0' then
					if CHIP_HAS_GLOBAL_SHUTTER = '1' and APSADCConfigReg_D.GlobalShutter_S = '1' then
						OutFifoDataRegCol_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTFRAME_GS;
					else
						OutFifoDataRegCol_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTFRAME_RS;
					end if;

					OutFifoDataRegColEnable_S <= '1';
					OutFifoWriteRegCol_S      <= '1';

					ColState_DN <= stColSRFeedA;
				end if;

			when stColSRFeedA =>
				APSChipColSRClockReg_S <= '0';
				APSChipColSRInReg_S    <= '1';

				ColState_DN <= stColSRFeedATick;

			when stColSRFeedATick =>
				APSChipColSRClockReg_S <= '1';
				APSChipColSRInReg_S    <= '1';

				ColState_DN <= stColSRFeedB;

			when stColSRFeedB =>
				APSChipColSRClockReg_S <= '0';
				APSChipColSRInReg_S    <= '1';

				ColState_DN <= stColSRFeedBTick;

			when stColSRFeedBTick =>
				APSChipColSRClockReg_S <= '1';
				APSChipColSRInReg_S    <= '1';

				if CHIP_HAS_GLOBAL_SHUTTER = '1' and APSADCConfigReg_D.GlobalShutter_S = '1' then
					-- Only switch to global shutter on chips supporting it.
					ColState_DN <= stGSReset;
				else
					ColState_DN <= stRSReset;

					-- RS: open APS TXGate before first reset.
					-- Opening it "again" when feeding in B has no impact.
					APSChipTXGateReg_SN <= '1';
				end if;

			when stRSFeedTick =>
				APSChipColSRClockReg_S <= '1';
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
					ColState_DN <= stRSReset;
				end if;

			when stRSReset =>
				if ColumnReadAPosition_D = CHIP_APS_SIZE_COLUMNS then
					APSChipColModeReg_DN <= COLMODE_NULL;
				else
					-- Do reset.
					APSChipColModeReg_DN <= COLMODE_RESETA;
				end if;

				if ResetTimeDone_S = '1' then
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
						ExposureDelayClear_S <= '1';
					end if;
				end if;

				ResetTimeCount_S <= '1';

			when stRSSwitchToReadA =>
				APSChipColModeReg_DN <= COLMODE_NULL;

				-- Start off the Row SM.
				RowReadStart_SN <= '1';
				ColState_DN     <= stRSReadA;

			when stRSReadA =>
				if ColumnReadAPosition_D = CHIP_APS_SIZE_COLUMNS then
					APSChipColModeReg_DN <= COLMODE_NULL;
				else
					-- Do column read A.
					APSChipColModeReg_DN <= COLMODE_READA;
				end if;

				-- Wait for the Row SM to complete its readout.
				if RowReadDone_SP = '1' then
					ColState_DN              <= stRSSwitchToReadB;
					ColumnReadAPositionInc_S <= '1';
				end if;

			when stRSSwitchToReadB =>
				APSChipColModeReg_DN <= COLMODE_NULL;

				-- Start off the Row SM.
				RowReadStart_SN <= '1';
				ColState_DN     <= stRSReadB;

			when stRSReadB =>
				if ReadBSRStatus_DP /= RBSTAT_NORMAL then
					APSChipColModeReg_DN <= COLMODE_NULL;
				else
					-- Do column read B.
					APSChipColModeReg_DN <= COLMODE_READB;
				end if;

				-- Wait for the Row SM to complete its readout.
				if RowReadDone_SP = '1' then
					-- If exposure time hasn't expired or we haven't yet even shifted in one
					-- 0 into the column SR, we first do that.
					if ExposureDelayDone_S = '1' and ReadBSRStatus_DP /= RBSTAT_NEED_ZERO_ONE then
						if ReadBSRStatus_DP = RBSTAT_NEED_ONE then
							-- If the 1 that represents the B read hasn't yet been shifted
							-- in, do so now.
							ColState_DN      <= stColSRFeedB;
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

			when stGSReset =>
				-- Do reset.
				APSChipColModeReg_DN <= COLMODE_RESETA;

				-- Open TXGate if requested during reset.
				if APSADCConfigReg_D.GSTXGateOpenReset_S = '1' then
					APSChipTXGateReg_SN <= '1';
				end if;

				if ResetTimeDone_S = '1' then
					if APSADCConfigReg_D.ResetRead_S = '1' then
						ColState_DN <= stGSSwitchToReadA;
					else
						ColState_DN <= stGSStartExposure;
					end if;
				end if;

				ResetTimeCount_S <= '1';

			when stGSSwitchToReadA =>
				APSChipColModeReg_DN <= COLMODE_NULL;

				-- Close TXGate again after reset.
				APSChipTXGateReg_SN <= '0';

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

				if RowReadDone_SP = '1' then
					ColState_DN              <= stGSReadAFeedTick;
					ColumnReadAPositionInc_S <= '1';
				end if;

			when stGSReadAFeedTick =>
				APSChipColSRClockReg_S <= '1';
				APSChipColSRInReg_S    <= '0';

				if ColumnReadAPosition_D = CHIP_APS_SIZE_COLUMNS then
					-- Done with reset read.
					ColState_DN <= stGSStartExposure;
				else
					ColState_DN <= stGSSwitchToReadA;
				end if;

			when stGSStartExposure =>
				APSChipColModeReg_DN <= COLMODE_NULL;

				-- TXGate must be open during exposure.
				APSChipTXGateReg_SN <= '1';

				-- Start exposure.
				ExposureDelayClear_S <= '1';
				ColState_DN          <= stGSEndExposure;

			when stGSEndExposure =>
				APSChipColModeReg_DN <= COLMODE_NULL;

				if ExposureDelayDone_S = '1' then
					-- Exposure completed, close TXGate and shift in read pattern.
					APSChipTXGateReg_SN <= '0';
					ColState_DN         <= stGSColSRFeedB1;
				end if;

			when stGSColSRFeedB1 =>
				APSChipColSRClockReg_S <= '0';
				APSChipColSRInReg_S    <= '1';

				ColState_DN <= stGSColSRFeedB1Tick;

			when stGSColSRFeedB1Tick =>
				APSChipColSRClockReg_S <= '1';
				APSChipColSRInReg_S    <= '1';

				ColState_DN <= stGSColSRFeedB0;

			when stGSColSRFeedB0 =>
				APSChipColSRClockReg_S <= '0';
				APSChipColSRInReg_S    <= '0';

				ColState_DN <= stGSColSRFeedB0Tick;

			when stGSColSRFeedB0Tick =>
				APSChipColSRClockReg_S <= '1';
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

				if RowReadDone_SP = '1' then
					ColState_DN              <= stGSReadBFeedTick;
					ColumnReadBPositionInc_S <= '1';
				end if;

			when stGSReadBFeedTick =>
				APSChipColSRClockReg_S <= '1';
				APSChipColSRInReg_S    <= '0';

				if ColumnReadBPosition_D = CHIP_APS_SIZE_COLUMNS then
					-- Done with signal read.
					ColState_DN <= stEndFrame;
				else
					ColState_DN <= stGSSwitchToReadB;
				end if;

			when stEndFrame =>
				-- Setup exposureDelay counter to count frame delay instead of exposure.
				ExposureDelayLimit_D <= APSADCConfigReg_D.FrameDelay_D;
				ExposureDelayClear_S <= '1';

				-- Zero column counters too.
				ColumnReadAPositionZero_S <= '1';
				ColumnReadBPositionZero_S <= '1';

				-- Write out end of frame marker. This and the start of frame marker are the only
				-- two events from this SM that always have to be committed and are never dropped.
				if OutFifoControl_SI.Full_S = '0' then
					OutFifoDataRegCol_D       <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_ENDFRAME;
					OutFifoDataRegColEnable_S <= '1';
					OutFifoWriteRegCol_S      <= '1';

					ColState_DN <= stWaitFrameDelay;
				end if;

			when stWaitFrameDelay =>
				-- Wait until enough time has passed between frames.
				ExposureDelayLimit_D <= APSADCConfigReg_D.FrameDelay_D;

				if ExposureDelayDone_S = '1' then
					ColState_DN <= stIdle;

					-- Ensure config reg is up-to-date when entering Idle state.
					APSADCConfigRegEnable_S <= '1';
				end if;

			when others => null;
		end case;
	end process columnMainStateMachine;

	apsStandardROI : if ENABLE_QUAD_ROI = false generate
	begin
		-- Concurrently calculate if the current row has to be read out or not.
		-- If not (like with ROI), we can just fast jump parts of that row.
		CurrentColumnAValid_S <= '1' when (ColumnReadAPosition_D >= APSADCConfigReg_D.StartColumn0_D and ColumnReadAPosition_D <= APSADCConfigReg_D.EndColumn0_D) else '0';
		CurrentColumnBValid_S <= '1' when (ColumnReadBPosition_D >= APSADCConfigReg_D.StartColumn0_D and ColumnReadBPosition_D <= APSADCConfigReg_D.EndColumn0_D) else '0';

		CurrentRowValid_S <= '1' when (RowReadPosition_D >= APSADCConfigReg_D.StartRow0_D and RowReadPosition_D <= APSADCConfigReg_D.EndRow0_D) else '0';
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
		-- Concurrently calculate if the current row has to be read out or not.
		-- If not (like with ROI), we can just fast jump parts of that row.
		ColumnA0Valid_S <= ColumnReadAPosition_D >= APSADCConfigReg_D.StartColumn0_D and ColumnReadAPosition_D <= APSADCConfigReg_D.EndColumn0_D;
		ColumnB0Valid_S <= ColumnReadBPosition_D >= APSADCConfigReg_D.StartColumn0_D and ColumnReadBPosition_D <= APSADCConfigReg_D.EndColumn0_D;
		Row0Valid_S     <= RowReadPosition_D >= APSADCConfigReg_D.StartRow0_D and RowReadPosition_D <= APSADCConfigReg_D.EndRow0_D;

		ColumnA1Valid_S <= ColumnReadAPosition_D >= APSADCConfigReg_D.StartColumn1_D and ColumnReadAPosition_D <= APSADCConfigReg_D.EndColumn1_D;
		ColumnB1Valid_S <= ColumnReadBPosition_D >= APSADCConfigReg_D.StartColumn1_D and ColumnReadBPosition_D <= APSADCConfigReg_D.EndColumn1_D;
		Row1Valid_S     <= RowReadPosition_D >= APSADCConfigReg_D.StartRow1_D and RowReadPosition_D <= APSADCConfigReg_D.EndRow1_D;

		ColumnA2Valid_S <= ColumnReadAPosition_D >= APSADCConfigReg_D.StartColumn2_D and ColumnReadAPosition_D <= APSADCConfigReg_D.EndColumn2_D;
		ColumnB2Valid_S <= ColumnReadBPosition_D >= APSADCConfigReg_D.StartColumn2_D and ColumnReadBPosition_D <= APSADCConfigReg_D.EndColumn2_D;
		Row2Valid_S     <= RowReadPosition_D >= APSADCConfigReg_D.StartRow2_D and RowReadPosition_D <= APSADCConfigReg_D.EndRow2_D;

		ColumnA3Valid_S <= ColumnReadAPosition_D >= APSADCConfigReg_D.StartColumn3_D and ColumnReadAPosition_D <= APSADCConfigReg_D.EndColumn3_D;
		ColumnB3Valid_S <= ColumnReadBPosition_D >= APSADCConfigReg_D.StartColumn3_D and ColumnReadBPosition_D <= APSADCConfigReg_D.EndColumn3_D;
		Row3Valid_S     <= RowReadPosition_D >= APSADCConfigReg_D.StartRow3_D and RowReadPosition_D <= APSADCConfigReg_D.EndRow3_D;

		CurrentColumnAValid_S <= '1' when (ColumnA0Valid_S or ColumnA1Valid_S or ColumnA2Valid_S or ColumnA3Valid_S) else '0';
		CurrentColumnBValid_S <= '1' when (ColumnB0Valid_S or ColumnB1Valid_S or ColumnB2Valid_S or ColumnB3Valid_S) else '0';
		CurrentRowValid_S     <= '1' when (Row0Valid_S or Row1Valid_S or Row2Valid_S or Row3Valid_S) else '0';
	end generate apsQuadROI;

	rowReadStateMachine : process(RowState_DP, APSADCConfigReg_D, APSADCData_DI, OutFifoControl_SI, APSChipColModeReg_DP, CurrentRowValid_S, RowReadStart_SP, SettleTimesDone_S, RowReadPosition_D)
	begin
		RowState_DN <= RowState_DP;

		OutFifoWriteRegRow_S      <= '0';
		OutFifoDataRegRowEnable_S <= '0';
		OutFifoDataRegRow_D       <= (others => '0');

		APSChipRowSRClockReg_S <= '0';
		APSChipRowSRInReg_S    <= '0';

		-- Row counters.
		RowReadPositionZero_S <= '0';
		RowReadPositionInc_S  <= '0';

		-- Settle times counter. By default count row settle time.
		SettleTimesLimit_D <= APSADCConfigReg_D.RowSettle_D;
		SettleTimesCount_S <= '0';

		-- Column SM communication.
		RowReadDone_SN <= '0';

		case RowState_DP is
			when stIdle =>
				-- Wait until the main column state machine signals us to do a row read.
				if RowReadStart_SP = '1' then
					RowState_DN <= stColSettleWait;
				end if;

				-- Setup proper source for column settle time (used in next state).
				SettleTimesLimit_D <= APSADCConfigReg_D.ColumnSettle_D;

			when stColSettleWait =>
				-- Wait for the column selection to be valid. We do this here so we don't have to duplicate
				-- this code in every column state inside the main column state machine.
				if SettleTimesDone_S = '1' then
					RowState_DN <= stRowSRInit;
				end if;

				SettleTimesCount_S <= '1';

				-- Keep proper source for column settle time selected while counting it.
				SettleTimesLimit_D <= APSADCConfigReg_D.ColumnSettle_D;

			when stRowSRInit =>
				APSChipRowSRClockReg_S <= '0';
				APSChipRowSRInReg_S    <= '1';

				-- Write event only if FIFO has place, else wait.
				-- If fake read (COLMODE_NULL), don't write anything.
				if OutFifoControl_SI.Full_S = '0' and APSChipColModeReg_DP /= COLMODE_NULL then
					if APSChipColModeReg_DP = COLMODE_READA then
						OutFifoDataRegRow_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTRESETCOL;
					else
						OutFifoDataRegRow_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTSIGNALCOL;
					end if;
					OutFifoDataRegRowEnable_S <= '1';
					OutFifoWriteRegRow_S      <= '1';
				end if;

				if OutFifoControl_SI.Full_S = '0' or APSChipColModeReg_DP = COLMODE_NULL or APSADCConfigReg_D.WaitOnTransferStall_S = '0' then
					RowState_DN <= stRowSRInitTick;
				end if;

			when stRowSRInitTick =>
				APSChipRowSRClockReg_S <= '1';
				APSChipRowSRInReg_S    <= '1';

				if CurrentRowValid_S = '1' then
					RowState_DN <= stRowSettleWait;
				else
					RowState_DN <= stRowFastJump;
				end if;

			when stRowSRFeedTick =>
				APSChipRowSRClockReg_S <= '1';
				APSChipRowSRInReg_S    <= '0';

				-- Check if we're done. This means that we just clock the 1 in the RowSR out,
				-- leaving it clean at only zeros. Further, the row read position is at the
				-- maximum, so we can detect that, zero it and exit.
				if RowReadPosition_D = CHIP_APS_SIZE_ROWS then
					RowState_DN           <= stRowDone;
					RowReadPositionZero_S <= '1';
				else
					if CurrentRowValid_S = '1' then
						RowState_DN <= stRowSettleWait;
					else
						RowState_DN <= stRowFastJump;
					end if;
				end if;

			when stRowSettleWait =>
				-- Wait for the row selection to be valid.
				if SettleTimesDone_S = '1' then
					RowState_DN <= stRowWriteEvent;
				end if;

				SettleTimesCount_S <= '1';

			when stRowWriteEvent =>
				-- Write event only if FIFO has place, else wait.
				if OutFifoControl_SI.Full_S = '0' and APSChipColModeReg_DP /= COLMODE_NULL then
					OutFifoDataRegRow_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_ADC_SAMPLE;
					OutFifoDataRegRow_D(APS_ADC_BUS_WIDTH - 1 downto 0)         <= APSADCData_DI;

					OutFifoDataRegRowEnable_S <= '1';
					OutFifoWriteRegRow_S      <= '1';
				end if;

				if OutFifoControl_SI.Full_S = '0' or APSChipColModeReg_DP = COLMODE_NULL or APSADCConfigReg_D.WaitOnTransferStall_S = '0' then
					RowState_DN          <= stRowSRFeedTick;
					RowReadPositionInc_S <= '1';
				end if;

			when stRowFastJump =>
				RowState_DN          <= stRowSRFeedTick;
				RowReadPositionInc_S <= '1';

			when stRowDone =>
				-- Write event only if FIFO has place, else wait.
				if OutFifoControl_SI.Full_S = '0' and APSChipColModeReg_DP /= COLMODE_NULL then
					OutFifoDataRegRow_D       <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_ENDCOL;
					OutFifoDataRegRowEnable_S <= '1';
					OutFifoWriteRegRow_S      <= '1';
				end if;

				if OutFifoControl_SI.Full_S = '0' or APSChipColModeReg_DP = COLMODE_NULL or APSADCConfigReg_D.WaitOnTransferStall_S = '0' then
					RowState_DN    <= stIdle;
					RowReadDone_SN <= '1';
				end if;

			when others => null;
		end case;
	end process rowReadStateMachine;

	-- FIFO output can be driven by both the column or the row state machines.
	-- Care must be taken to never have both at the same time output meaningful data.
	OutFifoWriteReg_S      <= OutFifoWriteRegCol_S or OutFifoWriteRegRow_S;
	OutFifoDataRegEnable_S <= OutFifoDataRegColEnable_S or OutFifoDataRegRowEnable_S;
	OutFifoDataReg_D       <= OutFifoDataRegCol_D or OutFifoDataRegRow_D;

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
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			ColState_DP <= stIdle;
			RowState_DP <= stIdle;

			ADCRunning_SP <= '0';

			RowReadStart_SP <= '0';
			RowReadDone_SP  <= '0';

			ReadBSRStatus_DP <= RBSTAT_NEED_ZERO_ONE;

			OutFifoControl_SO.Write_S <= '0';

			APSChipRowSRClock_SO <= '0';
			APSChipRowSRIn_SO    <= '0';
			APSChipColSRClock_SO <= '0';
			APSChipColSRIn_SO    <= '0';
			APSChipColModeReg_DP <= COLMODE_NULL;
			APSChipTXGateReg_SP  <= '0';

			APSADCOutputEnable_SBO <= '1';
			APSADCStandby_SO       <= '1';

			-- APS ADC config from another clock domain.
			APSADCConfigReg_D     <= tAPSADCConfigDefault;
			APSADCConfigSyncReg_D <= tAPSADCConfigDefault;
		elsif rising_edge(Clock_CI) then
			ColState_DP <= ColState_DN;
			RowState_DP <= RowState_DN;

			ADCRunning_SP <= ADCRunning_SN;

			RowReadStart_SP <= RowReadStart_SN;
			RowReadDone_SP  <= RowReadDone_SN;

			ReadBSRStatus_DP <= ReadBSRStatus_DN;

			OutFifoControl_SO.Write_S <= OutFifoWriteReg_S;

			APSChipRowSRClock_SO <= APSChipRowSRClockReg_S;
			APSChipRowSRIn_SO    <= APSChipRowSRInReg_S;
			APSChipColSRClock_SO <= APSChipColSRClockReg_S;
			APSChipColSRIn_SO    <= APSChipColSRInReg_S;
			APSChipColModeReg_DP <= APSChipColModeReg_DN;
			APSChipTXGateReg_SP  <= APSChipTXGateReg_SN;

			APSADCOutputEnable_SBO <= APSADCOutputEnableReg_SB;
			APSADCStandby_SO       <= APSADCStandbyReg_S;

			-- APS ADC config from another clock domain.
			if APSADCConfigRegEnable_S = '1' then
				APSADCConfigReg_D <= APSADCConfigSyncReg_D;
			end if;
			APSADCConfigSyncReg_D <= APSADCConfig_DI;
		end if;
	end process p_memoryzing;

	-- The output of this register goes to an intermediate signal, since we need to access it
	-- inside this module. That's not possible with 'out' signal directly.
	APSChipColMode_DO <= APSChipColModeReg_DP;
	APSChipTXGate_SBO <= not APSChipTXGateReg_SP;
end architecture Behavioral;
