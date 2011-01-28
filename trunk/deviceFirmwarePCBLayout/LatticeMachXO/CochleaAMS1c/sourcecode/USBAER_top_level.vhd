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
    SyncInxAI   : in  std_logic;        -- needs synchronization
    SynchOutxSO : out std_logic;

    -- communication with 8051   
    PC0xSIO  : inout  std_logic;
    PC1xSIO  : inout  std_logic;
    PC2xSIO  : inout  std_logic;
    PC3xSIO  : inout  std_logic;

    PA0xSIO : inout std_logic;
    PA1xSIO : inout std_logic;
    PA3xSIO : inout std_logic;
    PA7xSIO : inout std_logic;

    PE2xSI : in std_logic;
    PE3xSI : in std_logic;

    FXLEDxSI : in std_logic;

    -- ADC
    ADCclockxCO : out std_logic;
    ADCwordxDIO : inout std_logic_vector(11 downto 0);
   
    ADCwritexEBO : out std_logic;
    ADCreadxEBO : out std_logic;
    ADCconvstxEBO : out std_logic;
    ADCbusyxSI: in std_logic;
   
    CDVSTestSRRowClockxSO: out std_logic;
    CDVSTestSRColClockxSO: out std_logic;
    CDVSTestSRRowInxSO: out std_logic;
    CDVSTestSRColInxSO: out std_logic;
    CDVSTestRefEnablexEO : out std_logic;
    
    CDVSTestPowerdownxEO : out std_logic;
    CDVSTestSel5TxSO : out std_logic;
    CDVSTestChipResetxRBO: out std_logic;
    
    -- control LED
    LED1xSO : out std_logic;
    LED2xSO : out std_logic;
    LED3xSO : out std_logic;
 
    DebugxSIO : inout std_logic_vector(7 downto 0);

    -- AER monitor interface
    AERMonitorREQxABI    : in  std_logic;  -- needs synchronization
    AERMonitorACKxSBO    : out std_logic;
    AERMonitorAddressxDI : in  std_logic_vector(8 downto 0));

end USBAER_top_level;

architecture Structural of USBAER_top_level is
  
  component fifoStatemachine
    port (
      ClockxCI                   : in  std_logic;
      ResetxRBI                  : in  std_logic;
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
      HostResetTimestampxSI : in  std_logic;
      SyncInxAI             : in  std_logic;
      SyncOutxSO            : out std_logic;
      MasterxSO             : out std_logic;
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
    AddressTimestampSelectxSO  : out std_logic_vector(1 downto 0);
    ADCvalueReadyxSI : in std_logic;
    ReadADCvaluexEO : out std_logic;
    TimestampOverflowxSI : in std_logic;
    AddressMSBxDO : out std_logic_vector(1 downto 0);
    ResetTimestampxSBI : in std_logic
    );
  end component;

  component ADCStateMachine
    port (
      ClockxCI              : in    std_logic;
      ADCclockxCO           : out   std_logic;
      ResetxRBI             : in    std_logic;
      ADCwordxDIO           : inout std_logic_vector(11 downto 0);
      ADCoutxDO             : out   std_logic_vector(13 downto 0);
      ADCwritexEBO          : out   std_logic;
      ADCreadxEBO           : out   std_logic;
      ADCconvstxEBO         : out   std_logic;
      ADCbusyxSI            : in    std_logic;
      RegisterWritexEO      : out   std_logic;
      SRLatchxEI            : in    std_logic;
      RunADCxSI             : in    std_logic;
      UseCalibrationxSI     : in    std_logic;
      ScanEnablexSI         : in    std_logic;
      ScanXxSI              : in    std_logic_vector(4 downto 0);
      ScanYxSI              : in    std_logic_vector(4 downto 0);
      ADCconfigxDI          : in    std_logic_vector(11 downto 0);
      TrackTimexDI          : in    std_logic_vector(15 downto 0);
      RefOnTimexDI          : in    std_logic_vector(15 downto 0);
      RefOffTimexDI         : in    std_logic_vector(15 downto 0);
      IdleTimexDI           : in    std_logic_vector(15 downto 0);
      CDVSTestSRRowInxSO    : out   std_logic;
      CDVSTestSRRowClockxSO : out   std_logic;
      CDVSTestSRColInxSO    : out   std_logic;
      CDVSTestSRColClockxSO : out   std_logic;
      CDVSTestRefEnablexEO  : out   std_logic);
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

  -- signal declarations
  signal MonitorTimestampxD                          : std_logic_vector(13 downto 0);
  signal ActualTimestampxD                           : std_logic_vector(13 downto 0);

  -- register write enables
  signal TimestampRegWritexE   : std_logic;
  
  signal SyncInxA : std_logic;

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
  signal UseCDVSperiodicResetxS : std_logic;
  signal RxcolGxS : std_logic;

  -- signals regarding the timestamp
  signal TimestampOverflowxS   : std_logic;
  signal AddressMSBxD          : std_logic_vector(1 downto 0);
  signal TimestampMasterxS     : std_logic;

  -- various
  signal FifoTransactionxS : std_logic;
  signal FX2FifoWritexEB : std_logic;
  signal FX2FifoPktEndxSB     : std_logic;
  signal SynchOutxS        : std_logic;
  signal HostResetTimestampxS : std_logic;

  -- counter increment signal
  signal IncxS : std_logic;

  -- ADC related signals
  signal ReadADCvaluexE, ADCvalueReadyxS : std_logic;
  signal ADCregInxD : std_logic_vector(13 downto 0);
  signal ADCregOutxD : std_logic_vector(13 downto 0);
  signal ADCregWritexE : std_logic;
  signal ADCdataxD : std_logic_vector(13 downto 0);

  signal ADCclockxC           : std_logic;
  signal ADCwritexEB          : std_logic;
  signal ADCreadxEB           : std_logic;
  signal ADCconvstxEB         : std_logic;
  signal ADCbusyxS            : std_logic;
  signal CDVSTestSRRowClockxS, CDVSTestSRRowInxS : std_logic;
  signal CDVSTestSRColClockxS, CDVSTestSRColInxS : std_logic;
  signal CDVSTestRefEnablexE  : std_logic;

  signal SRDataOutxD : std_logic_vector(90 downto 0);
  signal RefOnTimexD, RefOffTimexD : std_logic_vector(15 downto 0);  -- allows a max time of
  signal IdleTimexD, TrackTimexD : std_logic_vector(15 downto 0);    -- ca 3ms (adc state
                                                                     -- machine is clocked
                                                                     -- at 15MHz)
  signal UseCalibrationxS : std_logic;
  signal ADCconfigxD : std_logic_vector(11 downto 0);
  signal SRoutxD, SRinxD, SRLatchxE, SRClockxC : std_logic;
  signal RunADCxS : std_logic;
  signal CDVSTestSel5TxS : std_logic;

  signal ScanEnablexS : std_logic;            -- whether scanner should run continously or we take ADC values from a single pixel
  signal ScanXxS, ScanYxS : std_logic_vector(4 downto 0);
  
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
  
  -- run the state machines either when reset is high or when in slave mode
  ResetxRB <= ResetxRBI;
  ResetxR <= not ResetxRBI;
  CounterResetxRB <= SynchronizerResetTimestampxSB;
  
  FX2FifoReadxEBO <= '1';

  SyncInxA <= not SyncInxAI;
  
  shiftRegister_1: shiftRegister
    generic map (
      width => 91)
    port map (
      ClockxCI   => SRClockxC,
      ResetxRBI  => ResetxRB,
      LatchxEI   => SRLatchxE,
      DxDI       => SRinxD,
      QxDO       => SRoutxD,
      DataOutxDO => SRDataOutxD);

  CDVSTestSel5TxS <= SRDataOutxD(0);
  UseCalibrationxS <= SRDataOutxD(1);
  ADCconfigxD <= SRDataOutxD(13 downto 2);
  TrackTimexD <= SRDataOutxD(29 downto 14);
  RefOnTimexD <= SRDataOutxD(45 downto 30);
  RefOffTimexD <= SRDataOutxD(61 downto 46);
  IdleTimexD <= SRDataOutxD(77 downto 62);
  ScanYxS <= SRDataOutxD(82 downto 78);
  ScanXxS <= SRDataOutxD(88 downto 84);
  ScanEnablexS <= SRDataOutxD(90);
  
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

  uSyncStateMachine : synchronizerStateMachine
    port map (
      ClockxCI              => ClockxC,
      ResetxRBI             => ResetxRB,
      RunxSI             => RunxS,
      HostResetTimestampxSI => HostResetTimestampxS,
      SyncInxAI             => SyncInxA,
      SyncOutxSO            => SynchOutxS,
      MasterxSO             => TimestampMasterxS,
      ResetTimestampxSBO    => SynchronizerResetTimestampxSB,
      IncrementCounterxSO   => IncxS);

  fifoStatemachine_1: fifoStatemachine
    port map (
      ClockxCI                   => IfClockxC,
      ResetxRBI                  => ResetxRB,
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
      XxDI                      => AERMonitorAddressxDI(8),
      UseLongAckxSI             => UseLongAckxS,
      FifoFullxSI               => FifoFullxS,
      FifoWritexEO              => FifoWritexE,
      TimestampRegWritexEO      => TimestampRegWritexE,
      AddressTimestampSelectxSO => AddressTimestampSelectxS,
      ADCvalueReadyxSI => ADCvalueReadyxS,
      ReadADCvaluexEO => ReadADCvaluexE,
      TimestampOverflowxSI      => TimestampOverflowxS,
      AddressMSBxDO             => AddressMSBxD,
      ResetTimestampxSBI        => SynchronizerResetTimestampxSB);
  
  ADCStateMachine_2: ADCStateMachine
    port map (
      ClockxCI              => IfClockxC,
      ADCclockxCO           => ADCclockxC,
      ResetxRBI             => ResetxRB,
      ADCwordxDIO           => ADCwordxDIO,
      ADCoutxDO             => ADCdataxD,
      ADCwritexEBO          => ADCwritexEB,
      ADCreadxEBO           => ADCreadxEB,
      ADCconvstxEBO         => ADCconvstxEB,
      ADCbusyxSI            => ADCbusyxS,
      RegisterWritexEO      => ADCregWritexE,
      SRLatchxEI            => SRLatchxE,
      RunADCxSI             => RunADCxS,
      UseCalibrationxSI     => UseCalibrationxS,
      ScanEnablexSI         => ScanEnablexS,
      ScanXxSI              => ScanXxS,
      ScanYxSI              => ScanYxS,
      ADCconfigxDI           => ADCconfigxD,
      TrackTimexDI           => TrackTimexD,
      RefOnTimexDI           => RefOnTimexD,
      RefOffTimexDI          => RefOffTimexD,
      IdleTimexDI            => IdleTimexD,
      CDVSTestSRRowInxSO    => CDVSTestSRRowInxS,
      CDVSTestSRRowClockxSO => CDVSTestSRRowClockxS,
      CDVSTestSRColInxSO    => CDVSTestSRColInxS,
      CDVSTestSRColClockxSO => CDVSTestSRColClockxS,
      CDVSTestRefEnablexEO  => CDVSTestRefEnablexE);
  
  ADCbusyxS <= ADCbusyxSI;

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
  
  SynchOutxSO <= SynchOutxS;
  FX2FifoPktEndxSBO <= FX2FifoPktEndxSB;
  FX2FifoWritexEBO <= FX2FifoWritexEB;
  AERMonitorACKxSBO <= AERMonitorACKxSB;

  -- reset early paket timer whenever a paket is sent (short or normal)
  ResetEarlyPaketTimerxS <= (SMResetEarlyPaketTimerxS or ECResetEarlyPaketTimerxS);

  -- mux to select how to drive datalines
  with AddressTimestampSelectxS select
    FifoDataInxD <=
    AddressMSBxD & "00000" & AERMonitorAddressxDI   when selectaddress,
    AddressMSBxD & MonitorTimestampxD when selecttimestamp,
    AddressMSBxD & ADCregOutxD when others;

  LED1xSO <= CDVSTestChipResetxRB;
  LED2xSO <= RunxS;
  LED3xSO <= FXLEDxSI;

  CDVSTestChipResetxRBO <= CDVSTestChipResetxRB;
  with UseCDVSperiodicResetxS select
    CDVSTestChipResetxRB <=
    PE3xSI when '0',
    CDVSTestPeriodicChipResetxRB when others;
  
  --CDVSTestChipResetxRBO <= PE3xSI;
  --CDVSTestChipResetxRBO <= CDVSTestChipResetxRB;

  CDVSTestPowerdownxEO <= PE2xSI;

  HostResetTimestampxS <= PA7xSIO;
  RunxS <= PA3xSIO or not TimestampMasterxS;
  PA1xSIO <= TimestampMasterxS;

  RunADCxS <= PC0xSIO;
  SRClockxC <= PC1xSIO;
  SRLatchxE <= PC2xSIO;
  SRinxD <= PC3xSIO;

  CDVSTestSRColClockxSO <= CDVSTestSRColClockxS;
  CDVSTestSRRowClockxSO <= CDVSTestSRRowClockxS;
  CDVSTestSRColInxSO <= CDVSTestSRColInxS;
  CDVSTestSRRowInxSO <= CDVSTestSRRowInxS;
  CDVSTestRefEnablexEO <= CDVSTestRefEnablexE;

  CDVSTestSel5TxSO <= CDVSTestSel5TxS;

  ADCconvstxEBO <= ADCconvstxEB;
  ADCreadxEBO <= ADCreadxEB;
  ADCwritexEBO <= ADCwritexEB;

  UseCDVSperiodicResetxS <= DebugxSIO(1);
  RxcolGxS <= '0';
  DebugxSIO(3) <= ADCconvstxEB;
  DebugxSIO(0) <= '0';
  DebugxSIO(2) <= '1';
  DebugxSIO(4) <= ADCbusyxS;
--  DebugxSIO(1 downto 0) <= ActualTimestampxD(2 downto 1);
--  DebugxSIO(7) <= FX2FifoWritexEB;
--  DebugxSIO(6) <= FX2FifoPktEndxSB;
  DebugxSIO(5) <= SRLatchxE;
  UseLongAckxS <= '0';
    
  DebugxSIO(7) <= UseCalibrationxS;
  DebugxSIO(6) <= CDVSTestSel5TxS;
 -- DebugxSIO(4) <= AERMonitorAddressxDI(8);

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


