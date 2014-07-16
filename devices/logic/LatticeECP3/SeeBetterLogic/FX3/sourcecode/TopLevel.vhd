library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.Settings.all;
use work.FIFORecords.all;
use work.MultiplexerConfigRecords.all;
use work.DVSAERConfigRecords.all;

entity TopLevel is
	port (
		USBClock_CI : in std_logic;
		Reset_RI	: in std_logic;

		SPISlaveSelect_ABI : in	 std_logic;
		SPIClock_AI		   : in	 std_logic;
		SPIMOSI_AI		   : in	 std_logic;
		SPIMISO_ZO		   : out std_logic;
		BiasDiagSelect_SI  : in	 std_logic;

		USBFifoData_DO			: out std_logic_vector(USB_FIFO_WIDTH-1 downto 0);
		USBFifoChipSelect_SBO	: out std_logic;
		USBFifoWrite_SBO		: out std_logic;
		USBFifoRead_SBO			: out std_logic;
		USBFifoPktEnd_SBO		: out std_logic;
		USBFifoAddress_DO		: out std_logic_vector(1 downto 0);
		USBFifoThr0Ready_SI		: in  std_logic;
		USBFifoThr0Watermark_SI : in  std_logic;
		USBFifoThr1Ready_SI		: in  std_logic;
		USBFifoThr1Watermark_SI : in  std_logic;

		LED1_SO : out std_logic;
		LED2_SO : out std_logic;
		LED3_SO : out std_logic;
		LED4_SO : out std_logic;

		ChipBiasEnable_SO	  : out std_logic;
		ChipBiasDiagSelect_SO : out std_logic;
		--ChipBiasBitOut_DI : in std_logic;

		DVSAERData_AI	: in  std_logic_vector(AER_BUS_WIDTH-1 downto 0);
		DVSAERReq_ABI	: in  std_logic;
		DVSAERAck_SBO	: out std_logic;
		DVSAERReset_SBO : out std_logic;

		APSChipRowSRClock_SO : out std_logic;
		APSChipRowSRIn_SO	 : out std_logic;
		APSChipColSRClock_SO : out std_logic;
		APSChipColSRIn_SO	 : out std_logic;
		APSChipColMode_DO	 : out std_logic_vector(1 downto 0);
		APSChipTXGate_SO	 : out std_logic;

		APSADCData_DI		   : in	 std_logic_vector(ADC_BUS_WIDTH-1 downto 0);
		APSADCOverflow_SI	   : in	 std_logic;
		APSADCClock_CO		   : out std_logic;
		APSADCOutputEnable_SBO : out std_logic;
		APSADCStandby_SO	   : out std_logic;

		IMUClock_ZO		: inout std_logic;	-- this is inout because it must be tristateable
		IMUData_ZIO		: inout std_logic;
		IMUInterrupt_AI : in	std_logic;

		SyncOutClock_CO	 : out std_logic;
		SyncOutSwitch_AI : in  std_logic;
		SyncOutSignal_SO : out std_logic;
		SyncInClock_AI	 : in  std_logic;
		SyncInSwitch_AI	 : in  std_logic;
		SyncInSignal_AI	 : in  std_logic);
end TopLevel;

architecture Structural of TopLevel is
	component USBClockSynchronizer is
		port (
			USBClock_CI					: in  std_logic;
			Reset_RI					: in  std_logic;
			ResetSync_RO				: out std_logic;
			USBFifoThr0Ready_SI			: in  std_logic;
			USBFifoThr0ReadySync_SO		: out std_logic;
			USBFifoThr0Watermark_SI		: in  std_logic;
			USBFifoThr0WatermarkSync_SO : out std_logic;
			USBFifoThr1Ready_SI			: in  std_logic;
			USBFifoThr1ReadySync_SO		: out std_logic;
			USBFifoThr1Watermark_SI		: in  std_logic;
			USBFifoThr1WatermarkSync_SO : out std_logic);
	end component USBClockSynchronizer;

	component LogicClockSynchronizer is
		port (
			LogicClock_CI		   : in	 std_logic;
			Reset_RI			   : in	 std_logic;
			ResetSync_RO		   : out std_logic;
			SPISlaveSelect_SBI	   : in	 std_logic;
			SPISlaveSelectSync_SBO : out std_logic;
			SPIClock_CI			   : in	 std_logic;
			SPIClockSync_CO		   : out std_logic;
			SPIMOSI_DI			   : in	 std_logic;
			SPIMOSISync_DO		   : out std_logic;
			DVSAERReq_SBI		   : in	 std_logic;
			DVSAERReqSync_SBO	   : out std_logic;
			IMUInterrupt_SI		   : in	 std_logic;
			IMUInterruptSync_SO	   : out std_logic;
			SyncOutSwitch_SI	   : in	 std_logic;
			SyncOutSwitchSync_SO   : out std_logic;
			SyncInClock_CI		   : in	 std_logic;
			SyncInClockSync_CO	   : out std_logic;
			SyncInSwitch_SI		   : in	 std_logic;
			SyncInSwitchSync_SO	   : out std_logic;
			SyncInSignal_SI		   : in	 std_logic;
			SyncInSignalSync_SO	   : out std_logic);
	end component LogicClockSynchronizer;

	component FX3Statemachine is
		port (
			Clock_CI					: in  std_logic;
			Reset_RI					: in  std_logic;
			USBFifoThread0Full_SI		: in  std_logic;
			USBFifoThread0AlmostFull_SI : in  std_logic;
			USBFifoThread1Full_SI		: in  std_logic;
			USBFifoThread1AlmostFull_SI : in  std_logic;
			USBFifoWrite_SBO			: out std_logic;
			USBFifoPktEnd_SBO			: out std_logic;
			USBFifoAddress_DO			: out std_logic_vector(1 downto 0);
			InFifoControl_SI			: in  tFromFifoReadSide;
			InFifoControl_SO			: out tToFifoReadSide);
	end component FX3Statemachine;

	component MultiplexerStateMachine is
		port (
			Clock_CI				 : in  std_logic;
			Reset_RI				 : in  std_logic;
			OutFifoControl_SI		 : in  tFromFifoWriteSide;
			OutFifoControl_SO		 : out tToFifoWriteSide;
			OutFifoData_DO			 : out std_logic_vector(USB_FIFO_WIDTH-1 downto 0);
			DVSAERFifoControl_SI	 : in  tFromFifoReadSide;
			DVSAERFifoControl_SO	 : out tToFifoReadSide;
			DVSAERFifoData_DI		 : in  std_logic_vector(EVENT_WIDTH-1 downto 0);
			APSADCFifoControl_SI	 : in  tFromFifoReadSide;
			APSADCFifoControl_SO	 : out tToFifoReadSide;
			APSADCFifoData_DI		 : in  std_logic_vector(EVENT_WIDTH-1 downto 0);
			IMUFifoControl_SI		 : in  tFromFifoReadSide;
			IMUFifoControl_SO		 : out tToFifoReadSide;
			IMUFifoData_DI			 : in  std_logic_vector(EVENT_WIDTH-1 downto 0);
			ExtTriggerFifoControl_SI : in  tFromFifoReadSide;
			ExtTriggerFifoControl_SO : out tToFifoReadSide;
			ExtTriggerFifoData_DI	 : in  std_logic_vector(EVENT_WIDTH-1 downto 0);
			MultiplexerConfig_DI	 : in  tMultiplexerConfig);
	end component MultiplexerStateMachine;

	component DVSAERStateMachine is
		port (
			Clock_CI		  : in	std_logic;
			Reset_RI		  : in	std_logic;
			OutFifoControl_SI : in	tFromFifoWriteSide;
			OutFifoControl_SO : out tToFifoWriteSide;
			OutFifoData_DO	  : out std_logic_vector(EVENT_WIDTH-1 downto 0);
			DVSAERData_DI	  : in	std_logic_vector(AER_BUS_WIDTH-1 downto 0);
			DVSAERReq_SBI	  : in	std_logic;
			DVSAERAck_SBO	  : out std_logic;
			DVSAERReset_SBO	  : out std_logic;
			DVSAERConfig_DI	  : in	tDVSAERConfig);
	end component DVSAERStateMachine;

	component IMUStateMachine is
		port (
			Clock_CI		  : in	  std_logic;
			Reset_RI		  : in	  std_logic;
			OutFifoControl_SI : in	  tFromFifoWriteSide;
			OutFifoControl_SO : out	  tToFifoWriteSide;
			OutFifoData_DO	  : out	  std_logic_vector(EVENT_WIDTH-1 downto 0);
			IMUClock_ZO		  : inout std_logic;
			IMUData_ZIO		  : inout std_logic;
			IMUInterrupt_SI	  : in	  std_logic);
	end component IMUStateMachine;

	component APSADCStateMachine is
		port (
			Clock_CI			   : in	 std_logic;
			Reset_RI			   : in	 std_logic;
			OutFifoControl_SI	   : in	 tFromFifoWriteSide;
			OutFifoControl_SO	   : out tToFifoWriteSide;
			OutFifoData_DO		   : out std_logic_vector(EVENT_WIDTH-1 downto 0);
			APSChipRowSRClock_SO   : out std_logic;
			APSChipRowSRIn_SO	   : out std_logic;
			APSChipColSRClock_SO   : out std_logic;
			APSChipColSRIn_SO	   : out std_logic;
			APSChipColMode_DO	   : out std_logic_vector(1 downto 0);
			APSChipTXGate_SO	   : out std_logic;
			APSADCData_DI		   : in	 std_logic_vector(ADC_BUS_WIDTH-1 downto 0);
			APSADCOverflow_SI	   : in	 std_logic;
			APSADCClock_CO		   : out std_logic;
			APSADCOutputEnable_SBO : out std_logic;
			APSADCStandby_SO	   : out std_logic);
	end component APSADCStateMachine;

	component ExtTriggerStateMachine is
		port (
			Clock_CI			: in  std_logic;
			Reset_RI			: in  std_logic;
			OutFifoControl_SI	: in  tFromFifoWriteSide;
			OutFifoControl_SO	: out tToFifoWriteSide;
			OutFifoData_DO		: out std_logic_vector(EVENT_WIDTH-1 downto 0);
			ExtTriggerSwitch_SI : in  std_logic;
			ExtTriggerSignal_SI : in  std_logic);
	end component ExtTriggerStateMachine;

	component SPIConfig is
		port (
			Clock_CI			 : in  std_logic;
			Reset_RI			 : in  std_logic;
			SPISlaveSelect_SBI	 : in  std_logic;
			SPIClock_CI			 : in  std_logic;
			SPIMOSI_DI			 : in  std_logic;
			SPIMISO_ZO			 : out std_logic;
			MultiplexerConfig_DO : out tMultiplexerConfig;
			DVSAERConfig_DO		 : out tDVSAERConfig);
	end component SPIConfig;

	component SimpleRegister is
		generic (
			RESET_VALUE : std_logic := '0');
		port (
			Clock_CI  : in	std_logic;
			Reset_RI  : in	std_logic;
			Enable_SI : in	std_logic;
			Input_SI  : in	std_logic;
			Output_SO : out std_logic);
	end component SimpleRegister;

	component FIFODualClock is
		generic (
			DATA_WIDTH		  : integer;
			DATA_DEPTH		  : integer;
			EMPTY_FLAG		  : integer;
			ALMOST_EMPTY_FLAG : integer;
			FULL_FLAG		  : integer;
			ALMOST_FULL_FLAG  : integer);
		port (
			Reset_RI	   : in	 std_logic;
			WrClock_CI	   : in	 std_logic;
			RdClock_CI	   : in	 std_logic;
			FifoControl_SI : in	 tToFifo;
			FifoControl_SO : out tFromFifo;
			FifoData_DI	   : in	 std_logic_vector(DATA_WIDTH-1 downto 0);
			FifoData_DO	   : out std_logic_vector(DATA_WIDTH-1 downto 0));
	end component FIFODualClock;

	component FIFO is
		generic (
			DATA_WIDTH		  : integer;
			DATA_DEPTH		  : integer;
			EMPTY_FLAG		  : integer;
			ALMOST_EMPTY_FLAG : integer;
			FULL_FLAG		  : integer;
			ALMOST_FULL_FLAG  : integer);
		port (
			Clock_CI	   : in	 std_logic;
			Reset_RI	   : in	 std_logic;
			FifoControl_SI : in	 tToFifo;
			FifoControl_SO : out tFromFifo;
			FifoData_DI	   : in	 std_logic_vector(DATA_WIDTH-1 downto 0);
			FifoData_DO	   : out std_logic_vector(DATA_WIDTH-1 downto 0));
	end component FIFO;

	component PLL is
		generic (
			CLOCK_FREQ	   : integer;
			OUT_CLOCK_FREQ : integer);
		port (
			Clock_CI	: in  std_logic;
			Reset_RI	: in  std_logic;
			OutClock_CO : out std_logic);
	end component PLL;

	signal USBReset_R	: std_logic;
	signal LogicClock_C : std_logic;
	signal LogicReset_R : std_logic;

	signal USBFifoThr0ReadySync_S, USBFifoThr0WatermarkSync_S, USBFifoThr1ReadySync_S, USBFifoThr1WatermarkSync_S : std_logic;
	signal DVSAERReqSync_SB, IMUInterruptSync_S																	  : std_logic;
	signal SyncOutSwitchSync_S, SyncInClockSync_C, SyncInSwitchSync_S, SyncInSignalSync_S						  : std_logic;
	signal SPISlaveSelectSync_SB, SPIClockSync_C, SPIMOSISync_D													  : std_logic;

	signal LogicUSBFifoControlIn_S	: tToFifo;
	signal LogicUSBFifoControlOut_S : tFromFifo;
	signal LogicUSBFifoDataIn_D		: std_logic_vector(USB_FIFO_WIDTH-1 downto 0);
	signal LogicUSBFifoDataOut_D	: std_logic_vector(USB_FIFO_WIDTH-1 downto 0);

	signal DVSAERFifoControlIn_S  : tToFifo;
	signal DVSAERFifoControlOut_S : tFromFifo;
	signal DVSAERFifoDataIn_D	  : std_logic_vector(EVENT_WIDTH-1 downto 0);
	signal DVSAERFifoDataOut_D	  : std_logic_vector(EVENT_WIDTH-1 downto 0);

	signal APSADCFifoControlIn_S  : tToFifo;
	signal APSADCFifoControlOut_S : tFromFifo;
	signal APSADCFifoDataIn_D	  : std_logic_vector(EVENT_WIDTH-1 downto 0);
	signal APSADCFifoDataOut_D	  : std_logic_vector(EVENT_WIDTH-1 downto 0);

	signal IMUFifoControlIn_S  : tToFifo;
	signal IMUFifoControlOut_S : tFromFifo;
	signal IMUFifoDataIn_D	   : std_logic_vector(EVENT_WIDTH-1 downto 0);
	signal IMUFifoDataOut_D	   : std_logic_vector(EVENT_WIDTH-1 downto 0);

	signal ExtTriggerFifoControlIn_S  : tToFifo;
	signal ExtTriggerFifoControlOut_S : tFromFifo;
	signal ExtTriggerFifoDataIn_D	  : std_logic_vector(EVENT_WIDTH-1 downto 0);
	signal ExtTriggerFifoDataOut_D	  : std_logic_vector(EVENT_WIDTH-1 downto 0);

	signal MultiplexerConfig_D : tMultiplexerConfig;
	signal DVSAERConfig_D	   : tDVSAERConfig;
begin
	-- First: synchronize all USB-related inputs to the USB clock.
	syncInputsToUSBClock : USBClockSynchronizer
		port map (
			USBClock_CI					=> USBClock_CI,
			Reset_RI					=> Reset_RI,
			ResetSync_RO				=> USBReset_R,
			USBFifoThr0Ready_SI			=> USBFifoThr0Ready_SI,
			USBFifoThr0ReadySync_SO		=> USBFifoThr0ReadySync_S,
			USBFifoThr0Watermark_SI		=> USBFifoThr0Watermark_SI,
			USBFifoThr0WatermarkSync_SO => USBFifoThr0WatermarkSync_S,
			USBFifoThr1Ready_SI			=> USBFifoThr1Ready_SI,
			USBFifoThr1ReadySync_SO		=> USBFifoThr1ReadySync_S,
			USBFifoThr1Watermark_SI		=> USBFifoThr1Watermark_SI,
			USBFifoThr1WatermarkSync_SO => USBFifoThr1WatermarkSync_S);

	-- Second: synchronize all logic-related inputs to the logic clock.
	syncInputsToLogicClock : LogicClockSynchronizer
		port map (
			LogicClock_CI		   => LogicClock_C,
			Reset_RI			   => Reset_RI,
			ResetSync_RO		   => LogicReset_R,
			SPISlaveSelect_SBI	   => SPISlaveSelect_ABI,
			SPISlaveSelectSync_SBO => SPISlaveSelectSync_SB,
			SPIClock_CI			   => SPIClock_AI,
			SPIClockSync_CO		   => SPIClockSync_C,
			SPIMOSI_DI			   => SPIMOSI_AI,
			SPIMOSISync_DO		   => SPIMOSISync_D,
			DVSAERReq_SBI		   => DVSAERReq_ABI,
			DVSAERReqSync_SBO	   => DVSAERReqSync_SB,
			IMUInterrupt_SI		   => IMUInterrupt_AI,
			IMUInterruptSync_SO	   => IMUInterruptSync_S,
			SyncOutSwitch_SI	   => SyncOutSwitch_AI,
			SyncOutSwitchSync_SO   => SyncOutSwitchSync_S,
			SyncInClock_CI		   => SyncInClock_AI,
			SyncInClockSync_CO	   => SyncInClockSync_C,
			SyncInSwitch_SI		   => SyncInSwitch_AI,
			SyncInSwitchSync_SO	   => SyncInSwitchSync_S,
			SyncInSignal_SI		   => SyncInSignal_AI,
			SyncInSignalSync_SO	   => SyncInSignalSync_S);

	-- Third: set all constant outputs.
	USBFifoChipSelect_SBO <= '0';  -- Always keep USB chip selected (active-low).
	USBFifoRead_SBO		  <= '1';  -- We never read from the USB data path (active-low).
	USBFifoData_DO		  <= LogicUSBFifoDataOut_D;
	ChipBiasEnable_SO	  <= DVSAERConfig_D.Run_S;	-- Always enable if chip is
													-- needed (DVS or APS).
	ChipBiasDiagSelect_SO <= BiasDiagSelect_SI;		-- Direct bypass.

	-- Wire all LEDs.
	led1Buffer : SimpleRegister
		port map (
			Clock_CI  => LogicClock_C,
			Reset_RI  => LogicReset_R,
			Enable_SI => '1',
			Input_SI  => MultiplexerConfig_D.Run_S,
			Output_SO => LED1_SO);

	led2Buffer : SimpleRegister
		port map (
			Clock_CI  => USBClock_CI,
			Reset_RI  => USBReset_R,
			Enable_SI => '1',
			Input_SI  => LogicUSBFifoControlOut_S.ReadSide.Empty_S,
			Output_SO => LED2_SO);

	led3Buffer : SimpleRegister
		port map (
			Clock_CI  => LogicClock_C,
			Reset_RI  => LogicReset_R,
			Enable_SI => '1',
			Input_SI  => not SPISlaveSelectSync_SB,
			Output_SO => LED3_SO);

	led4Buffer : SimpleRegister
		port map (
			Clock_CI  => LogicClock_C,
			Reset_RI  => LogicReset_R,
			Enable_SI => '1',
			Input_SI  => LogicUSBFifoControlOut_S.WriteSide.Full_S,
			Output_SO => LED4_SO);

	-- Generate logic clock using a PLL.
	logicClockPLL : PLL
		generic map (
			CLOCK_FREQ	   => USB_CLOCK_FREQ,
			OUT_CLOCK_FREQ => LOGIC_CLOCK_FREQ)
		port map (
			Clock_CI	=> USBClock_CI,
			Reset_RI	=> USBReset_R,
			OutClock_CO => LogicClock_C);

	usbFX3SM : FX3Statemachine
		port map (
			Clock_CI					=> USBClock_CI,
			Reset_RI					=> USBReset_R,
			USBFifoThread0Full_SI		=> USBFifoThr0ReadySync_S,
			USBFifoThread0AlmostFull_SI => USBFifoThr0WatermarkSync_S,
			USBFifoThread1Full_SI		=> USBFifoThr1ReadySync_S,
			USBFifoThread1AlmostFull_SI => USBFifoThr1WatermarkSync_S,
			USBFifoWrite_SBO			=> USBFifoWrite_SBO,
			USBFifoPktEnd_SBO			=> USBFifoPktEnd_SBO,
			USBFifoAddress_DO			=> USBFifoAddress_DO,
			InFifoControl_SI			=> LogicUSBFifoControlOut_S.ReadSide,
			InFifoControl_SO			=> LogicUSBFifoControlIn_S.ReadSide);

	-- Instantiate one FIFO to hold all the events coming out of the mixer-producer state machine.
	logicUSBFifo : FIFODualClock
		generic map (
			DATA_WIDTH		  => USB_FIFO_WIDTH,
			DATA_DEPTH		  => USBLOGIC_FIFO_SIZE,
			EMPTY_FLAG		  => 0,
			ALMOST_EMPTY_FLAG => USBLOGIC_FIFO_ALMOST_EMPTY_SIZE,
			FULL_FLAG		  => USBLOGIC_FIFO_SIZE,
			ALMOST_FULL_FLAG  => USBLOGIC_FIFO_SIZE - USBLOGIC_FIFO_ALMOST_FULL_SIZE)
		port map (
			Reset_RI	   => LogicReset_R,
			WrClock_CI	   => LogicClock_C,
			RdClock_CI	   => USBClock_CI,
			FifoControl_SI => LogicUSBFifoControlIn_S,
			FifoControl_SO => LogicUSBFifoControlOut_S,
			FifoData_DI	   => LogicUSBFifoDataIn_D,
			FifoData_DO	   => LogicUSBFifoDataOut_D);

	multiplexerSM : MultiplexerStateMachine
		port map (
			Clock_CI				 => LogicClock_C,
			Reset_RI				 => LogicReset_R,
			OutFifoControl_SI		 => LogicUSBFifoControlOut_S.WriteSide,
			OutFifoControl_SO		 => LogicUSBFifoControlIn_S.WriteSide,
			OutFifoData_DO			 => LogicUSBFifoDataIn_D,
			DVSAERFifoControl_SI	 => DVSAERFifoControlOut_S.ReadSide,
			DVSAERFifoControl_SO	 => DVSAERFifoControlIn_S.ReadSide,
			DVSAERFifoData_DI		 => DVSAERFifoDataOut_D,
			APSADCFifoControl_SI	 => APSADCFifoControlOut_S.ReadSide,
			APSADCFifoControl_SO	 => APSADCFifoControlIn_S.ReadSide,
			APSADCFifoData_DI		 => APSADCFifoDataOut_D,
			IMUFifoControl_SI		 => IMUFifoControlOut_S.ReadSide,
			IMUFifoControl_SO		 => IMUFifoControlIn_S.ReadSide,
			IMUFifoData_DI			 => IMUFifoDataOut_D,
			ExtTriggerFifoControl_SI => ExtTriggerFifoControlOut_S.ReadSide,
			ExtTriggerFifoControl_SO => ExtTriggerFifoControlIn_S.ReadSide,
			ExtTriggerFifoData_DI	 => ExtTriggerFifoDataOut_D,
			MultiplexerConfig_DI	 => MultiplexerConfig_D);

	dvsAerFifo : FIFO
		generic map (
			DATA_WIDTH		  => EVENT_WIDTH,
			DATA_DEPTH		  => DVSAER_FIFO_SIZE,
			EMPTY_FLAG		  => 0,
			ALMOST_EMPTY_FLAG => DVSAER_FIFO_ALMOST_EMPTY_SIZE,
			FULL_FLAG		  => DVSAER_FIFO_SIZE,
			ALMOST_FULL_FLAG  => DVSAER_FIFO_SIZE - DVSAER_FIFO_ALMOST_FULL_SIZE)
		port map (
			Clock_CI	   => LogicClock_C,
			Reset_RI	   => LogicReset_R,
			FifoControl_SI => DVSAERFifoControlIn_S,
			FifoControl_SO => DVSAERFifoControlOut_S,
			FifoData_DI	   => DVSAERFifoDataIn_D,
			FifoData_DO	   => DVSAERFifoDataOut_D);

	dvsAerSM : DVSAERStateMachine
		port map (
			Clock_CI		  => LogicClock_C,
			Reset_RI		  => LogicReset_R,
			OutFifoControl_SI => DVSAERFifoControlOut_S.WriteSide,
			OutFifoControl_SO => DVSAERFifoControlIn_S.WriteSide,
			OutFifoData_DO	  => DVSAERFifoDataIn_D,
			DVSAERData_DI	  => DVSAERData_AI,
			DVSAERReq_SBI	  => DVSAERReqSync_SB,
			DVSAERAck_SBO	  => DVSAERAck_SBO,
			DVSAERReset_SBO	  => DVSAERReset_SBO,
			DVSAERConfig_DI	  => DVSAERConfig_D);

	apsAdcFifo : FIFO
		generic map (
			DATA_WIDTH		  => EVENT_WIDTH,
			DATA_DEPTH		  => APSADC_FIFO_SIZE,
			EMPTY_FLAG		  => 0,
			ALMOST_EMPTY_FLAG => APSADC_FIFO_ALMOST_EMPTY_SIZE,
			FULL_FLAG		  => APSADC_FIFO_SIZE,
			ALMOST_FULL_FLAG  => APSADC_FIFO_SIZE - APSADC_FIFO_ALMOST_FULL_SIZE)
		port map (
			Clock_CI	   => LogicClock_C,
			Reset_RI	   => LogicReset_R,
			FifoControl_SI => APSADCFifoControlIn_S,
			FifoControl_SO => APSADCFifoControlOut_S,
			FifoData_DI	   => APSADCFifoDataIn_D,
			FifoData_DO	   => APSADCFifoDataOut_D);

	apsAdcSM : APSADCStateMachine
		port map (
			Clock_CI			   => LogicClock_C,
			Reset_RI			   => LogicReset_R,
			OutFifoControl_SI	   => APSADCFifoControlOut_S.WriteSide,
			OutFifoControl_SO	   => APSADCFifoControlIn_S.WriteSide,
			OutFifoData_DO		   => APSADCFifoDataIn_D,
			APSChipRowSRClock_SO   => APSChipRowSRClock_SO,
			APSChipRowSRIn_SO	   => APSChipRowSRIn_SO,
			APSChipColSRClock_SO   => APSChipColSRClock_SO,
			APSChipColSRIn_SO	   => APSChipColSRIn_SO,
			APSChipColMode_DO	   => APSChipColMode_DO,
			APSChipTXGate_SO	   => APSChipTXGate_SO,
			APSADCData_DI		   => APSADCData_DI,
			APSADCOverflow_SI	   => APSADCOverflow_SI,
			APSADCClock_CO		   => APSADCClock_CO,
			APSADCOutputEnable_SBO => APSADCOutputEnable_SBO,
			APSADCStandby_SO	   => APSADCStandby_SO);

	imuFifo : FIFO
		generic map (
			DATA_WIDTH		  => EVENT_WIDTH,
			DATA_DEPTH		  => IMU_FIFO_SIZE,
			EMPTY_FLAG		  => 0,
			ALMOST_EMPTY_FLAG => IMU_FIFO_ALMOST_EMPTY_SIZE,
			FULL_FLAG		  => IMU_FIFO_SIZE,
			ALMOST_FULL_FLAG  => IMU_FIFO_SIZE - IMU_FIFO_ALMOST_FULL_SIZE)
		port map (
			Clock_CI	   => LogicClock_C,
			Reset_RI	   => LogicReset_R,
			FifoControl_SI => IMUFifoControlIn_S,
			FifoControl_SO => IMUFifoControlOut_S,
			FifoData_DI	   => IMUFifoDataIn_D,
			FifoData_DO	   => IMUFifoDataOut_D);

	imuSM : IMUStateMachine
		port map (
			Clock_CI		  => LogicClock_C,
			Reset_RI		  => LogicReset_R,
			OutFifoControl_SI => IMUFifoControlOut_S.WriteSide,
			OutFifoControl_SO => IMUFifoControlIn_S.WriteSide,
			OutFifoData_DO	  => IMUFifoDataIn_D,
			IMUClock_ZO		  => IMUClock_ZO,
			IMUData_ZIO		  => IMUData_ZIO,
			IMUInterrupt_SI	  => IMUInterruptSync_S);

	extTriggerFifo : FIFO
		generic map (
			DATA_WIDTH		  => EVENT_WIDTH,
			DATA_DEPTH		  => EXT_TRIGGER_FIFO_SIZE,
			EMPTY_FLAG		  => 0,
			ALMOST_EMPTY_FLAG => EXT_TRIGGER_FIFO_ALMOST_EMPTY_SIZE,
			FULL_FLAG		  => EXT_TRIGGER_FIFO_SIZE,
			ALMOST_FULL_FLAG  => EXT_TRIGGER_FIFO_SIZE - EXT_TRIGGER_FIFO_ALMOST_FULL_SIZE)
		port map (
			Clock_CI	   => LogicClock_C,
			Reset_RI	   => LogicReset_R,
			FifoControl_SI => ExtTriggerFifoControlIn_S,
			FifoControl_SO => ExtTriggerFifoControlOut_S,
			FifoData_DI	   => ExtTriggerFifoDataIn_D,
			FifoData_DO	   => ExtTriggerFifoDataOut_D);

	extTriggerSM : ExtTriggerStateMachine
		port map (
			Clock_CI			=> LogicClock_C,
			Reset_RI			=> LogicReset_R,
			OutFifoControl_SI	=> ExtTriggerFifoControlOut_S.WriteSide,
			OutFifoControl_SO	=> ExtTriggerFifoControlIn_S.WriteSide,
			OutFifoData_DO		=> ExtTriggerFifoDataIn_D,
			ExtTriggerSwitch_SI => SyncInSwitchSync_S,
			ExtTriggerSignal_SI => SyncInSignalSync_S);

	spiConfiguration : SPIConfig
		port map (
			Clock_CI			 => LogicClock_C,
			Reset_RI			 => LogicReset_R,
			SPISlaveSelect_SBI	 => SPISlaveSelectSync_SB,
			SPIClock_CI			 => SPIClockSync_C,
			SPIMOSI_DI			 => SPIMOSISync_D,
			SPIMISO_ZO			 => SPIMISO_ZO,
			MultiplexerConfig_DO => MultiplexerConfig_D,
			DVSAERConfig_DO		 => DVSAERConfig_D);
end Structural;
