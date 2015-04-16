--------------------------------------------------------------------------------
-- Company: ini
-- Engineer: Raphael Berner
--
-- Create Date:    11:54:08 10/24/05
-- Design Name:    
-- Module Name:    USBAER_top_level - Structural
-- Project Name:   USBAERmini2
-- Target Device:  CoolrunnerII XC2C256
-- Tool versions:  
-- Description: top-level file, connects all blocks
--
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED."+";

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity USBAER_top_level is
  port (
    -- communication ports to FX2 Fifos
    FX2FifoDataxDIO         : out std_logic_vector(9 downto 0);
    FX2FifoInFullxSBI       : in    std_logic;
    FX2FifoWritexEBO        : out   std_logic;
    FX2FifoReadxEBO         : out   std_logic;
  
    FX2FifoPktEndxSBO       : out   std_logic;
    FX2FifoAddressxDO       : out   std_logic_vector(1 downto 0);
	
	-- FX2 interface to produce VREF
	FX2VrefStatusxDO       : out    std_logic_vector(1 downto 0);

    -- clock and reset inputs
    -- ClockxCI  : in std_logic;
    --IfClockxCO : out std_logic;
    IfClockxCI : in std_logic;
    ResetxRBI : in std_logic;

    -- ports to synchronize other USBAER boards
    Sync1xABI   : in  std_logic;        -- needs synchronization
    SynchOutxSBO : out std_logic;

    -- communication with 8051   
    PC0xSIO  : inout  std_logic;
    PC1xSIO  : inout  std_logic;
    PC2xSIO  : inout  std_logic;
    PC3xSIO  : inout  std_logic;

--    PA0xSIO : inout std_logic;
    PA0xSIO : inout std_logic;
    PA1xSIO : inout std_logic;
    PA3xSIO : inout std_logic;
    PA7xSIO : inout std_logic;

    PE2xSI : in std_logic;
    PE3xSI : in std_logic;

    FXLEDxSI : in std_logic;

	-- communication with chip
	ChipResetxDO			  : out   std_logic;
	ChipPreChargexDO		  : out   std_logic;
	ChipRreadoutxDO			  : out   std_logic;
	ChipRowScanInitxDO		  : out   std_logic;
	ChipColScanInitxDO		  : out   std_logic;
	ChipClockRowScanxCO		  : out   std_logic;
	ChipClockColScanxCO		  : out   std_logic;
	
	ChipBLoutxDI 			: in  std_logic_vector(9 downto 0);
	ChipBLinxDO				: out std_logic_vector(9 downto 0);
    
    CDVSTestBiasEnablexEO : out std_logic;
    
	
	CDVSTestBiasDiagSelxSO : out std_logic;
	CDVSTestBiasBitOutxSI : in std_logic;

    
    -- control LED
    LED1xSO : out std_logic;
    LED2xSO : out std_logic;
    LED3xSO : out std_logic;
 
    DebugxSIO : inout std_logic_vector(15 downto 0)

    -- AER monitor interface
    --AERMonitorREQxABI    : in  std_logic;  -- needs synchronization
    --AERMonitorACKxSBO    : out std_logic;
    --AERMonitorAddressxDI : in  std_logic_vector(8 downto 0)
	);

end USBAER_top_level;

architecture Structural of USBAER_top_level is
  
  component fifoStatemachine
    port (
      ClockxCI                   : in  std_logic;
      ResetxRBI                  : in  std_logic;
	  RunxSI                     : in  std_logic;
      FifoTransactionxSO         : out std_logic;
      FX2FifoInFullxSBI          : in  std_logic;
      FifoEmptyxSI               : in  std_logic;
      FifoReadxEO                : out std_logic;
      FX2FifoWritexEBO           : out std_logic;
      FX2FifoPktEndxSBO          : out std_logic;
      FX2FifoAddressxDO          : out std_logic_vector(1 downto 0);
      IncEventCounterxSO         : out std_logic;
      ResetEventCounterxSO       : out std_logic;
      ResetEarlyPaketTimerxSO    : out std_logic;
      EarlyPaketTimerOverflowxSI : in  std_logic);
  end component;

  component shiftRegister
    generic (
      width : natural);
    port (
      ClockxCI   : in  std_logic;
      ResetxRBI  : in  std_logic;
      LatchxEI   : in  std_logic;
      DxDI       : in  std_logic;
      QxDO       : out std_logic;
      DataOutxDO : out std_logic_vector((width-1) downto 0));
  end component;
  
  component DigLogClock --replacing the clockgen
    port (
      CLK: in std_logic;
      RESET: in std_logic;
      CLKOP: out std_logic; 
      LOCK: out std_logic);
  end component;

  component OperationStateMachineABC
    port (
		ClockxCI              : in    std_logic;
		CheckxDI			  : in    std_logic;
		S0xDI				  : in    std_logic;
		S1xDI				  : in    std_logic;
		ResetxDO			  : out   std_logic;
		PreChargexDO		  : out   std_logic;
		ReadoutxDO			  : out   std_logic;
		RowScanInitxDO		  : out   std_logic;
		ColScanInitxDO		  : out   std_logic;
		ClockRowScanxCO		  : out   std_logic;
		ClockColScanxCO		  : out   std_logic;
		--fifo interface, adapting from monitorStateMachine
		-- fifo flags
		FifoFullxSI           : in  std_logic;
		-- fifo control lines
		FifoWritexEO          : out std_logic;
		
		-- log counter interface
		CounterResetxRBO		: out	std_logic;
		CounterIncrementxSO		: out	std_logic;
		
		-- FX2 interface to produce VREF
		VrefStatusxDO       : out    std_logic_vector(1 downto 0)
	);
  end component;
  
 
  
  component wordRegister
    generic (
      width          :     natural := 14);
    port (
      ClockxCI       : in  std_logic;
      ResetxRBI      : in  std_logic;
      WriteEnablexEI : in  std_logic;
      DataInxDI      : in  std_logic_vector(width-1 downto 0);
      DataOutxDO     : out std_logic_vector(width-1 downto 0));
  end component;

  
  component timestampCounter -- to be modified to be the log counter
    port (
      ClockxCI      : in  std_logic;
      ResetxRBI     : in  std_logic;
      IncrementxSI  : in  std_logic;
      OverflowxSO   : out std_logic;
      DataxDO       : out std_logic_vector(13 downto 0));
  end component;

  
  component AERfifo
    port (
      Data: in  std_logic_vector(9 downto 0); 
      WrClock: in  std_logic;
      RdClock: in  std_logic; 
      WrEn: in  std_logic;
      RdEn: in  std_logic;
      Reset: in  std_logic; 
      RPReset: in  std_logic;
      Q: out  std_logic_vector(9 downto 0); 
      Empty: out  std_logic;
      Full: out  std_logic; 
      AlmostEmpty: out  std_logic;
      AlmostFull: out  std_logic);
  end component;

  -- routing
  signal SyncInxAB : std_logic;

  signal UseLongAckxS : std_logic;
  
  -- communication between state machines

  signal IncEventCounterxS         : std_logic; --fifoSM
  signal ResetEventCounterxS       : std_logic; --fifoSM
  signal EarlyPaketTimerOverflowxS : std_logic; --fifoSM
  signal SMResetEarlyPaketTimerxS : std_logic; --fifoSM

  -- clock, reset
  signal ClockxC, IfClockxC             : std_logic;
  signal ResetxRB, ResetxR              : std_logic;
  signal RunxS : std_logic;
  signal CounterResetxRB               : std_logic;
  signal CDVSTestChipResetxRB : std_logic; 
  signal CDVSTestPeriodicChipResetxRB : std_logic;
  signal UseCDVSperiodicResetxS : std_logic;
  --signal RxcolGxS : std_logic;

  -- signals regarding the timestamp
  signal TimestampOverflowxS   : std_logic;
  signal AddressMSBxD          : std_logic_vector(1 downto 0);
  signal TimestampMasterxS     : std_logic;
  signal ActualTimestampxD		: std_logic_vector(9 downto 0);

  -- various
  signal FifoTransactionxS : std_logic;
  signal FX2FifoWritexEB : std_logic;
  signal FX2FifoPktEndxSB     : std_logic;
  signal SyncOutxSB        : std_logic;
  signal HostResetTimestampxS : std_logic;

  signal TriggerxS : std_logic;

  -- counter increment signal
  signal IncxS : std_logic;

  signal SRDataOutxD : std_logic_vector(2 downto 0);
   
  --signal ADCconfigxD : std_logic_vector(11 downto 0);
  signal SRoutxD, SRinxD, SRLatchxE, SRClockxC : std_logic;
  signal RunADCxS : std_logic;
  
  --signal ADCStateOutputLEDxS : std_logic;
  
  -- lock signal from PLL, unused so far
  signal LockxS : std_logic;

  -- fifo signals
  signal FifoDataInxD, FifoDataOutxD : std_logic_vector(9 downto 0);
  signal FifoWritexE, FifoReadxE : std_logic;
  signal FifoEmptyxS, FifoAlmostEmptyxS, FifoFullxS, FifoAlmostFullxS : std_logic;
  
  -- operationSM signals
  signal CheckxD				: std_logic;
  signal S0xD	 				: std_logic;
  signal S1xD					: std_logic;
  signal ChipResetxD			  :   std_logic;
  signal ChipPreChargexD		  :   std_logic;
  signal ChipRreadoutxD			  :   std_logic;
  signal ChipRowScanInitxD		  :   std_logic;
  signal ChipColScanInitxD		  :   std_logic;
  signal ChipClockRowScanxC		  :   std_logic;
  signal ChipClockColScanxC		  :   std_logic;
  
  signal VrefStatusxD				: std_logic_vector(1 downto 0);
  
  -- constants used for mux
  constant selectADC : std_logic_vector(1 downto 0) := "11";
  constant selectaddress   : std_logic_vector(1 downto 0) := "01";
  constant selecttimestamp : std_logic_vector(1 downto 0) := "00";
  constant selecttrigger : std_logic_vector(1 downto 0) := "10";
  
begin
  IfClockxC <= IfClockxCI;
  
  
  uClockGen : DigLogClock
    port map (
      CLK  =>  IFClockxCI,
      RESET=> ResetxR,
      CLKOP=> ClockxC,
      LOCK=>  LockxS);

  --ClockxC <= IFClockxCI;
  
  -- routing
  
  CDVSTestBiasDiagSelxSO <= PA0xSIO; 
  
  -- run the state machines either when reset is high or when in slave mode
  ResetxRB <= ResetxRBI;
  ResetxR <= not ResetxRBI;
  
  
  FX2FifoReadxEBO <= '1';

  SyncInxAB <= Sync1xABI;
  
  shiftRegister_1: shiftRegister
    generic map (
      width => 3)--?
    port map (
      ClockxCI   => SRClockxC,--to 8051
      ResetxRBI  => ResetxRB,
      LatchxEI   => SRLatchxE,
      DxDI       => SRinxD,
      QxDO       => SRoutxD,
      DataOutxDO => SRDataOutxD);

  CheckxD		<= SRDataOutxD(0);
  S0xD	 		<= SRDataOutxD(1);
  S1xD			<= SRDataOutxD(2);
    
  uFifo : AERfifo
    port map (
      Data(9 downto 0)=> FifoDataInxD,
      WrClock => ClockxC,
      RdClock => IfClockxC, --FX2
      WrEn=> FifoWritexE, 
      RdEn=> FifoReadxE,
      Reset => ChipResetxD, --? by FX2 or SM
      RPReset=> ChipResetxD,
      Q(9 downto 0)=>  FifoDataOutxD,
      Empty=> FifoEmptyxS, 
      Full=> FifoFullxS,
      AlmostEmpty=> FifoAlmostEmptyxS,
      AlmostFull=> FifoAlmostFullxS);

  FX2FifoDataxDIO <= FifoDataOutxD;
  
   
  uTimestampCounter : timestampCounter
    port map (
      ClockxCI      => ClockxC,
      ResetxRBI     => CounterResetxRB,
      IncrementxSI  => IncxS,
      OverflowxSO   => TimestampOverflowxS,
      DataxDO       => ActualTimestampxD);

	ChipBLinxDO <= ActualTimestampxD;

   TimestampMasterxS <= '1';
     
  fifoStatemachine_1: fifoStatemachine
    port map (
      ClockxCI                   => IfClockxC,
      ResetxRBI                  => ResetxRB,
	  RunxSI					 => RunxS,
      FifoTransactionxSO         => FifoTransactionxS,
      FX2FifoInFullxSBI          => FX2FifoInFullxSBI,
      FifoEmptyxSI               => FifoEmptyxS,
      FifoReadxEO                => FifoReadxE,
      FX2FifoWritexEBO           => FX2FifoWritexEB,
      FX2FifoPktEndxSBO          => FX2FifoPktEndxSB,
      FX2FifoAddressxDO          => FX2FifoAddressxDO,
      IncEventCounterxSO         => IncEventCounterxS,
      ResetEventCounterxSO       => ResetEventCounterxS,
      ResetEarlyPaketTimerxSO    => SMResetEarlyPaketTimerxS,
      EarlyPaketTimerOverflowxSI => EarlyPaketTimerOverflowxS);

  OperationStateMachine: OperationStateMachineABC
	port map (
		ClockxCI              	=> IfClockxC,
		CheckxDI			  	=> CheckxD,
		S0xDI				  	=> S0xD,
		S1xDI				  	=> S1xD,
		ResetxDO			  	=> ChipResetxD,
		PreChargexDO		  	=> ChipPreChargexD,
		ReadoutxDO			  	=> ChipRreadoutxD,
		RowScanInitxDO		  	=> ChipRowScanInitxD,
		ColScanInitxDO		  	=> ChipColScanInitxD,
		ClockRowScanxCO		  	=> ChipClockRowScanxC,
		ClockColScanxCO		  	=> ChipClockColScanxC,
		--fifo interface, adapting from monitorStateMachine
		-- fifo flags
		FifoFullxSI           	=> FifoFullxS,
		-- fifo control lines
		FifoWritexEO           	=> FifoWritexE,
	
		-- log counter interface
		CounterResetxRBO		=> CounterResetxRB,
		CounterIncrementxSO		=> IncxS,
		-- FX2 interface to produce VREF
		VrefStatusxDO       	=> VrefStatusxD
		);
  
	ChipResetxDO			  <= ChipResetxD;
	ChipPreChargexDO		  <= ChipPreChargexD;
	ChipRreadoutxDO			  <= ChipRreadoutxD;
	ChipRowScanInitxDO		  <= ChipRowScanInitxD;
	ChipColScanInitxDO		  <= ChipColScanInitxD;
	ChipClockRowScanxCO		  <= ChipClockRowScanxC;
	ChipClockColScanxCO		  <= ChipClockColScanxC;
	FX2VrefStatusxDO		  <= VrefStatusxD;
  
    
  
  SynchOutxSBO <= SyncOutxSB;
  FX2FifoPktEndxSBO <= FX2FifoPktEndxSB;
  FX2FifoWritexEBO <= FX2FifoWritexEB;
  
  -- reset early paket timer whenever a paket is sent (short or normal)
  --ResetEarlyPaketTimerxS <= (SMResetEarlyPaketTimerxS or ECResetEarlyPaketTimerxS);

  
    FifoDataInxD <= ChipBLoutxDI;--????
    
  LED1xSO <= CDVSTestChipResetxRB;
  LED2xSO <= RunxS;
  --LED3xSO <= ADCStateOutputLEDxS;

  

  CDVSTestBiasEnablexEO <= not PE2xSI;

  HostResetTimestampxS <= PA7xSIO;
  RunxS <= PA3xSIO;
  --ExtTriggerxE <= PA1xSIO;

  RunADCxS <= PC0xSIO;
  SRClockxC <= PC1xSIO;
  SRLatchxE <= PC2xSIO;
  SRinxD <= PC3xSIO;
  
  --RxcolGxS <= '0';
  
  --DebugxSIO(0) <= '0';
  --ExtTriggerxE <= DebugxSIO(2);
  --DebugxSIO(1) <= '1';
 -- DebugxSIO(0) <= FX2FifoInFullxSBI;
 -- DebugxSIO(7) <= FifoFullxS;
 --    DebugxSIO(1) <= ADCvalueReadyxS;
 --    DebugxSIO(6) <= ReadADCvaluexE;
  --DebugxSIO(7 downto 0) <= --???

  
  DebugxSIO(8) <= '0';
  UseCDVSperiodicResetxS <= DebugxSIO(9);
  DebugxSIO(10) <= '1';
  
  --DebugxSIO(11) <= TestPixelxE;
  --DebugxSIO(12) <= ADCbusyxS;
--  DebugxSIO(1 downto 0) <= ActualTimestampxD(2 downto 1);
--  DebugxSIO(7) <= FX2FifoWritexEB;
--  DebugxSIO(6) <= FX2FifoPktEndxSB;

  DebugxSIO(13) <= '0';
  UseLongAckxS <= DebugxSIO(14);  
  DebugxSIO(15) <= '1';
  
  -- DebugxSIO(8) <= CDVSTestBiasBitOutxSI;
 -- DebugxSIO(4) <= AERMonitorAddressxDI(8);

    -- purpose: synchronize asynchronous inputs
  -- type   : sequential
  -- inputs : ClockxCI
  -- outputs: 
  
end Structural;


