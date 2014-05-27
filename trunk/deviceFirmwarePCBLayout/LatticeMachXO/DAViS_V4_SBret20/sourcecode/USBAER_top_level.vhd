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
    FX2FifoDataxDIO         : out std_logic_vector(15 downto 0);
    FX2FifoInFullxSBI       : in    std_logic;
    FX2FifoWritexEBO        : out   std_logic;
    FX2FifoReadxEBO         : out   std_logic;
  
    FX2FifoPktEndxSBO       : out   std_logic;
    FX2FifoAddressxDO       : out   std_logic_vector(1 downto 0);

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

    -- ADC
    ADCclockxCO : out std_logic;
    ADCwordxDI : in std_logic_vector(9 downto 0);
   
    ADCoexEBO : out std_logic;
    ADCstbyxEO : out std_logic;	
	ADCovrxSI : in std_logic;
   
    CDVSTestSRRowClockxSO: out std_logic;
    CDVSTestSRColClockxSO: out std_logic;
    CDVSTestSRRowInxSO: out std_logic;
    CDVSTestSRColInxSO: out std_logic;
    
    CDVSTestBiasEnablexEO : out std_logic;
    CDVSTestChipResetxRBO: out std_logic;
	
	CDVSTestColMode0xSO : out std_logic;
	CDVSTestColMode1xSO : out std_logic;
	
	CDVSTestBiasDiagSelxSO : out std_logic;
	CDVSTestBiasBitOutxSI : in std_logic;

	CDVSTestApsTxGatexSO : out std_logic;
    
    -- control LED
    LED1xSO : out std_logic;
    LED2xSO : out std_logic;
    LED3xSO : out std_logic;
 
    DebugxSIO : inout std_logic_vector(15 downto 0);

    -- AER monitor interface
    AERMonitorREQxABI    : in  std_logic;  -- needs synchronization
    AERMonitorACKxSBO    : out std_logic;
    AERMonitorAddressxDI : in  std_logic_vector(9 downto 0));

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
  
  component clockgen
    port (
      CLK: in std_logic;
      RESET: in std_logic;
      CLKOP: out std_logic; 
      LOCK: out std_logic);
  end component;

  component cDVSResetStateMachine
    port (
      ClockxCI      : in  std_logic;
      ResetxRBI     : in  std_logic;
      AERackxSBI    : in  std_logic;
      RxcolGxSI     : in  std_logic;
      cDVSresetxRBI : in  std_logic;
      CDVSresetxRBO : out std_logic);
  end component;
  
   component synchronizerStateMachine
     port (
       ClockxCI              : in  std_logic;
       ResetxRBI             : in  std_logic;
       RunxSI                : in  std_logic;
       ConfigxSI             : in  std_logic;
       SyncInxABI            : in  std_logic;
       SyncOutxSBO           : out std_logic;
       TriggerxSO            : out std_logic;
       HostResetTimestampxSI : in  std_logic;
       ResetTimestampxSBO    : out std_logic;
       IncrementCounterxSO   : out std_logic);
   end component;                                       

  component monitorStateMachine
    port (
    ClockxCI               : in  std_logic;
    ResetxRBI              : in  std_logic;
    AERREQxSBI     : in  std_logic;
    AERACKxSBO     : out std_logic;
    XxDI        : in std_logic;
    UseLongAckxSI        : in std_logic;
    FifoFullxSI         : in  std_logic;
    FifoWritexEO          : out std_logic;
    TimestampRegWritexEO     : out std_logic;
    AddressRegWritexEO       : out std_logic;
    AddressTimestampSelectxSO  : out std_logic_vector(1 downto 0);
    ADCvalueReadyxSI : in std_logic;
    ReadADCvaluexEO : out std_logic;
    TimestampOverflowxSI : in std_logic;
    TriggerxSI : in std_logic;
    AddressMSBxDO : out std_logic_vector(1 downto 0);
    ResetTimestampxSBI : in std_logic
    );
  end component;

  component ADCStateMachine
    port (
		ClockxCI              : in    std_logic;
		ADCclockxCO           : out   std_logic;
		ResetxRBI             : in    std_logic;
		ADCwordxDI            : in    std_logic_vector(9 downto 0);
		ADCoutxDO             : out   std_logic_vector(13 downto 0);
		ADCoexEBO	          : out   std_logic;
		ADCstbyxEO            : out   std_logic;
		ADCovrxSI			  : in	  std_logic;
		RegisterWritexEO      : out   std_logic;
		SRLatchxEI            : in    std_logic;
		RunADCxSI             : in    std_logic;
		ExposurexDI          : in    std_logic_vector(15 downto 0);
		ColSettlexDI          : in    std_logic_vector(15 downto 0);
		RowSettlexDI          : in    std_logic_vector(15 downto 0);
		ResSettlexDI          : in    std_logic_vector(15 downto 0);
		FramePeriodxDI		  : in    std_logic_vector(15 downto 0);
		ExtTriggerxEI		  : in    std_logic;
		CDVSTestSRRowInxSO    : out   std_logic;
		CDVSTestSRRowClockxSO : out   std_logic;
		CDVSTestSRColInxSO    : out   std_logic;
		CDVSTestSRColClockxSO : out   std_logic;
		CDVSTestColMode0xSO   : out   std_logic;
		CDVSTestColMode1xSO   : out   std_logic;
		CDVSTestApsTxGatexSO  : out   std_logic;
		ADCStateOutputLEDxSO  : out	  std_logic);
  end component;
  
  component ADCvalueReady
    port (
      ClockxCI         : in  std_logic;
      ResetxRBI        : in  std_logic;
      RegisterWritexEI : in  std_logic;
      ReadValuexEI     : in  std_logic;
      ValueReadyxSO    : out std_logic);
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

  component eventCounter
    port (
      ClockxCI     : in  std_logic;
      ResetxRBI    : in  std_logic;
      ClearxSI     : in  std_logic;
      IncrementxSI : in  std_logic;
      OverflowxSO  : out std_logic);
  end component;

  component timestampCounter
    port (
      ClockxCI      : in  std_logic;
      ResetxRBI     : in  std_logic;
      IncrementxSI  : in  std_logic;
      OverflowxSO   : out std_logic;
      DataxDO       : out std_logic_vector(13 downto 0));
  end component;

  component earlyPaketTimer
    port (
      ClockxCI        : in  std_logic;
      ResetxRBI       : in  std_logic;
      ClearxSI        : in  std_logic;
      TimerExpiredxSO : out std_logic);
  end component;

  component AERfifo
    port (
      Data: in  std_logic_vector(15 downto 0); 
      WrClock: in  std_logic;
      RdClock: in  std_logic; 
      WrEn: in  std_logic;
      RdEn: in  std_logic;
      Reset: in  std_logic; 
      RPReset: in  std_logic;
      Q: out  std_logic_vector(15 downto 0); 
      Empty: out  std_logic;
      Full: out  std_logic; 
      AlmostEmpty: out  std_logic;
      AlmostFull: out  std_logic);
  end component;

  -- routing
  -- signal CDVSTestBiasDiagSelxS 	: std_logic;

  -- signal declarations
  signal MonitorTimestampxD                          : std_logic_vector(13 downto 0);
  signal ActualTimestampxD                           : std_logic_vector(13 downto 0);

  -- register write enables
  signal TimestampRegWritexE   : std_logic;
  
  signal SyncInxAB : std_logic;

  signal AERREQxSB, AERReqSyncxSBN  : std_logic;

  signal AERMonitorACKxSB : std_logic;
  signal UseLongAckxS : std_logic;
  
  -- mux control signals
  signal AddressTimestampSelectxS : std_logic_vector(1 downto 0);

  -- communication between state machines
--  signal SetMonitorEventReadyxS    : std_logic;
--  signal ClearMonitorEventxS       : std_logic;
--  signal MonitorEventReadyxS       : std_logic;
  signal IncEventCounterxS         : std_logic;
  signal ResetEventCounterxS       : std_logic;
  signal ResetEarlyPaketTimerxS    : std_logic;
  signal EarlyPaketTimerOverflowxS : std_logic;
  signal SMResetEarlyPaketTimerxS : std_logic;
  signal ECResetEarlyPaketTimerxS : std_logic;

  -- clock, reset
  signal ClockxC, IfClockxC             : std_logic;
  signal ResetxRB, ResetxR              : std_logic;
  signal RunxS : std_logic;
  signal CounterResetxRB               : std_logic;
  signal SynchronizerResetTimestampxSB : std_logic;
  signal CDVSTestChipResetxRB : std_logic; 
  signal CDVSTestPeriodicChipResetxRB : std_logic;
  signal RxcolGxS : std_logic;

  -- signals regarding the timestamp
  signal TimestampOverflowxS   : std_logic;
  signal AddressMSBxD          : std_logic_vector(1 downto 0);
  signal TimestampMasterxS     : std_logic;

  -- various
  signal FifoTransactionxS : std_logic;
  signal FX2FifoWritexEB : std_logic;
  signal FX2FifoPktEndxSB     : std_logic;
  signal SyncOutxSB        : std_logic;
  signal HostResetTimestampxS : std_logic;

  signal TriggerxS : std_logic;

  signal AddressRegOutxD : std_logic_vector(9 downto 0);
  signal AddressRegWritexE : std_logic;
  signal AddressRegOut8xD : std_logic;

  -- counter increment signal
  signal IncxS : std_logic;

  -- ADC related signals
  signal ReadADCvaluexE, ADCvalueReadyxS : std_logic;
  signal ADCregInxD : std_logic_vector(13 downto 0);
  signal ADCregOutxD : std_logic_vector(13 downto 0);
  signal ADCregWritexE : std_logic;
  signal ADCdataxD : std_logic_vector(13 downto 0);
  
  signal ADCsmRstxE           : std_logic;
  signal ADCclockxC           : std_logic;
  signal ADCoexEB	          : std_logic;
  signal ADCstbyxE            : std_logic;
  signal ADCovrxS			  : std_logic;
  signal CDVSTestSRRowClockxS, CDVSTestSRRowInxS : std_logic;
  signal CDVSTestSRColClockxS, CDVSTestSRColInxS : std_logic;
  signal CDVSTestColMode0xS, CDVSTestColMode1xS : std_logic;
  signal CDVSTestApsTxGatexS  : std_logic;
  signal CDVSTestBiasBitOutxS : std_logic;
  signal ExtTriggerxE				: std_logic;
  
  signal SRDataOutxD : std_logic_vector(79 downto 0);
  
  signal ExposurexD, ColSettlexD, RowSettlexD, ResSettlexD : std_logic_vector(15 downto 0); 
  signal FramePeriodxD : std_logic_vector(15 downto 0); 
  
  signal SRoutxD, SRinxD, SRLatchxE, SRClockxC : std_logic;
  signal RunADCxS : std_logic;
  
  signal ADCStateOutputLEDxS : std_logic;
  
  -- lock signal from PLL, unused so far
  signal LockxS : std_logic;

  -- fifo signals
  signal FifoDataInxD, FifoDataOutxD : std_logic_vector(15 downto 0);
  signal FifoWritexE, FifoReadxE : std_logic;
  signal FifoEmptyxS, FifoAlmostEmptyxS, FifoFullxS, FifoAlmostFullxS : std_logic;
  
  -- constants used for mux
  constant selectADC : std_logic_vector(1 downto 0) := "11";
  constant selectaddress   : std_logic_vector(1 downto 0) := "01";
  constant selecttimestamp : std_logic_vector(1 downto 0) := "00";
  constant selecttrigger : std_logic_vector(1 downto 0) := "10";
  
begin
  IfClockxC <= IfClockxCI;
  ADCclockxCO <= ADCclockxC;
  
  uClockGen : clockgen
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
  CounterResetxRB <= SynchronizerResetTimestampxSB;
  
  FX2FifoReadxEBO <= '1';

  SyncInxAB <= Sync1xABI;
  
  shiftRegister_1: shiftRegister
    generic map (
      width => 80)
    port map (
      ClockxCI   => SRClockxC,
      ResetxRBI  => ResetxRB,
      LatchxEI   => SRLatchxE,
      DxDI       => SRinxD,
      QxDO       => SRoutxD,
      DataOutxDO => SRDataOutxD);

  ExposurexD <= SRDataOutxD(15 downto 0);
  ColSettlexD <= SRDataOutxD(31 downto 16);
  RowSettlexD <= SRDataOutxD(47 downto 32);
  ResSettlexD <= SRDataOutxD(63 downto 48);
  FramePeriodxD <= SRDataOutxD(79 downto 64);
  
  uFifo : AERfifo
    port map (
      Data(15 downto 0)=> FifoDataInxD,
      WrClock => ClockxC,
      RdClock => IfClockxC,
      WrEn=> FifoWritexE, 
      RdEn=> FifoReadxE,
      Reset => ResetxR,
      RPReset=> ResetxR,
      Q(15 downto 0)=>  FifoDataOutxD,
      Empty=> FifoEmptyxS, 
      Full=> FifoFullxS,
      AlmostEmpty=> FifoAlmostEmptyxS,
      AlmostFull=> FifoAlmostFullxS);

  FX2FifoDataxDIO <= FifoDataOutxD;

  uMonitorAddressRegister : wordRegister
    generic map (
      width          => 10)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => AddressRegWritexE,
      DataInxDI      => AERMonitorAddressxDI,
      DataOutxDO     => AddressRegOutxD);
  
  uMonitorTimestampRegister : wordRegister
    generic map (
      width          => 14)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => TimestampRegWritexE,
      DataInxDI      => ActualTimestampxD,
      DataOutxDO     => MonitorTimestampxD);

  uADCRegister : wordRegister
    generic map (
      width          => 14)
    port map (
      ClockxCI       => IfClockxC,
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => ADCregWritexE,
      DataInxDI      => ADCregInxD,
      DataOutxDO     => ADCregOutxD);

  ADCregInxD <= ADCdataxD;
  
  uEarlyPaketTimer : earlyPaketTimer
    port map (
      ClockxCI        => ClockxC,
      ResetxRBI       => ResetxRB,
      ClearxSI        => ResetEarlyPaketTimerxS,
      TimerExpiredxSO => EarlyPaketTimerOverflowxS);

  uEventCounter : eventCounter
    port map (
      ClockxCI     => ClockxC,
      ResetxRBI    => ResetxRB,
      ClearxSI     => ResetEventCounterxS,
      IncrementxSI => IncEventCounterxS,
      OverflowxSO  => ECResetEarlyPaketTimerxS);

  uTimestampCounter : timestampCounter
    port map (
      ClockxCI      => ClockxC,
      ResetxRBI     => CounterResetxRB,
      IncrementxSI  => IncxS,
      OverflowxSO   => TimestampOverflowxS,
      DataxDO       => ActualTimestampxD);

  uSynchronizerStateMachine_1: synchronizerStateMachine
    port map (
      ClockxCI              => ClockxC,
      ResetxRBI             => ResetxRB,
      RunxSI                => RunxS,
      ConfigxSI             => TimestampMasterxS,
      SyncInxABI            => SyncInxAB,
      SyncOutxSBO           => SyncOutxSB,
      TriggerxSO            => TriggerxS,
      HostResetTimestampxSI => HostResetTimestampxS,
      ResetTimestampxSBO    => SynchronizerResetTimestampxSB,
      IncrementCounterxSO   => IncxS);

   TimestampMasterxS <= '1'; --PA1xSIO; Timestampmaster is disabled solving timestamp gets stacked.
     
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

  monitorStateMachine_1: monitorStateMachine
    port map (
      ClockxCI                  => ClockxC,
      ResetxRBI                 => ResetxRB,
      AERREQxSBI                => AERREQxSB,
      AERACKxSBO                => AERMonitorACKxSB,
      XxDI                      => AERMonitorAddressxDI(9),
      UseLongAckxSI             => UseLongAckxS,
      FifoFullxSI               => FifoFullxS,
      FifoWritexEO              => FifoWritexE,
      TimestampRegWritexEO      => TimestampRegWritexE,
      AddressRegWritexEO => AddressRegWritexE,
      AddressTimestampSelectxSO => AddressTimestampSelectxS,
      ADCvalueReadyxSI => ADCvalueReadyxS,
      ReadADCvaluexEO => ReadADCvaluexE,
      TimestampOverflowxSI      => TimestampOverflowxS,
      TriggerxSI => TriggerxS,
      AddressMSBxDO             => AddressMSBxD,
      ResetTimestampxSBI        => SynchronizerResetTimestampxSB);
  
  ADCStateMachine_1: ADCStateMachine
    port map (
      ClockxCI              => IfClockxC,
      ADCclockxCO           => ADCclockxC,
      ResetxRBI             => ADCsmRstxE,
      ADCwordxDI           	=> ADCwordxDI,
      ADCoutxDO             => ADCdataxD,
      ADCoexEBO          	=> ADCoexEB,
      ADCstbyxEO           	=> ADCstbyxE,
	  ADCovrxSI				=> ADCovrxS,
      RegisterWritexEO      => ADCregWritexE,
      SRLatchxEI            => SRLatchxE,
      RunADCxSI             => RunADCxS,
	  ExposurexDI          => ExposurexD,
	  ColSettlexDI          => ColSettlexD,
	  RowSettlexDI          => RowSettlexD,
	  ResSettlexDI          => ResSettlexD,
	  FramePeriodxDI		=> FramePeriodxD,
	  ExtTriggerxEI			=> ExtTriggerxE,
	  CDVSTestSRRowInxSO    => CDVSTestSRRowInxS,
      CDVSTestSRRowClockxSO => CDVSTestSRRowClockxS,
      CDVSTestSRColInxSO    => CDVSTestSRColInxS,
      CDVSTestSRColClockxSO => CDVSTestSRColClockxS,
	  CDVSTestColMode0xSO   => CDVSTestColMode0xS,
	  CDVSTestColMode1xSO   => CDVSTestColMode1xS,
	  CDVSTestApsTxGatexSO   => CDVSTestApsTxGatexS,
	  ADCStateOutputLEDxSO  => ADCStateOutputLEDxS
	  );
  
  ADCovrxS	<= ADCovrxSI;
  ADCsmRstxE <= ResetxRB and RunxS;

  ADCvalueReady_1: ADCvalueReady
    port map (
      ClockxCI         => ClockxC,
      ResetxRBI        => ResetxRB,
      RegisterWritexEI => ADCregWritexE,
      ReadValuexEI     => ReadADCvaluexE,
      ValueReadyxSO    => ADCvalueReadyxS);

  cDVSResetStateMachine_1: cDVSResetStateMachine
    port map (
      ClockxCI      => ClockxC,
      ResetxRBI     => ResetxRB,
      AERackxSBI    => AERREQxSB,
      RxcolGxSI => RxcolGxS,
      cDVSresetxRBI => PE3xSI,
      CDVSresetxRBO => CDVSTestPeriodicChipResetxRB);
  
  SynchOutxSBO <= SyncOutxSB;
  FX2FifoPktEndxSBO <= FX2FifoPktEndxSB;
  FX2FifoWritexEBO <= FX2FifoWritexEB;
  AERMonitorACKxSBO <= AERMonitorACKxSB;

  -- reset early paket timer whenever a paket is sent (short or normal)
  ResetEarlyPaketTimerxS <= (SMResetEarlyPaketTimerxS or ECResetEarlyPaketTimerxS);

  -- mux to select how to drive dataline 8
  
  with AddressRegOutxD(9) select
    AddressRegOut8xD <=
	'0' when '0',
	AddressRegOutxD(8) when '1',
	'0' when others;

  -- mux to select how to drive datalines
  with AddressTimestampSelectxS select
    FifoDataInxD <=
    AddressMSBxD & "00" & AddressRegOutxD(9) & "00" & AddressRegOut8xD & AddressRegOutxD(7 downto 0) when selectaddress, -- hack to put the xbit at bit position 11 (which allows addresses up to 10 bits)
    AddressMSBxD & MonitorTimestampxD when selecttimestamp,
    AddressMSBxD & "01000000000000" when selecttrigger,                                    
    AddressMSBxD & ADCregOutxD when others;

  LED1xSO <= CDVSTestChipResetxRB;
  LED2xSO <= RunxS;
  LED3xSO <= ADCStateOutputLEDxS;
  --LED3xSO <= ExtTriggerxE;

  CDVSTestChipResetxRBO <= CDVSTestChipResetxRB;
  CDVSTestChipResetxRB <= PE3xSI;
  
  --CDVSTestChipResetxRBO <= PE3xSI;
  --CDVSTestChipResetxRBO <= CDVSTestChipResetxRB;

  CDVSTestBiasEnablexEO <= not PE2xSI;

  HostResetTimestampxS <= PA7xSIO;
  RunxS <= PA3xSIO;
  ExtTriggerxE <= '0'; --PA1xSIO; ExtTrigger is disabled solving timestamp gets stacked.

  RunADCxS <= PC0xSIO;
  SRClockxC <= PC1xSIO;
  SRLatchxE <= PC2xSIO;
  SRinxD <= PC3xSIO;

  CDVSTestSRColClockxSO <= CDVSTestSRColClockxS;
  CDVSTestSRRowClockxSO <= CDVSTestSRRowClockxS;
  CDVSTestSRColInxSO <= CDVSTestSRColInxS;
  CDVSTestSRRowInxSO <= CDVSTestSRRowInxS;

  CDVSTestColMode0xSO <= CDVSTestColMode0xS;
  CDVSTestColMode1xSO <= CDVSTestColMode1xS;

  CDVSTestApsTxGatexSO <= CDVSTestApsTxGatexS;
  
  CDVSTestBiasBitOutxS <= CDVSTestBiasBitOutxSI;

  ADCstbyxEO <= ADCstbyxE;
  ADCoexEBO <= ADCoexEB;

  
  RxcolGxS <= '0';
  UseLongAckxS <= '0';

--  DebugxSIO(13) <= '0';
--  UseLongAckxS <= DebugxSIO(14);  
--  DebugxSIO(15) <= '1';
  
  DebugxSIO(0) <= CDVSTestBiasBitOutxS;
  
    -- purpose: synchronize asynchronous inputs
  -- type   : sequential
  -- inputs : ClockxCI
  -- outputs: 
  synchronizer : process (ClockxC)
  begin
    if ClockxC'event and ClockxC = '1' then 
      AERREQxSB         <= AERReqSyncxSBN;
      AERReqSyncxSBN <= AERMonitorREQxABI;
    end if;
  end process synchronizer;
end Structural;


