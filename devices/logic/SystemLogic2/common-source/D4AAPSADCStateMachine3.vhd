library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.D4AAPSADCConfigRecords.all;
use work.Settings.APS_ADC_BUS_WIDTH;
use work.Settings.CHIP_APS_SIZE_COLUMNS;
use work.Settings.CHIP_APS_SIZE_ROWS;
use work.Settings.CHIP_APS_HAS_GLOBAL_SHUTTER;

entity D4AAPSADCStateMachine3 is
	port(
		Clock_CI                 : in  std_logic; -- This clock must be 30MHz, use PLL to generate.
		Reset_RI                 : in  std_logic; -- This reset must be synchronized to the above clock.

		-- Fifo output (to Multiplexer, must be a dual-clock FIFO)
		OutFifoControl_SI        : in  tFromFifoWriteSide;
		OutFifoControl_SO        : out tToFifoWriteSide;
		OutFifoData_DO           : out std_logic_vector(EVENT_WIDTH - 1 downto 0);

		APSChipColSRClock_CO     : out std_logic;
		APSChipColSRIn_SO        : out std_logic;
		APSChipRowSRClock_CO     : out std_logic;
		APSChipRowSRIn_SO        : out std_logic;
		APSChipOverflowGate_SO   : out std_logic;
		APSChipTXGate_SO         : out std_logic;
		APSChipReset_SO          : out std_logic;
		APSChipGlobalShutter_SBO : out std_logic;

		ChipADCData_DI           : in  std_logic_vector(APS_ADC_BUS_WIDTH - 1 downto 0);
		ChipADCRampClear_SO      : out std_logic;
		ChipADCRampClock_CO      : out std_logic;
		ChipADCRampBitIn_SO      : out std_logic;
		ChipADCScanClock_CO      : out std_logic;
		ChipADCScanControl_SO    : out std_logic;
		ChipADCSample_SO         : out std_logic;
		ChipADCGrayCounter_DO    : out std_logic_vector(APS_ADC_BUS_WIDTH - 1 downto 0);
		Debug_DO    : out std_logic_vector(1 downto 0);

		-- Configuration input
		D4AAPSADCConfig_DI       : in  tD4AAPSADCConfig);
end entity D4AAPSADCStateMachine3;

architecture Behavioral of D4AAPSADCStateMachine3 is
	attribute syn_enum_encoding : string;

	type tPixelState is (stIdle, stStartFrame, stRSIdle, stRSReadoutFeedOne1, stRSReadoutFeedOne1Tick, stRSReadoutFeedOne2, stRSReadoutFeedOne2Tick, stRSReadoutFeedOne3, stRSReadoutFeedOne3Tick, stRSFDSettle, stRSSample1Start, stRSSample1Done, stRSChargeTransfer, stRSSample2Start, stRSSample2Done,
		                 stRSFeed, stRSFeedTick, stGSIdle, stGSPDReset, stGSExposureStart, stGSResetFallTime, stGSChargeTransfer, stGSExposureEnd, stGSSwitchToReadout1, stGSSwitchToReadout2, stGSReadoutFeedOne, stGSReadoutFeedOneTick, stGSReadoutFeedZero, stGSReadoutFeedZeroTick, stGSSample1Start, stGSSample1Done,
		                 stGSFDReset, stGSSample2Start, stGSSample2Done, stEndFrame, stWaitFrameDelay);
	attribute syn_enum_encoding of tPixelState : type is "onehot";

	-- present and next state
	signal PixelState_DP, PixelState_DN : tPixelState;

	-- Row and column read counters.
	signal RowReadPositionZero_S, RowReadPositionInc_S       : std_logic;
	signal RowReadPosition_D                                 : unsigned(CHIP_APS_SIZE_ROWS'range);
	signal ColumnReadPositionZero_S, ColumnReadPositionInc_S : std_logic;
	signal ColumnReadPosition_D                              : unsigned(CHIP_APS_SIZE_COLUMNS'range);

	-- Exposure time counter.
	signal ExposureClear_S, ExposureTimeDone_S : std_logic;

	-- Charge transfer time counter.
	signal TransferTimeCount_S, TransferTimeDone_S : std_logic;

	-- Frame delay (between consecutive frames) counter.
	signal FrameDelayCount_S, FrameDelayDone_S : std_logic;

	-- RS specific time counters.
	signal RSFDSettleTimeCount_S, RSFDSettleTimeDone_S : std_logic;
	signal RSCpResetTimeCount_S, RSCpResetTimeDone_S   : std_logic;
	signal RSCpSettleTimeCount_S, RSCpSettleTimeDone_S : std_logic;

	-- GS specific time counters.
	signal GSPDResetTimeCount_S, GSPDResetTimeDone_S             : std_logic;
	signal GSResetFallTimeCount_S, GSResetFallTimeDone_S         : std_logic;
	signal GSTXFallTimeCount_S, GSTXFallTimeDone_S               : std_logic;
	signal GSFDResetTimeCount_S, GSFDResetTimeDone_S             : std_logic;
	signal GSCpResetFDTimeCount_S, GSCpResetFDTimeDone_S         : std_logic;
	signal GSCpResetSettleTimeCount_S, GSCpResetSettleTimeDone_S : std_logic;

	signal ClockSlowDownCount_S, ClockSlowDownDone_S : std_logic;

	-- Communication between row and column state machines. Done through a register for full decoupling.
	signal ColSampleStart_SP, ColSampleStart_SN : std_logic;
	signal ColScanStart_SP, ColScanStart_SN     : std_logic;
	signal ColSampleDone_SP, ColSampleDone_SN   : std_logic;
	signal ColScanStartAck                      : std_logic;
	signal ColSampleStartAck                    : std_logic;
	signal ColSampleDoneAck                     : std_logic;

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

	-- The column readout SM needs to know what kind of sample is being read out currently.
	signal APSSampleType_DP, APSSampleType_DN : std_logic_vector(1 downto 0);
	signal APSSampleType1_DP, APSSampleType1_DN : std_logic_vector(1 downto 0);
	signal APSSampleType2_DP, APSSampleType2_DN : std_logic_vector(1 downto 0);
	signal APSSampleType3_DP, APSSampleType3_DN : std_logic_vector(1 downto 0);
	

	constant SAMPLETYPE_NULL    : std_logic_vector(1 downto 0) := "00";
	constant SAMPLETYPE_FDRESET : std_logic_vector(1 downto 0) := "01";
	constant SAMPLETYPE_CPRESET : std_logic_vector(1 downto 0) := "10";
	constant SAMPLETYPE_SIGNAL  : std_logic_vector(1 downto 0) := "11";

	-- Register outputs to FIFO.
	signal OutFifoWriteReg_S, OutFifoWriteRegRow_S, OutFifoWriteRegCol_S                : std_logic;
	signal OutFifoDataRegEnable_S, OutFifoDataRegRowEnable_S, OutFifoDataRegColEnable_S : std_logic;
	signal OutFifoDataReg_D, OutFifoDataRegRow_D, OutFifoDataRegCol_D                   : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	-- Register all outputs to chip APS control for clean transitions.
	signal APSChipRowSRClockReg_C, APSChipRowSRInReg_S : std_logic;
	signal APSChipColSRClockReg_C, APSChipColSRInReg_S : std_logic;

	-- Register all outputs to ADC and chip for clean transitions.
	signal APSChipOverflowGateReg_SP, APSChipOverflowGateReg_SN   : std_logic;
	signal APSChipTXGateReg_SP, APSChipTXGateReg_SN               : std_logic;
	signal APSChipResetReg_SP, APSChipResetReg_SN                 : std_logic;
	signal APSChipGlobalShutterReg_SP, APSChipGlobalShutterReg_SN : std_logic;

	type tChipColSampleState is (stSampleIdle, stRowSettleWait, stColSample, stColRampFeed, stColRampFeedTick, stColRampReset, stColRampClockLow, stColRampClockHigh);
	attribute syn_enum_encoding of tChipColSampleState : type is "onehot";

	-- present and next state
	signal ChipColSampleState_DP, ChipColSampleState_DN : tChipColSampleState;

	type tChipColScanState is (stScanIdle, stColScanStart, stColScanSelect, stColScanSelectTick, stColScanReadValue, stColScanNextValue, stColScanDone);
	attribute syn_enum_encoding of tChipColScanState : type is "onehot";

	-- present and next state
	signal ChipColScanState_DP, ChipColScanState_DN : tChipColScanState;

	-- On-chip ADC control.
	signal ChipADCRampClearReg_S   : std_logic;
	signal ChipADCRampClockReg_C   : std_logic;
	signal ChipADCRampBitInReg_S   : std_logic;
	signal ChipADCScanClockReg_C   : std_logic;
	signal ChipADCScanControlReg_S : std_logic;
	signal ChipADCSampleReg_S      : std_logic;

	-- Ramp clock counter. Could be used to generate grey-code if needed too.
	signal RampTickCount1_S, RampTickCount2_S, RampTickDone_S, RampTickHalfDone_S : std_logic;

	-- Row settle time (before first column is read, like an additional offset before each sample).
	signal RowSettleTimeCount_S, RowSettleTimeDone_S : std_logic;

	-- Sample time settle counter.
	signal SampleSettleTimeCount_S, SampleSettleTimeDone_S : std_logic;

	-- Ramp reset time counter.
	signal RampResetTimeCount_S, RampResetTimeDone_S : std_logic;

	-- Scan control constants.
	constant SCAN_CONTROL_COPY_OVER    : std_logic := '0';
	constant SCAN_CONTROL_SCAN_THROUGH : std_logic := '1';

	-- Double register configuration input, since it comes from a different clock domain (LogicClock), it
	-- needs to go through a double-flip-flop synchronizer to guarantee correctness.
	signal D4AAPSADCConfigSyncReg_D, D4AAPSADCConfigReg_D : tD4AAPSADCConfig;
	signal D4AAPSADCConfigRegEnable_S                     : std_logic;
	
begin
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

	ExposureTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE              => APS_EXPOSURE_SIZE,
			RESET_ON_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => ExposureClear_S,
			Enable_SI    => '1',
			DataLimit_DI => D4AAPSADCConfigReg_D.Exposure_D,
			Overflow_SO  => ExposureTimeDone_S,
			Data_DO      => open);

	TransferTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_TRANSFERTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => TransferTimeCount_S,
			DataLimit_DI => D4AAPSADCConfigReg_D.Transfer_D,
			Overflow_SO  => TransferTimeDone_S,
			Data_DO      => open);

	FrameDelayCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_FRAMEDELAY_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => FrameDelayCount_S,
			DataLimit_DI => D4AAPSADCConfigReg_D.FrameDelay_D,
			Overflow_SO  => FrameDelayDone_S,
			Data_DO      => open);

	RSFDSettleTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_RSFDSETTLETIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => RSFDSettleTimeCount_S,
			DataLimit_DI => D4AAPSADCConfigReg_D.RSFDSettle_D,
			Overflow_SO  => RSFDSettleTimeDone_S,
			Data_DO      => open);

	RSCpResetTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_RSCPRESETTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => RSCpResetTimeCount_S,
			DataLimit_DI => D4AAPSADCConfigReg_D.RSCpReset_D,
			Overflow_SO  => RSCpResetTimeDone_S,
			Data_DO      => open);

	RSCpSettleTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_RSCPSETTLETIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => RSCpSettleTimeCount_S,
			DataLimit_DI => D4AAPSADCConfigReg_D.RSCpSettle_D,
			Overflow_SO  => RSCpSettleTimeDone_S,
			Data_DO      => open);

	GSPDResetTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_GSPDRESETTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => GSPDResetTimeCount_S,
			DataLimit_DI => D4AAPSADCConfigReg_D.GSPDReset_D,
			Overflow_SO  => GSPDResetTimeDone_S,
			Data_DO      => open);

	GSResetFallTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_GSRESETFALLTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => GSResetFallTimeCount_S,
			DataLimit_DI => D4AAPSADCConfigReg_D.GSResetFall_D,
			Overflow_SO  => GSResetFallTimeDone_S,
			Data_DO      => open);

	GSTXFallTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_GSTXFALLTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => GSTXFallTimeCount_S,
			DataLimit_DI => D4AAPSADCConfigReg_D.GSTXFall_D,
			Overflow_SO  => GSTXFallTimeDone_S,
			Data_DO      => open);

	GSFDResetTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_GSFDRESETTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => GSFDResetTimeCount_S,
			DataLimit_DI => D4AAPSADCConfigReg_D.GSFDReset_D,
			Overflow_SO  => GSFDResetTimeDone_S,
			Data_DO      => open);

	GSCpResetFDTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_GSCPRESETFDTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => GSCpResetFDTimeCount_S,
			DataLimit_DI => D4AAPSADCConfigReg_D.GSCpResetFD_D,
			Overflow_SO  => GSCpResetFDTimeDone_S,
			Data_DO      => open);

	GSCpResetSettleTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_GSCPRESETSETTLETIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => GSCpResetSettleTimeCount_S,
			DataLimit_DI => D4AAPSADCConfigReg_D.GSCpResetSettle_D,
			Overflow_SO  => GSCpResetSettleTimeDone_S,
			Data_DO      => open);

	clockSlowDownCounter : entity work.ContinuousCounter
		generic map(
			SIZE => 3)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => ClockSlowDownCount_S,
			DataLimit_DI => (others => '1'),
			Overflow_SO  => ClockSlowDownDone_S,
			Data_DO      => open);

	PixelStateMachine : process(PixelState_DP, D4AAPSADCConfigReg_D, APSChipGlobalShutterReg_SP, APSChipOverflowGateReg_SP, APSChipResetReg_SP, APSChipTXGateReg_SP, ColSampleDone_SP, ExposureTimeDone_S, FrameDelayDone_S, GSFDResetTimeDone_S, GSPDResetTimeDone_S, GSResetFallTimeDone_S, GSTXFallTimeDone_S, OutFifoControl_SI, RSFDSettleTimeDone_S, ReadBSRStatus_DP, RowReadPosition_D, TransferTimeDone_S, ClockSlowDownDone_S, APSSampleType_DP, ColSampleStart_SP)
	begin
		PixelState_DN <= PixelState_DP; -- Keep current state by default.

		OutFifoWriteRegRow_S      <= '0';
		OutFifoDataRegRowEnable_S <= '0';
		OutFifoDataRegRow_D       <= (others => '0');

		APSChipRowSRClockReg_C <= '0';
		APSChipRowSRInReg_S    <= '0';

		-- Row counter.
		RowReadPositionZero_S <= '0';
		RowReadPositionInc_S  <= '0';

		-- Column SM communication.
		ColSampleDoneAck  <= '0';
		ColSampleStart_SN <= ColSampleStart_SP;

		-- Don't clear exposure by default, only when requested!
		ExposureClear_S <= '0';

		-- Don't enable any counter by default.
		TransferTimeCount_S        <= '0';
		FrameDelayCount_S          <= '0';
		RSFDSettleTimeCount_S      <= '0';
		RSCpResetTimeCount_S       <= '0';
		RSCpSettleTimeCount_S      <= '0';
		GSPDResetTimeCount_S       <= '0';
		GSResetFallTimeCount_S     <= '0';
		GSTXFallTimeCount_S        <= '0';
		GSFDResetTimeCount_S       <= '0';
		GSCpResetFDTimeCount_S     <= '0';
		GSCpResetSettleTimeCount_S <= '0';

		ClockSlowDownCount_S <= '0';

		-- Keep value by default.
		APSChipOverflowGateReg_SN  <= APSChipOverflowGateReg_SP;
		APSChipTXGateReg_SN        <= APSChipTXGateReg_SP;
		APSChipResetReg_SN         <= APSChipResetReg_SP;
		APSChipGlobalShutterReg_SN <= APSChipGlobalShutterReg_SP;

		-- Keep value by default.
		ReadBSRStatus_DN <= ReadBSRStatus_DP;

		-- No valid sample type by default.
		APSSampleType_DN <= APSSampleType_DP;

		-- Only update configuration when in Idle state. Doing so while the frame is being read out
		-- would cause different timing, exposure and read out types, resulting in corrupted frames.
		D4AAPSADCConfigRegEnable_S <= '0';

		case PixelState_DP is
			when stIdle =>
				D4AAPSADCConfigRegEnable_S <= '1';

				if D4AAPSADCConfigReg_D.Run_S = '1' then
					PixelState_DN <= stStartFrame;
				end if;

			when stStartFrame =>
				-- Write out start of frame marker. This and the end of frame marker are the only
				-- two events from this SM that always have to be committed and are never dropped.
				if OutFifoControl_SI.Full_S = '0' then
					if CHIP_APS_HAS_GLOBAL_SHUTTER = '1' and D4AAPSADCConfigReg_D.GlobalShutter_S = '1' then
						if D4AAPSADCConfigReg_D.ResetRead_S = '1' then
							OutFifoDataRegRow_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTFRAME_GS;
						else
							OutFifoDataRegRow_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTFRAME_GS_NORST;
						end if;

						PixelState_DN <= stGSIdle;
					else
						if D4AAPSADCConfigReg_D.ResetRead_S = '1' then
							OutFifoDataRegRow_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTFRAME_RS;
						else
							OutFifoDataRegRow_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTFRAME_RS_NORST;
						end if;

						PixelState_DN <= stRSIdle;
					end if;

					OutFifoDataRegRowEnable_S <= '1';
					OutFifoWriteRegRow_S      <= '1';
				end if;

			when stRSIdle =>
				-- Set all signals to default for RS.
				APSChipResetReg_SN         <= '1';
				APSChipTXGateReg_SN        <= '0';
				APSChipOverflowGateReg_SN  <= '0';
				APSChipGlobalShutterReg_SN <= '0';

				PixelState_DN <= stRSReadoutFeedOne1;

			when stRSReadoutFeedOne1 =>
				-- RS uses 111 pattern first. Shift register is at all zeros at startup.
				-- So shift in three 1s first. Then we start with the first column.
				APSChipRowSRInReg_S    <= '1';
				APSChipRowSRClockReg_C <= '0';

				ClockSlowDownCount_S <= '1';

				if ClockSlowDownDone_S = '1' then
					PixelState_DN <= stRSReadoutFeedOne1Tick;
				end if;

			when stRSReadoutFeedOne1Tick =>
				-- Tick 1.
				APSChipRowSRInReg_S    <= '1';
				APSChipRowSRClockReg_C <= '1';

				ClockSlowDownCount_S <= '1';

				if ClockSlowDownDone_S = '1' then
					PixelState_DN <= stRSReadoutFeedOne2;
				end if;

			when stRSReadoutFeedOne2 =>
				--- Feed 1.
				APSChipRowSRInReg_S    <= '1';
				APSChipRowSRClockReg_C <= '0';

				ClockSlowDownCount_S <= '1';

				if ClockSlowDownDone_S = '1' then
					PixelState_DN <= stRSReadoutFeedOne2Tick;
				end if;

			when stRSReadoutFeedOne2Tick =>
				-- Tick 1.
				APSChipRowSRInReg_S    <= '1';
				APSChipRowSRClockReg_C <= '1';

				ClockSlowDownCount_S <= '1';

				if ClockSlowDownDone_S = '1' then
					PixelState_DN <= stRSReadoutFeedOne3;
				end if;

			when stRSReadoutFeedOne3 =>
				-- Feed 1.
				APSChipRowSRInReg_S    <= '1';
				APSChipRowSRClockReg_C <= '0';

				ClockSlowDownCount_S <= '1';

				if ClockSlowDownDone_S = '1' then
					PixelState_DN <= stRSReadoutFeedOne3Tick;
				end if;

			when stRSReadoutFeedOne3Tick =>
				-- Tick 1.
				APSChipRowSRInReg_S    <= '1';
				APSChipRowSRClockReg_C <= '1';

				ClockSlowDownCount_S <= '1';

				if ClockSlowDownDone_S = '1' then
					PixelState_DN <= stRSFDSettle;
				end if;

			when stRSFDSettle =>
				RSFDSettleTimeCount_S <= '1';

				if RSFDSettleTimeDone_S = '1' then
					PixelState_DN <= stRSSample1Start;
				end if;

			when stRSSample1Start =>
				APSChipResetReg_SN <= '0'; -- Turn off reset.

				ColSampleStart_SN <= '1';

				PixelState_DN <= stRSSample1Done;

			when stRSSample1Done =>
				--if ReadBSRStatus_DP = RBSTAT_NORMAL then
					APSSampleType_DN <= SAMPLETYPE_FDRESET;
				--else
					--APSSampleType_DN <= SAMPLETYPE_NULL;
				--end if;

				if ColSampleDone_SP = '1' then
					PixelState_DN    <= stRSChargeTransfer;
					ColSampleDoneAck <= '1';
				end if;

			when stRSChargeTransfer =>
				APSChipTXGateReg_SN <= '1';

				TransferTimeCount_S <= '1';

				if TransferTimeDone_S = '1' then
					PixelState_DN <= stRSSample2Start;
				end if;

			when stRSSample2Start =>
				APSChipTXGateReg_SN <= '0'; -- Turn off again.

				if ReadBSRStatus_DP = RBSTAT_NEED_ZERO_ONE then
					ExposureClear_S <= '1';
				end if;

				ColSampleStart_SN <= '1';

				PixelState_DN <= stRSSample2Done;

			when stRSSample2Done =>
				--if ReadBSRStatus_DP = RBSTAT_NORMAL then
					APSSampleType_DN <= SAMPLETYPE_SIGNAL;
				--else
					--APSSampleType_DN <= SAMPLETYPE_NULL;
				--end if;

				if ColSampleDone_SP = '1' then
					ColSampleDoneAck   <= '1';
					APSChipResetReg_SN <= '1';

					-- If exposure time hasn't expired or we haven't yet even shifted in one
					-- 0 into the row SR, we first do that.
					if ExposureTimeDone_S = '1' and ReadBSRStatus_DP /= RBSTAT_NEED_ZERO_ONE then
						if ReadBSRStatus_DP = RBSTAT_NEED_ONE then
							-- If the 1 that represents the read hasn't yet been shifted
							-- in, do so now.
							PixelState_DN    <= stRSReadoutFeedOne3;
							ReadBSRStatus_DN <= RBSTAT_NEED_ZERO_TWO;
						elsif ReadBSRStatus_DP = RBSTAT_NEED_ZERO_TWO then
							-- Shift in the second 0 (the one after the 1) that is needed
							-- for a read of the very first column to work.
							PixelState_DN    <= stRSFeed;
							ReadBSRStatus_DN <= RBSTAT_NORMAL;
						else
							-- Finally, reads are happening, their position is increasing.
							PixelState_DN        <= stRSFeed;
							RowReadPositionInc_S <= '1';
						end if;
					else
						-- Just shift in a zero.
						PixelState_DN <= stRSFeed;
					end if;
				end if;

			when stRSFeed =>
				APSChipRowSRInReg_S    <= '0';
				APSChipRowSRClockReg_C <= '0';

				ClockSlowDownCount_S <= '1';

				if ClockSlowDownDone_S = '1' then
					PixelState_DN <= stRSFeedTick;
				end if;

			when stRSFeedTick =>
				APSChipRowSRInReg_S    <= '0';
				APSChipRowSRClockReg_C <= '1';

				-- A first zero has just been shifted in.
				if ReadBSRStatus_DP = RBSTAT_NEED_ZERO_ONE then
					ReadBSRStatus_DN <= RBSTAT_NEED_ONE;
				end if;

				ClockSlowDownCount_S <= '1';

				if ClockSlowDownDone_S = '1' then
					-- Check if we're done (reads ended).
					if RowReadPosition_D = CHIP_APS_SIZE_ROWS then
						PixelState_DN <= stEndFrame;

						-- Reset ReadB status to initial (need at least a zero), for next frame.
						ReadBSRStatus_DN <= RBSTAT_NEED_ZERO_ONE;
					else
						PixelState_DN <= stRSFDSettle;
					end if;
				end if;

			when stGSIdle =>
				-- Set all signals to default for GS.
				APSChipResetReg_SN         <= '1';
				APSChipTXGateReg_SN        <= '0';
				APSChipOverflowGateReg_SN  <= '1';
				APSChipGlobalShutterReg_SN <= '1';

				PixelState_DN <= stGSPDReset;

			when stGSPDReset =>
				GSPDResetTimeCount_S <= '1';

				if GSPDResetTimeDone_S = '1' then
					ExposureClear_S <= '1';

					PixelState_DN <= stGSExposureStart;
				end if;

			when stGSExposureStart =>
				APSChipOverflowGateReg_SN <= '0';

				if ExposureTimeDone_S = '1' then
					PixelState_DN <= stGSResetFallTime;
				end if;

			when stGSResetFallTime =>
				APSChipResetReg_SN <= '0';

				GSResetFallTimeCount_S <= '1';

				if GSResetFallTimeDone_S = '1' then
					PixelState_DN <= stGSChargeTransfer;
				end if;

			when stGSChargeTransfer =>
				APSChipTXGateReg_SN <= '1';

				TransferTimeCount_S <= '1';

				if TransferTimeDone_S = '1' then
					PixelState_DN <= stGSExposureEnd;
				end if;

			when stGSExposureEnd =>
				APSChipTXGateReg_SN <= '0';

				GSTXFallTimeCount_S <= '1';

				if GSTXFallTimeDone_S = '1' then
					PixelState_DN <= stGSSwitchToReadout1;
				end if;

			when stGSSwitchToReadout1 =>
				APSChipOverflowGateReg_SN <= '1';

				PixelState_DN <= stGSSwitchToReadout2;

			when stGSSwitchToReadout2 =>
				APSChipOverflowGateReg_SN <= '1';

				PixelState_DN <= stGSReadoutFeedOne;

			when stGSReadoutFeedOne =>
				-- GS turned off from here on.
				APSChipGlobalShutterReg_SN <= '0';

				-- GS uses 010 pattern. Shift register is at all zeros at startup.
				-- So we first shift in a 1, and then a 0. Then we start with the first column.
				APSChipRowSRInReg_S    <= '1';
				APSChipRowSRClockReg_C <= '0';

				ClockSlowDownCount_S <= '1';

				if ClockSlowDownDone_S = '1' then
					PixelState_DN <= stGSReadoutFeedOneTick;
				end if;

			when stGSReadoutFeedOneTick =>
				-- Tick 1.
				APSChipRowSRInReg_S    <= '1';
				APSChipRowSRClockReg_C <= '1';

				ClockSlowDownCount_S <= '1';

				if ClockSlowDownDone_S = '1' then
					PixelState_DN <= stGSReadoutFeedZero;
				end if;

			when stGSReadoutFeedZero =>
				-- Feed 0.
				APSChipRowSRInReg_S    <= '0';
				APSChipRowSRClockReg_C <= '0';

				ClockSlowDownCount_S <= '1';

				if ClockSlowDownDone_S = '1' then
					PixelState_DN <= stGSReadoutFeedZeroTick;
				end if;

			when stGSReadoutFeedZeroTick =>
				-- Tick 0.
				APSChipRowSRInReg_S    <= '0';
				APSChipRowSRClockReg_C <= '1';

				ClockSlowDownCount_S <= '1';

				if ClockSlowDownDone_S = '1' then
					if RowReadPosition_D = CHIP_APS_SIZE_ROWS then
						-- Done with reads.
						PixelState_DN <= stEndFrame;
					else
						PixelState_DN <= stGSSample1Start;
					end if;
				end if;

			when stGSSample1Start =>
				ColSampleStart_SN <= '1';
				APSSampleType_DN  <= SAMPLETYPE_SIGNAL;

				PixelState_DN <= stGSSample1Done;

			when stGSSample1Done =>
				if ColSampleDone_SP = '1' then
					PixelState_DN    <= stGSFDReset;
					ColSampleDoneAck <= '1';
				end if;

			when stGSFDReset =>
				APSChipResetReg_SN <= '1';

				GSFDResetTimeCount_S <= '1';

				if GSFDResetTimeDone_S = '1' then
					PixelState_DN <= stGSSample2Start;
				end if;

			when stGSSample2Start =>
				APSChipResetReg_SN <= '0'; -- Turn off again.

				ColSampleStart_SN <= '1';
				APSSampleType_DN  <= SAMPLETYPE_FDRESET;

				PixelState_DN <= stGSSample2Done;

			when stGSSample2Done =>
				if ColSampleDone_SP = '1' then
					ColSampleDoneAck          <= '1';
					APSChipOverflowGateReg_SN <= '1';

					-- Increase row count, now that we're done with last read.
					RowReadPositionInc_S <= '1';

					PixelState_DN <= stGSReadoutFeedZero;
				end if;

			when stEndFrame =>
				-- Zero row counter too.
				RowReadPositionZero_S <= '1';

				-- Write out end of frame marker. This and the start of frame marker are the only
				-- two events from this SM that always have to be committed and are never dropped.
				if OutFifoControl_SI.Full_S = '0' then
					OutFifoDataRegRow_D       <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_ENDFRAME;
					OutFifoDataRegRowEnable_S <= '1';
					OutFifoWriteRegRow_S      <= '1';

					PixelState_DN <= stWaitFrameDelay;
				end if;

			when stWaitFrameDelay =>
				FrameDelayCount_S <= '1';

				-- Wait until enough time has passed between frames.
				if FrameDelayDone_S = '1' then
					PixelState_DN <= stIdle;

					-- Ensure config reg is up-to-date when entering Idle state.
					D4AAPSADCConfigRegEnable_S <= '1';
				end if;

			when others => null;
		end case;
	end process PixelStateMachine;

	-- Don't generate any external gray-code. Internal gray-counter works.
	ChipADCGrayCounter_DO <= (others => '0');

	colReadPosition : entity work.ContinuousCounter
		generic map(
			SIZE              => CHIP_APS_SIZE_COLUMNS'length,
			RESET_ON_OVERFLOW => false,
			GENERATE_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => ColumnReadPositionZero_S,
			Enable_SI    => ColumnReadPositionInc_S,
			DataLimit_DI => CHIP_APS_SIZE_COLUMNS,
			Overflow_SO  => open,
			Data_DO      => ColumnReadPosition_D);

	rampTickCounter1 : entity work.ContinuousCounter
		generic map(
			SIZE => APS_ADC_BUS_WIDTH)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => RampTickCount1_S,
			DataLimit_DI => to_unsigned(1021, APS_ADC_BUS_WIDTH),
			Overflow_SO  => RampTickDone_S,
			Data_DO      => open);
			
	rampTickCounter2 : entity work.ContinuousCounter
		generic map(
			SIZE => APS_ADC_BUS_WIDTH)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => RampTickCount2_S,
			DataLimit_DI => to_unsigned(511, APS_ADC_BUS_WIDTH),
			Overflow_SO  => RampTickHalfDone_S,
			Data_DO      => open);

	rowSettleTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_ROWSETTLETIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => RowSettleTimeCount_S,
			DataLimit_DI => D4AAPSADCConfigReg_D.RowSettle_D,
			Overflow_SO  => RowSettleTimeDone_S,
			Data_DO      => open);

	sampleSettleTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_SAMPLESETTLETIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => SampleSettleTimeCount_S,
			DataLimit_DI => D4AAPSADCConfigReg_D.SampleSettle_D,
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
			DataLimit_DI => D4AAPSADCConfigReg_D.RampReset_D,
			Overflow_SO  => RampResetTimeDone_S,
			Data_DO      => open);

	chipADCColumnSampleStateMachine : process(ChipColSampleState_DP, ColSampleStart_SP, RampResetTimeDone_S, RampTickDone_S, RowSettleTimeDone_S, SampleSettleTimeDone_S, ColSampleDone_SP, ColScanStart_SP, APSSampleType1_DP, APSSampleType_DP, APSSampleType1_DN, RampTickHalfDone_S)
	begin
		ChipColSampleState_DN <= ChipColSampleState_DP;

		-- ADC clock counter.
		RampTickCount1_S <= '0';
		RampTickCount2_S <= '0';

		-- Settle times counters.
		RowSettleTimeCount_S    <= '0';
		SampleSettleTimeCount_S <= '0';
		RampResetTimeCount_S    <= '0';

		ColScanStart_SN   <= ColScanStart_SP;
		ColSampleDone_SN  <= ColSampleDone_SP;
		ColSampleStartAck <= '0';

		-- On-chip ADC.
		ChipADCRampClearReg_S <= '1';   -- Clear ramp by default.
		ChipADCRampClockReg_C <= '0';
		ChipADCRampBitInReg_S <= '0';
		ChipADCSampleReg_S    <= '0';
		
		APSSampleType1_DN <= APSSampleType1_DP;
		APSSampleType2_DN <= APSSampleType2_DP;

		case ChipColSampleState_DP is
			when stSampleIdle =>
				-- Wait until the main row state machine signals us to do a column read.
				if ColSampleStart_SP = '1' then
					ChipColSampleState_DN <= stRowSettleWait;
					ColSampleStartAck     <= '1';
					--APSSampleType1_DN <= APSSampleType_DP;
				end if;

			when stRowSettleWait =>
				-- Additional wait for the row selection to be valid.
				if RowSettleTimeDone_S = '1' then
					ChipColSampleState_DN <= stColSample;
					APSSampleType1_DN <= APSSampleType_DP;
				end if;

				RowSettleTimeCount_S <= '1';

			when stColSample =>
				-- Do not clear Ramp while in use!
				ChipADCRampClearReg_S <= '0';

				-- Do sample now!
				ChipADCSampleReg_S <= '1';

				if SampleSettleTimeDone_S = '1' then
					ChipColSampleState_DN <= stColRampFeed;
				end if;

				SampleSettleTimeCount_S <= '1';

			when stColRampFeed =>
				-- Do not clear Ramp while in use!
				ChipADCRampClearReg_S <= '0';

				ChipADCRampClockReg_C <= '0'; -- Set BitIn one cycle before to ensure the value is stable.
				ChipADCRampBitInReg_S <= '1';

				ChipColSampleState_DN <= stColRampFeedTick;

			when stColRampFeedTick =>
				-- Do not clear Ramp while in use!
				ChipADCRampClearReg_S <= '0';

				ChipADCRampClockReg_C <= '1';
				ChipADCRampBitInReg_S <= '1';

				ChipColSampleState_DN <= stColRampReset;

				-- ready for PixelSM to move on
				ColSampleDone_SN <= '1';
				--APSSampleType1_DN <= APSSampleType_DP;

			when stColRampReset =>
				-- Do not clear Ramp while in use!
				ChipADCRampClearReg_S <= '0';

				if RampResetTimeDone_S = '1' then
					ChipColSampleState_DN <= stColRampClockLow;
				end if;

				RampResetTimeCount_S <= '1';

			when stColRampClockLow =>
				ChipADCRampClockReg_C <= '0';

				-- Do not clear Ramp while in use!
				ChipADCRampClearReg_S <= '0';

				ChipColSampleState_DN <= stColRampClockHigh;

			when stColRampClockHigh =>
				ChipADCRampClockReg_C <= '1';

				-- Do not clear Ramp while in use!
				ChipADCRampClearReg_S <= '0';

				-- Increase counter and stop ramping when maximum reached.
				if APSSampleType1_DP = SAMPLETYPE_SIGNAL then
					RampTickCount1_S <= '1';
				elsif APSSampleType1_DP = SAMPLETYPE_FDRESET then
					RampTickCount2_S <= '1';
				end if;

				if APSSampleType1_DP = SAMPLETYPE_SIGNAL and RampTickDone_S = '1'  then
					ChipColSampleState_DN <= stSampleIdle;
					ColScanStart_SN       <= '1';
					APSSampleType2_DN <= APSSampleType1_DP;
				elsif APSSampleType1_DP = SAMPLETYPE_FDRESET and RampTickHalfDone_S = '1' then
					ChipColSampleState_DN <= stSampleIdle;
					ColScanStart_SN       <= '1';
					APSSampleType2_DN <= APSSampleType1_DP;
				else
					ChipColSampleState_DN <= stColRampClockLow;
				end if;

			when others => null;
		end case;
	end process chipADCColumnSampleStateMachine;

	chipADCColumnScanStateMachine : process(ChipColScanState_DP, D4AAPSADCConfigReg_D, ChipADCData_DI, ColScanStart_SP, ColumnReadPosition_D, OutFifoControl_SI, APSSampleType1_DP)
	begin
		ChipColScanState_DN <= ChipColScanState_DP;

		OutFifoWriteRegCol_S      <= '0';
		OutFifoDataRegColEnable_S <= '0';
		OutFifoDataRegCol_D       <= (others => '0');

		APSChipColSRClockReg_C <= '0';
		APSChipColSRInReg_S    <= '0';

		-- Column counter.
		ColumnReadPositionZero_S <= '0';
		ColumnReadPositionInc_S  <= '0';

		-- Column SM communication.
		ColScanStartAck <= '0';

		-- On-chip ADC.
		ChipADCScanClockReg_C   <= '0';
		ChipADCScanControlReg_S <= SCAN_CONTROL_SCAN_THROUGH; -- Scan by default.
		
		APSSampleType3_DN <= APSSampleType3_DP;

		case ChipColScanState_DP is
			when stScanIdle =>
				-- Wait until the sample state machine signals us to scan.
				if ColScanStart_SP = '1' then
					ChipColScanState_DN <= stColScanStart;
					APSSampleType3_DN <= APSSampleType2_DP;
				end if;

			when stColScanStart =>
				ColScanStartAck <= '1';
				

				-- Write event only if FIFO has place, else wait.
				-- If fake read (SAMPLETYPE_NULL), don't write anything.
				if OutFifoControl_SI.Full_S = '0' and APSSampleType3_DP /= SAMPLETYPE_NULL then
					if APSSampleType3_DP = SAMPLETYPE_FDRESET then
						OutFifoDataRegCol_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTRESETCOL;
					elsif APSSampleType3_DP = SAMPLETYPE_CPRESET then
						OutFifoDataRegCol_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTSRESET2COL;
					else
						OutFifoDataRegCol_D <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_STARTSIGNALCOL;
					end if;

					OutFifoDataRegColEnable_S <= '1';
					OutFifoWriteRegCol_S      <= '1';
				end if;

				if OutFifoControl_SI.Full_S = '0' or APSSampleType3_DP = SAMPLETYPE_NULL or D4AAPSADCConfigReg_D.WaitOnTransferStall_S = '0' then
					ChipColScanState_DN <= stColScanSelect;
				end if;

			when stColScanSelect =>
				ChipADCScanClockReg_C   <= '0';
				ChipADCScanControlReg_S <= SCAN_CONTROL_COPY_OVER;

				ChipColScanState_DN <= stColScanSelectTick;

			when stColScanSelectTick =>
				ChipADCScanClockReg_C   <= '1';
				ChipADCScanControlReg_S <= SCAN_CONTROL_COPY_OVER;

				ChipColScanState_DN <= stColScanReadValue;

			when stColScanReadValue =>
				-- Write event only if FIFO has place, else wait.
				if OutFifoControl_SI.Full_S = '0' and APSSampleType3_DP /= SAMPLETYPE_NULL then
					OutFifoDataRegCol_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_ADC_SAMPLE;

					-- Convert from gray-code to binary. This uses a direct algorithm instead of using the previously stored binary
					-- value at each step. Lastly, the output is negated so that the range 0-1023 is properly inverted to be the same
					-- as for external ADC, where 0 represents lowest voltage and 1023 highest voltage.
					OutFifoDataRegCol_D(9) <= not (ChipADCData_DI(9));
					OutFifoDataRegCol_D(8) <= not (ChipADCData_DI(8) xor ChipADCData_DI(9));
					OutFifoDataRegCol_D(7) <= not (ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
					OutFifoDataRegCol_D(6) <= not (ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
					OutFifoDataRegCol_D(5) <= not (ChipADCData_DI(5) xor ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
					OutFifoDataRegCol_D(4) <= not (ChipADCData_DI(4) xor ChipADCData_DI(5) xor ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
					OutFifoDataRegCol_D(3) <= not (ChipADCData_DI(3) xor ChipADCData_DI(4) xor ChipADCData_DI(5) xor ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
					OutFifoDataRegCol_D(2) <= not (ChipADCData_DI(2) xor ChipADCData_DI(3) xor ChipADCData_DI(4) xor ChipADCData_DI(5) xor ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
					OutFifoDataRegCol_D(1) <= not (ChipADCData_DI(1) xor ChipADCData_DI(2) xor ChipADCData_DI(3) xor ChipADCData_DI(4) xor ChipADCData_DI(5) xor ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));
					OutFifoDataRegCol_D(0) <= not (ChipADCData_DI(0) xor ChipADCData_DI(1) xor ChipADCData_DI(2) xor ChipADCData_DI(3) xor ChipADCData_DI(4) xor ChipADCData_DI(5) xor ChipADCData_DI(6) xor ChipADCData_DI(7) xor ChipADCData_DI(8) xor ChipADCData_DI(9));

					OutFifoDataRegColEnable_S <= '1';
					OutFifoWriteRegCol_S      <= '1';
				end if;

				if OutFifoControl_SI.Full_S = '0' or APSSampleType3_DP = SAMPLETYPE_NULL or D4AAPSADCConfigReg_D.WaitOnTransferStall_S = '0' then
					ChipColScanState_DN     <= stColScanNextValue;
					ColumnReadPositionInc_S <= '1';
				end if;

			when stColScanNextValue =>
				ChipADCScanClockReg_C <= '1';

				-- Check if we're done. The column read position is at the
				-- maximum, so we can detect that, zero it and exit.
				if ColumnReadPosition_D = CHIP_APS_SIZE_COLUMNS then
					ChipColScanState_DN      <= stColScanDone;
					ColumnReadPositionZero_S <= '1';
				else
					ChipColScanState_DN <= stColScanReadValue;
				end if;

			when stColScanDone =>
				-- Write event only if FIFO has place, else wait.
				if OutFifoControl_SI.Full_S = '0' and APSSampleType3_DP /= SAMPLETYPE_NULL then
					OutFifoDataRegCol_D       <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_APS_ENDCOL;
					OutFifoDataRegColEnable_S <= '1';
					OutFifoWriteRegCol_S      <= '1';
				end if;

				if OutFifoControl_SI.Full_S = '0' or APSSampleType3_DP = SAMPLETYPE_NULL or D4AAPSADCConfigReg_D.WaitOnTransferStall_S = '0' then
					ChipColScanState_DN <= stScanIdle;
				end if;

			when others => null;
		end case;
	end process chipADCColumnScanStateMachine;

	chipADCRegisterUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then
			ChipColSampleState_DP <= stSampleIdle;
			ChipColScanState_DP   <= stScanIdle;

			ChipADCRampClear_SO   <= '1'; -- Clear ramp by default.
			ChipADCRampClock_CO   <= '0';
			ChipADCRampBitIn_SO   <= '0';
			ChipADCScanClock_CO   <= '0';
			ChipADCScanControl_SO <= SCAN_CONTROL_SCAN_THROUGH;
			ChipADCSample_SO      <= '0';
		elsif rising_edge(Clock_CI) then
			ChipColSampleState_DP <= ChipColSampleState_DN;
			ChipColScanState_DP   <= ChipColScanState_DN;

			ChipADCRampClear_SO   <= ChipADCRampClearReg_S;
			ChipADCRampClock_CO   <= ChipADCRampClockReg_C;
			ChipADCRampBitIn_SO   <= ChipADCRampBitInReg_S;
			ChipADCScanClock_CO   <= ChipADCScanClockReg_C;
			ChipADCScanControl_SO <= ChipADCScanControlReg_S;
			ChipADCSample_SO      <= D4AAPSADCConfigReg_D.SampleEnable_S and ChipADCSampleReg_S;
		end if;
	end process chipADCRegisterUpdate;

	-- FIFO output can be driven by both the column or the row state machines.
	-- Care must be taken to never have both at the same time output meaningful data.
	OutFifoWriteReg_S      <= OutFifoWriteRegRow_S or OutFifoWriteRegCol_S;
	OutFifoDataRegEnable_S <= OutFifoDataRegRowEnable_S or OutFifoDataRegColEnable_S;
	OutFifoDataReg_D       <= OutFifoDataRegRow_D or OutFifoDataRegCol_D;

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
			PixelState_DP <= stIdle;

			ColSampleStart_SP <= '0';
			ColSampleDone_SP  <= '0';
			ColScanStart_SP   <= '0';

			ReadBSRStatus_DP <= RBSTAT_NEED_ZERO_ONE;
			APSSampleType_DP <= SAMPLETYPE_NULL;
			APSSampleType1_DP <= SAMPLETYPE_NULL;
			APSSampleType2_DP <= SAMPLETYPE_NULL;
			APSSampleType3_DP <= SAMPLETYPE_NULL;

			OutFifoControl_SO.Write_S <= '0';

			APSChipColSRClock_CO <= '0';
			APSChipColSRIn_SO    <= '0';
			APSChipRowSRClock_CO <= '0';
			APSChipRowSRIn_SO    <= '0';

			APSChipOverflowGateReg_SP  <= '1';
			APSChipTXGateReg_SP        <= '0';
			APSChipResetReg_SP         <= '1';
			APSChipGlobalShutterReg_SP <= '1';

			-- APS ADC config from another clock domain.
			D4AAPSADCConfigReg_D     <= tD4AAPSADCConfigDefault;
			D4AAPSADCConfigSyncReg_D <= tD4AAPSADCConfigDefault;
		elsif rising_edge(Clock_CI) then
			PixelState_DP <= PixelState_DN;

			ColSampleStart_SP <= ColSampleStart_SN xor ColSampleStartAck;
			ColSampleDone_SP  <= ColSampleDone_SN xor ColSampleDoneAck;
			ColScanStart_SP   <= ColScanStart_SN xor ColScanStartAck;

			ReadBSRStatus_DP <= ReadBSRStatus_DN;
			APSSampleType_DP <= APSSampleType_DN;
			APSSampleType1_DP <= APSSampleType1_DN;
			APSSampleType2_DP <= APSSampleType2_DN;
			APSSampleType3_DP <= APSSampleType3_DN;

			OutFifoControl_SO.Write_S <= OutFifoWriteReg_S;

			APSChipColSRClock_CO <= APSChipColSRClockReg_C;
			APSChipColSRIn_SO    <= APSChipColSRInReg_S;
			APSChipRowSRClock_CO <= APSChipRowSRClockReg_C;
			APSChipRowSRIn_SO    <= APSChipRowSRInReg_S;

			APSChipOverflowGateReg_SP  <= APSChipOverflowGateReg_SN;
			APSChipTXGateReg_SP        <= APSChipTXGateReg_SN;
			APSChipResetReg_SP         <= APSChipResetReg_SN;
			APSChipGlobalShutterReg_SP <= APSChipGlobalShutterReg_SN;

			-- D4A APS ADC config from another clock domain.
			if D4AAPSADCConfigRegEnable_S = '1' then
				D4AAPSADCConfigReg_D <= D4AAPSADCConfigSyncReg_D;
			end if;
			D4AAPSADCConfigSyncReg_D <= D4AAPSADCConfig_DI;
		end if;
	end process registerUpdate;

	-- The output of this register goes to an intermediate signal, since we need to access it
	-- inside this module. That's not possible with 'out' signal directly.
	APSChipOverflowGate_SO   <= APSChipOverflowGateReg_SP;
	APSChipTXGate_SO         <= APSChipTXGateReg_SP;
	APSChipReset_SO          <= APSChipResetReg_SP;
	APSChipGlobalShutter_SBO <= not APSChipGlobalShutterReg_SP;
	Debug_DO <= APSSampleType3_DP;
end architecture Behavioral;
