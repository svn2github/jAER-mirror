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

	type tRowSRState is (stIdle, stRSExposureStart0, stRSExposureStart1, stRSExposureStart2, stRSExposure, stRSExposureEnd, stRSReadout, stGSReadout0, stGSReadout1);
	attribute syn_enum_encoding of tRowSRState : type is "onehot";
	-- present and next state
	signal RowSRState_DP, RowSRState_DN : tRowSRState;
	
	type tChipADCState is (stIdle, stSettle, stSample, stConvert, stClear);
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
	signal ChipADCSample_S, ChipADCSampleDone_S : std_logic;

	-- Exposure time counter.
	signal ExposureTimeCount_S, ExposureTimeDone_S : std_logic;

	-- Transfer time counter.
	signal TransferTimeCount_S, TransferTimeDone_S : std_logic;

	-- Reset time counter (make bigger to allow for long resets if needed).
	signal RSCpResetTimeCount_S, RSCpResetTimeDone_S : std_logic;
	signal RSCpSettleTimeCount_S, RSCpSettleTimeDone_S : std_logic;
	
	-- Lengthen the NULL states between different, active column states.
	signal NullTimeCount_S, NullTimeDone_S : std_logic;

	-- Column settle time (before first row is read, like an additional offset).
	signal ColSettleTimeCount_S, ColSettleTimeDone_S : std_logic;

	-- Row settle time counter.
	signal RSRowSettleTimeCount_S, RSRowSettleTimeDone_S : std_logic;
	
	signal GSPDResetTimeCount_S, GSPDResetTimeDone_S : std_logic;
	signal GSTXFallTimeCount_S, GSTXFallTimeDone_S : std_logic;
	signal GSFDResetTimeCount_S, GSFDResetTimeDone_S : std_logic;
	signal GSCpResetFDTimeCount_S, GSCpResetFDTimeDone_S : std_logic;
	signal GSCpResetSettleTimeCount_S, GSCpResetSettleTimeDone_S : std_logic;
	signal APSFrameInitiate_S, GSReadoutStart_S : std_logic;

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

	GSTXFallTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_GSTXFALLTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => GSTXFallTimeCount_S,
			DataLimit_DI => APSADCConfigReg_D.GSTXFall_D,
			Overflow_SO  => GSTXFallTimeDone_S,
			Data_DO      => open);

	GSPDResetTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_GSPDRESETTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => GSPDResetTimeCount_S,
			DataLimit_DI => APSADCConfigReg_D.GSPDReset_D,
			Overflow_SO  => GSPDResetTimeDone_S,
			Data_DO      => open);
	
	GSFDResetTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_GSFDRESETTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => GSFDResetTimeCount_S,
			DataLimit_DI => APSADCConfigReg_D.GSFDReset_D,
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
			DataLimit_DI => APSADCConfigReg_D.GSCpResetFD_D,
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
			DataLimit_DI => APSADCConfigReg_D.GSCpResetSettle_D,
			Overflow_SO  => GSCpResetSettleTimeDone_S,
			Data_DO      => open);

	ExposureTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE              => APS_EXPOSURE_SIZE,
			RESET_ON_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => ExposureTimeCount_S,
			DataLimit_DI => APSADCConfigReg_D.Exposure_D,
			Overflow_SO  => ExposureTimeDone_S,
			Data_DO      => open);

	RSCpResetTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_RSCPRESETTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => RSCpResetTimeCount_S,
			DataLimit_DI => APSADCConfigReg_D.RSCpReset_D,
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
			DataLimit_DI => APSADCConfigReg_D.RSCpSettle_D,
			Overflow_SO  => RSCpSettleTimeDone_S,
			Data_DO      => open);

	TransferTimeCounter : entity work.ContinuousCounter
		generic map(
			SIZE => APS_TRANSFERTIME_SIZE)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => TransferTimeCount_S,
			DataLimit_DI => APSADCConfigReg_D.Transfer_D,
			Overflow_SO  => TransferTimeDone_S,
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

	PixelStateMachine : process(APSADCConfigReg_D, PixelState_DP, APSRowSRClockReg_C, RSRowSettleTimeDone_S, ChipADCSampleDone_S, ExposureTimeDone_S, TransferTimeDone_S, RSCpResetTimeDone_S, RSCpSettleTimeDone_S, APSFrameInitiate_S, GSPDResetTimeDone_S, GSTXFallTimeDone_S, GSFDResetTimeDone_S, GSCpResetFDTimeDone_S, GSCpResetSettleTimeDone_S, RowReadPosition_D)
	begin
		PixelState_DN <= PixelState_DP;     -- Keep current state by default.

		OutFifoWriteRegCol_S      <= '0';
		OutFifoDataRegColEnable_S <= '0';
		OutFifoDataRegCol_D       <= (others => '0');

		ExposureTimeCount_S <= '0';
		RSRowSettleTimeCount_S <= '0';
		ChipADCSample_S <= '0';
		TransferTimeCount_S <= '0';
		RSCpResetTimeCount_S <= '0';
		RSCpSettleTimeCount_S <= '0';		

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
				elsif APSADCConfigReg_D.GlobalShutter_S = '1' then
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
				TransferTimeCount_S <= '1';

				if TransferTimeDone_S = '1' then
					PixelState_DN <= stRSSample2;
				end if;

			when stRSSample2 =>
				TransferTimeCount_S <= '0';
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
				elsif APSADCConfigReg_D.GlobalShutter_S = '0' then
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
				ExposureTimeCount_S <= '1';
				
				if ExposureTimeDone_S = '1' then
					PixelState_DN <= stGSChargeTransfer;
				end if;
				
			when stGSChargeTransfer =>
				ExposureTimeCount_S <= '0';
				APSRSTReg_S <= '0';
				APSTXReg_S <= '1';
				TransferTimeCount_S <= '1';
				
				if TransferTimeDone_S = '1' then
					PixelState_DN <= stGSExposureEnd;
				end if;
				
			when stGSExposureEnd =>
				TransferTimeCount_S <= '0';
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
				GSReadoutStart_S <= '1';
				
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
	end process PixelStateMachine;

	RowSRStateMachine : process(RowSRState_DP, APSADCConfigReg_D, APSFrameInitiate_S, GSReadoutStart_S, RowReadPosition_D, ExposureTimeDone_S)
	begin
		RowSRState_DN <= RowSRState_DP;

		OutFifoWriteRegRow_S      <= '0';
		OutFifoDataRegRowEnable_S <= '0';
		OutFifoDataRegRow_D       <= (others => '0');

		APSRowSRClockReg_S <= '0';
		APSRowSRInReg_S    <= '0';

		-- Row counters.
		RowReadPositionZero_S <= '0';
		RowReadPositionInc_S  <= '0';

		case RowSRState_DP is
			when stIdle =>
				APSRowSRInReg_S <= '0';
				
				if APSADCConfigReg_D.GlobalShutter_S = '0' and APSFrameInitiate_S = '1' then
					RowSRState_DN <= stRSExposureStart0;
				elsif APSADCConfigReg_D.GlobalShutter_S = '1' and GSReadoutStart_S = '1' then
					RowSRState_DN <= stGSReadout0;
				end if;

			when stRSExposureStart0 =>
				APSRowSRInReg_S <= '1';

				RowSRState_DN <= stRSExposureStart1;

			when stRSExposureStart1 =>
				APSRowSRInReg_S <= '1';

				RowSRState_DN <= stRSExposureStart2;

			when stRSExposureStart2 =>
				APSRowSRInReg_S <= '1';

				RowSRState_DN <= stRSExposure;
				
			when stRSExposure =>
				APSRowSRInReg_S <= '0';
				ExposureTimeCount_S <= '1';
				
				if ExposureTimeDone_S <= '1' then
					RowSRState_DN <= stRSExposureEnd;
				end if;
				
			when stRSExposureEnd =>
				APSRowSRInReg_S <= '1';
				ExposureTimeCount_S <= '0';
				
				RowSRState_DN <= stRSReadout;
				
			when stRSReadout =>
				APSRowSRInReg_S <= '0';
				
				if RowReadPosition_D = CHIP_APS_SIZE_ROWS then
					RowSRState_DN <= stIdle;
				end if;
					
			when stGSReadout0 =>
				APSRowSRInReg_S <= '1';
				
				RowSRState_DN <= stGSReadout1;
				
			when stGSReadout1 =>
				APSRowSRInReg_S <= '0';
				
				if RowReadPosition_D = CHIP_APS_SIZE_ROWS then
					RowSRState_DN <= stIdle;
				end if;

		end case;
	end process RowSRStateMachine;
	
	ChipADCStateMachine : process(ChipADCState_DP, ChipADCSample_S, ChipADCSettleTimeDone_S, ChipADCRampDone_S)
	begin
		ChipADCState_DN <= ChipADCState_DP;
		
		case ChipADCState_DP is
			when stIdle =>
				ChipADCRampClearReg_S <= '0';
				ChipADCRampBitInReg_S <= '0';
				ChipADCRampClockReg_C <= '0';
				ChipADCSampleReg_S <= '1';
				ChipADCSampleDone_S <= '0';
				
				if ChipADCSample_S = '1' then
					ChipADCState_DN <= stSettle;
				end if;
			
			when stSettle =>
				ChipADCSettleTimeCount_S <= '1';
				
				if ChipADCSettleTimeDone_S = '1' then
					ChipADCState_DN <= stSample;
				end if;
			
			when stSample =>
				ChipADCSampleReg_S <= '0';
				ChipADCRampClearReg_S <= '0';
				ChipADCRampBitInReg_S <= '1';
				
				ChipADCState_DN <= stConvert;
				
			when stConvert =>
				ChipADCSampleReg_S <= '0';
				ChipADCSampleDone_S <= '1';
				ChipADCRampBitInReg_S <= '0';
				ChipADCRampCount_S <= '1';
				
				if ChipADCRampDone_S = '1' then
					ChipADCState_DN <= stClear;
				end if;
				
			when stClear =>
				ChipADCSampleReg_S <= '0';
				ChipADCRampClearReg_S <= '1';
				ChipADCRampBitInReg_S <= '1';
				ChipADCRampClockReg_C <= '1';
				
				ChipADCState_DN <= stIdle;

		end case;
	end process ChipADCStateMachine;
	
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
