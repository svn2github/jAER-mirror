library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity topLevel is
	port (
		USBClock_CI : in std_logic;
		Reset_RBI : in std_logic;
		FPGARun_SI : in std_logic;

		USBFifoData_DO : out std_logic_vector(15 downto 0);
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
		LED4_SO : out std_logic);
end topLevel;

architecture Structural of topLevel is
	constant FAST_CLOCK_FREQ : integer := 100;
	constant SLOW_CLOCK_FREQ : integer := 25;

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
	port (
		Clock_CI : in  std_logic;
		Reset_RBI : in  std_logic;
		CountEnable_SI : in std_logic;
		Data_DO : out std_logic_vector(15 downto 0));
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
  
	signal Reset_RI: std_logic;
	signal AERFifoDataIn_D : std_logic_vector(15 downto 0);
	signal AERFifoWrite_S, AERFifoRead_S : std_logic;
	signal AERFifoEmpty_S, AERFifoFull_S, AERFifoAlmostEmpty_S : std_logic;
	signal SlowClock_C : std_logic;
	signal USBFifoThr0ReadySync_S, USBFifoThr0WatermarkSync_S, USBFifoThr1ReadySync_S, USBFifoThr1WatermarkSync_S : std_logic;
begin
	Reset_RI <= not Reset_RBI;
	AERFifoWrite_S <= FPGARun_SI and (not AERFifoFull_S);
	USBFifoRead_SBO <= '1';
	LED1_SO <= AERFifoEmpty_S;
	LED2_SO <= AERFifoFull_S;
	LED3_SO <= '0';
	LED4_SO <= '0';

	slowClockPLL : pmi_pll
	generic map (
		pmi_freq_clki => FAST_CLOCK_FREQ,
		pmi_freq_clkfb => SLOW_CLOCK_FREQ,
		pmi_freq_clkop => SLOW_CLOCK_FREQ,
		pmi_freq_clkos => SLOW_CLOCK_FREQ,
		pmi_freq_clkok => SLOW_CLOCK_FREQ,
		pmi_family => "ECP3",
		pmi_phase_adj => 0,
		pmi_duty_cycle => 50,
		pmi_clkfb_source => "CLKOP",
		pmi_fdel => "off",
		pmi_fdel_val => 0)
	port map (
		CLKI => USBClock_CI,
		CLKFB => SlowClock_C,
		RESET => Reset_RI,
		CLKOP => SlowClock_C,
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
		InFifoEmpty_SI => AERFifoEmpty_S,
		InFifoAlmostEmpty_SI => AERFifoAlmostEmpty_S,
		InFifoRead_SO => AERFifoRead_S);

	-- Instantiate one FIFO to hold all the events coming out of the mixer-producer state machine.
	usbFifo: pmi_fifo_dc
	generic map (
		pmi_data_width_w => 16,
		pmi_data_depth_w => 64,
		pmi_data_width_r => 16,
		pmi_data_depth_r => 64,
		pmi_full_flag => 64,
		pmi_empty_flag => 0,
		pmi_almost_full_flag => 56,
		pmi_almost_empty_flag => 8,
		pmi_regmode => "noreg",
		pmi_resetmode => "async",
		pmi_family => "ECP3",
		pmi_implementation => "LUT"
	)
	port map (
		Data => AERFifoDataIn_D,
		WrClock => SlowClock_C,
		RdClock => USBClock_CI,
		WrEn => AERFifoWrite_S, 
		RdEn => AERFifoRead_S,
		Reset => Reset_RI,
		RPReset => Reset_RI,
		Q =>  USBFifoData_DO,
		Empty => AERFifoEmpty_S, 
		Full => AERFifoFull_S,
		AlmostEmpty => AERFifoAlmostEmpty_S,
		AlmostFull => open
	);

	numberGenerator : continuousCounter
	port map (
		Clock_CI => SlowClock_C,
		Reset_RBI => Reset_RBI,
		CountEnable_SI => AERFifoWrite_S,
		Data_DO => AERFifoDataIn_D);
end Structural;
