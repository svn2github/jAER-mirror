library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.all;
use work.FIFORecords.all;
use work.FX3ConfigRecords.all;

entity TopLevel is
	port(
		USBClock_CI             : in  std_logic;
		Reset_RI                : in  std_logic;

		SPISlaveSelect_ABI      : in  std_logic;
		SPIClock_AI             : in  std_logic;
		SPIMOSI_AI              : in  std_logic;
		SPIMISO_DZO             : out std_logic;

		USBFifoData_DO          : out std_logic_vector(USB_FIFO_WIDTH - 1 downto 0);
		USBFifoChipSelect_SBO   : out std_logic;
		USBFifoWrite_SBO        : out std_logic;
		USBFifoRead_SBO         : out std_logic;
		USBFifoPktEnd_SBO       : out std_logic;
		USBFifoAddress_DO       : out std_logic_vector(1 downto 0);
		USBFifoThr0Ready_SI     : in  std_logic;
		USBFifoThr0Watermark_SI : in  std_logic;
		USBFifoThr1Ready_SI     : in  std_logic;
		USBFifoThr1Watermark_SI : in  std_logic;

		LED1_SO                 : out std_logic;
		LED2_SO                 : out std_logic;
		LED3_SO                 : out std_logic;
		LED4_SO                 : out std_logic;
		LED5_SO                 : out std_logic;
		LED6_SO                 : out std_logic);
end TopLevel;

architecture Structural of TopLevel is
	signal USBReset_R   : std_logic;
	signal LogicClock_C : std_logic;
	signal LogicReset_R : std_logic;

	signal USBFifoThr0ReadySync_S, USBFifoThr0WatermarkSync_S, USBFifoThr1ReadySync_S, USBFifoThr1WatermarkSync_S : std_logic;
	signal SPISlaveSelectSync_SB, SPIClockSync_C, SPIMOSISync_D                                                   : std_logic;

	signal LogicUSBFifoControlIn_S  : tToFifo;
	signal LogicUSBFifoControlOut_S : tFromFifo;
	signal LogicUSBFifoDataIn_D     : std_logic_vector(USB_FIFO_WIDTH - 1 downto 0);
	signal LogicUSBFifoDataOut_D    : std_logic_vector(USB_FIFO_WIDTH - 1 downto 0);

	signal ConfigModuleAddress_D : unsigned(6 downto 0);
	signal ConfigParamAddress_D  : unsigned(7 downto 0);
	signal ConfigParamInput_D    : std_logic_vector(31 downto 0);
	signal ConfigLatchInput_S    : std_logic;
	signal ConfigParamOutput_D   : std_logic_vector(31 downto 0);

	signal RunStreamTester_S       : std_logic;
	signal EnableStreamTesterReg_S : std_logic;
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
			SPIMOSISync_DO         => SPIMOSISync_D);

	-- Third: set all constant outputs.
	USBFifoChipSelect_SBO <= '0';       -- Always keep USB chip selected (active-low).
	USBFifoRead_SBO       <= '1';       -- We never read from the USB data path (active-low).
	USBFifoData_DO        <= LogicUSBFifoDataOut_D;

	-- Wire all LEDs.
	led1Buffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => RunStreamTester_S,
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
			FX3Running_SO               => open,
			FX3Config_DI                => tFX3ConfigDefault);

	-- Instantiate one FIFO to hold all the events coming out of the mixer-producer state machine.
	logicUSBFifo : entity work.FIFODualClock
		generic map(
			DATA_WIDTH        => USB_FIFO_WIDTH,
			DATA_DEPTH        => USBLOGIC_FIFO_SIZE,
			EMPTY_FLAG        => 0,
			ALMOST_EMPTY_FLAG => USBLOGIC_FIFO_ALMOST_EMPTY_SIZE,
			FULL_FLAG         => USBLOGIC_FIFO_SIZE,
			ALMOST_FULL_FLAG  => USBLOGIC_FIFO_SIZE - USBLOGIC_FIFO_ALMOST_FULL_SIZE)
		port map(
			Reset_RI       => LogicReset_R,
			WrClock_CI     => LogicClock_C,
			RdClock_CI     => USBClock_CI,
			FifoControl_SI => LogicUSBFifoControlIn_S,
			FifoControl_SO => LogicUSBFifoControlOut_S,
			FifoData_DI    => LogicUSBFifoDataIn_D,
			FifoData_DO    => LogicUSBFifoDataOut_D);

	-- Generate a continuous 16bit number for testing the data stream from FPGA to USB.
	numberGenerator : entity work.ContinuousCounter
		generic map(
			SIZE              => 16,
			RESET_ON_OVERFLOW => true,
			GENERATE_OVERFLOW => false)
		port map(
			Clock_CI                  => LogicClock_C,
			Reset_RI                  => LogicReset_R,
			Clear_SI                  => '0',
			Enable_SI                 => RunStreamTester_S and not LogicUSBFifoControlOut_S.WriteSide.Full_S,
			DataLimit_DI              => (others => '1'),
			Overflow_SO               => open,
			std_logic_vector(Data_DO) => LogicUSBFifoDataIn_D);

	LogicUSBFifoControlIn_S.WriteSide.Write_S <= RunStreamTester_S and not LogicUSBFifoControlOut_S.WriteSide.Full_S;

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

	-- Module 0, Parameter 0, Bit 0 tells us if we should run the data stream testing.
	spiConfigurationOutputSelect : process(ConfigModuleAddress_D, ConfigParamAddress_D, RunStreamTester_S)
	begin
		-- Output side select.
		ConfigParamOutput_D <= (others => '0');

		if ConfigModuleAddress_D = 0 and ConfigParamAddress_D = 0 then
			ConfigParamOutput_D(0) <= RunStreamTester_S;
		end if;
	end process spiConfigurationOutputSelect;

	EnableStreamTesterReg_S <= '1' when (ConfigModuleAddress_D = 0 and ConfigParamAddress_D = 0 and ConfigLatchInput_S = '1') else '0';

	runStreamTesterReg : entity work.SimpleRegister
		generic map(
			SIZE => 1)
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => EnableStreamTesterReg_S,
			Input_SI(0)  => ConfigParamInput_D(0),
			Output_SO(0) => RunStreamTester_S);
end Structural;
