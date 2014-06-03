library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.settings.all;

entity topLevel is
	port (
		USBClock_CI : in std_logic;
		Reset_RBI : in std_logic;

		DVSReset_SBI : in std_logic;
		FPGARun_SI : in std_logic;
		ADCRun_SI : in std_logic;
		BiasEnable_SI : in std_logic;
		FPGAShiftRegClock_CI : in std_logic;
		FPGAShiftRegLatch_SI : in std_logic;
		FPGAShiftRegBitIn_DI : in std_logic;
		FPGATimestampReset_SI : in std_logic;
		FPGATimestampMaster_SI : in std_logic;
		BiasDiagSel_SI : in std_logic;

		USBFifoData_DO : out std_logic_vector(USB_FIFO_WIDTH-1 downto 0);
		USBFifoChipSelect_SBO : out std_logic;
		USBFifoWrite_SBO : out std_logic;
		USBFifoRead_SBO : out std_logic;
		USBFifoPktEnd_SBO : out std_logic;
		USBFifoAddress_DO : out std_logic_vector(1 downto 0);
		USBFifoThr0Ready_SI : in std_logic;
		USBFifoThr0Watermark_SI : in std_logic;
		USBFifoThr1Ready_SI : in std_logic;
		USBFifoThr1Watermark_SI : in std_logic;

		LED1_SO : out std_logic;
		LED2_SO : out std_logic;
		LED3_SO : out std_logic;
		LED4_SO : out std_logic;

		ChipReset_SBO : out std_logic;

		ChipBiasEnable_SO : out std_logic;
		ChipBiasDiagSel_SO : out std_logic;
		--ChipBiasBitOut_DI : in std_logic;

		DVSAERData_DI : in std_logic_vector(AER_BUS_WIDTH-1 downto 0);
		DVSAERReq_SBI : in std_logic;
		DVSAERAck_SBO : out std_logic;

		APSChipRowSRClock_SO : out std_logic;
		APSChipRowSRIn_SO : out std_logic;
		APSChipColSRClock_SO : out std_logic;
		APSChipColSRIn_SO : out std_logic;
		APSChipColState0_SO : out std_logic;
		APSChipColState1_SO : out std_logic;
		APSChipTXGate_SO : out std_logic;

		APSADCData_DI : in std_logic_vector(ADC_BUS_WIDTH-1 downto 0);
		APSADCOverflow_SI : in std_logic;
		APSADCClock_CO : out std_logic;
		APSADCWrite_SO : out std_logic;
		APSADCRead_SO : out std_logic;

		IMUClock_CO : inout std_logic; -- this is inout because it must be tristateable
		IMUData_DIO : inout std_logic;
		IMUInterrupt_SI : in std_logic;

		SyncOutClock_CO : out std_logic;
		SyncOutSwitch_SI : in std_logic;
		SyncOutSignal_SO : out std_logic;
		SyncInClock_CI : in std_logic;
		SyncInSwitch_SI : in std_logic;
		SyncInSignal_SI : in std_logic);
end topLevel;

architecture Structural of topLevel is
	component DFFSynchronizer
	port (
		SyncClock_CI : in std_logic;
		Reset_RBI : in std_logic;
		SignalToSync_SI : in std_logic;
		SyncedSignal_SO : out std_logic);
	end component;

	component FX3Statemachine
	port (
		Clock_CI : in std_logic;
		Reset_RBI : in std_logic;
		Run_SI : in std_logic;
		USBFifoThread0Full_SI : in std_logic;
		USBFifoThread0AlmostFull_SI : in std_logic;
		USBFifoThread1Full_SI : in std_logic;
		USBFifoThread1AlmostFull_SI : in std_logic;
		USBFifoChipSelect_SBO : out std_logic;
		USBFifoWrite_SBO : out std_logic;
		USBFifoPktEnd_SBO : out std_logic;
		USBFifoAddress_DO : out std_logic_vector(1 downto 0);
		InFifoEmpty_SI : in std_logic;
		InFifoAlmostEmpty_SI : in std_logic;
		InFifoRead_SO : out std_logic);
	end component;

	-- Use double-clock FIFO from the Lattice Portable Module Interfaces.
	-- This is a more portable variation than what you'd get with the other tools,
	-- but slightly less configurable. It has everything we need though, and allows
	-- for easy switching between underlying hardware implementations and tuning.
	component pmi_fifo_dc is
	generic (
		pmi_data_width_w : integer := 18; 
		pmi_data_width_r : integer := 18; 
		pmi_data_depth_w : integer := 256; 
		pmi_data_depth_r : integer := 256; 
		pmi_full_flag : integer := 256; 
		pmi_empty_flag : integer := 0; 
		pmi_almost_full_flag : integer := 252; 
		pmi_almost_empty_flag : integer := 4; 
		pmi_regmode : string := "reg"; 
		pmi_resetmode : string := "async"; 
		pmi_family : string := "EC" ; 
		module_type : string := "pmi_fifo_dc"; 
		pmi_implementation : string := "EBR");
	port (
		Data : in std_logic_vector(pmi_data_width_w-1 downto 0);
		WrClock: in std_logic;
		RdClock: in std_logic;
		WrEn: in std_logic;
		RdEn: in std_logic;
		Reset: in std_logic;
		RPReset: in std_logic;
		Q : out std_logic_vector(pmi_data_width_r-1 downto 0);
		Empty: out std_logic;
		Full: out std_logic;
		AlmostEmpty: out std_logic;
		AlmostFull: out std_logic);
	end component pmi_fifo_dc;

	component continuousCounter
	generic (
		COUNTER_WIDTH : integer := 16;
		RESET_ON_OVERFLOW : boolean := true);
	port (
		Clock_CI : in std_logic;
		Reset_RBI : in std_logic;
		Clear_SI : in std_logic;
		Enable_SI : in std_logic;
		DataLimit_DI : in unsigned(COUNTER_WIDTH-1 downto 0);
		Overflow_SO : out std_logic;
		Data_DO : out unsigned(COUNTER_WIDTH-1 downto 0));
	end component;

	component TimestampGenerator
	port (
		Clock_CI : in std_logic;
		Reset_RBI : in std_logic;
		FPGATimestampReset_SI : in std_logic;
		TimestampOverflow_SO : out std_logic;
		Timestamp_DO : out std_logic_vector(TIMESTAMP_WIDTH-1 downto 0));
	end component;

	component pmi_pll is
	generic (
		pmi_freq_clki : integer := 100; 
		pmi_freq_clkfb : integer := 100; 
		pmi_freq_clkop : integer := 100; 
		pmi_freq_clkos : integer := 100; 
		pmi_freq_clkok : integer := 50; 
		pmi_family : string := "EC"; 
		pmi_phase_adj : integer := 0; 
		pmi_duty_cycle : integer := 50; 
		pmi_clkfb_source : string := "CLKOP"; 
		pmi_fdel : string := "off"; 
		pmi_fdel_val : integer := 0; 
		module_type : string := "pmi_pll" );
	port (
		CLKI: in std_logic;
		CLKFB: in std_logic;
		RESET: in std_logic;
		CLKOP: out std_logic;
		CLKOS: out std_logic;
		CLKOK: out std_logic;
		CLKOK2: out std_logic;
		LOCK: out std_logic);
	end component pmi_pll;

	signal LogicClock_C : std_logic;
	signal Reset_RI: std_logic;

	signal TimestampOverflow_S : std_logic;
	signal Timestamp_D : std_logic_vector(TIMESTAMP_WIDTH-1 downto 0);

	signal USBFifoDataIn_D : std_logic_vector(USB_FIFO_WIDTH-1 downto 0); -- 16-bit wide USB data path.
	signal USBFifoWrite_S, USBFifoRead_S : std_logic;
	signal USBFifoEmpty_S, USBFifoAlmostEmpty_S, USBFifoFull_S, USBFifoAlmostFull_S : std_logic;
	signal USBFifoThr0ReadySync_S, USBFifoThr0WatermarkSync_S, USBFifoThr1ReadySync_S, USBFifoThr1WatermarkSync_S : std_logic;
begin
	Reset_RI <= not Reset_RBI; -- Generate active-high reset.
	USBFifoRead_SBO <= '1'; -- We never, ever read from the USB data path.

	LED1_SO <= USBFifoEmpty_S;
	LED2_SO <= USBFifoFull_S;
	LED3_SO <= USBFifoAlmostEmpty_S;
	LED4_SO <= USBFifoAlmostFull_S;

	logicClockPLL : pmi_pll
	generic map (
		pmi_freq_clki => USB_CLOCK_FREQ,
		pmi_freq_clkfb => LOGIC_CLOCK_FREQ,
		pmi_freq_clkop => LOGIC_CLOCK_FREQ,
		pmi_freq_clkos => LOGIC_CLOCK_FREQ,
		pmi_freq_clkok => LOGIC_CLOCK_FREQ,
		pmi_family => "ECP3",
		pmi_phase_adj => 0,
		pmi_duty_cycle => 50,
		pmi_clkfb_source => "CLKOP",
		pmi_fdel => "off",
		pmi_fdel_val => 0)
	port map (
		CLKI => USBClock_CI,
		CLKFB => LogicClock_C,
		RESET => Reset_RI,
		CLKOP => LogicClock_C,
		CLKOS => open,
		CLKOK => open,
		CLKOK2 => open,
		LOCK => open);

	-- Ensure synchronization of FX3 inputs related to GPIF FIFO.
	syncUSBFifoThr0Ready : DFFSynchronizer
	port map (
		SyncClock_CI => USBClock_CI,
		Reset_RBI => Reset_RBI,
		SignalToSync_SI => USBFifoThr0Ready_SI,
		SyncedSignal_SO => USBFifoThr0ReadySync_S);

	syncUSBFifoThr0Watermark : DFFSynchronizer
	port map (
		SyncClock_CI => USBClock_CI,
		Reset_RBI => Reset_RBI,
		SignalToSync_SI => USBFifoThr0Watermark_SI,
		SyncedSignal_SO => USBFifoThr0WatermarkSync_S);

	syncUSBFifoThr1Ready : DFFSynchronizer
	port map (
		SyncClock_CI => USBClock_CI,
		Reset_RBI => Reset_RBI,
		SignalToSync_SI => USBFifoThr1Ready_SI,
		SyncedSignal_SO => USBFifoThr1ReadySync_S);

	syncUSBFifoThr1Watermark : DFFSynchronizer
	port map (
		SyncClock_CI => USBClock_CI,
		Reset_RBI => Reset_RBI,
		SignalToSync_SI => USBFifoThr1Watermark_SI,
		SyncedSignal_SO => USBFifoThr1WatermarkSync_S);

	usbFX3Statemachine: FX3Statemachine
	port map (
		Clock_CI => USBClock_CI,
		Reset_RBI => Reset_RBI,
		Run_SI => FPGARun_SI,
		USBFifoThread0Full_SI => USBFifoThr0ReadySync_S,
		USBFifoThread0AlmostFull_SI => USBFifoThr0WatermarkSync_S,
		USBFifoThread1Full_SI => USBFifoThr1ReadySync_S,
		USBFifoThread1AlmostFull_SI => USBFifoThr1WatermarkSync_S,
		USBFifoChipSelect_SBO => USBFifoChipSelect_SBO,
		USBFifoWrite_SBO => USBFifoWrite_SBO,
		USBFifoPktEnd_SBO => USBFifoPktEnd_SBO,
		USBFifoAddress_DO => USBFifoAddress_DO,
		InFifoEmpty_SI => USBFifoEmpty_S,
		InFifoAlmostEmpty_SI => USBFifoAlmostEmpty_S,
		InFifoRead_SO => USBFifoRead_S);

	-- Instantiate one FIFO to hold all the events coming out of the mixer-producer state machine.
	usbFifo: pmi_fifo_dc
	generic map (
		pmi_data_width_w => USB_FIFO_WIDTH,
		pmi_data_depth_w => USB_FIFO_SIZE,
		pmi_data_width_r => USB_FIFO_WIDTH,
		pmi_data_depth_r => USB_FIFO_SIZE,
		pmi_full_flag => USB_FIFO_SIZE,
		pmi_empty_flag => 0,
		pmi_almost_full_flag => USB_FIFO_SIZE - USB_BURST_WRITE_LENGTH,
		pmi_almost_empty_flag => USB_BURST_WRITE_LENGTH,
		pmi_regmode => "noreg",
		pmi_resetmode => "async",
		pmi_family => "ECP3",
		pmi_implementation => "LUT")
	port map (
		Data => USBFifoDataIn_D,
		WrClock => LogicClock_C,
		RdClock => USBClock_CI,
		WrEn => USBFifoWrite_S, 
		RdEn => USBFifoRead_S,
		Reset => Reset_RI,
		RPReset => Reset_RI,
		Q =>  USBFifoData_DO,
		Empty => USBFifoEmpty_S, 
		Full => USBFifoFull_S,
		AlmostEmpty => USBFifoAlmostEmpty_S,
		AlmostFull => USBFifoAlmostFull_S);

	tsGenerator : TimestampGenerator
	port map (
		Clock_CI => LogicClock_C,
		Reset_RBI => Reset_RBI,
		FPGATimestampReset_SI => FPGATimestampReset_SI,
		TimestampOverflow_SO => TimestampOverflow_S,
		Timestamp_DO => Timestamp_D);
end Structural;
