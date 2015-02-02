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

entity D4AAPSADCStateMachine is
	generic(
		ENABLE_QUAD_ROI : boolean := false);
	port(
		Clock_CI               : in  std_logic; -- This clock must be 30MHz, use PLL to generate.
		Reset_RI               : in  std_logic; -- This reset must be synchronized to the above clock.

		-- Fifo output (to Multiplexer, must be a dual-clock FIFO)
		OutFifoControl_SI      : in  tFromFifoWriteSide;
		OutFifoControl_SO      : out tToFifoWriteSide;
		OutFifoData_DO         : out std_logic_vector(EVENT_WIDTH - 1 downto 0);

		APSRowSRClock_CO   : out std_logic;
		APSRowSRIn_SO      : out std_logic;
		APSColSRClock_CO   : out std_logic;
		APSColSRIn_SO      : out std_logic;
		APSGS_SBO      : out std_logic;
		APSOVG_SO	: out std_logic;
		APSTX_SO      : out std_logic;
		APSRST_SO	: out std_logic;

		ChipADCRampClock_CO          : out  std_logic;
		ChipADCRampBitIn_SO     : out std_logic;
		ChipADCRampClear_SO     : out std_logic;
		ChipADCScanClock_CO         : out std_logic;
		ChipADCScanControl_SO         : out std_logic;
		ChipADCSample_SO         : out std_logic;

		-- Configuration input
		APSADCConfig_DI        : in  tAPSADCConfig);
end entity D4AAPSADCStateMachine;

architecture Behavioral of D4AAPSADCStateMachine is
	attribute syn_enum_encoding : string;

	type tPixelState is (stRSIdle, stRSRowSettle, stRSSample1, stRSChargeTransfer, stRSSample2, stRSCpReset, stRSCpSettle, stRSSample3, stGSIdle, stGSPDReset, stGSExposureStart, stGSChargeTransfer, stGSExposureEnd, stGSSwitchToReadout, stGSReadoutStart, stGSSample1, stGSFDReset, stGSSample2, stGSCpResetFD, stGSCpResetSettle, stGSSample3, stGSCurrentRowEnd);
	attribute syn_enum_encoding of tPixelState : type is "onehot";

	-- present and next state
	signal PixelState_DP, PixelState_DN : tPixelState;

	type tRowSRState is (stIdle, stRSExposureStart, stRSExposureEnd, stGSReadout);
	attribute syn_enum_encoding of tRowSRState : type is "onehot";

	-- present and next state
	signal RowSRState_DP, RowSRState_DN : tRowSRState;
	
	type tChipADCState is (stIdle, stSettle, stConvert, stScan);
	attribute syn_enum_encoding of tChipADCState : type is "onehot";

	-- present and next state
	signal ChipADCState_DP, ChipADCState_DN : tChipADCState;

	constant ADC_STARTUP_CYCLES      : integer := ADC_CLOCK_FREQ * 20; -- At 30MHz, wait 20 microseconds.
	constant ADC_STARTUP_CYCLES_SIZE : integer := integer(ceil(log2(real(ADC_STARTUP_CYCLES))));

	constant COLMODE_NULL   : std_logic_vector(1 downto 0) := "00";
	constant COLMODE_READA  : std_logic_vector(1 downto 0) := "01";
	constant COLMODE_READB  : std_logic_vector(1 downto 0) := "10";
	constant COLMODE_RESETA : std_logic_vector(1 downto 0) := "11";

	-- Take note if the ADC is running already or not. If not, it has to be started.
	signal ADCRunning_SP, ADCRunning_SN : std_logic;

	signal ADCStartupCount_S, ADCStartupDone_S : std_logic;

	-- Exposure time counter.
	signal ExposureClear_S, ExposureDone_S : std_logic;

	-- Frame delay (between consecutive frames) counter.
	signal FrameDelayCount_S, FrameDelayDone_S : std_logic;

	-- Reset time counter (make bigger to allow for long resets if needed).
	signal ResetTimeCount_S, ResetTimeDone_S : std_logic;

	-- Lengthen the NULL states between different, active column states.
	signal NullTimeCount_S, NullTimeDone_S : std_logic;

	-- Column settle time (before first row is read, like an additional offset).
	signal ColSettleTimeCount_S, ColSettleTimeDone_S : std_logic;

	-- Row settle time counter.
	signal RowSettleTimeCount_S, RowSettleTimeDone_S : std_logic;

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
	signal APSRowSRClockReg_C, APSRowSRInReg_S  : std_logic;
	signal APSColSRClockReg_C, APSColSRInReg_S  : std_logic;
	signal APSGSReg_SB, APSOVGReg_S, APSTXReg_S, APSRSTReg_S     : std_logic;
	signal ChipADCSampleReg_S, ChipADCRampClockReg_C, ChipADCRampBitInReg_S, ChipADCRampClearReg_S   : std_logic;
	signal ChipADCScanClockReg_C, ChipADCScanControlReg_S : std_logic;

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

	columnSettleTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_COLSETTLETIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => ColSettleTimeCount_S,
			DataLimit_DI => APSADCConfigReg_D.ColumnSettle_D,
			Overflow_SO  => ColSettleTimeDone_S,
			Data_DO      => open);

	RSRowSettleTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_RSROWSETTLETIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => RSRowSettleTimeCount_S,
			DataLimit_DI => APSADCConfigReg_D.RSRowSettle_D,
			Overflow_SO  => RSRowSettleTimeDone_S,
			Data_DO      => open);

	PixelStateMachine : process(ColState_DP, OutFifoControl_SI, ADCRunning_SP, ADCStartupDone_S, APSADCConfigReg_D, RowReadDone_SP, NullTimeDone_S, ResetTimeDone_S, APSChipTXGateReg_SP, ColumnReadAPosition_D, ColumnReadBPosition_D, ReadBSRStatus_DP, CurrentColumnAValid_S, CurrentColumnBValid_S, ExposureDone_S, FrameDelayDone_S)
	begin
		PixelState_DN <= PixelState_DP;     -- Keep current state by default.

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

		case PixelState_DP is
			when stRSIdle =>
				APSRSTReg_S <= '1';
				APSTXReg_S <= '0';
				APSOVGReg_S <= '0';
				APSGSReg_SB <= '1';
				ChipADCSample_S <= '0';

				if APSADCConfigReg_D.GlobalShutter_S = '0' and APSRowSRClockReg_C = '1' then
					PixelState_DN <= stRSRowSettle;
					RSRowSettleTimeCount_S <= '1';
				else if APSADCConfigReg_D.GlobalShutter_S = '1' then
					PixelState_DN <= stGSIdle;
				end if;

			when stRSRowSettle =>
				
				if RSRowSettleTimeDone_S = '1' then
					PixelState_DN   <= stRSSample1;
				end if;

			when stRSSample1 =>
				RSRowSettleTimeCount_S <= '0';
				APSRSTReg_S <= '0';
				ChipADCSample_S <= '1';
				
				if ChipADCSampleDone_S = '1' then
					PixelState_DN <= stRSChargeTransfer;
				end if;

			when stRSChargeTransfer =>
				ChipADCSample_S <= '0';
				APSTXReg_S <= '1';
				RSTransferTimeCount_S <= '1';

				if RSTransferTimeDone_S = '1' then
					PixelState_DN <= stRSSample2;
				end if;

			when stRSSample2 =>
				RSTransferTimeCount_S <= '0';
				APSTXReg_S <= '0';
				ChipADCSample_S <= '1';
				
				if ChipADCSampleDone_S = '1' then
					PixelState_DN <= stRSCpReset;
				end if;
				
			when stRSCpReset =>
				ChipADCSample_S <= '0';
				APSTXReg_S <= '1';
				APSOVGReg_S <= '1';
				RSCpResetTimeCount_S <= '1';
				
				if RSCpResetTimeDone_S = '1' then
					PixelState_DN <= stRSCpSettle;
				end if;

			when stRSCpSettle =>
				RSCpResetTimeCount_S <= '0';
				APSOVGReg_S <= '0';
				RSCpSettleTimeCount_S <= '1';
				
				if RSCpSettleTimeDone_S = '1' then
					PixelState_DN <= stRSSample3;
				end if;

			when stRSSample3 =>
				RSCpSettleTimeCount_S <= '0';
				APSTXReg_S <= '0';
				ChipADCSample_S <= '1';
				
				if ChipADCSampleDone_S = '1' then
					PixelState_DN <= stRSidle;
				end if;
				
			when stGSIdle =>
				APSRSTReg_S <= '1';
				APSTXReg_S <= '0';
				APSOVGReg_S <= '1';
				APSGSReg_SB <= '0';
				ChipADCSample_S <= '0';
				
				if APSADCConfigReg_D.GlobalShutter_S = '1' and APSFrameInitiate_S = '1' then
					PixelState_DN <= stGSPDReset;
				else if APSADCConfigReg_D.GlobalShutter_S = '0' then
					PixelState_DN <= stRSIdle;
				end if;
				
			when stGSPDReset =>
				GSPDResetTimeCount_S <= '1';
				
				if GSPDResetTimeDone_S = '1' then
					PixelState_DN <= stGSExposureStart;
				end if;
				
			when stGSExposureStart =>
				GSPDResetTimeCount_S <= '0';
				APSOVGReg_S <= '0';
				GSExposureTimeCount_S <= '1';
				
				if GSExposureTimeDone_S = '1' then
					PixelState_DN <= stGSChargeTransfer;
				end if;
				
			when stGSChargeTransfer =>
				GSExposureTimeCount_S <= '0';
				APSRSTReg_S <= '0';
				APSTXReg_S <= '1';
				GSTransferTimeCount_S <= '1';
				
				if GSTransferTimeDone_S = '1' then
					PixelState_DN <= stGSExposureEnd;
				end if;
				
			when stGSExposureEnd =>
				GSTransferTimeCount_S <= '0';
				APSTXReg_S <= '0';
				GSTXFallTimeCount_S <= '1';
				
				if GSTXFallTimeDone_S = '1' then
					PixelState_DN <= stGSSwitchToReadout;
				end if;
				
			when stGSSwitchToReadout =>
				GSTXFallTimeCount_S <= '0';
				APSOVGReg_S <= '1';
				PixelState_DN <= stGSReadoutStart;
				
			when stGSReadoutStart =>
				APSGSReg_SB <= '1';
				RowReadPositionInc_S <= '1';
				
				if APSRowSRClockReg_C = '1' then
					PixelState_DN <= stGSSample1;
				end if;
				
			when stGSSample1 =>
				ChipADCSample_S <= '1';
				
				if ChipADCSampleDone_S = '1' then
					PixelState_DN <= stGSFDReset;
				end if;
				
			when stGSFDReset =>
				ChipADCSample_S <= '0';
				GSFDResetTimeCount_S <= '1';
				
				if GSFDResetTimeDone_S = '1' then
					PixelState_DN <= stGSSample2;
				end if;
				
			when stGSSample2 =>
				GSFDResetTimeCount_S <= '0';
				ChipADCSample_S <= '1';
				
				if ChipADCSampleDone_S = '1' then
					PixelState_DN <= stGSCpResetFD;
				end if;
				
			when stGSCpResetFD =>
				ChipADCSample_S <= '0';
				APSTXReg_S <= '1';
				GSCpResetFDTimeCount_S <= '1';
				
				if GSCpResetFDTimeDone_S = '1' then
					PixelState_DN <= stGSCpResetSettle;
				end if;
			
			when stGSCpResetSettle =>
				GSCpResetFDTimeCount_S <= '0';
				APSOVGReg_S <= '0';
				GSCpResetSettleTimeCount_S <= '1';
				
				if GSCpResetSettleTimeDone_S = '1' then
					PixelState_DN <= stGSSample3;
				end if;
				
			when stGSSample3 =>
				GSCpResetSettleTimeCount_S <= '0';
				APSTXReg_S <= '0';
				GSTXFallTimeCount_S <= '1';
				ChipADCSample_S <= '1';
				
				if ChipADCSampleDone_S = '1' and GSTXFallTimeDone_S <= '1' then
					PixelState_DN <= stGSCurrentRowEnd;
				end if;
				
			when stGSCurrentRowEnd =>
				GSTXFallTimeCount_S <= '0';
				ChipADCSample_S <= '0';
				APSOVGReg_S <= '1';
				
				if RowReadPosition_D = CHIP_APS_SIZE_ROWS then
					PixelState_DN <= stGSIdle;
				else
					PixelState_DN <= stGSReadoutStart;
				end if;
				
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

	rowReadStateMachine : process(RowState_DP, APSADCConfigReg_D, APSADCData_DI, OutFifoControl_SI, APSChipColModeReg_DP, CurrentRowValid_S, RowReadStart_SP, RowReadPosition_D, ColSettleTimeDone_S, RowSettleTimeDone_S)
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

		-- Settle times counters (column and row).
		ColSettleTimeCount_S <= '0';
		RowSettleTimeCount_S <= '0';

		-- Column SM communication.
		RowReadDone_SN <= '0';

		case RowState_DP is
			when stIdle =>
				-- Wait until the main column state machine signals us to do a row read.
				if RowReadStart_SP = '1' then
					RowState_DN <= stRowSRFeedInit;
				end if;

			when stRowSRFeedInit =>
				-- We first feed in the row register pattern, since the column settle time
				-- has to pass _after_ the first row has been selected.
				APSChipRowSRClockReg_S <= '0';
				APSChipRowSRInReg_S    <= '1';

				RowState_DN <= stRowSRFeedInitTick;

			when stRowSRFeedInitTick =>
				APSChipRowSRClockReg_S <= '1';
				APSChipRowSRInReg_S    <= '1';

				RowState_DN <= stColSettleWait;

			when stColSettleWait =>
				-- Additional wait for the column selection to be valid, once both the colum and
				-- the current row pattern have been shifted in. We do this here, because the row
				-- pattern also has to have been shifted in for this to be effective.
				if ColSettleTimeDone_S = '1' then
					RowState_DN <= stRowStart;
				end if;

				ColSettleTimeCount_S <= '1';

			when stRowStart =>
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
					-- Same decision to do here as in stRowSRFeedTick.
					if CurrentRowValid_S = '1' then
						RowState_DN <= stRowSettleWait;
					else
						RowState_DN <= stRowFastJump;
					end if;
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
				if RowSettleTimeDone_S = '1' then
					RowState_DN <= stRowWriteEvent;
				end if;

				RowSettleTimeCount_S <= '1';

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
