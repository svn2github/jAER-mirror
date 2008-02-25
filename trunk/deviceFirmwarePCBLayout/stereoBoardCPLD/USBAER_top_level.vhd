--------------------------------------------------------------------------------
-- Company: Universidad de Sevilla
--          Institute of Neuroinformatics, UNI/ETHZ
-- Engineer: Raphael Berner
--           Rico Möckel (adapted for two monitors)
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
    PC1xSI                : in  std_logic;                     -- unused
    PExDI                 : in  std_logic_vector(3 downto 0);  -- unused

    -- control LED
    LEDxSO : out std_logic;

    -- AER monitor interface
    AERMonitorREQxABI    : in  std_logic;  -- needs synchronization
    AERMonitorACKxSBO    : out std_logic;
    AERMonitorAddressxDI : in  std_logic_vector(14 downto 0);

    -- AER monitor interface 2
    AERMonitorREQxABI2    : in  std_logic;  -- needs synchronization
    AERMonitorACKxSBO2    : out std_logic;
    AERMonitorAddressxDI2 : in  std_logic_vector(14 downto 0));

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
      IncEventCounterxSO         : out std_logic;
      ResetEventCounterxSO       : out std_logic;
      ResetEarlyPaketTimerxSO    : out std_logic;
      TimestampOverflowxSI       : in  std_logic;
      TimestampBit15xDO          : out std_logic; 
      ResetTimestampxSBI : in std_logic;
      TimestampBit14xDO : out std_logic;
      EarlyPaketTimerOverflowxSI : in  std_logic);
  end component;

  component synchronizerStateMachine
    port (
      ClockxCI              : in  std_logic;
      ResetxRBI             : in  std_logic;
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
      AERACKxSBO           : out std_logic;
      AddressRegWritexEO   : out std_logic;
      TimestampRegWritexEO : out std_logic;
      SetEventReadyxSO     : out std_logic;
      EventReadyxSI        : in  std_logic;
      MissedEventxSO       : out std_logic;
      FifoFullxSBI         : in  std_logic;
      OverflowxSI          : in  std_logic);
  end component;

  component mergerStateMachine is
    port ( 
	   Clk                  : in   std_logic;                    --Clock
		Rst                  : in   std_logic;                    --Reset
	   SetMonitorEventReady : in   std_logic_vector(1 downto 0); --inputs from monitor SM indicating that there is a new valid event
      ClearEventReady      : in   std_logic;                    --input from FIFO SM indicating the event has been copied to FIFO
	   MonitorEventReady    : out  std_logic_vector(1 downto 0); --output to monitor SM indicating that there is a new valid event
      EventReady           : out  std_logic;                    --output to FIFO SM indicating there is a new valid event
      Sel                  : out  std_logic);                   --output for selecting channel             
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

  component earlyPaketTimer
    port (
      ClockxCI        : in  std_logic;
      ResetxRBI       : in  std_logic;
      ClearxSI        : in  std_logic;
      TimerExpiredxSO : out std_logic);
  end component;

  -- signal declarations
  signal MonitorAddressxD                            : std_logic_vector(14 downto 0);
  signal MonitorAddressxD2                           : std_logic_vector(14 downto 0);
  signal MonitorAddressSumxD                         : std_logic_vector(15 downto 0);
  signal MonitorTimestampxD                          : std_logic_vector(13 downto 0);
  signal MonitorTimestampxD2                          : std_logic_vector(13 downto 0);
  signal MonitorTimestampSumxD                       : std_logic_vector(13 downto 0);
  signal FifoAddressRegInxD, FifoAddressRegOutxD     : std_logic_vector(15 downto 0);
  signal FifoTimestampRegInxD, FifoTimestampRegOutxD : std_logic_vector(15 downto 0);
  signal ActualTimestampxD                           : std_logic_vector(13 downto 0);

  -- register write enables
  signal FifoAddressRegWritexE      : std_logic;
  signal FifoTimestampRegWritexE    : std_logic;
  signal MonitorAddressRegWritexE   : std_logic_vector(1 downto 0);
  signal MonitorTimestampRegWritexE : std_logic_vector(1 downto 0);

  -- mux control signals
  signal RegisterInputSelectxS    : std_logic;
  signal AddressTimestampSelectxS : std_logic_vector(1 downto 0);
  signal MonitorSelect            : std_logic;

  -- communication between state machines
  signal SetMonitorEventReadyxS    : std_logic_vector(1 downto 0);
  signal ClearMonitorEventxS       : std_logic;
  signal MonitorEventReadyxS       : std_logic_vector(1 downto 0);
  signal EventReady                : std_logic;
  signal IncEventCounterxS         : std_logic;
  signal ResetEventCounterxS       : std_logic;
  signal ResetEarlyPaketTimerxS    : std_logic;
  signal EarlyPaketTimerOverflowxS : std_logic;
  signal SMResetEarlyPaketTimerxS : std_logic;
  signal ECResetEarlyPaketTimerxS : std_logic;
  
  -- clock, reset
  signal ClockxC                       : std_logic;
  signal ResetxRB                      : std_logic;
  signal CounterResetxRB               : std_logic;
  signal SynchronizerResetTimestampxSB : std_logic;

  -- signals regarding the timestamp
  signal TimestampOverflowxS   : std_logic;
  signal TimestampBit15xD      : std_logic;
  signal TimestampBit14xD      : std_logic;
  signal TimestampMasterxS     : std_logic;

  -- enable signals for monitor and sequencer
  signal RunMonitorxS     : std_logic;

  -- connected to 8051 interrupts
  signal MissedEventxS : std_logic_vector(1 downto 0);

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
  -- run the state machines either when reset is high or when in slave mode
  ResetxRB <= ResetxRBI or not TimestampMasterxS;
  CounterResetxRB <= SynchronizerResetTimestampxSB;
  
  Interrupt1xSB0 <= (MissedEventxS(0) OR MissedEventxS(1));
  Interrupt0xSB0 <= '1';
  
  
  uFifoAddressRegister : wordRegister
    generic map (
      width          => 16)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => FifoAddressRegWritexE,
      DataInxDI      => FifoAddressRegInxD,
      DataOutxDO     => FifoAddressRegOutxD);

  uFifoTimestampRegister : wordRegister
    generic map (
      width          => 16)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => FifoTimestampRegWritexE,
      DataInxDI      => FifoTimestampRegInxD,
      DataOutxDO     => FifoTimestampRegOutxD);

  uMonitorAddressRegister : wordRegister
    generic map (
      width          => 15)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => MonitorAddressRegWritexE(0),
      DataInxDI      => AERMonitorAddressxDI,
      DataOutxDO     => MonitorAddressxD);

  uMonitorAddressRegister2 : wordRegister
    generic map (
      width          => 15)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => MonitorAddressRegWritexE(1),
      DataInxDI      => AERMonitorAddressxDI2,
      DataOutxDO     => MonitorAddressxD2);

  uMonitorTimestampRegister : wordRegister
    generic map (
      width          => 14)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => MonitorTimestampRegWritexE(0),
      DataInxDI      => ActualTimestampxD,
      DataOutxDO     => MonitorTimestampxD);

  uMonitorTimestampRegister2 : wordRegister
    generic map (
      width          => 14)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => MonitorTimestampRegWritexE(1),
      DataInxDI      => ActualTimestampxD,
      DataOutxDO     => MonitorTimestampxD2);

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

  uSynchStateMachine : synchronizerStateMachine
    port map (
      ClockxCI              => ClockxC,
      ResetxRBI             => ResetxRB,
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
      ResetxRBI                  => ResetxRB,
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
      MonitorEventReadyxSI       => EventReady,
      ClearMonitorEventxSO       => ClearMonitorEventxS,
      IncEventCounterxSO         => IncEventCounterxS,
      ResetEventCounterxSO       => ResetEventCounterxS,
      ResetEarlyPaketTimerxSO    => SMResetEarlyPaketTimerxS,
      TimestampOverflowxSI       => TimestampOverflowxS,
      TimestampBit15xDO          => TimestampBit15xD,
      ResetTimestampxSBI => SynchronizerResetTimestampxSB,
      TimestampBit14xDO => TimestampBit14xD,
      EarlyPaketTimerOverflowxSI => EarlyPaketTimerOverflowxS);

  uMonitorStateMachine : monitorStateMachine
    port map (
      ClockxCI             => ClockxC,
      ResetxRBI            => ResetxRB,
      RunxSI               => RunMonitorxS,
      AERREQxABI           => AERMonitorREQxABI,
      AERACKxSBO           => AERMonitorACKxSBO,
      AddressRegWritexEO   => MonitorAddressRegWritexE(0),
      TimestampRegWritexEO => MonitorTimestampRegWritexE(0),
      SetEventReadyxSO     => SetMonitorEventReadyxS(0),
      EventReadyxSI        => MonitorEventReadyxS(0),
      MissedEventxSO       => MissedEventxS(0),
      FifoFullxSBI         => FifoInFullxSBI,
      OverflowxSI          => TimestampOverflowxS);

  uMonitorStateMachine2 : monitorStateMachine
    port map (
      ClockxCI             => ClockxC,
      ResetxRBI            => ResetxRB,
      RunxSI               => RunMonitorxS,
      AERREQxABI           => AERMonitorREQxABI2,
      AERACKxSBO           => AERMonitorACKxSBO2,
      AddressRegWritexEO   => MonitorAddressRegWritexE(1),
      TimestampRegWritexEO => MonitorTimestampRegWritexE(1),
      SetEventReadyxSO     => SetMonitorEventReadyxS(1),
      EventReadyxSI        => MonitorEventReadyxS(1),
      MissedEventxSO       => MissedEventxS(1),
      FifoFullxSBI         => FifoInFullxSBI,
      OverflowxSI          => TimestampOverflowxS);

  uMergerStateMachine : mergerStateMachine
    port map ( 
	   Clk                  => ClockxC, --Clock
		Rst                  => ResetxRB, --Reset
	   SetMonitorEventReady => SetMonitorEventReadyxS, --inputs from monitor SM indicating that there is a new valid event
      ClearEventReady      => ClearMonitorEventxS, --input from FIFO SM indicating the event has been copied to FIFO
	   MonitorEventReady    => MonitorEventReadyxS, --output to monitor SM indicating that there is a new valid event
      EventReady           => EventReady, --output to FIFO SM indicating there is a new valid event
      Sel                  => MonitorSelect);--output for selecting channel             


  SynchOutxSO <= SynchOutxS;
  FifoPktEndxSBO <= FifoPktEndxSB;
 
  
  -- run monitor either when 8051 signals to do so,
  -- or when in slave mode
  RunMonitorxS <= RunMonitorxSI when (TriggerModexSI = '0')
                  else not TimestampMasterxS;


  -- reset early paket timer whenever a paket is sent (short or normal)
  ResetEarlyPaketTimerxS <= (SMResetEarlyPaketTimerxS or ECResetEarlyPaketTimerxS);

  -- mux to select how to drive datalines
  with AddressTimestampSelectxS select
    FifoDataxDIO <=
    FifoAddressRegOutxD   when selectaddress,
    FifoTimestampRegOutxD when selecttimestamp,
    (others => 'Z')       when others;

  -- mux for fifo registers
  FifoAddressRegInxD <= MonitorAddressSumxD;

  FifoTimestampRegInxD <= (TimestampBit15xD & TimestampBit14xD & MonitorTimestampSumxD);

  MonitorAddressSumxD(14 downto 0) <= MonitorAddressxD(14 downto 0) when (MonitorSelect = '0')
                         else MonitorAddressxD2(14 downto 0);
  MonitorAddressSumxD(15) <= MonitorSelect;
  MonitorTimestampSumxD <= MonitorTimestampxD when (MonitorSelect = '0')
                         else MonitorTimestampxD2;

  LEDxSO             <= TimestampMasterxS;
  TimestampMasterxSO <= TimestampMasterxS;

  -- this process controls the EventReady Register which is used for the
  -- communication between fifoSM and monitor SM
--  p_eventready : process (ClockxC, ResetxRB)
--  begin  -- process p_eventready
--    if ResetxRB = '0' then              -- asynchronous reset (active low)
--      MonitorEventReadyxS   <= '0';
--    elsif ClockxC'event and ClockxC = '1' then  -- rising clock edge
--      if SetMonitorEventReadyxS = '1' and ClearMonitorEventxS = '1' then
--        MonitorEventReadyxS <= '0';
--      elsif SetMonitorEventReadyxS = '1' then
--        MonitorEventReadyxS <= '1';
--      elsif ClearMonitorEventxS = '1' then
--        MonitorEventReadyxS <= '0';
--      end if;
--    end if;
--  end process p_eventready;

end Structural;


