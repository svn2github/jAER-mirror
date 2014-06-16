library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.all;

entity TopLevel is
	port (
		USBClock_CI : in std_logic;
		Reset_RI	: in std_logic;

		FPGARun_AI : in std_logic;

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
		LED4_SO : out std_logic);
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
			LogicClock_CI  : in	 std_logic;
			Reset_RI	   : in	 std_logic;
			ResetSync_RO   : out std_logic;
			FPGARun_SI	   : in	 std_logic;
			FPGARunSync_SO : out std_logic);
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

	component ContinuousCounter is
		generic (
			COUNTER_WIDTH	  : integer := 16;
			RESET_ON_OVERFLOW : boolean := true;
			SHORT_OVERFLOW	  : boolean := false;
			OVERFLOW_AT_ZERO  : boolean := false);
		port (
			Clock_CI	 : in  std_logic;
			Reset_RI	 : in  std_logic;
			Clear_SI	 : in  std_logic;
			Enable_SI	 : in  std_logic;
			DataLimit_DI : in  unsigned(COUNTER_WIDTH-1 downto 0);
			Overflow_SO	 : out std_logic;
			Data_DO		 : out unsigned(COUNTER_WIDTH-1 downto 0));
	end component ContinuousCounter;

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

	signal FPGARunSync_S : std_logic;

	signal USBFifoThr0ReadySync_S, USBFifoThr0WatermarkSync_S, USBFifoThr1ReadySync_S, USBFifoThr1WatermarkSync_S : std_logic;

	signal USBFifoFPGAData_D																		: std_logic_vector(USB_FIFO_WIDTH-1 downto 0);
	signal USBFifoFPGAWrite_S, USBFifoFPGARead_S													: std_logic;
	signal USBFifoFPGAEmpty_S, USBFifoFPGAAlmostEmpty_S, USBFifoFPGAFull_S, USBFifoFPGAAlmostFull_S : std_logic;
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
			LogicClock_CI  => LogicClock_C,
			Reset_RI	   => Reset_RI,
			ResetSync_RO   => LogicReset_R,
			FPGARun_SI	   => FPGARun_AI,
			FPGARunSync_SO => FPGARunSync_S);

	-- Third: set all constant outputs.
	USBFifoChipSelect_SBO <= '0';  -- Always keep USB chip selected (active-low).
	USBFifoRead_SBO		  <= '1';  -- We never read from the USB data path (active-low).

	-- Wire all LEDs.
	LED1_SO <= USBFifoFPGAEmpty_S;
	LED2_SO <= USBFifoFPGAAlmostFull_S;
	LED3_SO <= USBFifoFPGAAlmostEmpty_S;
	LED4_SO <= USBFifoFPGAFull_S;

	USBFifoFPGAWrite_S <= FPGARunSync_S and (not USBFifoFPGAFull_S);

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

	countGenerator : ContinuousCounter
		generic map (
			COUNTER_WIDTH	  => USB_FIFO_WIDTH,
			RESET_ON_OVERFLOW => true)
		port map (
			Clock_CI				  => LogicClock_C,
			Reset_RI				  => LogicReset_R,
			Clear_SI				  => '0',
			Enable_SI				  => USBFifoFPGAWrite_S,
			DataLimit_DI			  => (others => '1'),
			Overflow_SO				  => open,
			std_logic_vector(Data_DO) => USBFifoFPGAData_D);
end Structural;
