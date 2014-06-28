library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.Settings.all;

entity TopLevel is
	port (
		USBClock_CI : in std_logic;
		Reset_RI	: in std_logic;

		LogicRun_AI		  : in	std_logic;
		DVSRun_AI		  : in	std_logic;
		APSRun_AI		  : in	std_logic;
		IMURun_AI		  : in	std_logic;
		SPI_SSN_ABI		  : in	std_logic;
		SPI_Clock_AI	  : in	std_logic;
		SPI_MOSI_AI		  : in	std_logic;
		SPI_MISO_DO		  : out std_logic;
		BiasEnable_SI	  : in	std_logic;
		BiasDiagSelect_SI : in	std_logic;

		USBFifoData_DO				: out std_logic_vector(USB_FIFO_WIDTH-1 downto 0);
		USBFifoWrite_SBO			: out std_logic;
		USBFifoRead_SBO				: out std_logic;
		USBFifoPktEnd_SBO			: out std_logic;
		USBFifoAddress_DO			: out std_logic_vector(1 downto 0);
		USBFifoFullFlag_SI			: in  std_logic;
		USBFifoProgrammableFlag_SBI : in  std_logic;

		LED1_SO : out std_logic;
		LED2_SO : out std_logic;
		LED3_SO : out std_logic;

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
			USBClock_CI					   : in	 std_logic;
			Reset_RI					   : in	 std_logic;
			ResetSync_RO				   : out std_logic;
			USBFifoFullFlag_SI			   : in	 std_logic;
			USBFifoFullFlagSync_SO		   : out std_logic;
			USBFifoProgrammableFlag_SI	   : in	 std_logic;
			USBFifoProgrammableFlagSync_SO : out std_logic);
	end component USBClockSynchronizer;

	component LogicClockSynchronizer is
		port (
			LogicClock_CI		 : in  std_logic;
			Reset_RI			 : in  std_logic;
			ResetSync_RO		 : out std_logic;
			LogicRun_SI			 : in  std_logic;
			LogicRunSync_SO		 : out std_logic;
			DVSRun_SI			 : in  std_logic;
			DVSRunSync_SO		 : out std_logic;
			APSRun_SI			 : in  std_logic;
			APSRunSync_SO		 : out std_logic;
			IMURun_SI			 : in  std_logic;
			IMURunSync_SO		 : out std_logic;
			DVSAERReq_SBI		 : in  std_logic;
			DVSAERReqSync_SBO	 : out std_logic;
			IMUInterrupt_SI		 : in  std_logic;
			IMUInterruptSync_SO	 : out std_logic;
			SyncOutSwitch_SI	 : in  std_logic;
			SyncOutSwitchSync_SO : out std_logic;
			SyncInClock_CI		 : in  std_logic;
			SyncInClockSync_CO	 : out std_logic;
			SyncInSwitch_SI		 : in  std_logic;
			SyncInSwitchSync_SO	 : out std_logic;
			SyncInSignal_SI		 : in  std_logic;
			SyncInSignalSync_SO	 : out std_logic);
	end component LogicClockSynchronizer;

	component FX2Statemachine is
		port (
			Clock_CI				: in  std_logic;
			Reset_RI				: in  std_logic;
			USBFifoEP6Full_SI		: in  std_logic;
			USBFifoEP6AlmostFull_SI : in  std_logic;
			USBFifoWrite_SBO		: out std_logic;
			USBFifoPktEnd_SBO		: out std_logic;
			InFifoEmpty_SI			: in  std_logic;
			InFifoAlmostEmpty_SI	: in  std_logic;
			InFifoRead_SO			: out std_logic);
	end component FX2Statemachine;

	component MultiplexerStateMachine is
		port (
			Clock_CI					 : in  std_logic;
			Reset_RI					 : in  std_logic;
			Run_SI						 : in  std_logic;
			TimestampReset_SI			 : in  std_logic;
			OutFifoFull_SI				 : in  std_logic;
			OutFifoAlmostFull_SI		 : in  std_logic;
			OutFifoWrite_SO				 : out std_logic;
			OutFifoData_DO				 : out std_logic_vector(USB_FIFO_WIDTH-1 downto 0);
			DVSAERFifoEmpty_SI			 : in  std_logic;
			DVSAERFifoAlmostEmpty_SI	 : in  std_logic;
			DVSAERFifoRead_SO			 : out std_logic;
			DVSAERFifoData_DI			 : in  std_logic_vector(EVENT_WIDTH-1 downto 0);
			APSADCFifoEmpty_SI			 : in  std_logic;
			APSADCFifoAlmostEmpty_SI	 : in  std_logic;
			APSADCFifoRead_SO			 : out std_logic;
			APSADCFifoData_DI			 : in  std_logic_vector(EVENT_WIDTH-1 downto 0);
			IMUFifoEmpty_SI				 : in  std_logic;
			IMUFifoAlmostEmpty_SI		 : in  std_logic;
			IMUFifoRead_SO				 : out std_logic;
			IMUFifoData_DI				 : in  std_logic_vector(EVENT_WIDTH-1 downto 0);
			ExtTriggerFifoEmpty_SI		 : in  std_logic;
			ExtTriggerFifoAlmostEmpty_SI : in  std_logic;
			ExtTriggerFifoRead_SO		 : out std_logic;
			ExtTriggerFifoData_DI		 : in  std_logic_vector(EVENT_WIDTH-1 downto 0));
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

	component IMUStateMachine is
		port (
			Clock_CI			 : in	 std_logic;
			Reset_RI			 : in	 std_logic;
			IMURun_SI			 : in	 std_logic;
			OutFifoFull_SI		 : in	 std_logic;
			OutFifoAlmostFull_SI : in	 std_logic;
			OutFifoWrite_SO		 : out	 std_logic;
			OutFifoData_DO		 : out	 std_logic_vector(EVENT_WIDTH-1 downto 0);
			IMUClock_ZO			 : inout std_logic;
			IMUData_ZIO			 : inout std_logic;
			IMUInterrupt_SI		 : in	 std_logic);
	end component IMUStateMachine;

	component APSADCStateMachine is
		port (
			Clock_CI			   : in	 std_logic;
			Reset_RI			   : in	 std_logic;
			APSRun_SI			   : in	 std_logic;
			OutFifoFull_SI		   : in	 std_logic;
			OutFifoAlmostFull_SI   : in	 std_logic;
			OutFifoWrite_SO		   : out std_logic;
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
			Clock_CI			 : in  std_logic;
			Reset_RI			 : in  std_logic;
			ExtTriggerRun_SI	 : in  std_logic;
			OutFifoFull_SI		 : in  std_logic;
			OutFifoAlmostFull_SI : in  std_logic;
			OutFifoWrite_SO		 : out std_logic;
			OutFifoData_DO		 : out std_logic_vector(EVENT_WIDTH-1 downto 0);
			ExtTriggerSwitch_SI	 : in  std_logic;
			ExtTriggerSignal_SI	 : in  std_logic);
	end component ExtTriggerStateMachine;

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

	signal USBFifoFullFlagSync_S, USBFifoProgrammableFlagSync_S							  : std_logic;
	signal LogicRunSync_S, DVSRunSync_S, APSRunSync_S, IMURunSync_S						  : std_logic;
	signal DVSAERReqSync_SB, IMUInterruptSync_S											  : std_logic;
	signal SyncOutSwitchSync_S, SyncInClockSync_C, SyncInSwitchSync_S, SyncInSignalSync_S : std_logic;

	signal DVSRun_S, APSRun_S, IMURun_S, ExtTriggerRun_S						 : std_logic;
	signal DVSFifoReset_R, APSFifoReset_R, IMUFifoReset_R, ExtTriggerFifoReset_R : std_logic;

	signal USBFifoFPGAData_D																		: std_logic_vector(USB_FIFO_WIDTH-1 downto 0);
	signal USBFifoFPGAWrite_S, USBFifoFPGARead_S													: std_logic;
	signal USBFifoFPGAEmpty_S, USBFifoFPGAAlmostEmpty_S, USBFifoFPGAFull_S, USBFifoFPGAAlmostFull_S : std_logic;

	signal DVSAERFifoDataWrite_D, DVSAERFifoDataRead_D											: std_logic_vector(EVENT_WIDTH-1 downto 0);
	signal DVSAERFifoWrite_S, DVSAERFifoRead_S													: std_logic;
	signal DVSAERFifoEmpty_S, DVSAERFifoAlmostEmpty_S, DVSAERFifoFull_S, DVSAERFifoAlmostFull_S : std_logic;

	signal APSADCFifoDataWrite_D, APSADCFifoDataRead_D											: std_logic_vector(EVENT_WIDTH-1 downto 0);
	signal APSADCFifoWrite_S, APSADCFifoRead_S													: std_logic;
	signal APSADCFifoEmpty_S, APSADCFifoAlmostEmpty_S, APSADCFifoFull_S, APSADCFifoAlmostFull_S : std_logic;

	signal IMUFifoDataWrite_D, IMUFifoDataRead_D									: std_logic_vector(EVENT_WIDTH-1 downto 0);
	signal IMUFifoWrite_S, IMUFifoRead_S											: std_logic;
	signal IMUFifoEmpty_S, IMUFifoAlmostEmpty_S, IMUFifoFull_S, IMUFifoAlmostFull_S : std_logic;

	signal ExtTriggerFifoDataWrite_D, ExtTriggerFifoDataRead_D													: std_logic_vector(EVENT_WIDTH-1 downto 0);
	signal ExtTriggerFifoWrite_S, ExtTriggerFifoRead_S															: std_logic;
	signal ExtTriggerFifoEmpty_S, ExtTriggerFifoAlmostEmpty_S, ExtTriggerFifoFull_S, ExtTriggerFifoAlmostFull_S : std_logic;
begin
	-- First: synchronize all USB-related inputs to the USB clock.
	syncInputsToUSBClock : USBClockSynchronizer
		port map (
			USBClock_CI					   => USBClock_CI,
			Reset_RI					   => Reset_RI,
			ResetSync_RO				   => USBReset_R,
			USBFifoFullFlag_SI			   => USBFifoFullFlag_SI,
			USBFifoFullFlagSync_SO		   => USBFifoFullFlagSync_S,
			USBFifoProgrammableFlag_SI	   => not USBFifoProgrammableFlag_SBI,
			USBFifoProgrammableFlagSync_SO => USBFifoProgrammableFlagSync_S);

	-- Second: synchronize all logic-related inputs to the logic clock.
	syncInputsToLogicClock : LogicClockSynchronizer
		port map (
			LogicClock_CI		 => LogicClock_C,
			Reset_RI			 => Reset_RI,
			ResetSync_RO		 => LogicReset_R,
			LogicRun_SI			 => LogicRun_AI,
			LogicRunSync_SO		 => LogicRunSync_S,
			DVSRun_SI			 => DVSRun_AI,
			DVSRunSync_SO		 => DVSRunSync_S,
			APSRun_SI			 => APSRun_AI,
			APSRunSync_SO		 => APSRunSync_S,
			IMURun_SI			 => IMURun_AI,
			IMURunSync_SO		 => IMURunSync_S,
			DVSAERReq_SBI		 => DVSAERReq_ABI,
			DVSAERReqSync_SBO	 => DVSAERReqSync_SB,
			IMUInterrupt_SI		 => IMUInterrupt_AI,
			IMUInterruptSync_SO	 => IMUInterruptSync_S,
			SyncOutSwitch_SI	 => SyncOutSwitch_AI,
			SyncOutSwitchSync_SO => SyncOutSwitchSync_S,
			SyncInClock_CI		 => SyncInClock_AI,
			SyncInClockSync_CO	 => SyncInClockSync_C,
			SyncInSwitch_SI		 => SyncInSwitch_AI,
			SyncInSwitchSync_SO	 => SyncInSwitchSync_S,
			SyncInSignal_SI		 => SyncInSignal_AI,
			SyncInSignalSync_SO	 => SyncInSignalSync_S);

	-- Third: set all constant outputs.
	USBFifoRead_SBO		  <= '1';  -- We never read from the USB data path (active-low).
	USBFifoAddress_DO	  <= "10";		-- Always write to EP6.
	ChipBiasEnable_SO	  <= BiasEnable_SI;		 -- Direct bypass.
	ChipBiasDiagSelect_SO <= BiasDiagSelect_SI;	 -- Direct bypass.

	-- Wire all LEDs.
	LED1_SO <= LogicRunSync_S;
	LED2_SO <= USBFifoFPGAEmpty_S;
	LED3_SO <= USBFifoFPGAFull_S;

	-- Only run data producers if the whole logic also is running.
	DVSRun_S		<= DVSRunSync_S and LogicRunSync_S;
	APSRun_S		<= APSRunSync_S and LogicRunSync_S;
	IMURun_S		<= IMURunSync_S and LogicRunSync_S;
	ExtTriggerRun_S <= LogicRunSync_S;

	-- Keep data transmission FIFOs in reset if FPGA is not running, so
	-- that they will be empty when resuming operation (no stale data).
	DVSFifoReset_R		  <= LogicReset_R or (not LogicRunSync_S);
	APSFifoReset_R		  <= LogicReset_R or (not LogicRunSync_S);
	IMUFifoReset_R		  <= LogicReset_R or (not LogicRunSync_S);
	ExtTriggerFifoReset_R <= LogicReset_R or (not LogicRunSync_S);

	-- Generate logic clock using a PLL.
	logicClockPLL : PLL
		generic map (
			CLOCK_FREQ	   => USB_CLOCK_FREQ,
			OUT_CLOCK_FREQ => LOGIC_CLOCK_FREQ)
		port map (
			Clock_CI	=> USBClock_CI,
			Reset_RI	=> USBReset_R,
			OutClock_CO => LogicClock_C);

	usbFX2SM : FX2Statemachine
		port map (
			Clock_CI				=> USBClock_CI,
			Reset_RI				=> USBReset_R,
			USBFifoEP6Full_SI		=> USBFifoFullFlagSync_S,
			USBFifoEP6AlmostFull_SI => USBFifoProgrammableFlagSync_S,
			USBFifoWrite_SBO		=> USBFifoWrite_SBO,
			USBFifoPktEnd_SBO		=> USBFifoPktEnd_SBO,
			InFifoEmpty_SI			=> USBFifoFPGAEmpty_S,
			InFifoAlmostEmpty_SI	=> USBFifoFPGAAlmostEmpty_S,
			InFifoRead_SO			=> USBFifoFPGARead_S);

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
			Reset_RI	   => USBReset_R,
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
			Clock_CI					 => LogicClock_C,
			Reset_RI					 => LogicReset_R,
			Run_SI						 => LogicRunSync_S,
			TimestampReset_SI			 => '0',
			OutFifoFull_SI				 => USBFifoFPGAFull_S,
			OutFifoAlmostFull_SI		 => USBFifoFPGAAlmostFull_S,
			OutFifoWrite_SO				 => USBFifoFPGAWrite_S,
			OutFifoData_DO				 => USBFifoFPGAData_D,
			DVSAERFifoEmpty_SI			 => DVSAERFifoEmpty_S,
			DVSAERFifoAlmostEmpty_SI	 => DVSAERFifoAlmostEmpty_S,
			DVSAERFifoRead_SO			 => DVSAERFifoRead_S,
			DVSAERFifoData_DI			 => DVSAERFifoDataRead_D,
			APSADCFifoEmpty_SI			 => APSADCFifoEmpty_S,
			APSADCFifoAlmostEmpty_SI	 => APSADCFifoAlmostEmpty_S,
			APSADCFifoRead_SO			 => APSADCFifoRead_S,
			APSADCFifoData_DI			 => APSADCFifoDataRead_D,
			IMUFifoEmpty_SI				 => IMUFifoEmpty_S,
			IMUFifoAlmostEmpty_SI		 => IMUFifoAlmostEmpty_S,
			IMUFifoRead_SO				 => IMUFifoRead_S,
			IMUFifoData_DI				 => IMUFifoDataRead_D,
			ExtTriggerFifoEmpty_SI		 => ExtTriggerFifoEmpty_S,
			ExtTriggerFifoAlmostEmpty_SI => ExtTriggerFifoAlmostEmpty_S,
			ExtTriggerFifoRead_SO		 => ExtTriggerFifoRead_S,
			ExtTriggerFifoData_DI		 => ExtTriggerFifoDataRead_D);

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
			Reset_RI	   => DVSFifoReset_R,
			DataIn_DI	   => DVSAERFifoDataWrite_D,
			WrEnable_SI	   => DVSAERFifoWrite_S,
			DataOut_DO	   => DVSAERFifoDataRead_D,
			RdEnable_SI	   => DVSAERFifoRead_S,
			Empty_SO	   => DVSAERFifoEmpty_S,
			AlmostEmpty_SO => DVSAERFifoAlmostEmpty_S,
			Full_SO		   => DVSAERFifoFull_S,
			AlmostFull_SO  => DVSAERFifoAlmostFull_S);

	dvsAerSM : DVSAERStateMachine
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
			Reset_RI	   => APSFifoReset_R,
			DataIn_DI	   => APSADCFifoDataWrite_D,
			WrEnable_SI	   => APSADCFifoWrite_S,
			DataOut_DO	   => APSADCFifoDataRead_D,
			RdEnable_SI	   => APSADCFifoRead_S,
			Empty_SO	   => APSADCFifoEmpty_S,
			AlmostEmpty_SO => APSADCFifoAlmostEmpty_S,
			Full_SO		   => APSADCFifoFull_S,
			AlmostFull_SO  => APSADCFifoAlmostFull_S);

	apsAdcSM : APSADCStateMachine
		port map (
			Clock_CI			   => LogicClock_C,
			Reset_RI			   => LogicReset_R,
			APSRun_SI			   => APSRun_S,
			OutFifoFull_SI		   => APSADCFifoFull_S,
			OutFifoAlmostFull_SI   => APSADCFifoAlmostFull_S,
			OutFifoWrite_SO		   => APSADCFifoWrite_S,
			OutFifoData_DO		   => APSADCFifoDataWrite_D,
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
			Reset_RI	   => IMUFifoReset_R,
			DataIn_DI	   => IMUFifoDataWrite_D,
			WrEnable_SI	   => IMUFifoWrite_S,
			DataOut_DO	   => IMUFifoDataRead_D,
			RdEnable_SI	   => IMUFifoRead_S,
			Empty_SO	   => IMUFifoEmpty_S,
			AlmostEmpty_SO => IMUFifoAlmostEmpty_S,
			Full_SO		   => IMUFifoFull_S,
			AlmostFull_SO  => IMUFifoAlmostFull_S);

	imuSM : IMUStateMachine
		port map (
			Clock_CI			 => LogicClock_C,
			Reset_RI			 => LogicReset_R,
			IMURun_SI			 => IMURun_S,
			OutFifoFull_SI		 => IMUFifoFull_S,
			OutFifoAlmostFull_SI => IMUFifoAlmostFull_S,
			OutFifoWrite_SO		 => IMUFifoWrite_S,
			OutFifoData_DO		 => IMUFifoDataWrite_D,
			IMUClock_ZO			 => IMUClock_ZO,
			IMUData_ZIO			 => IMUData_ZIO,
			IMUInterrupt_SI		 => IMUInterruptSync_S);

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
			Reset_RI	   => ExtTriggerFifoReset_R,
			DataIn_DI	   => ExtTriggerFifoDataWrite_D,
			WrEnable_SI	   => ExtTriggerFifoWrite_S,
			DataOut_DO	   => ExtTriggerFifoDataRead_D,
			RdEnable_SI	   => ExtTriggerFifoRead_S,
			Empty_SO	   => ExtTriggerFifoEmpty_S,
			AlmostEmpty_SO => ExtTriggerFifoAlmostEmpty_S,
			Full_SO		   => ExtTriggerFifoFull_S,
			AlmostFull_SO  => ExtTriggerFifoAlmostFull_S);

	extTriggerSM : ExtTriggerStateMachine
		port map (
			Clock_CI			 => LogicClock_C,
			Reset_RI			 => LogicReset_R,
			ExtTriggerRun_SI	 => ExtTriggerRun_S,
			OutFifoFull_SI		 => ExtTriggerFifoFull_S,
			OutFifoAlmostFull_SI => ExtTriggerFifoAlmostFull_S,
			OutFifoWrite_SO		 => ExtTriggerFifoWrite_S,
			OutFifoData_DO		 => ExtTriggerFifoDataWrite_D,
			ExtTriggerSwitch_SI	 => SyncInSwitchSync_S,
			ExtTriggerSignal_SI	 => SyncInSignalSync_S);
end Structural;
