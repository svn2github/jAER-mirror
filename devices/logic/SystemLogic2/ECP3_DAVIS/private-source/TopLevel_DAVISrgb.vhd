library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.Settings.all;
use work.FIFORecords.all;
use work.MultiplexerConfigRecords.all;
use work.DVSAERConfigRecords.all;
use work.D4AAPSADCConfigRecords.all;
use work.IMUConfigRecords.all;
use work.ExtInputConfigRecords.all;
use work.ChipBiasConfigRecords.all;
use work.SystemInfoConfigRecords.all;
use work.FX3ConfigRecords.all;

entity TopLevel_DAVISrgb is
	port(
		USBClock_CI                 : in    std_logic;
		Reset_RI                    : in    std_logic;

		SPISlaveSelect_ABI          : in    std_logic;
		SPIClock_AI                 : in    std_logic;
		SPIMOSI_AI                  : in    std_logic;
		SPIMISO_DZO                 : out   std_logic;

		USBFifoData_DO              : out   std_logic_vector(USB_FIFO_WIDTH - 1 downto 0);
		USBFifoChipSelect_SBO       : out   std_logic;
		USBFifoWrite_SBO            : out   std_logic;
		USBFifoRead_SBO             : out   std_logic;
		USBFifoPktEnd_SBO           : out   std_logic;
		USBFifoAddress_DO           : out   std_logic_vector(1 downto 0);
		USBFifoThr0Ready_SI         : in    std_logic;
		USBFifoThr0Watermark_SI     : in    std_logic;
		USBFifoThr1Ready_SI         : in    std_logic;
		USBFifoThr1Watermark_SI     : in    std_logic;

		LED1_SO                     : out   std_logic;
		LED2_SO                     : out   std_logic;
		LED3_SO                     : out   std_logic;
		LED4_SO                     : out   std_logic;
		LED5_SO                     : out   std_logic;
		LED6_SO                     : out   std_logic;

		ChipBiasEnable_SO           : out   std_logic;
		ChipBiasDiagSelect_SO       : out   std_logic;
		ChipBiasAddrSelect_SBO      : out   std_logic;
		ChipBiasClock_CBO           : out   std_logic;
		ChipBiasBitIn_DO            : out   std_logic;
		ChipBiasLatch_SBO           : out   std_logic;
		--ChipBiasBitOut_DI : in std_logic;

		DVSAERData_AI               : in    std_logic_vector(DVS_AER_BUS_WIDTH - 1 downto 0);
		DVSAERReq_ABI               : in    std_logic;
		DVSAERAck_SBO               : out   std_logic;
		DVSAERReset_SBO             : out   std_logic;

		APSChipColSRClock_CO        : out   std_logic;
		APSChipColSRIn_SO           : out   std_logic;
		APSChipRowSRClock_CO        : out   std_logic;
		APSChipRowSRIn_SO           : out   std_logic;
		APSChipOverflowGate_SO      : out   std_logic;
		APSChipTXGate_SO            : out   std_logic;
		APSChipReset_SO             : out   std_logic;
		APSChipGlobalShutter_SBO    : out   std_logic;

		ExternalADCData_DI          : in    std_logic_vector(APS_ADC_BUS_WIDTH - 1 downto 0);
		ExternalADCOverflow_SI      : in    std_logic;
		ExternalADCClock_CO         : out   std_logic;
		ExternalADCOutputEnable_SBO : out   std_logic;
		ExternalADCStandby_SO       : out   std_logic;

		ChipADCData_DI              : in    std_logic_vector(APS_ADC_BUS_WIDTH - 1 downto 0);
		ChipADCRampClear_SO         : out   std_logic;
		ChipADCRampClock_CO         : out   std_logic;
		ChipADCRampBitIn_SO         : out   std_logic;
		ChipADCScanClock_CO         : out   std_logic;
		ChipADCScanControl_SO       : out   std_logic;
		ChipADCSample_SO            : out   std_logic;
		ChipADCGrayCounter_DO       : out   std_logic_vector(APS_ADC_BUS_WIDTH - 1 downto 0);
		Debug1_DO                    : out   std_logic;
		Debug2_DO                    : out   std_logic;
		Debug3_DO                    : out   std_logic;

		IMUClock_CZO                : out   std_logic;
		IMUData_DZIO                : inout std_logic;
		IMUInterrupt_AI             : in    std_logic;
		IMUFSync_SO                 : out   std_logic;

		SyncOutClock_CO             : out   std_logic;
		SyncOutSwitch_AI            : in    std_logic;
		SyncOutSignal_SO            : out   std_logic;
		SyncInClock_AI              : in    std_logic;
		SyncInSwitch_AI             : in    std_logic;
		SyncInSignal_AI             : in    std_logic);
end TopLevel_DAVISrgb;

architecture Structural of TopLevel_DAVISrgb is
	signal USBReset_R   : std_logic;
	signal LogicClock_C : std_logic;
	signal LogicReset_R : std_logic;
	signal ADCClock_C   : std_logic;
	signal ADCReset_R   : std_logic;

	signal USBFifoThr0ReadySync_S, USBFifoThr0WatermarkSync_S, USBFifoThr1ReadySync_S, USBFifoThr1WatermarkSync_S : std_logic;
	signal DVSAERReqSync_SB, IMUInterruptSync_S                                                                   : std_logic;
	signal SyncOutSwitchSync_S, SyncInClockSync_C, SyncInSwitchSync_S, SyncInSignalSync_S                         : std_logic;
	signal SPISlaveSelectSync_SB, SPIClockSync_C, SPIMOSISync_D                                                   : std_logic;
	signal DeviceIsMaster_S                                                                                       : std_logic;

	signal In1Timestamp_S, In2Timestamp_S, In3Timestamp_S, In4Timestamp_S : std_logic;

	signal LogicUSBFifoControlIn_S  : tToFifo;
	signal LogicUSBFifoControlOut_S : tFromFifo;
	signal LogicUSBFifoDataIn_D     : std_logic_vector(FULL_EVENT_WIDTH - 1 downto 0);
	signal LogicUSBFifoDataOut_D    : std_logic_vector(USB_FIFO_WIDTH - 1 downto 0);

	signal DVSAERFifoControlIn_S  : tToFifo;
	signal DVSAERFifoControlOut_S : tFromFifo;
	signal DVSAERFifoDataIn_D     : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal DVSAERFifoDataOut_D    : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	signal APSADCFifoControlIn_S  : tToFifo;
	signal APSADCFifoControlOut_S : tFromFifo;
	signal APSADCFifoDataIn_D     : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal APSADCFifoDataOut_D    : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	signal IMUFifoControlIn_S  : tToFifo;
	signal IMUFifoControlOut_S : tFromFifo;
	signal IMUFifoDataIn_D     : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal IMUFifoDataOut_D    : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	signal ExtInputFifoControlIn_S  : tToFifo;
	signal ExtInputFifoControlOut_S : tFromFifo;
	signal ExtInputFifoDataIn_D     : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal ExtInputFifoDataOut_D    : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	signal ConfigModuleAddress_D : unsigned(6 downto 0);
	signal ConfigParamAddress_D  : unsigned(7 downto 0);
	signal ConfigParamInput_D    : std_logic_vector(31 downto 0);
	signal ConfigLatchInput_S    : std_logic;
	signal ConfigParamOutput_D   : std_logic_vector(31 downto 0);

	signal MultiplexerConfigParamOutput_D : std_logic_vector(31 downto 0);
	signal DVSAERConfigParamOutput_D      : std_logic_vector(31 downto 0);
	signal D4AAPSADCConfigParamOutput_D   : std_logic_vector(31 downto 0);
	signal IMUConfigParamOutput_D         : std_logic_vector(31 downto 0);
	signal ExtInputConfigParamOutput_D    : std_logic_vector(31 downto 0);
	signal BiasConfigParamOutput_D        : std_logic_vector(31 downto 0);
	signal ChipConfigParamOutput_D        : std_logic_vector(31 downto 0);
	signal SystemInfoConfigParamOutput_D  : std_logic_vector(31 downto 0);
	signal FX3ConfigParamOutput_D         : std_logic_vector(31 downto 0);

	signal MultiplexerConfig_D, MultiplexerConfigReg_D, MultiplexerConfigReg2_D : tMultiplexerConfig;
	signal DVSAERConfig_D, DVSAERConfigReg_D, DVSAERConfigReg2_D                : tDVSAERConfig;
	signal D4AAPSADCConfig_D, D4AAPSADCConfigReg_D, D4AAPSADCConfigReg2_D       : tD4AAPSADCConfig;
	signal IMUConfig_D, IMUConfigReg_D, IMUConfigReg2_D                         : tIMUConfig;
	signal ExtInputConfig_D, ExtInputConfigReg_D, ExtInputConfigReg2_D          : tExtInputConfig;
	signal FX3Config_D, FX3ConfigReg_D, FX3ConfigReg2_D                         : tFX3Config;
begin
	-- First: synchronize all USB-related inputs to the USB clock.
	syncInputsToUSBClock : entity work.FX3USBClockSynchronizer
		port map(
			USBClock_CI                 => USBClock_CI,
			Reset_RI                    => Reset_RI,
			ResetSync_RO                => USBReset_R,
			USBFifoThr0Ready_SI         => USBFifoThr0Ready_SI,
			USBFifoThr0ReadySync_SO     => USBFifoThr0ReadySync_S,
			USBFifoThr0Watermark_SI     => USBFifoThr0Watermark_SI,
			USBFifoThr0WatermarkSync_SO => USBFifoThr0WatermarkSync_S,
			USBFifoThr1Ready_SI         => USBFifoThr1Ready_SI,
			USBFifoThr1ReadySync_SO     => USBFifoThr1ReadySync_S,
			USBFifoThr1Watermark_SI     => USBFifoThr1Watermark_SI,
			USBFifoThr1WatermarkSync_SO => USBFifoThr1WatermarkSync_S);

	-- Second: synchronize all logic-related inputs to the logic clock.
	syncInputsToLogicClock : entity work.LogicClockSynchronizer
		port map(
			LogicClock_CI          => LogicClock_C,
			Reset_RI               => Reset_RI,
			ResetSync_RO           => LogicReset_R,
			SPISlaveSelect_SBI     => SPISlaveSelect_ABI,
			SPISlaveSelectSync_SBO => SPISlaveSelectSync_SB,
			SPIClock_CI            => SPIClock_AI,
			SPIClockSync_CO        => SPIClockSync_C,
			SPIMOSI_DI             => SPIMOSI_AI,
			SPIMOSISync_DO         => SPIMOSISync_D,
			DVSAERReq_SBI          => DVSAERReq_ABI,
			DVSAERReqSync_SBO      => DVSAERReqSync_SB,
			IMUInterrupt_SI        => IMUInterrupt_AI,
			IMUInterruptSync_SO    => IMUInterruptSync_S,
			SyncOutSwitch_SI       => SyncOutSwitch_AI,
			SyncOutSwitchSync_SO   => SyncOutSwitchSync_S,
			SyncInClock_CI         => SyncInClock_AI,
			SyncInClockSync_CO     => SyncInClockSync_C,
			SyncInSwitch_SI        => SyncInSwitch_AI,
			SyncInSwitchSync_SO    => SyncInSwitchSync_S,
			SyncInSignal_SI        => SyncInSignal_AI,
			SyncInSignalSync_SO    => SyncInSignalSync_S);

	-- Third: set all constant outputs.
	USBFifoChipSelect_SBO <= '0';       -- Always keep USB chip selected (active-low).
	USBFifoRead_SBO       <= '1';       -- We never read from the USB data path (active-low).
	USBFifoData_DO        <= LogicUSBFifoDataOut_D;
	IMUFSync_SO           <= '0';       -- Not used, tie to ground according to docs.
	-- Always enable chip if it is needed (for DVS or APS or forced).
	chipBiasEnableBuffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => DVSAERConfig_D.Run_S or D4AAPSADCConfig_D.Run_S or MultiplexerConfig_D.ForceChipBiasEnable_S,
			Output_SO(0) => ChipBiasEnable_SO);

	-- Wire all LEDs.
	led1Buffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => MultiplexerConfig_D.Run_S,
			Output_SO(0) => LED1_SO);

	led2Buffer : entity work.SimpleRegister
		port map(
			Clock_CI     => USBClock_CI,
			Reset_RI     => USBReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => LogicUSBFifoControlOut_S.ReadSide.Empty_S,
			Output_SO(0) => LED2_SO);

	led3Buffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => not SPISlaveSelectSync_SB,
			Output_SO(0) => LED3_SO);

	led4Buffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => LogicUSBFifoControlOut_S.WriteSide.Full_S,
			Output_SO(0) => LED4_SO);

	led5Buffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => '0',
			Output_SO(0) => LED5_SO);

	led6Buffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => '0',
			Output_SO(0) => LED6_SO);

	-- Generate logic clock using a PLL.
	logicClockPLL : entity work.PLL
		generic map(
			CLOCK_FREQ     => USB_CLOCK_FREQ,
			OUT_CLOCK_FREQ => LOGIC_CLOCK_FREQ)
		port map(
			Clock_CI    => USBClock_CI,
			Reset_RI    => USBReset_R,
			OutClock_CO => LogicClock_C);

	-- Generate ADC clock using a PLL. Must be 30MHz.
	adcClockPLL : entity work.PLL
		generic map(
			CLOCK_FREQ     => USB_CLOCK_FREQ,
			OUT_CLOCK_FREQ => ADC_CLOCK_FREQ)
		port map(
			Clock_CI    => USBClock_CI,
			Reset_RI    => USBReset_R,
			OutClock_CO => ADCClock_C);

	-- Also create synchronized reset signal for ADC.
	adcResetSync : entity work.ResetSynchronizer
		port map(
			ExtClock_CI  => ADCClock_C,
			ExtReset_RI  => Reset_RI,
			SyncReset_RO => ADCReset_R);

	usbFX3SM : entity work.FX3Statemachine
		port map(
			Clock_CI                    => USBClock_CI,
			Reset_RI                    => USBReset_R,
			USBFifoThread0Full_SI       => USBFifoThr0ReadySync_S,
			USBFifoThread0AlmostFull_SI => USBFifoThr0WatermarkSync_S,
			USBFifoThread1Full_SI       => USBFifoThr1ReadySync_S,
			USBFifoThread1AlmostFull_SI => USBFifoThr1WatermarkSync_S,
			USBFifoWrite_SBO            => USBFifoWrite_SBO,
			USBFifoPktEnd_SBO           => USBFifoPktEnd_SBO,
			USBFifoAddress_DO           => USBFifoAddress_DO,
			InFifoControl_SI            => LogicUSBFifoControlOut_S.ReadSide,
			InFifoControl_SO            => LogicUSBFifoControlIn_S.ReadSide,
			FX3Config_DI                => FX3ConfigReg2_D);

	fx3SPIConfig : entity work.FX3SPIConfig
		port map(
			Clock_CI                => LogicClock_C,
			Reset_RI                => LogicReset_R,
			FX3Config_DO            => FX3Config_D,
			ConfigModuleAddress_DI  => ConfigModuleAddress_D,
			ConfigParamAddress_DI   => ConfigParamAddress_D,
			ConfigParamInput_DI     => ConfigParamInput_D,
			ConfigLatchInput_SI     => ConfigLatchInput_S,
			FX3ConfigParamOutput_DO => FX3ConfigParamOutput_D);

	-- Instantiate one FIFO to hold all the events coming out of the mixer-producer state machine.
	logicUSBFifo : entity work.FIFODualClock
		generic map(
			DATA_WIDTH        => USB_FIFO_WIDTH,
			DATA_DEPTH        => USBLOGIC_FIFO_SIZE,
			ALMOST_EMPTY_FLAG => USBLOGIC_FIFO_ALMOST_EMPTY_SIZE,
			ALMOST_FULL_FLAG  => USBLOGIC_FIFO_ALMOST_FULL_SIZE)
		port map(
			Reset_RI       => LogicReset_R,
			WrClock_CI     => LogicClock_C,
			RdClock_CI     => USBClock_CI,
			FifoControl_SI => LogicUSBFifoControlIn_S,
			FifoControl_SO => LogicUSBFifoControlOut_S,
			FifoData_DI    => LogicUSBFifoDataIn_D,
			FifoData_DO    => LogicUSBFifoDataOut_D);

	-- In1 is DVS, TS Y addresses. In2 is APS, TS special. In3 is IMU, TS Start6. In4 is ExtInput, TS all.
	In1Timestamp_S <= '1' when DVSAERFifoDataOut_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) = EVENT_CODE_Y_ADDR else '0';
	In2Timestamp_S <= '1' when APSADCFifoDataOut_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) = EVENT_CODE_SPECIAL else '0';
	In3Timestamp_S <= '1' when IMUFifoDataOut_D(EVENT_DATA_WIDTH_MAX - 1 downto 0) = EVENT_CODE_SPECIAL_IMU_START6 else '0';
	In4Timestamp_S <= '1' when true else '0';

	multiplexerSM : entity work.MultiplexerStateMachine
		port map(
			Clock_CI             => LogicClock_C,
			Reset_RI             => LogicReset_R,
			SyncInClock_CI       => SyncInClockSync_C,
			SyncOutClock_CO      => SyncOutClock_CO,
			DeviceIsMaster_SO    => DeviceIsMaster_S,
			OutFifoControl_SI    => LogicUSBFifoControlOut_S.WriteSide,
			OutFifoControl_SO    => LogicUSBFifoControlIn_S.WriteSide,
			OutFifoData_DO       => LogicUSBFifoDataIn_D,
			In1FifoControl_SI    => DVSAERFifoControlOut_S.ReadSide,
			In1FifoControl_SO    => DVSAERFifoControlIn_S.ReadSide,
			In1FifoData_DI       => DVSAERFifoDataOut_D,
			In1Timestamp_SI      => In1Timestamp_S,
			In2FifoControl_SI    => APSADCFifoControlOut_S.ReadSide,
			In2FifoControl_SO    => APSADCFifoControlIn_S.ReadSide,
			In2FifoData_DI       => APSADCFifoDataOut_D,
			In2Timestamp_SI      => In2Timestamp_S,
			In3FifoControl_SI    => IMUFifoControlOut_S.ReadSide,
			In3FifoControl_SO    => IMUFifoControlIn_S.ReadSide,
			In3FifoData_DI       => IMUFifoDataOut_D,
			In3Timestamp_SI      => In3Timestamp_S,
			In4FifoControl_SI    => ExtInputFifoControlOut_S.ReadSide,
			In4FifoControl_SO    => ExtInputFifoControlIn_S.ReadSide,
			In4FifoData_DI       => ExtInputFifoDataOut_D,
			In4Timestamp_SI      => In4Timestamp_S,
			MultiplexerConfig_DI => MultiplexerConfigReg2_D);

	multiplexerSPIConfig : entity work.MultiplexerSPIConfig
		port map(
			Clock_CI                        => LogicClock_C,
			Reset_RI                        => LogicReset_R,
			MultiplexerConfig_DO            => MultiplexerConfig_D,
			ConfigModuleAddress_DI          => ConfigModuleAddress_D,
			ConfigParamAddress_DI           => ConfigParamAddress_D,
			ConfigParamInput_DI             => ConfigParamInput_D,
			ConfigLatchInput_SI             => ConfigLatchInput_S,
			MultiplexerConfigParamOutput_DO => MultiplexerConfigParamOutput_D);

	dvsAerFifo : entity work.FIFO
		generic map(
			DATA_WIDTH        => EVENT_WIDTH,
			DATA_DEPTH        => DVSAER_FIFO_SIZE,
			ALMOST_EMPTY_FLAG => DVSAER_FIFO_ALMOST_EMPTY_SIZE,
			ALMOST_FULL_FLAG  => DVSAER_FIFO_ALMOST_FULL_SIZE)
		port map(
			Clock_CI       => LogicClock_C,
			Reset_RI       => LogicReset_R,
			FifoControl_SI => DVSAERFifoControlIn_S,
			FifoControl_SO => DVSAERFifoControlOut_S,
			FifoData_DI    => DVSAERFifoDataIn_D,
			FifoData_DO    => DVSAERFifoDataOut_D);

	dvsAerSM : entity work.DVSAERStateMachine
		generic map(
			ENABLE_PIXEL_FILTERING     => true,
			ENABLE_BA_FILTERING        => DVS_BAFILTER_ENABLE,
			BA_FILTER_SUBSAMPLE_COLUMN => DVS_BAFILTER_SUBSAMPLE_COL,
			BA_FILTER_SUBSAMPLE_ROW    => DVS_BAFILTER_SUBSAMPLE_ROW)
		port map(
			Clock_CI          => LogicClock_C,
			Reset_RI          => LogicReset_R,
			OutFifoControl_SI => DVSAERFifoControlOut_S.WriteSide,
			OutFifoControl_SO => DVSAERFifoControlIn_S.WriteSide,
			OutFifoData_DO    => DVSAERFifoDataIn_D,
			DVSAERData_DI     => DVSAERData_AI,
			DVSAERReq_SBI     => DVSAERReqSync_SB,
			DVSAERAck_SBO     => DVSAERAck_SBO,
			DVSAERReset_SBO   => DVSAERReset_SBO,
			DVSAERConfig_DI   => DVSAERConfigReg2_D);

	dvsaerSPIConfig : entity work.DVSAERSPIConfig
		generic map(
			ENABLE_PIXEL_FILTERING => true,
			ENABLE_BA_FILTERING    => DVS_BAFILTER_ENABLE)
		port map(
			Clock_CI                   => LogicClock_C,
			Reset_RI                   => LogicReset_R,
			DVSAERConfig_DO            => DVSAERConfig_D,
			ConfigModuleAddress_DI     => ConfigModuleAddress_D,
			ConfigParamAddress_DI      => ConfigParamAddress_D,
			ConfigParamInput_DI        => ConfigParamInput_D,
			ConfigLatchInput_SI        => ConfigLatchInput_S,
			DVSAERConfigParamOutput_DO => DVSAERConfigParamOutput_D);

	-- Dual-clock FIFO is needed to bridge from ADC clock (ADCClock_C in this case) to logic clock.
	apsAdcFifo : entity work.FIFODualClock
		generic map(
			DATA_WIDTH        => EVENT_WIDTH,
			DATA_DEPTH        => APSADC_FIFO_SIZE,
			ALMOST_EMPTY_FLAG => APSADC_FIFO_ALMOST_EMPTY_SIZE,
			ALMOST_FULL_FLAG  => APSADC_FIFO_ALMOST_FULL_SIZE)
		port map(
			Reset_RI       => ADCReset_R,
			WrClock_CI     => ADCClock_C,
			RdClock_CI     => LogicClock_C,
			FifoControl_SI => APSADCFifoControlIn_S,
			FifoControl_SO => APSADCFifoControlOut_S,
			FifoData_DI    => APSADCFifoDataIn_D,
			FifoData_DO    => APSADCFifoDataOut_D);

	apsAdcSM : entity work.D4AAPSADCStateMachine3
		port map(
			Clock_CI                 => ADCClock_C,
			Reset_RI                 => ADCReset_R,
			OutFifoControl_SI        => APSADCFifoControlOut_S.WriteSide,
			OutFifoControl_SO        => APSADCFifoControlIn_S.WriteSide,
			OutFifoData_DO           => APSADCFifoDataIn_D,
			APSChipColSRClock_CO     => APSChipColSRClock_CO,
			APSChipColSRIn_SO        => APSChipColSRIn_SO,
			APSChipRowSRClock_CO     => APSChipRowSRClock_CO,
			APSChipRowSRIn_SO        => APSChipRowSRIn_SO,
			APSChipOverflowGate_SO   => APSChipOverflowGate_SO,
			APSChipTXGate_SO         => APSChipTXGate_SO,
			APSChipReset_SO          => APSChipReset_SO,
			APSChipGlobalShutter_SBO => APSChipGlobalShutter_SBO,
			ChipADCData_DI           => ChipADCData_DI,
			ChipADCRampClear_SO      => ChipADCRampClear_SO,
			ChipADCRampClock_CO      => ChipADCRampClock_CO,
			ChipADCRampBitIn_SO      => ChipADCRampBitIn_SO,
			ChipADCScanClock_CO      => ChipADCScanClock_CO,
			ChipADCScanControl_SO    => ChipADCScanControl_SO,
			ChipADCSample_SO         => ChipADCSample_SO,
			ChipADCGrayCounter_DO    => ChipADCGrayCounter_DO,
			Debug1_DO				 => Debug1_DO,
			Debug2_DO				 => Debug2_DO,
			Debug3_DO				 => Debug3_DO,
			D4AAPSADCConfig_DI       => D4AAPSADCConfigReg2_D);

	apsAdcSPIConfig : entity work.D4AAPSADCSPIConfig
		port map(
			Clock_CI                      => LogicClock_C,
			Reset_RI                      => LogicReset_R,
			D4AAPSADCConfig_DO            => D4AAPSADCConfig_D,
			ConfigModuleAddress_DI        => ConfigModuleAddress_D,
			ConfigParamAddress_DI         => ConfigParamAddress_D,
			ConfigParamInput_DI           => ConfigParamInput_D,
			ConfigLatchInput_SI           => ConfigLatchInput_S,
			D4AAPSADCConfigParamOutput_DO => D4AAPSADCConfigParamOutput_D);

	imuFifo : entity work.FIFO
		generic map(
			DATA_WIDTH        => EVENT_WIDTH,
			DATA_DEPTH        => IMU_FIFO_SIZE,
			ALMOST_EMPTY_FLAG => IMU_FIFO_ALMOST_EMPTY_SIZE,
			ALMOST_FULL_FLAG  => IMU_FIFO_ALMOST_FULL_SIZE,
			MEMORY            => "LUT")
		port map(
			Clock_CI       => LogicClock_C,
			Reset_RI       => LogicReset_R,
			FifoControl_SI => IMUFifoControlIn_S,
			FifoControl_SO => IMUFifoControlOut_S,
			FifoData_DI    => IMUFifoDataIn_D,
			FifoData_DO    => IMUFifoDataOut_D);

	imuSM : entity work.IMUStateMachine
		port map(
			Clock_CI          => LogicClock_C,
			Reset_RI          => LogicReset_R,
			OutFifoControl_SI => IMUFifoControlOut_S.WriteSide,
			OutFifoControl_SO => IMUFifoControlIn_S.WriteSide,
			OutFifoData_DO    => IMUFifoDataIn_D,
			IMUClock_CZO      => IMUClock_CZO,
			IMUData_DZIO      => IMUData_DZIO,
			IMUInterrupt_SI   => IMUInterruptSync_S,
			IMUConfig_DI      => IMUConfigReg2_D);

	imuSPIConfig : entity work.IMUSPIConfig
		port map(
			Clock_CI                => LogicClock_C,
			Reset_RI                => LogicReset_R,
			IMUConfig_DO            => IMUConfig_D,
			ConfigModuleAddress_DI  => ConfigModuleAddress_D,
			ConfigParamAddress_DI   => ConfigParamAddress_D,
			ConfigParamInput_DI     => ConfigParamInput_D,
			ConfigLatchInput_SI     => ConfigLatchInput_S,
			IMUConfigParamOutput_DO => IMUConfigParamOutput_D);

	extInputFifo : entity work.FIFO
		generic map(
			DATA_WIDTH        => EVENT_WIDTH,
			DATA_DEPTH        => EXT_INPUT_FIFO_SIZE,
			ALMOST_EMPTY_FLAG => EXT_INPUT_FIFO_ALMOST_EMPTY_SIZE,
			ALMOST_FULL_FLAG  => EXT_INPUT_FIFO_ALMOST_FULL_SIZE,
			MEMORY            => "LUT")
		port map(
			Clock_CI       => LogicClock_C,
			Reset_RI       => LogicReset_R,
			FifoControl_SI => ExtInputFifoControlIn_S,
			FifoControl_SO => ExtInputFifoControlOut_S,
			FifoData_DI    => ExtInputFifoDataIn_D,
			FifoData_DO    => ExtInputFifoDataOut_D);

	extInputSM : entity work.ExtInputStateMachine
		port map(
			Clock_CI              => LogicClock_C,
			Reset_RI              => LogicReset_R,
			OutFifoControl_SI     => ExtInputFifoControlOut_S.WriteSide,
			OutFifoControl_SO     => ExtInputFifoControlIn_S.WriteSide,
			OutFifoData_DO        => ExtInputFifoDataIn_D,
			ExtInputSignal_SI     => SyncInSignalSync_S,
			CustomOutputSignal_SI => '1',
			ExtInputSignal_SO     => SyncOutSignal_SO,
			ExtInputConfig_DI     => ExtInputConfigReg2_D);

	extInputSPIConfig : entity work.ExtInputSPIConfig
		port map(
			Clock_CI                     => LogicClock_C,
			Reset_RI                     => LogicReset_R,
			ExtInputConfig_DO            => ExtInputConfig_D,
			ConfigModuleAddress_DI       => ConfigModuleAddress_D,
			ConfigParamAddress_DI        => ConfigParamAddress_D,
			ConfigParamInput_DI          => ConfigParamInput_D,
			ConfigLatchInput_SI          => ConfigLatchInput_S,
			ExtInputConfigParamOutput_DO => ExtInputConfigParamOutput_D);

	systemInfoSPIConfig : entity work.SystemInfoSPIConfig
		port map(
			Clock_CI                       => LogicClock_C,
			Reset_RI                       => LogicReset_R,
			DeviceIsMaster_SI              => DeviceIsMaster_S,
			ConfigParamAddress_DI          => ConfigParamAddress_D,
			SystemInfoConfigParamOutput_DO => SystemInfoConfigParamOutput_D);

	configRegisters : process(LogicClock_C, LogicReset_R) is
	begin
		if LogicReset_R = '1' then
			MultiplexerConfigReg2_D <= tMultiplexerConfigDefault;
			DVSAERConfigReg2_D      <= tDVSAERConfigDefault;
			D4AAPSADCConfigReg2_D   <= tD4AAPSADCConfigDefault;
			IMUConfigReg2_D         <= tIMUConfigDefault;
			ExtInputConfigReg2_D    <= tExtInputConfigDefault;
			FX3ConfigReg2_D         <= tFX3ConfigDefault;

			MultiplexerConfigReg_D <= tMultiplexerConfigDefault;
			DVSAERConfigReg_D      <= tDVSAERConfigDefault;
			D4AAPSADCConfigReg_D   <= tD4AAPSADCConfigDefault;
			IMUConfigReg_D         <= tIMUConfigDefault;
			ExtInputConfigReg_D    <= tExtInputConfigDefault;
			FX3ConfigReg_D         <= tFX3ConfigDefault;
		elsif rising_edge(LogicClock_C) then
			MultiplexerConfigReg2_D <= MultiplexerConfigReg_D;
			DVSAERConfigReg2_D      <= DVSAERConfigReg_D;
			D4AAPSADCConfigReg2_D   <= D4AAPSADCConfigReg_D;
			IMUConfigReg2_D         <= IMUConfigReg_D;
			ExtInputConfigReg2_D    <= ExtInputConfigReg_D;
			FX3ConfigReg2_D         <= FX3ConfigReg_D;

			MultiplexerConfigReg_D <= MultiplexerConfig_D;
			DVSAERConfigReg_D      <= DVSAERConfig_D;
			D4AAPSADCConfigReg_D   <= D4AAPSADCConfig_D;
			IMUConfigReg_D         <= IMUConfig_D;
			ExtInputConfigReg_D    <= ExtInputConfig_D;
			FX3ConfigReg_D         <= FX3Config_D;
		end if;
	end process configRegisters;

	spiConfiguration : entity work.SPIConfig
		port map(
			Clock_CI               => LogicClock_C,
			Reset_RI               => LogicReset_R,
			SPISlaveSelect_SBI     => SPISlaveSelectSync_SB,
			SPIClock_CI            => SPIClockSync_C,
			SPIMOSI_DI             => SPIMOSISync_D,
			SPIMISO_DZO            => SPIMISO_DZO,
			ConfigModuleAddress_DO => ConfigModuleAddress_D,
			ConfigParamAddress_DO  => ConfigParamAddress_D,
			ConfigParamInput_DO    => ConfigParamInput_D,
			ConfigLatchInput_SO    => ConfigLatchInput_S,
			ConfigParamOutput_DI   => ConfigParamOutput_D);

	spiConfigurationOutputSelect : process(ConfigModuleAddress_D, ConfigParamAddress_D, MultiplexerConfigParamOutput_D, DVSAERConfigParamOutput_D, D4AAPSADCConfigParamOutput_D, IMUConfigParamOutput_D, ExtInputConfigParamOutput_D, BiasConfigParamOutput_D, ChipConfigParamOutput_D, SystemInfoConfigParamOutput_D, FX3ConfigParamOutput_D)
	begin
		-- Output side select.
		ConfigParamOutput_D <= (others => '0');

		case ConfigModuleAddress_D is
			when MULTIPLEXERCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= MultiplexerConfigParamOutput_D;

			when DVSAERCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= DVSAERConfigParamOutput_D;

			when D4AAPSADCCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= D4AAPSADCConfigParamOutput_D;

			when IMUCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= IMUConfigParamOutput_D;

			when EXTINPUTCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= ExtInputConfigParamOutput_D;

			when CHIPBIASCONFIG_MODULE_ADDRESS =>
				if ConfigParamAddress_D(7) = '0' then
					ConfigParamOutput_D <= BiasConfigParamOutput_D;
				else
					ConfigParamOutput_D <= ChipConfigParamOutput_D;
				end if;

			when SYSTEMINFOCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= SystemInfoConfigParamOutput_D;

			when FX3CONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= FX3ConfigParamOutput_D;

			when others => null;
		end case;
	end process spiConfigurationOutputSelect;

	chipBiasSelector : entity work.ChipBiasSelector
		port map(
			Clock_CI                 => LogicClock_C,
			Reset_RI                 => LogicReset_R,
			ChipBiasDiagSelect_SO    => ChipBiasDiagSelect_SO,
			ChipBiasAddrSelect_SBO   => ChipBiasAddrSelect_SBO,
			ChipBiasClock_CBO        => ChipBiasClock_CBO,
			ChipBiasBitIn_DO         => ChipBiasBitIn_DO,
			ChipBiasLatch_SBO        => ChipBiasLatch_SBO,
			ConfigModuleAddress_DI   => ConfigModuleAddress_D,
			ConfigParamAddress_DI    => ConfigParamAddress_D,
			ConfigParamInput_DI      => ConfigParamInput_D,
			ConfigLatchInput_SI      => ConfigLatchInput_S,
			BiasConfigParamOutput_DO => BiasConfigParamOutput_D,
			ChipConfigParamOutput_DO => ChipConfigParamOutput_D);
end Structural;
