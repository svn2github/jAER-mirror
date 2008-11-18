--------------------------------------------------------------------------------
-- Company: Universidad de Sevilla
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
    FifoDataxDIO         : inout std_logic_vector(15 downto 0);
    FifoInFullxSBI       : in    std_logic;
    FifoOutEmptyxSBI     : in    std_logic;
    FifoWritexEBO        : out   std_logic;
    FifoReadxEBO         : out   std_logic;
    FifoOutputEnablexEBO : out   std_logic;
    FifoPktEndxSBO       : out   std_logic;
    FifoAddressxDO       : out   std_logic_vector(1 downto 0);

    -- clock and reset inputs
    ClockxCI  : in std_logic;
    ResetxRBI : in std_logic;

    -- ports to synchronize other USBAER boards
    SyncInxAI   : in  std_logic;        -- needs synchronization
    SynchOutxSO : out std_logic;

    -- communication with 8051
    RunMonitorxSI         : in  std_logic;
    RunSynthesizerxSI     : in  std_logic;
    TimestampTickxSI      : in  std_logic;
    TriggerModexSI        : in  std_logic;
    TimestampMasterxSO    : out std_logic;
    HostResetTimestampxSI : in  std_logic;
    Interrupt0xSB0        : out std_logic;
    Interrupt1xSB0        : out std_logic;
    MissEventsEnabledxEI                : in  std_logic;                     -- unused
    PExDI                 : in  std_logic_vector(3 downto 0);  -- unused
    PC1xSI : in std_logic;

    -- control LED
    LEDxSO : out std_logic;

    -- AER monitor interface
    AERMonitorREQxABI    : in  std_logic;  -- needs synchronization
    AERMonitorACKxSBO    : out std_logic;
    AERMonitorAddressxDI : in  std_logic_vector(15 downto 0);

    -- AER pass-through interface
    AERSnifACKxABI : in  std_logic;     -- needs synchronization
    AERSnifREQxSBO : out std_logic;

    -- AER sequencer interface
    AERSynthREQxSBO    : out std_logic;
    AERSynthACKxABI    : in  std_logic;  -- needs synchronization
    AERSynthAddressxDO : out std_logic_vector(15 downto 0));
end USBAER_top_level;

architecture Structural of USBAER_top_level is
  component fifoStateMachine
    port (
      ClockxCI                   : in  std_logic;
      ResetxRBI                  : in  std_logic;
      FifoTransactionxSO         : out std_logic;
      FifoInFullxSBI             : in  std_logic;
      FifoOutEmptyxSBI           : in  std_logic;
      FifoWritexEBO              : out std_logic;
      FifoReadxEBO               : out std_logic;
      FifoOutputEnablexEBO       : out std_logic;
      FifoPktEndxSBO             : out std_logic;
      FifoAddressxDO             : out std_logic_vector(1 downto 0);
      AddressRegWritexEO         : out std_logic;
      TimestampRegWritexEO       : out std_logic;
      RegisterInputSelectxSO     : out std_logic;
      AddressTimestampSelectxSO  : out std_logic_vector(1 downto 0);
      MonitorEventReadyxSI       : in  std_logic;
      ClearMonitorEventxSO       : out std_logic;
      EventRequestxSI            : in  std_logic;
      EventRequestACKxSO         : out std_logic;
      IncEventCounterxSO         : out std_logic;
      ResetEventCounterxSO       : out std_logic;
      TimestampOverflowxSI       : in  std_logic;
      TimestampBit15xDO          : out std_logic;
      ResetTimestampxSBI          : in std_logic;
      TimestampBit14xDO          : out std_logic;
      PaketSentxSI : in  std_logic);
  end component;

  component sequencerCounter
    port (
      ClockxCI     : in  std_logic;
      ResetxRBI    : in  std_logic;
      SyncResetxRBI    : in  std_logic;
      IncrementxSI : in  std_logic;
      DataxDO      : out std_logic_vector(16 downto 0));
  end component;
  
  component synchronizerStateMachine
    port (
      ClockxCI              : in  std_logic;
      ResetxRBI             : in  std_logic;
      RunxSI                : in  std_logic;
      ConfigxSI             : in  std_logic;
      HostResetTimestampxSI : in  std_logic;
      SyncInxAI             : in  std_logic;
      SyncOutxSO            : out std_logic;
      MasterxSO             : out std_logic;
      ResetTimestampxSBO    : out std_logic;
      IncrementCounterxSO   : out std_logic);
  end component;

  component monitorStateMachine
    port (
      ClockxCI             : in  std_logic;
      ResetxRBI            : in  std_logic;
      RunxSI               : in  std_logic;
      AERREQxABI           : in  std_logic;
      AERSnifACKxABI       : in  std_logic;
      AERACKxSBO           : out std_logic;
      AERSnifREQxSBO       : out std_logic;
      AddressRegWritexEO   : out std_logic;
      TimestampRegWritexEO : out std_logic;
      SetEventReadyxSO     : out std_logic;
      EventReadyxSI        : in  std_logic;
      MissedEventxSO       : out std_logic;
      FifoFullxSBI         : in  std_logic;
      MissEventsEnabledxEI : in std_logic;
      OverflowxSI          : in  std_logic);
  end component;

  component synthStateMachine
    port (
      ClockxCI               : in  std_logic;
      ResetxRBI              : in  std_logic;
      RunxSI                 : in  std_logic;
      AERREQxSBO             : out std_logic;
      AERACKxABI             : in  std_logic;
      EqualxSI               : in  std_logic;
      AddressRegWritexEO     : out std_logic;
      TimestampRegWritexEO   : out std_logic;
      SequencerResetxRBO : out std_logic;
      EventRequestxSO        : out std_logic;
      EventRequestACKxSI     : in  std_logic);
  end component;

  component wordRegister
    generic (
      width          :     natural := 16);
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

  -- signal declarations
  signal MonitorAddressxD                            : std_logic_vector(15 downto 0);
  signal MonitorTimestampxD                          : std_logic_vector(13 downto 0);
  signal FifoAddressRegInxD, FifoAddressRegOutxD     : std_logic_vector(15 downto 0);
  signal FifoTimestampRegInxD, FifoTimestampRegOutxD : std_logic_vector(15 downto 0);
  signal ActualTimestampxD                           : std_logic_vector(13 downto 0);
  signal SynthTimestampxD                            : std_logic_vector(15 downto 0);
  signal AERSynthAddressxD                           : std_logic_vector(15 downto 0);

  -- register write enables
  signal FifoAddressRegWritexE      : std_logic;
  signal FifoTimestampRegWritexE    : std_logic;
  signal MonitorAddressRegWritexE   : std_logic;
  signal MonitorTimestampRegWritexE : std_logic;
  signal SynthAddressRegWritexE     : std_logic;
  signal SynthTimestampRegWritexE   : std_logic;

  -- mux control signals
  signal RegisterInputSelectxS    : std_logic;
  signal AddressTimestampSelectxS : std_logic_vector(1 downto 0);

  -- communication between state machines
  signal SetMonitorEventReadyxS    : std_logic;
  signal ClearMonitorEventxS       : std_logic;
  signal MonitorEventReadyxS       : std_logic;
  signal EventRequestxS            : std_logic;
  signal EventRequestACKxS         : std_logic;
  signal IncEventCounterxS         : std_logic;
  signal ResetEventCounterxS       : std_logic;
  signal PaketSentxS : std_logic;

  -- comparison between sequencer timestamp and actual timestamp
  signal EqualxS                  : std_logic;

  -- clock, reset
  signal ClockxC                       : std_logic;
  signal RunxS                      : std_logic;
  signal CounterResetxRB               : std_logic;
  signal SynchronizerResetTimestampxSB : std_logic;

  -- signals regarding the timestamp
  signal TimestampOverflowxS   : std_logic;
  signal TimestampBit15xD      : std_logic;
  signal TimestampBit14xD      : std_logic;
  signal TimestampMasterxS     : std_logic;

  -- signals regarding the sequencer
  signal SequencerResetxRB : std_logic;
  signal SequencerTimestampxD : std_logic_vector(16 downto 0);
  
  -- enable signals for monitor and sequencer
  signal RunMonitorxS, RunSynthesizerxS : std_logic;

  -- connected to 8051 interrupts
  signal MissedEventxS : std_logic;

  -- various
  signal FifoTransactionxS : std_logic;
  signal FifoPktEndxSB     : std_logic;
  signal SynchOutxS        : std_logic;

  -- counter increment signal
  signal IncxS : std_logic;

  -- constants used for mux
  constant highZ           : std_logic_vector := "00";
  constant selectaddress   : std_logic_vector := "10";
  constant selecttimestamp : std_logic_vector := "01";
  constant selectmonitor   : std_logic        := '1';


begin
  ClockxC  <= ClockxCI;
  -- run the state machines either when one of the run signals is high or when in slave mode
  RunxS <= RunSynthesizerxSI or RunMonitorxSI or not TimestampMasterxS;
  CounterResetxRB <= SynchronizerResetTimestampxSB;
  
  Interrupt1xSB0 <= MissedEventxS;
  Interrupt0xSB0 <= '1';

  uFifoAddressRegister : wordRegister
    generic map (
      width          => 16)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => RunxS,
      WriteEnablexEI => FifoAddressRegWritexE,
      DataInxDI      => FifoAddressRegInxD,
      DataOutxDO     => FifoAddressRegOutxD);

  uFifoTimestampRegister : wordRegister
    generic map (
      width          => 16)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => RunxS,
      WriteEnablexEI => FifoTimestampRegWritexE,
      DataInxDI      => FifoTimestampRegInxD,
      DataOutxDO     => FifoTimestampRegOutxD);

  uMonitorAddressRegister : wordRegister
    generic map (
      width          => 16)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => RunxS,
      WriteEnablexEI => MonitorAddressRegWritexE,
      DataInxDI      => AERMonitorAddressxDI,
      DataOutxDO     => MonitorAddressxD);

  uMonitorTimestampRegister : wordRegister
    generic map (
      width          => 14)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => RunxS,
      WriteEnablexEI => MonitorTimestampRegWritexE,
      DataInxDI      => ActualTimestampxD,
      DataOutxDO     => MonitorTimestampxD);

  uSynthAddressRegister : wordRegister
    generic map (
      width          => 16)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => RunxS,
      WriteEnablexEI => SynthAddressRegWritexE,
      DataInxDI      => FifoAddressRegOutxD,
      DataOutxDO     => AERSynthAddressxD);

  uSynthTimestampRegister : wordRegister
    generic map (
      width          => 16)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => RunxS,
      WriteEnablexEI => SynthTimestampRegWritexE,
      DataInxDI      => FifoTimestampRegOutxD,
      DataOutxDO     => SynthTimestampxD);


  uEventCounter : eventCounter
    port map (
      ClockxCI     => ClockxC,
      ResetxRBI    => RunxS,
      ClearxSI     => ResetEventCounterxS,
      IncrementxSI => IncEventCounterxS,
      OverflowxSO  => PaketSentxS);

  uTimestampCounter : timestampCounter
    port map (
      ClockxCI      => ClockxC,
      ResetxRBI     => CounterResetxRB,
      IncrementxSI  => IncxS,
      OverflowxSO   => TimestampOverflowxS,
      DataxDO       => ActualTimestampxD);

  sequencerCounter_1: sequencerCounter
    port map (
      ClockxCI     => ClockxC,
      ResetxRBI =>  RunxS,
      SyncResetxRBI    => SequencerResetxRB,
      IncrementxSI => IncxS,
      DataxDO      => SequencerTimestampxD);
  
  uSynchronizerStateMachine : synchronizerStateMachine
    port map (
      ClockxCI              => ClockxC,
      ResetxRBI             => ResetxRBI,
      RunxSI => RunxS,
      ConfigxSI             => TimestampTickxSI,
      HostResetTimestampxSI => HostResetTimestampxSI,
      SyncInxAI             => SyncInxAI,
      SyncOutxSO            => SynchOutxS,
      MasterxSO             => TimestampMasterxS,
      ResetTimestampxSBO    => SynchronizerResetTimestampxSB,
      IncrementCounterxSO   => IncxS);

  uFifoStateMachine : fifoStateMachine
    port map (
      ClockxCI                   => ClockxC,
      ResetxRBI                  => RunxS,
      FifoTransactionxSO         => FifoTransactionxS,
      FifoInFullxSBI             => FifoInFullxSBI,
      FifoOutEmptyxSBI           => FifoOutEmptyxSBI,
      FifoWritexEBO              => FifoWritexEBO,
      FifoReadxEBO               => FifoReadxEBO,
      FifoOutputEnablexEBO       => FifoOutputEnablexEBO,
      FifoPktEndxSBO             => FifoPktEndxSB,
      FifoAddressxDO             => FifoAddressxDO,
      AddressRegWritexEO         => FifoAddressRegWritexE,
      TimestampRegWritexEO       => FifoTimestampRegWritexE,
      RegisterInputSelectxSO     => RegisterInputSelectxS,
      AddressTimestampSelectxSO  => AddressTimestampSelectxS,
      MonitorEventReadyxSI       => MonitorEventReadyxS,
      ClearMonitorEventxSO       => ClearMonitorEventxS,
      EventRequestxSI            => EventRequestxS,
      EventRequestACKxSO         => EventRequestACKxS,
      IncEventCounterxSO         => IncEventCounterxS,
      ResetEventCounterxSO       => ResetEventCounterxS,
      TimestampOverflowxSI       => TimestampOverflowxS,
      TimestampBit15xDO          => TimestampBit15xD,
      ResetTimestampxSBI => SynchronizerResetTimestampxSB,
      TimestampBit14xDO => TimestampBit14xD,
      PaketSentxSI => PaketSentxS);

  uMonitorStateMachine : monitorStateMachine
    port map (
      ClockxCI             => ClockxC,
      ResetxRBI            => RunxS,
      RunxSI               => RunMonitorxS,
      AERREQxABI           => AERMonitorREQxABI,
      AERSnifACKxABI       => AERSnifACKxABI,
      AERACKxSBO           => AERMonitorACKxSBO,
      AERSnifREQxSBO       => AERSnifREQxSBO,
      AddressRegWritexEO   => MonitorAddressRegWritexE,
      TimestampRegWritexEO => MonitorTimestampRegWritexE,
      SetEventReadyxSO     => SetMonitorEventReadyxS,
      EventReadyxSI        => MonitorEventReadyxS,
      MissedEventxSO       => MissedEventxS,
      FifoFullxSBI         => FifoInFullxSBI,
      MissEventsEnabledxEI => MissEventsEnabledxEI,
      OverflowxSI          => TimestampOverflowxS);

  uSynthStateMachine : synthStateMachine
    port map (
      ClockxCI               => ClockxC,
      ResetxRBI              => RunxS,
      RunxSI                 => RunSynthesizerxS,
      AERREQxSBO             => AERSynthREQxSBO,
      AERACKxABI             => AERSynthACKxABI,
      EqualxSI               => EqualxS,
      AddressRegWritexEO     => SynthAddressRegWritexE,
      TimestampRegWritexEO   => SynthTimestampRegWritexE,
      SequencerResetxRBO => SequencerResetxRB,
      EventRequestxSO        => EventRequestxS,
      EventRequestACKxSI     => EventRequestACKxS);


  -- compare stored timestamp to actual timestamp
  EqualxS <= '0' when (SequencerTimestampxD < ('0' & SynthTimestampxD))
             else '1';

  SynchOutxSO <= SynchOutxS;
  FifoPktEndxSBO <= FifoPktEndxSB;
  AERSynthAddressxDO <= AERSynthAddressxD;
  
  -- run monitor either when 8051 signals to do so,
  -- or when in slave mode
  RunMonitorxS <= RunMonitorxSI; -- when (TriggerModexSI = '0')
                  -- else not TimestampMasterxS;

  RunSynthesizerxS <= RunSynthesizerxSI; -- when (TriggerModexSI = '0')
                      -- else not TimestampMasterxS;

 
  -- mux to select how to drive datalines
  with AddressTimestampSelectxS select
    FifoDataxDIO <=
    FifoAddressRegOutxD   when selectaddress,
    FifoTimestampRegOutxD when selecttimestamp,
    (others => 'Z')       when others;

  -- mux for fifo registers
  FifoAddressRegInxD <= MonitorAddressxD when ( RegisterInputSelectxS = selectmonitor)
                        else FifoDataxDIO;
  FifoTimestampRegInxD <= (TimestampBit15xD & TimestampBit14xD & MonitorTimestampxD) when ( RegisterInputSelectxS = selectmonitor)
                          else FifoDataxDIO;

  LEDxSO             <= TimestampMasterxS;
  TimestampMasterxSO <= TimestampMasterxS;

  -- this process controls the EventReady Register which is used for the
  -- communication between fifoSM and monitor SM
  p_eventready : process (ClockxC, RunxS)
  begin  -- process p_eventready
    if RunxS = '0' then              -- asynchronous reset (active low)
      MonitorEventReadyxS   <= '0';
    elsif ClockxC'event and ClockxC = '1' then  -- rising clock edge
      if SetMonitorEventReadyxS = '1' and ClearMonitorEventxS = '1' then
        MonitorEventReadyxS <= '0';
      elsif SetMonitorEventReadyxS = '1' then
        MonitorEventReadyxS <= '1';
      elsif ClearMonitorEventxS = '1' then
        MonitorEventReadyxS <= '0';
      end if;
    end if;
  end process p_eventready;

end Structural;


