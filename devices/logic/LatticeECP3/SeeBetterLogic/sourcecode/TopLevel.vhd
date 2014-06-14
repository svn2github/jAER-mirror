library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.Settings.all;

entity TopLevel is
	port (
		USBClock_CI : in std_logic;
		Reset_RI	: in std_logic;

		FPGARun_AI			  : in std_logic;
		DVSRun_AI			  : in std_logic;
		ADCRun_AI			  : in std_logic;
		IMURun_AI			  : in std_logic;
		FPGAShiftRegClock_CI  : in std_logic;
		FPGAShiftRegLatch_SI  : in std_logic;
		FPGAShiftRegBitIn_DI  : in std_logic;
		FPGATimestampReset_AI : in std_logic;
		BiasEnable_SI		  : in std_logic;
		BiasDiagSelect_SI	  : in std_logic;

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

		DVSAERData_DI	: in  std_logic_vector(AER_BUS_WIDTH-1 downto 0);
		DVSAERReq_ABI	: in  std_logic;
		DVSAERAck_SBO	: out std_logic;
		DVSAERReset_SBO : out std_logic;

		APSChipRowSRClock_SO : out std_logic;
		APSChipRowSRIn_SO	 : out std_logic;
		APSChipColSRClock_SO : out std_logic;
		APSChipColSRIn_SO	 : out std_logic;
		APSChipColState0_SO	 : out std_logic;
		APSChipColState1_SO	 : out std_logic;
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
		SyncInClock_CI	 : in  std_logic;
		SyncInSwitch_AI	 : in  std_logic;
		SyncInSignal_SI	 : in  std_logic);
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
			LogicClock_CI			  : in	std_logic;
			Reset_RI				  : in	std_logic;
			ResetSync_RO			  : out std_logic;
			FPGARun_SI				  : in	std_logic;
			FPGARunSync_SO			  : out std_logic;
			DVSRun_SI				  : in	std_logic;
			DVSRunSync_SO			  : out std_logic;
			ADCRun_SI				  : in	std_logic;
			ADCRunSync_SO			  : out std_logic;
			IMURun_SI				  : in	std_logic;
			IMURunSync_SO			  : out std_logic;
			FPGATimestampReset_SI	  : in	std_logic;
			FPGATimestampResetSync_SO : out std_logic;
			DVSAERReq_SBI			  : in	std_logic;
			DVSAERReqSync_SBO		  : out std_logic;
			IMUInterrupt_SI			  : in	std_logic;
			IMUInterruptSync_SO		  : out std_logic);
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
			InFifoEmpty_SI				: in  std_logic;
			InFifoAlmostEmpty_SI		: in  std_logic;
			InFifoRead_SO				: out std_logic);
	end component FX3Statemachine;

	component MultiplexerStateMachine is
		port (
			Clock_CI				 : in  std_logic;
			Reset_RI				 : in  std_logic;
			FPGARun_SI				 : in  std_logic;
			FPGATimestampReset_SI	 : in  std_logic;
			OutFifoFull_SI			 : in  std_logic;
			OutFifoAlmostFull_SI	 : in  std_logic;
			OutFifoWrite_SO			 : out std_logic;
			OutFifoData_DO			 : out std_logic_vector(USB_FIFO_WIDTH-1 downto 0);
			DVSAERFifoEmpty_SI		 : in  std_logic;
			DVSAERFifoAlmostEmpty_SI : in  std_logic;
			DVSAERFifoRead_SO		 : out std_logic;
			DVSAERFifoData_DI		 : in  std_logic_vector(EVENT_WIDTH-1 downto 0));
	end component MultiplexerStateMachine;

	component DVSAERStateMachine is
		port (
			Clock_CI			 : in  std_logic;
			Reset_RI			 : in  std_logic;
			DVSRun_SI			 : in  std_logic;
			OutFifoFull_SI		 : in  std_logic;
			OutFifoAlmostFull_SI : in  std_logic;
			OutFifoWrite_SO		 : out std_logic;
			OutFifoData_DO		 : out std_logic_vector(EVENT_WIDTH-1 downto 0);
			DVSAERData_DI		 : in  std_logic_vector(AER_BUS_WIDTH-1 downto 0);
			DVSAERReq_SBI		 : in  std_logic;
			DVSAERAck_SBO		 : out std_logic;
			DVSAERReset_SBO		 : out std_logic);
	end component DVSAERStateMachine;

	component PulseDetector is
		generic (
			PULSE_MINIMAL_LENGTH_CYCLES : integer	:= 50;
			PULSE_POLARITY				: std_logic := '1');
		port (
			Clock_CI		 : in  std_logic;
			Reset_RI		 : in  std_logic;
			InputSignal_SI	 : in  std_logic;
			PulseDetected_SO : out std_logic);
	end component PulseDetector;

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
			DataIn_DI	   : in	 std_logic_vector(DATA_WIDTH-1 downto 0);
			WrClock_CI	   : in	 std_logic;
			WrEnable_SI	   : in	 std_logic;
			DataOut_DO	   : out std_logic_vector(DATA_WIDTH-1 downto 0);
			RdClock_CI	   : in	 std_logic;
			RdEnable_SI	   : in	 std_logic;
			Empty_SO	   : out std_logic;
			AlmostEmpty_SO : out std_logic;
			Full_SO		   : out std_logic;
			AlmostFull_SO  : out std_logic);
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
			DataIn_DI	   : in	 std_logic_vector(DATA_WIDTH-1 downto 0);
			WrEnable_SI	   : in	 std_logic;
			DataOut_DO	   : out std_logic_vector(DATA_WIDTH-1 downto 0);
			RdEnable_SI	   : in	 std_logic;
			Empty_SO	   : out std_logic;
			AlmostEmpty_SO : out std_logic;
			Full_SO		   : out std_logic;
			AlmostFull_SO  : out std_logic);
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

	signal FPGATimestampResetDetect_S : std_logic;

	signal USBFifoThr0ReadySync_S, USBFifoThr0WatermarkSync_S, USBFifoThr1ReadySync_S, USBFifoThr1WatermarkSync_S				   : std_logic;
	signal FPGARunSync_S, DVSRunSync_S, ADCRunSync_S, IMURunSync_S, FPGATimestampResetSync_S, DVSAERReqSync_SB, IMUInterruptSync_S : std_logic;

	signal DVSRun_S, ADCRun_S, IMURun_S					  : std_logic;
	signal DVSFifoReset_R, ADCFifoReset_R, IMUFifoReset_R : std_logic;

	signal USBFifoFPGAData_D																		: std_logic_vector(USB_FIFO_WIDTH-1 downto 0);
	signal USBFifoFPGAWrite_S, USBFifoFPGARead_S													: std_logic;
	signal USBFifoFPGAEmpty_S, USBFifoFPGAAlmostEmpty_S, USBFifoFPGAFull_S, USBFifoFPGAAlmostFull_S : std_logic;

	signal DVSAERFifoDataWrite_D, DVSAERFifoDataRead_D											: std_logic_vector(EVENT_WIDTH-1 downto 0);
	signal DVSAERFifoWrite_S, DVSAERFifoRead_S													: std_logic;
	signal DVSAERFifoEmpty_S, DVSAERFifoAlmostEmpty_S, DVSAERFifoFull_S, DVSAERFifoAlmostFull_S : std_logic;
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
			LogicClock_CI			  => LogicClock_C,
			Reset_RI				  => Reset_RI,
			ResetSync_RO			  => LogicReset_R,
			FPGARun_SI				  => FPGARun_AI,
			FPGARunSync_SO			  => FPGARunSync_S,
			DVSRun_SI				  => DVSRun_AI,
			DVSRunSync_SO			  => DVSRunSync_S,
			ADCRun_SI				  => ADCRun_AI,
			ADCRunSync_SO			  => ADCRunSync_S,
			IMURun_SI				  => IMURun_AI,
			IMURunSync_SO			  => IMURunSync_S,
			FPGATimestampReset_SI	  => FPGATimestampReset_AI,
			FPGATimestampResetSync_SO => FPGATimestampResetSync_S,
			DVSAERReq_SBI			  => DVSAERReq_ABI,
			DVSAERReqSync_SBO		  => DVSAERReqSync_SB,
			IMUInterrupt_SI			  => IMUInterrupt_AI,
			IMUInterruptSync_SO		  => IMUInterruptSync_S);

	-- Third: set all constant outputs.
	USBFifoChipSelect_SBO <= '0';  -- Always keep USB chip selected (active-low).
	USBFifoRead_SBO		  <= '1';  -- We never read from the USB data path (active-low).
	ChipBiasEnable_SO	  <= BiasEnable_SI;		 -- Direct bypass.
	ChipBiasDiagSelect_SO <= BiasDiagSelect_SI;	 -- Direct bypass.

	-- Wire all LEDs.
	LED1_SO <= USBFifoFPGAEmpty_S;
	LED2_SO <= USBFifoFPGAFull_S;
	LED3_SO <= USBFifoFPGAAlmostEmpty_S;
	LED4_SO <= USBFifoFPGAAlmostFull_S;

	-- Only run data producers if the whole FPGA also is running.
	DVSRun_S <= DVSRunSync_S and FPGARunSync_S;
	ADCRun_S <= ADCRunSync_S and FPGARunSync_S;
	IMURun_S <= IMURunSync_S and FPGARunSync_S;

	-- Keep data transmission FIFOs in reset if FPGA is not running, so
	-- that they will be empty when resuming operation (no stale data).
	DVSFifoReset_R <= LogicReset_R or (not FPGARunSync_S);
	ADCFifoReset_R <= LogicReset_R or (not FPGARunSync_S);
	IMUFifoReset_R <= LogicReset_R or (not FPGARunSync_S);

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
			InFifoEmpty_SI				=> USBFifoFPGAEmpty_S,
			InFifoAlmostEmpty_SI		=> USBFifoFPGAAlmostEmpty_S,
			InFifoRead_SO				=> USBFifoFPGARead_S);

	-- Instantiate one FIFO to hold all the events coming out of the mixer-producer state machine.
	usbFifoFPGA : FIFODualClock
		generic map (
			DATA_WIDTH		  => USB_FIFO_WIDTH,
			DATA_DEPTH		  => USBFPGA_FIFO_SIZE,
			EMPTY_FLAG		  => 0,
			ALMOST_EMPTY_FLAG => USBFPGA_FIFO_ALMOST_EMPTY_SIZE,
			FULL_FLAG		  => USBFPGA_FIFO_SIZE,
			ALMOST_FULL_FLAG  => USBFPGA_FIFO_SIZE - USBFPGA_FIFO_ALMOST_FULL_SIZE)
		port map (
			Reset_RI	   => LogicReset_R,
			DataIn_DI	   => USBFifoFPGAData_D,
			WrClock_CI	   => LogicClock_C,
			WrEnable_SI	   => USBFifoFPGAWrite_S,
			DataOut_DO	   => USBFifoData_DO,
			RdClock_CI	   => USBClock_CI,
			RdEnable_SI	   => USBFifoFPGARead_S,
			Empty_SO	   => USBFifoFPGAEmpty_S,
			AlmostEmpty_SO => USBFifoFPGAAlmostEmpty_S,
			Full_SO		   => USBFifoFPGAFull_S,
			AlmostFull_SO  => USBFifoFPGAAlmostFull_S);

	multiplexerSM : MultiplexerStateMachine
		port map (
			Clock_CI				 => LogicClock_C,
			Reset_RI				 => LogicReset_R,
			FPGARun_SI				 => FPGARunSync_S,
			FPGATimestampReset_SI	 => FPGATimestampResetDetect_S,
			OutFifoFull_SI			 => USBFifoFPGAFull_S,
			OutFifoAlmostFull_SI	 => USBFifoFPGAAlmostFull_S,
			OutFifoWrite_SO			 => USBFifoFPGAWrite_S,
			OutFifoData_DO			 => USBFifoFPGAData_D,
			DVSAERFifoEmpty_SI		 => DVSAERFifoEmpty_S,
			DVSAERFifoAlmostEmpty_SI => DVSAERFifoAlmostEmpty_S,
			DVSAERFifoRead_SO		 => DVSAERFifoRead_S,
			DVSAERFifoData_DI		 => DVSAERFifoDataRead_D);

	dvsaerFifo : FIFO
		generic map (
			DATA_WIDTH		  => EVENT_WIDTH,
			DATA_DEPTH		  => DVSAER_FIFO_SIZE,
			EMPTY_FLAG		  => 0,
			ALMOST_EMPTY_FLAG => DVSAER_FIFO_ALMOST_EMPTY_SIZE,
			FULL_FLAG		  => DVSAER_FIFO_SIZE,
			ALMOST_FULL_FLAG  => DVSAER_FIFO_SIZE - DVSAER_FIFO_ALMOST_FULL_SIZE)
		port map (
			Clock_CI	   => LogicClock_C,
			Reset_RI	   => DVSFifoReset_R,
			DataIn_DI	   => DVSAERFifoDataWrite_D,
			WrEnable_SI	   => DVSAERFifoWrite_S,
			DataOut_DO	   => DVSAERFifoDataRead_D,
			RdEnable_SI	   => DVSAERFifoRead_S,
			Empty_SO	   => DVSAERFifoEmpty_S,
			AlmostEmpty_SO => DVSAERFifoAlmostEmpty_S,
			Full_SO		   => DVSAERFifoFull_S,
			AlmostFull_SO  => DVSAERFifoAlmostFull_S);

	dvsaerSM : DVSAERStateMachine
		port map (
			Clock_CI			 => LogicClock_C,
			Reset_RI			 => LogicReset_R,
			DVSRun_SI			 => DVSRun_S,
			OutFifoFull_SI		 => DVSAERFifoFull_S,
			OutFifoAlmostFull_SI => DVSAERFifoAlmostFull_S,
			OutFifoWrite_SO		 => DVSAERFifoWrite_S,
			OutFifoData_DO		 => DVSAERFifoDataWrite_D,
			DVSAERData_DI		 => DVSAERData_DI,
			DVSAERReq_SBI		 => DVSAERReqSync_SB,
			DVSAERAck_SBO		 => DVSAERAck_SBO,
			DVSAERReset_SBO		 => DVSAERReset_SBO);

	-- Detect FPGATimestampReset_SI pulse from host and then generate just one
	-- quick reset pulse for FPGA consumption.
	timestampResetDetect : PulseDetector
		generic map (
			PULSE_MINIMAL_LENGTH_CYCLES => LOGIC_CLOCK_FREQ / 2)
		port map (
			Clock_CI		 => LogicClock_C,
			Reset_RI		 => LogicReset_R,
			InputSignal_SI	 => FPGATimestampResetSync_S,
			PulseDetected_SO => FPGATimestampResetDetect_S);
end Structural;
