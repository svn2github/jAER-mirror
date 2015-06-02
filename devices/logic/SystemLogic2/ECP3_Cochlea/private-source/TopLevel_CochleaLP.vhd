library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.Settings.all;
use work.FIFORecords.all;
use work.MultiplexerConfigRecords.all;
use work.SystemInfoConfigRecords.all;
use work.FX3ConfigRecords.all;
use work.ChipBiasConfigRecords.all;

entity TopLevel_CochleaLP is
	port(
		USBClock_CI                : in  std_logic;
		Reset_RI                   : in  std_logic;

		SPISlaveSelect_ABI         : in  std_logic;
		SPIClock_AI                : in  std_logic;
		SPIMOSI_AI                 : in  std_logic;
		SPIMISO_DZO                : out std_logic;

		USBFifoData_DO             : out std_logic_vector(USB_FIFO_WIDTH - 1 downto 0);
		USBFifoChipSelect_SBO      : out std_logic;
		USBFifoWrite_SBO           : out std_logic;
		USBFifoRead_SBO            : out std_logic;
		USBFifoPktEnd_SBO          : out std_logic;
		USBFifoAddress_DO          : out std_logic_vector(1 downto 0);
		USBFifoThr0Ready_SI        : in  std_logic;
		USBFifoThr0Watermark_SI    : in  std_logic;
		USBFifoThr1Ready_SI        : in  std_logic;
		USBFifoThr1Watermark_SI    : in  std_logic;

		LED1_SO                    : out std_logic;
		LED2_SO                    : out std_logic;
		LED3_SO                    : out std_logic;
		LED4_SO                    : out std_logic;
		LED5_SO                    : out std_logic;
		LED6_SO                    : out std_logic;

		ChipBiasEnable_SO          : out std_logic;
		ChipBiasDiagSelect_SO      : out std_logic;
		ChipBiasAddrSelect_SBO     : out std_logic;
		ChipBiasClock_CBO          : out std_logic;
		ChipBiasBitIn_DO           : out std_logic;
		ChipBiasLatch_SBO          : out std_logic;
		--ChipBiasBitOut_DI : in std_logic;

		-- Fake event input from USBAERmini boards.
		DVSAERData_AI              : in  std_logic_vector(AER_BUS_WIDTH - 1 downto 0);
		DVSAERReq_ABI              : in  std_logic;
		DVSAERAck_SBO              : out std_logic;

		-- Communication with AERCorrFilter chip.
		AERCorrFilterPass_SI       : in  std_logic;
		AERCorrFilterPassEnable_SO : out std_logic;
		AERCorrFilterData_DO       : out std_logic_vector(AER_BUS_WIDTH - 1 downto 0);
		AERCorrFilterReq_SBO       : out std_logic;
		AERCorrFilterAck_SBO       : out std_logic;

		SyncOutClock_CO            : out std_logic;
		SyncOutSwitch_AI           : in  std_logic;
		SyncOutSignal_SO           : out std_logic;
		SyncInClock_AI             : in  std_logic;
		SyncInSwitch_AI            : in  std_logic;
		SyncInSignal_AI            : in  std_logic);
end TopLevel_CochleaLP;

architecture Structural of TopLevel_CochleaLP is
	signal USBReset_R   : std_logic;
	signal LogicClock_C : std_logic;
	signal LogicReset_R : std_logic;

	signal USBFifoThr0ReadySync_S, USBFifoThr0WatermarkSync_S, USBFifoThr1ReadySync_S, USBFifoThr1WatermarkSync_S : std_logic;
	signal DVSAERReqSync_SB, DVSAERAck_SB                                                                         : std_logic;
	signal SyncInClockSync_C                                                                                      : std_logic;
	signal SPISlaveSelectSync_SB, SPIClockSync_C, SPIMOSISync_D                                                   : std_logic;
	signal DeviceIsMaster_S                                                                                       : std_logic;

	signal In1Timestamp_S : std_logic;

	signal LogicUSBFifoControlIn_S  : tToFifo;
	signal LogicUSBFifoControlOut_S : tFromFifo;
	signal LogicUSBFifoDataIn_D     : std_logic_vector(FULL_EVENT_WIDTH - 1 downto 0);
	signal LogicUSBFifoDataOut_D    : std_logic_vector(USB_FIFO_WIDTH - 1 downto 0);

	signal DVSAERCorrFilterFifoControlIn_S  : tToFifo;
	signal DVSAERCorrFilterFifoControlOut_S : tFromFifo;
	signal DVSAERCorrFilterFifoDataIn_D     : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal DVSAERCorrFilterFifoDataOut_D    : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	signal ConfigModuleAddress_D : unsigned(6 downto 0);
	signal ConfigParamAddress_D  : unsigned(7 downto 0);
	signal ConfigParamInput_D    : std_logic_vector(31 downto 0);
	signal ConfigLatchInput_S    : std_logic;
	signal ConfigParamOutput_D   : std_logic_vector(31 downto 0);

	signal MultiplexerConfigParamOutput_D      : std_logic_vector(31 downto 0);
	signal DVSAERCorrFilterConfigParamOutput_D : std_logic_vector(31 downto 0);
	signal BiasConfigParamOutput_D             : std_logic_vector(31 downto 0);
	signal ChipConfigParamOutput_D             : std_logic_vector(31 downto 0);
	signal SystemInfoConfigParamOutput_D       : std_logic_vector(31 downto 0);
	signal FX3ConfigParamOutput_D              : std_logic_vector(31 downto 0);

	signal MultiplexerConfig_D, MultiplexerConfigReg_D, MultiplexerConfigReg2_D                : tMultiplexerConfig;
	signal DVSAERCorrFilterConfig_D, DVSAERCorrFilterConfigReg_D, DVSAERCorrFilterConfigReg2_D : tDVSAERCorrFilterConfig;
	signal FX3Config_D, FX3ConfigReg_D, FX3ConfigReg2_D                                        : tFX3Config;

	signal AERCorrFilterBiasConfig_D, AERCorrFilterBiasConfigReg_D : tAERCorrFilterBiasConfig;
	signal AERCorrFilterChipConfig_D, AERCorrFilterChipConfigReg_D : tAERCorrFilterChipConfig;

	signal AERCorrFilterPassEnableReg_S : std_logic;
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
			IMUInterrupt_SI        => '0',
			IMUInterruptSync_SO    => open,
			SyncOutSwitch_SI       => '0',
			SyncOutSwitchSync_SO   => open,
			SyncInClock_CI         => SyncInClock_AI,
			SyncInClockSync_CO     => SyncInClockSync_C,
			SyncInSwitch_SI        => '0',
			SyncInSwitchSync_SO    => open,
			SyncInSignal_SI        => '0',
			SyncInSignalSync_SO    => open);

	-- Third: set all constant outputs.
	USBFifoChipSelect_SBO <= '0';       -- Always keep USB chip selected (active-low).
	USBFifoRead_SBO       <= '1';       -- We never read from the USB data path (active-low).
	USBFifoData_DO        <= LogicUSBFifoDataOut_D;

	-- Always enable chip if it is needed (for DVS or APS or forced).
	chipBiasEnableBuffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => DVSAERCorrFilterConfig_D.Run_S or MultiplexerConfig_D.ForceChipBiasEnable_S,
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

	-- In1 is DVS, TS Y addresses.
	In1Timestamp_S <= '1' when DVSAERCorrFilterFifoDataOut_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) = EVENT_CODE_Y_ADDR else '0';

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
			In1FifoControl_SI    => DVSAERCorrFilterFifoControlOut_S.ReadSide,
			In1FifoControl_SO    => DVSAERCorrFilterFifoControlIn_S.ReadSide,
			In1FifoData_DI       => DVSAERCorrFilterFifoDataOut_D,
			In1Timestamp_SI      => In1Timestamp_S,
			In2FifoControl_SI    => (others => '1'),
			In2FifoControl_SO    => open,
			In2FifoData_DI       => (others => '0'),
			In2Timestamp_SI      => '0',
			In3FifoControl_SI    => (others => '1'),
			In3FifoControl_SO    => open,
			In3FifoData_DI       => (others => '0'),
			In3Timestamp_SI      => '0',
			In4FifoControl_SI    => (others => '1'),
			In4FifoControl_SO    => open,
			In4FifoData_DI       => (others => '0'),
			In4Timestamp_SI      => '0',
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
			FifoControl_SI => DVSAERCorrFilterFifoControlIn_S,
			FifoControl_SO => DVSAERCorrFilterFifoControlOut_S,
			FifoData_DI    => DVSAERCorrFilterFifoDataIn_D,
			FifoData_DO    => DVSAERCorrFilterFifoDataOut_D);

	-- Connect all AER buses as specified (Y configuration).
	DVSAERAck_SBO        <= DVSAERAck_SB;
	AERCorrFilterAck_SBO <= DVSAERAck_SB;
	AERCorrFilterReq_SBO <= DVSAERReqSync_SB;
	AERCorrFilterData_DO <= DVSAERData_AI;

	dvsAerCorrFilterSM : entity work.DVSAERCorrFilterStateMachine
		port map(
			Clock_CI                   => LogicClock_C,
			Reset_RI                   => LogicReset_R,
			OutFifoControl_SI          => DVSAERCorrFilterFifoControlOut_S.WriteSide,
			OutFifoControl_SO          => DVSAERCorrFilterFifoControlIn_S.WriteSide,
			OutFifoData_DO             => DVSAERCorrFilterFifoDataIn_D,
			DVSAERData_DI              => DVSAERData_AI,
			DVSAERReq_SBI              => DVSAERReqSync_SB,
			DVSAERAck_SBO              => DVSAERAck_SB,
			DVSAERReset_SBO            => open,
			AERCorrFilterPass_SI       => AERCorrFilterPass_SI,
			AERCorrFilterPassEnable_SO => AERCorrFilterPassEnableReg_S,
			DVSAERCorrFilterConfig_DI  => DVSAERCorrFilterConfigReg2_D);

	passEnableBuffer : entity work.SimpleRegister
		generic map(
			SIZE => 1)
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => AERCorrFilterPassEnableReg_S,
			Output_SO(0) => AERCorrFilterPassEnable_SO);

	dvsAerSPIConfig : entity work.DVSAERCorrFilterSPIConfig
		port map(
			Clock_CI                             => LogicClock_C,
			Reset_RI                             => LogicReset_R,
			DVSAERCorrFilterConfig_DO            => DVSAERCorrFilterConfig_D,
			ConfigModuleAddress_DI               => ConfigModuleAddress_D,
			ConfigParamAddress_DI                => ConfigParamAddress_D,
			ConfigParamInput_DI                  => ConfigParamInput_D,
			ConfigLatchInput_SI                  => ConfigLatchInput_S,
			DVSAERCorrFilterConfigParamOutput_DO => DVSAERCorrFilterConfigParamOutput_D);

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
			MultiplexerConfigReg2_D      <= tMultiplexerConfigDefault;
			DVSAERCorrFilterConfigReg2_D <= tDVSAERCorrFilterConfigDefault;
			FX3ConfigReg2_D              <= tFX3ConfigDefault;

			MultiplexerConfigReg_D      <= tMultiplexerConfigDefault;
			DVSAERCorrFilterConfigReg_D <= tDVSAERCorrFilterConfigDefault;
			FX3ConfigReg_D              <= tFX3ConfigDefault;
		elsif rising_edge(LogicClock_C) then
			MultiplexerConfigReg2_D      <= MultiplexerConfigReg_D;
			DVSAERCorrFilterConfigReg2_D <= DVSAERCorrFilterConfigReg_D;
			FX3ConfigReg2_D              <= FX3ConfigReg_D;

			MultiplexerConfigReg_D      <= MultiplexerConfig_D;
			DVSAERCorrFilterConfigReg_D <= DVSAERCorrFilterConfig_D;
			FX3ConfigReg_D              <= FX3Config_D;
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

	spiConfigurationOutputSelect : process(ConfigModuleAddress_D, ConfigParamAddress_D, MultiplexerConfigParamOutput_D, DVSAERCorrFilterConfigParamOutput_D, BiasConfigParamOutput_D, ChipConfigParamOutput_D, SystemInfoConfigParamOutput_D, FX3ConfigParamOutput_D)
	begin
		-- Output side select.
		ConfigParamOutput_D <= (others => '0');

		case ConfigModuleAddress_D is
			when MULTIPLEXERCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= MultiplexerConfigParamOutput_D;

			when DVSAERCORRFILTERCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= DVSAERCorrFilterConfigParamOutput_D;

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

	chipBiasSM : entity work.AERCorrFilterStateMachine
		port map(
			Clock_CI               => LogicClock_C,
			Reset_RI               => LogicReset_R,
			ChipBiasDiagSelect_SO  => ChipBiasDiagSelect_SO,
			ChipBiasAddrSelect_SBO => ChipBiasAddrSelect_SBO,
			ChipBiasClock_CBO      => ChipBiasClock_CBO,
			ChipBiasBitIn_DO       => ChipBiasBitIn_DO,
			ChipBiasLatch_SBO      => ChipBiasLatch_SBO,
			BiasConfig_DI          => AERCorrFilterBiasConfigReg_D,
			ChipConfig_DI          => AERCorrFilterChipConfigReg_D);

	chipBiasConfigRegisters : process(LogicClock_C, LogicReset_R) is
	begin
		if LogicReset_R = '1' then
			AERCorrFilterBiasConfigReg_D <= tAERCorrFilterBiasConfigDefault;
			AERCorrFilterChipConfigReg_D <= tAERCorrFilterChipConfigDefault;
		elsif rising_edge(LogicClock_C) then
			AERCorrFilterBiasConfigReg_D <= AERCorrFilterBiasConfig_D;
			AERCorrFilterChipConfigReg_D <= AERCorrFilterChipConfig_D;
		end if;
	end process chipBiasConfigRegisters;

	chipBiasSPIConfig : entity work.AERCorrFilterSPIConfig
		port map(
			Clock_CI                 => LogicClock_C,
			Reset_RI                 => LogicReset_R,
			BiasConfig_DO            => AERCorrFilterBiasConfig_D,
			ChipConfig_DO            => AERCorrFilterChipConfig_D,
			ConfigModuleAddress_DI   => ConfigModuleAddress_D,
			ConfigParamAddress_DI    => ConfigParamAddress_D,
			ConfigParamInput_DI      => ConfigParamInput_D,
			ConfigLatchInput_SI      => ConfigLatchInput_S,
			BiasConfigParamOutput_DO => BiasConfigParamOutput_D,
			ChipConfigParamOutput_DO => ChipConfigParamOutput_D);
end Structural;
