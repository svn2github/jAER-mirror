library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.Settings.all;

entity TopLevel is
	port (
		USBClock_CI : in std_logic;
		Reset_RI	: in std_logic;

		FPGARun_SI			  : in std_logic;
		DVSRun_SI			  : in std_logic;
		ADCRun_SI			  : in std_logic;
		IMURun_SI			  : in std_logic;
		FPGAShiftRegClock_CI  : in std_logic;
		FPGAShiftRegLatch_SI  : in std_logic;
		FPGAShiftRegBitIn_DI  : in std_logic;
		FPGATimestampReset_SI : in std_logic;
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
		DVSAERReq_SBI	: in  std_logic;
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

		IMUClock_CO		: inout std_logic;	-- this is inout because it must be tristateable
		IMUData_DIO		: inout std_logic;
		IMUInterrupt_SI : in	std_logic;

		SyncOutClock_CO	 : out std_logic;
		SyncOutSwitch_SI : in  std_logic;
		SyncOutSignal_SO : out std_logic;
		SyncInClock_CI	 : in  std_logic;
		SyncInSwitch_SI	 : in  std_logic;
		SyncInSignal_SI	 : in  std_logic);
end TopLevel;

architecture Structural of TopLevel is
	component USBClockSynchronizer
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
	end component;

	component LogicClockSynchronizer
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
	end component;

	component FX3Statemachine
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
	end component;

	component MultiplexerStateMachine
		port (
			Clock_CI				 : in  std_logic;
			Reset_RI				 : in  std_logic;
			FPGARun_SI				 : in  std_logic;
			TimestampReset_SI		 : in  std_logic;
			TimestampOverflow_SI	 : in  std_logic;
			Timestamp_DI			 : in  std_logic_vector(TIMESTAMP_WIDTH-1 downto 0);
			OutFifoFull_SI			 : in  std_logic;
			OutFifoAlmostFull_SI	 : in  std_logic;
			OutFifoWrite_SO			 : out std_logic;
			OutFifoData_DO			 : out std_logic_vector(USB_FIFO_WIDTH-1 downto 0);
			DVSAERFifoEmpty_SI		 : in  std_logic;
			DVSAERFifoAlmostEmpty_SI : in  std_logic;
			DVSAERFifoRead_SO		 : out std_logic;
			DVSAERFifoData_DI		 : in  std_logic_vector(EVENT_WIDTH-1 downto 0));
	end component;

	component TimestampGenerator
		port (
			Clock_CI			  : in	std_logic;
			Reset_RI			  : in	std_logic;
			FPGARun_SI			  : in	std_logic;
			FPGATimestampReset_SI : in	std_logic;
			TimestampReset_SO	  : out std_logic;
			TimestampOverflow_SO  : out std_logic;
			Timestamp_DO		  : out std_logic_vector(TIMESTAMP_WIDTH-1 downto 0));
	end component;

	component DVSAERStateMachine
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
	end component;

	-- Use double-clock FIFO from the Lattice Portable Module Interfaces.
	-- This is a more portable variation than what you'd get with the other tools,
	-- but slightly less configurable. It has everything we need though, and allows
	-- for easy switching between underlying hardware implementations and tuning.
	component pmi_fifo_dc is
		generic (
			pmi_data_width_w	  : integer := 18;
			pmi_data_width_r	  : integer := 18;
			pmi_data_depth_w	  : integer := 256;
			pmi_data_depth_r	  : integer := 256;
			pmi_full_flag		  : integer := 256;
			pmi_empty_flag		  : integer := 0;
			pmi_almost_full_flag  : integer := 252;
			pmi_almost_empty_flag : integer := 4;
			pmi_regmode			  : string	:= "reg";
			pmi_resetmode		  : string	:= "async";
			pmi_family			  : string	:= "EC";
			module_type			  : string	:= "pmi_fifo_dc";
			pmi_implementation	  : string	:= "EBR");
		port (
			Data		: in  std_logic_vector(pmi_data_width_w-1 downto 0);
			WrClock		: in  std_logic;
			RdClock		: in  std_logic;
			WrEn		: in  std_logic;
			RdEn		: in  std_logic;
			Reset		: in  std_logic;
			RPReset		: in  std_logic;
			Q			: out std_logic_vector(pmi_data_width_r-1 downto 0);
			Empty		: out std_logic;
			Full		: out std_logic;
			AlmostEmpty : out std_logic;
			AlmostFull	: out std_logic);
	end component pmi_fifo_dc;

	component pmi_fifo is
		generic (
			pmi_data_width		  : integer := 8;
			pmi_data_depth		  : integer := 256;
			pmi_full_flag		  : integer := 256;
			pmi_empty_flag		  : integer := 0;
			pmi_almost_full_flag  : integer := 252;
			pmi_almost_empty_flag : integer := 4;
			pmi_regmode			  : string	:= "reg";
			pmi_family			  : string	:= "EC";
			module_type			  : string	:= "pmi_fifo";
			pmi_implementation	  : string	:= "EBR");
		port (
			Data		: in  std_logic_vector(pmi_data_width-1 downto 0);
			Clock		: in  std_logic;
			WrEn		: in  std_logic;
			RdEn		: in  std_logic;
			Reset		: in  std_logic;
			Q			: out std_logic_vector(pmi_data_width-1 downto 0);
			Empty		: out std_logic;
			Full		: out std_logic;
			AlmostEmpty : out std_logic;
			AlmostFull	: out std_logic);
	end component pmi_fifo;

	component pmi_pll is
		generic (
			pmi_freq_clki	 : integer := 100;
			pmi_freq_clkfb	 : integer := 100;
			pmi_freq_clkop	 : integer := 100;
			pmi_freq_clkos	 : integer := 100;
			pmi_freq_clkok	 : integer := 50;
			pmi_family		 : string  := "EC";
			pmi_phase_adj	 : integer := 0;
			pmi_duty_cycle	 : integer := 50;
			pmi_clkfb_source : string  := "CLKOP";
			pmi_fdel		 : string  := "off";
			pmi_fdel_val	 : integer := 0;
			module_type		 : string  := "pmi_pll");
		port (
			CLKI   : in	 std_logic;
			CLKFB  : in	 std_logic;
			RESET  : in	 std_logic;
			CLKOP  : out std_logic;
			CLKOS  : out std_logic;
			CLKOK  : out std_logic;
			CLKOK2 : out std_logic;
			LOCK   : out std_logic);
	end component pmi_pll;

	signal USBReset_R	: std_logic;
	signal LogicClock_C : std_logic;
	signal LogicReset_R : std_logic;

	signal TimestampReset_S	   : std_logic;
	signal TimestampOverflow_S : std_logic;
	signal Timestamp_D		   : std_logic_vector(TIMESTAMP_WIDTH-1 downto 0);

	signal USBFifoThr0ReadySync_S, USBFifoThr0WatermarkSync_S, USBFifoThr1ReadySync_S, USBFifoThr1WatermarkSync_S				   : std_logic;
	signal FPGARunSync_S, DVSRunSync_S, ADCRunSync_S, IMURunSync_S, FPGATimestampResetSync_S, DVSAERReqSync_SB, IMUInterruptSync_S : std_logic;

	signal DVSRun_S, ADCRun_S, IMURun_S					  : std_logic;
	signal DVSFifoReset_S, ADCFifoReset_S, IMUFifoReset_S : std_logic;

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
			FPGARun_SI				  => FPGARun_SI,
			FPGARunSync_SO			  => FPGARunSync_S,
			DVSRun_SI				  => DVSRun_SI,
			DVSRunSync_SO			  => DVSRunSync_S,
			ADCRun_SI				  => ADCRun_SI,
			ADCRunSync_SO			  => ADCRunSync_S,
			IMURun_SI				  => IMURun_SI,
			IMURunSync_SO			  => IMURunSync_S,
			FPGATimestampReset_SI	  => FPGATimestampReset_SI,
			FPGATimestampResetSync_SO => FPGATimestampResetSync_S,
			DVSAERReq_SBI			  => DVSAERReq_SBI,
			DVSAERReqSync_SBO		  => DVSAERReqSync_SB,
			IMUInterrupt_SI			  => IMUInterrupt_SI,
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
	DVSFifoReset_S <= LogicReset_R or (not FPGARunSync_S);
	ADCFifoReset_S <= LogicReset_R or (not FPGARunSync_S);
	IMUFifoReset_S <= LogicReset_R or (not FPGARunSync_S);

	-- Generate logic clock using a PLL.
	logicClockPLL : pmi_pll
		generic map (
			pmi_freq_clki	 => USB_CLOCK_FREQ,
			pmi_freq_clkfb	 => LOGIC_CLOCK_FREQ,
			pmi_freq_clkop	 => LOGIC_CLOCK_FREQ,
			pmi_freq_clkos	 => LOGIC_CLOCK_FREQ,
			pmi_freq_clkok	 => LOGIC_CLOCK_FREQ,
			pmi_family		 => DEVICE_FAMILY,
			pmi_phase_adj	 => 0,
			pmi_duty_cycle	 => 50,
			pmi_clkfb_source => "CLKOP",
			pmi_fdel		 => "off",
			pmi_fdel_val	 => 0)
		port map (
			CLKI   => USBClock_CI,
			CLKFB  => LogicClock_C,
			RESET  => USBReset_R,
			CLKOP  => LogicClock_C,
			CLKOS  => open,
			CLKOK  => open,
			CLKOK2 => open,
			LOCK   => open);

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
	usbFifoFPGA : pmi_fifo_dc
		generic map (
			pmi_data_width_w	  => USB_FIFO_WIDTH,
			pmi_data_depth_w	  => USBFPGA_FIFO_SIZE,
			pmi_data_width_r	  => USB_FIFO_WIDTH,
			pmi_data_depth_r	  => USBFPGA_FIFO_SIZE,
			pmi_full_flag		  => USBFPGA_FIFO_SIZE,
			pmi_empty_flag		  => 0,
			pmi_almost_full_flag  => USBFPGA_FIFO_SIZE - USBFPGA_FIFO_ALMOST_SIZE,
			pmi_almost_empty_flag => USBFPGA_FIFO_ALMOST_SIZE,
			pmi_regmode			  => "noreg",
			pmi_resetmode		  => "async",
			pmi_family			  => DEVICE_FAMILY,
			pmi_implementation	  => "LUT")
		port map (
			Data		=> USBFifoFPGAData_D,
			WrClock		=> LogicClock_C,
			RdClock		=> USBClock_CI,
			WrEn		=> USBFifoFPGAWrite_S,
			RdEn		=> USBFifoFPGARead_S,
			Reset		=> LogicReset_R,
			RPReset		=> LogicReset_R,
			Q			=> USBFifoData_DO,
			Empty		=> USBFifoFPGAEmpty_S,
			Full		=> USBFifoFPGAFull_S,
			AlmostEmpty => USBFifoFPGAAlmostEmpty_S,
			AlmostFull	=> USBFifoFPGAAlmostFull_S);

	multiplexerSM : MultiplexerStateMachine
		port map (
			Clock_CI				 => LogicClock_C,
			Reset_RI				 => LogicReset_R,
			FPGARun_SI				 => FPGARunSync_S,
			TimestampReset_SI		 => TimestampReset_S,
			TimestampOverflow_SI	 => TimestampOverflow_S,
			Timestamp_DI			 => Timestamp_D,
			OutFifoFull_SI			 => USBFifoFPGAFull_S,
			OutFifoAlmostFull_SI	 => USBFifoFPGAAlmostFull_S,
			OutFifoWrite_SO			 => USBFifoFPGAWrite_S,
			OutFifoData_DO			 => USBFifoFPGAData_D,
			DVSAERFifoEmpty_SI		 => DVSAERFifoEmpty_S,
			DVSAERFifoAlmostEmpty_SI => DVSAERFifoAlmostEmpty_S,
			DVSAERFifoRead_SO		 => DVSAERFifoRead_S,
			DVSAERFifoData_DI		 => DVSAERFifoDataRead_D);

	tsGenerator : TimestampGenerator
		port map (
			Clock_CI			  => LogicClock_C,
			Reset_RI			  => LogicReset_R,
			FPGARun_SI			  => FPGARunSync_S,
			FPGATimestampReset_SI => FPGATimestampResetSync_S,
			TimestampReset_SO	  => TimestampReset_S,
			TimestampOverflow_SO  => TimestampOverflow_S,
			Timestamp_DO		  => Timestamp_D);

	dvsaerFifo : pmi_fifo
		generic map (
			pmi_data_width		  => EVENT_WIDTH,
			pmi_data_depth		  => DVSAER_FIFO_SIZE,
			pmi_full_flag		  => DVSAER_FIFO_SIZE,
			pmi_empty_flag		  => 0,
			pmi_almost_full_flag  => DVSAER_FIFO_SIZE - DVSAER_FIFO_ALMOST_SIZE,
			pmi_almost_empty_flag => DVSAER_FIFO_ALMOST_SIZE,
			pmi_regmode			  => "noreg",
			pmi_family			  => DEVICE_FAMILY,
			pmi_implementation	  => "LUT")
		port map (
			Data		=> DVSAERFifoDataWrite_D,
			Clock		=> LogicClock_C,
			WrEn		=> DVSAERFifoWrite_S,
			RdEn		=> DVSAERFifoRead_S,
			Reset		=> DVSFifoReset_S,
			Q			=> DVSAERFifoDataRead_D,
			Empty		=> DVSAERFifoEmpty_S,
			Full		=> DVSAERFifoFull_S,
			AlmostEmpty => DVSAERFifoAlmostEmpty_S,
			AlmostFull	=> DVSAERFifoAlmostFull_S);

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
end Structural;
