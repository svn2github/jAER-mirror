library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.all;
use work.FIFORecords.all;
use work.FX3ConfigRecords.all;
use work.TestConfigRecords.all;

entity TopLevel is
	port(
		USBClock_CI                : in    std_logic;
		Reset_RI                   : in    std_logic;

		SPISlaveSelect_ABI         : in    std_logic;
		SPIClock_AI                : in    std_logic;
		SPIMOSI_AI                 : in    std_logic;
		SPIMISO_DZO                : out   std_logic;

		USBFifoData_DO             : out   std_logic_vector(USB_FIFO_WIDTH - 1 downto 0);
		USBFifoChipSelect_SBO      : out   std_logic;
		USBFifoWrite_SBO           : out   std_logic;
		USBFifoRead_SBO            : out   std_logic;
		USBFifoPktEnd_SBO          : out   std_logic;
		USBFifoAddress_DO          : out   std_logic_vector(1 downto 0);
		USBFifoThr0Ready_SI        : inout std_logic;
		USBFifoThr0Watermark_SI    : inout std_logic;
		USBFifoThr1Ready_SI        : inout std_logic;
		USBFifoThr1Watermark_SI    : inout std_logic;

		LED1_SO                    : out   std_logic;
		LED2_SO                    : out   std_logic;
		LED3_SO                    : out   std_logic;
		LED4_SO                    : out   std_logic;
		LED5_SO                    : out   std_logic;
		LED6_SO                    : out   std_logic;

		SERDESClockOutputEnable_SO : out   std_logic;

		AuxClockOutputEnable_SO    : out   std_logic;
		AuxClockPos_CI             : in    std_logic;
		AuxClockNeg_CI             : in    std_logic;

		SRAMChipEnable1_SBO        : out   std_logic;
		SRAMOutputEnable1_SBO      : out   std_logic;
		SRAMWriteEnable1_SBO       : out   std_logic;
		SRAMChipEnable2_SBO        : out   std_logic;
		SRAMOutputEnable2_SBO      : out   std_logic;
		SRAMWriteEnable2_SBO       : out   std_logic;
		SRAMChipEnable3_SBO        : out   std_logic;
		SRAMOutputEnable3_SBO      : out   std_logic;
		SRAMWriteEnable3_SBO       : out   std_logic;
		SRAMChipEnable4_SBO        : out   std_logic;
		SRAMOutputEnable4_SBO      : out   std_logic;
		SRAMWriteEnable4_SBO       : out   std_logic;
		SRAMAddress_DO             : out   std_logic_vector(20 downto 0);
		SRAMData_DZIO              : inout std_logic_vector(15 downto 0);

		SDCardData_DO              : out   std_logic_vector(3 downto 0);
		SDCardCommand_SO           : out   std_logic;
		SDCardClock_CO             : out   std_logic;

		RTCSlaveSelect_SBO         : out   std_logic;
		RTCClock_CO                : out   std_logic;
		RTCMOSI_DO                 : out   std_logic;
		RTCMISO_AI                 : in    std_logic;
		RTCInterrupt_AI            : in    std_logic;

		SyncOutClock_CO            : out   std_logic;
		SyncOutSwitch_AI           : in    std_logic;
		SyncOutSignal_SO           : out   std_logic;
		SyncInClock_AI             : in    std_logic;
		SyncInSwitch_AI            : in    std_logic;
		SyncInSignal_AI            : in    std_logic;

		Bank0_DO                   : out   std_logic_vector(37 downto 0);
		Bank0VRef_DO               : out   std_logic_vector(1 downto 0);
		Bank0ClockPos_CO           : out   std_logic;
		Bank0ClockNeg_CO           : out   std_logic;

		Bank1_DO                   : out   std_logic_vector(29 downto 0);
		Bank1VRef_DO               : out   std_logic_vector(1 downto 0);

		Bank2_DO                   : out   std_logic_vector(19 downto 0);
		Bank2VRef_DO               : out   std_logic_vector(1 downto 0);
		Bank2ClockPos_CO           : out   std_logic;
		Bank2ClockNeg_CO           : out   std_logic;

		Bank7_DO                   : out   std_logic_vector(31 downto 0);
		Bank7VRef_DO               : out   std_logic_vector(1 downto 0);
		Bank7ClockPos_CO           : out   std_logic;
		Bank7ClockNeg_CO           : out   std_logic);
end TopLevel;

architecture Structural of TopLevel is
	signal USBReset_R   : std_logic;
	signal LogicClock_C : std_logic;
	signal LogicReset_R : std_logic;

	signal USBFifoData_D        : std_logic_vector(USB_FIFO_WIDTH - 1 downto 0);
	signal USBFifoChipSelect_SB : std_logic;
	signal USBFifoWrite_SB      : std_logic;
	signal USBFifoRead_SB       : std_logic;
	signal USBFifoPktEnd_SB     : std_logic;
	signal USBFifoAddress_D     : std_logic_vector(1 downto 0);

	signal USBFifoThr0ReadySync_S, USBFifoThr0WatermarkSync_S, USBFifoThr1ReadySync_S, USBFifoThr1WatermarkSync_S : std_logic;
	signal SPISlaveSelectSync_SB, SPIClockSync_C, SPIMOSISync_D                                                   : std_logic;
	signal RTCMISOSync_D, RTCInterruptSync_S                                                                      : std_logic;
	signal Bank0Pulse_S, Bank1Pulse_S, Bank2Pulse_S, Bank7Pulse_S                                                 : std_logic;
	signal SyncConnectorPulse_S                                                                                   : std_logic;

	signal LogicUSBFifoControlIn_S  : tToFifo;
	signal LogicUSBFifoControlOut_S : tFromFifo;
	signal LogicUSBFifoDataIn_D     : std_logic_vector(NUMBER_GENERATOR_WIDTH - 1 downto 0);
	signal LogicUSBFifoDataOut_D    : std_logic_vector(USB_FIFO_WIDTH - 1 downto 0);

	signal ConfigModuleAddress_D : unsigned(6 downto 0);
	signal ConfigParamAddress_D  : unsigned(7 downto 0);
	signal ConfigParamInput_D    : std_logic_vector(31 downto 0);
	signal ConfigLatchInput_S    : std_logic;
	signal ConfigParamOutput_D   : std_logic_vector(31 downto 0);

	signal TestConfigParamOutput_D : std_logic_vector(31 downto 0);
	signal FX3ConfigParamOutput_D  : std_logic_vector(31 downto 0);

	signal TestConfig_D, TestConfigReg_D : tTestConfig;
	signal FX3Config_D, FX3ConfigReg_D   : tFX3Config;
begin
	USBFifoData_DO          <= (others => '1') when TestConfigReg_D.TestUSBOutputsHigh_S = '1' else USBFifoData_D;
	USBFifoChipSelect_SBO   <= '1' when TestConfigReg_D.TestUSBOutputsHigh_S = '1' else USBFifoChipSelect_SB;
	USBFifoWrite_SBO        <= '1' when TestConfigReg_D.TestUSBOutputsHigh_S = '1' else USBFifoWrite_SB;
	USBFifoRead_SBO         <= '1' when TestConfigReg_D.TestUSBOutputsHigh_S = '1' else USBFifoRead_SB;
	USBFifoPktEnd_SBO       <= '1' when TestConfigReg_D.TestUSBOutputsHigh_S = '1' else USBFifoPktEnd_SB;
	USBFifoAddress_DO       <= (others => '1') when TestConfigReg_D.TestUSBOutputsHigh_S = '1' else USBFifoAddress_D;
	USBFifoThr0Ready_SI     <= '1' when TestConfigReg_D.TestUSBOutputsHigh_S = '1' else 'Z';
	USBFifoThr0Watermark_SI <= '1' when TestConfigReg_D.TestUSBOutputsHigh_S = '1' else 'Z';
	USBFifoThr1Ready_SI     <= '1' when TestConfigReg_D.TestUSBOutputsHigh_S = '1' else 'Z';
	USBFifoThr1Watermark_SI <= '1' when TestConfigReg_D.TestUSBOutputsHigh_S = '1' else 'Z';

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
			RTCMISO_DI             => RTCMISO_AI,
			RTCMISOSync_DO         => RTCMISOSync_D,
			RTCInterrupt_SI        => RTCInterrupt_AI,
			RTCInterruptSync_SO    => RTCInterruptSync_S);

	-- Third: set all constant outputs.
	USBFifoChipSelect_SB <= '0';        -- Always keep USB chip selected (active-low).
	USBFifoRead_SB       <= '1';        -- We never read from the USB data path (active-low).
	USBFifoData_D        <= LogicUSBFifoDataOut_D;

	-- Wire all LEDs.
	led1Buffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => TestConfigReg_D.TestUSBFifo_S,
			Output_SO(0) => LED1_SO);

	led2Buffer : entity work.SimpleRegister
		port map(
			Clock_CI     => USBClock_CI,
			Reset_RI     => USBReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => not SPISlaveSelectSync_SB,
			Output_SO(0) => LED2_SO);

	led3Buffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => SyncOutSwitch_AI,
			Output_SO(0) => LED3_SO);

	led4Buffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => SyncInSwitch_AI,
			Output_SO(0) => LED4_SO);

	led5Buffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => SyncInClock_AI,
			Output_SO(0) => LED5_SO);

	led6Buffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => SyncInSignal_AI,
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
			USBFifoWrite_SBO            => USBFifoWrite_SB,
			USBFifoPktEnd_SBO           => USBFifoPktEnd_SB,
			USBFifoAddress_DO           => USBFifoAddress_D,
			InFifoControl_SI            => LogicUSBFifoControlOut_S.ReadSide,
			InFifoControl_SO            => LogicUSBFifoControlIn_S.ReadSide,
			FX3Config_DI                => FX3ConfigReg_D);

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
	logicUSBFifo : entity work.FIFODualClockDouble
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

	-- Generate a continuous N-bit number for testing the data stream from FPGA to USB.
	numberGenerator : entity work.ContinuousCounter
		generic map(
			SIZE              => NUMBER_GENERATOR_WIDTH,
			RESET_ON_OVERFLOW => true,
			GENERATE_OVERFLOW => false)
		port map(
			Clock_CI                  => LogicClock_C,
			Reset_RI                  => LogicReset_R,
			Clear_SI                  => '0',
			Enable_SI                 => TestConfigReg_D.TestUSBFifo_S and not LogicUSBFifoControlOut_S.WriteSide.Full_S,
			DataLimit_DI              => (others => '1'),
			Overflow_SO               => open,
			std_logic_vector(Data_DO) => LogicUSBFifoDataIn_D);

	LogicUSBFifoControlIn_S.WriteSide.Write_S <= TestConfigReg_D.TestUSBFifo_S and not LogicUSBFifoControlOut_S.WriteSide.Full_S;

	-- Generate 1MHz clock on bank 0 to see that all pins get a signal.
	bank0Generator : entity work.PulseGenerator
		generic map(
			SIZE => 8)
		port map(
			Clock_CI         => LogicClock_C,
			Reset_RI         => LogicReset_R,
			PulsePolarity_SI => '1',
			PulseInterval_DI => to_unsigned(LOGIC_CLOCK_FREQ, 8),
			PulseLength_DI   => to_unsigned(LOGIC_CLOCK_FREQ / 2, 8),
			Zero_SI          => not TestConfigReg_D.TestBank0_S,
			PulseOut_SO      => Bank0Pulse_S);

	Bank0_DO     <= (others => Bank0Pulse_S);
	Bank0VRef_DO <= (others => Bank0Pulse_S);

	-- Generate 2MHz clock on bank 1 to see that all pins get a signal.
	bank1Generator : entity work.PulseGenerator
		generic map(
			SIZE => 8)
		port map(
			Clock_CI         => LogicClock_C,
			Reset_RI         => LogicReset_R,
			PulsePolarity_SI => '1',
			PulseInterval_DI => to_unsigned(LOGIC_CLOCK_FREQ / 2, 8),
			PulseLength_DI   => to_unsigned(LOGIC_CLOCK_FREQ / 4, 8),
			Zero_SI          => not TestConfigReg_D.TestBank1_S,
			PulseOut_SO      => Bank1Pulse_S);

	Bank1_DO     <= (others => Bank1Pulse_S);
	Bank1VRef_DO <= (others => Bank1Pulse_S);

	-- Generate 4MHz clock on bank 2 to see that all pins get a signal.
	bank2Generator : entity work.PulseGenerator
		generic map(
			SIZE => 8)
		port map(
			Clock_CI         => LogicClock_C,
			Reset_RI         => LogicReset_R,
			PulsePolarity_SI => '1',
			PulseInterval_DI => to_unsigned(LOGIC_CLOCK_FREQ / 4, 8),
			PulseLength_DI   => to_unsigned(LOGIC_CLOCK_FREQ / 8, 8),
			Zero_SI          => not TestConfigReg_D.TestBank2_S,
			PulseOut_SO      => Bank2Pulse_S);

	Bank2_DO     <= (others => Bank2Pulse_S);
	Bank2VRef_DO <= (others => Bank2Pulse_S);

	-- Generate 8MHz clock on bank 7 to see that all pins get a signal.
	bank7Generator : entity work.PulseGenerator
		generic map(
			SIZE => 8)
		port map(
			Clock_CI         => LogicClock_C,
			Reset_RI         => LogicReset_R,
			PulsePolarity_SI => '1',
			PulseInterval_DI => to_unsigned(LOGIC_CLOCK_FREQ / 8, 8),
			PulseLength_DI   => to_unsigned(LOGIC_CLOCK_FREQ / 16, 8),
			Zero_SI          => not TestConfigReg_D.TestBank7_S,
			PulseOut_SO      => Bank7Pulse_S);

	Bank7_DO     <= (others => Bank7Pulse_S);
	Bank7VRef_DO <= (others => Bank7Pulse_S);

	-- Auxiliary Clock test: if the external, auxiliary 100MHz clock is
	-- enabled, it is directly forwarded to all clock outputs. This tests
	-- both the clock input and outputs, and the oscillator itself.
	Bank0ClockPos_CO <= AuxClockPos_CI;
	Bank0ClockNeg_CO <= AuxClockNeg_CI;

	Bank2ClockPos_CO <= AuxClockPos_CI;
	Bank2ClockNeg_CO <= AuxClockNeg_CI;

	Bank7ClockPos_CO <= AuxClockPos_CI;
	Bank7ClockNeg_CO <= AuxClockNeg_CI;

	AuxClockOutputEnable_SO <= TestConfigReg_D.TestAuxClock_S;

	-- SERDES Clock test: enable or disable 150MHz SERDES clock.
	SERDESClockOutputEnable_SO <= TestConfigReg_D.TestSERDESClock_S;

	-- TODO: SERDES testing (SATA link data exchange).
	-- Use Lattice PCS block (IPExpress tool).

	-- TODO: RTC testing (SPI data exchange, interrupt).
	RTCSlaveSelect_SBO <= '1';
	RTCClock_CO        <= '1';
	RTCMOSI_DO         <= '1';
	-- RTCMISOSync_D
	-- RTCInterruptSync_S

	-- TODO: SD-Card testing (SPI-like data exchange).
	SDCardClock_CO   <= '1';
	SDCardCommand_SO <= '1';
	SDCardData_DO    <= (others => '1');

	-- Test sync connectors, put inputs to LEDs (above) and output a 10KHz clock.
	syncOutGenerator : entity work.PulseGenerator
		generic map(
			SIZE => 16)
		port map(
			Clock_CI         => LogicClock_C,
			Reset_RI         => LogicReset_R,
			PulsePolarity_SI => '1',
			PulseInterval_DI => to_unsigned(LOGIC_CLOCK_FREQ * 100, 16),
			PulseLength_DI   => to_unsigned(LOGIC_CLOCK_FREQ * 50, 16),
			Zero_SI          => not TestConfigReg_D.TestSyncConnectors_S,
			PulseOut_SO      => SyncConnectorPulse_S);

	SyncOutClock_CO  <= SyncConnectorPulse_S;
	SyncOutSignal_SO <= SyncConnectorPulse_S;

	testSPIConfig : entity work.TestSPIConfig
		port map(
			Clock_CI                 => LogicClock_C,
			Reset_RI                 => LogicReset_R,
			TestConfig_DO            => TestConfig_D,
			ConfigModuleAddress_DI   => ConfigModuleAddress_D,
			ConfigParamAddress_DI    => ConfigParamAddress_D,
			ConfigParamInput_DI      => ConfigParamInput_D,
			ConfigLatchInput_SI      => ConfigLatchInput_S,
			TestConfigParamOutput_DO => TestConfigParamOutput_D);

	configRegisters : process(LogicClock_C, LogicReset_R) is
	begin
		if LogicReset_R = '1' then
			TestConfigReg_D <= tTestConfigDefault;
			FX3ConfigReg_D  <= tFX3ConfigDefault;
		elsif rising_edge(LogicClock_C) then
			TestConfigReg_D <= TestConfig_D;
			FX3ConfigReg_D  <= FX3Config_D;
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

	spiConfigurationOutputSelect : process(ConfigModuleAddress_D, TestConfigParamOutput_D, FX3ConfigParamOutput_D)
	begin
		-- Output side select.
		ConfigParamOutput_D <= (others => '0');

		case ConfigModuleAddress_D is
			when TESTCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= TestConfigParamOutput_D;

			when FX3CONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= FX3ConfigParamOutput_D;

			when others => null;
		end case;
	end process spiConfigurationOutputSelect;
end Structural;
