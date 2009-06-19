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
    FifoDataxDIO         : out std_logic_vector(15 downto 0);
    FifoInFullxSBI       : in    std_logic;
    FifoWritexEBO        : out   std_logic;
    FifoReadxEBO         : out   std_logic;
    FifoOutputEnablexEBO : out   std_logic;
    FifoPktEndxSBO       : out   std_logic;
    FifoAddressxDO       : out   std_logic_vector(1 downto 0);

    --IFclockxCO : out std_logic;

    -- clock and reset inputs
    ClockxCI  : in std_logic;
    ResetxRBI : in std_logic;

    -- ports to synchronize other USBAER boards
    SyncInxAI   : in  std_logic;        -- needs synchronization
    SyncOutxSO : out std_logic;

    -- communication with 8051
    TimestampTickxSI      : in  std_logic;
    TriggerModexSI        : in  std_logic;
    TimestampMasterxSO    : out std_logic;
    HostResetTimestampxSI : in  std_logic;
    RunMonitorxSI : in std_logic;
   -- Interrupt0xSB0        : out std_logic;
    Interrupt1xSB0        : out std_logic;
   -- PC1xSI                : in  std_logic;                     -- unused
   -- PExDI                 : in  std_logic_vector(3 downto 0);  -- unused

    -- control LED
    LEDxSO : out std_logic;
    Debug1xSO : out std_logic;
    Debug2xSO : out std_logic;

    -- AER monitor interface
    AERMonitorREQxABI    : in  std_logic;  -- needs synchronization
    AERMonitorACKxSBO    : out std_logic;
    AERMonitorAddressxDI : in  std_logic_vector(15 downto 0));

end USBAER_top_level;

architecture Structural of USBAER_top_level is
  component fifoStateMachine
    port (
      ClockxCI                   : in  std_logic;
      ResetxRBI                  : in  std_logic;
      
      FifoTransactionxSO         : out std_logic;
      
      FifoInFullxSBI             : in  std_logic;
      
      FifoWritexEBO              : out std_logic;
      FifoPktEndxSBO             : out std_logic;
      FifoAddressxDO             : out std_logic_vector(1 downto 0);
      
      AddressRegWritexEO         : out std_logic;
      AddressTimestampSelectxSO  : out std_logic;
      
      MonitorEventReadyxSI       : in  std_logic;
      ClearMonitorEventxSO       : out std_logic;
      IncEventCounterxSO         : out std_logic;
      ResetEventCounterxSO       : out std_logic;
      ResetEarlyPaketTimerxSO    : out std_logic;
      
      TimestampOverflowxSI       : in  std_logic;
      TimestampMSBxDO          : out std_logic_vector(1 downto 0);
      ResetTimestampxSBI          : in std_logic;
      EarlyPaketTimerOverflowxSI : in  std_logic);
  end component;

  component synchronizerStateMachine
    port (
      ClockxCI              : in  std_logic;
      ResetxRBI             : in  std_logic;
      RunxSI : in std_logic;
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
      FifoInFullxSBI : in std_logic;
      RegWritexEO   : out std_logic;
      SetEventReadyxSO     : out std_logic;
      EventReadyxSI        : in  std_logic);
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
  signal MonitorAddressxD                            : std_logic_vector(15 downto 0);
  signal MonitorTimestampxD                          : std_logic_vector(13 downto 0);
  
  signal FifoAddressRegInxD, FifoAddressRegOutxD     : std_logic_vector(15 downto 0);
  signal FifoTimestampRegInxD, FifoTimestampRegOutxD     : std_logic_vector(15 downto 0);
  signal FifoAddressxD, FifoTimestampxD : std_logic_vector(15 downto 0);
  
  signal ActualTimestampxD                           : std_logic_vector(13 downto 0);

  -- register write enables
  signal FifoRegWritexE      : std_logic;
  signal MonitorRegWritexE   : std_logic;
  
  signal SyncInxA : std_logic;

  signal AERMonitorACKxSB : std_logic;
  
  -- mux control signals
  signal AddressTimestampSelectxS : std_logic;

  -- communication between state machines
  signal SetMonitorEventReadyxS    : std_logic;
  signal ClearMonitorEventxS       : std_logic;
  signal MonitorEventReadyxS       : std_logic;
  signal IncEventCounterxS         : std_logic;
  signal ResetEventCounterxS       : std_logic;
  signal ResetEarlyPaketTimerxS    : std_logic;
  signal EarlyPaketTimerOverflowxS : std_logic;
  signal SMResetEarlyPaketTimerxS : std_logic;
  signal ECResetEarlyPaketTimerxS : std_logic;

  -- clock, reset
  signal ClockxC                       : std_logic;
  signal RunxS                      : std_logic;
  signal SynchronizerResetTimestampxSB : std_logic;
  signal CounterResetxRB : std_logic;

  -- signals regarding the timestamp
  signal TimestampOverflowxS   : std_logic;
  signal TimestampMSBxD          : std_logic_vector(1 downto 0);
  signal TimestampMasterxS     : std_logic;

  -- enable signals for monitor
  signal RunMonitorxS : std_logic;

  -- various
  signal FifoTransactionxS : std_logic;
  signal FifoPktEndxSB     : std_logic;
  signal SyncOutxS        : std_logic;

  -- counter increment signal
  signal IncxS : std_logic;

  -- constants used for mux
  constant selectaddress   : std_logic := '1';
  constant selecttimestamp : std_logic := '0';
 -- constant selectmonitor   : std_logic        := '1';

 -- attribute noreduce : string;
  
 -- signal IFclock2xC, IFclock3xC : std_logic;
 -- signal IFclock4xC, IFclock5xC : std_logic;
 -- attribute noreduce of IFclock5xC: signal is  "YES";
 -- attribute noreduce of IFclock4xC: signal is  "YES";
 -- attribute noreduce of IFclock3xC: signal is  "YES";
 -- attribute noreduce of IFclock2xC: signal is  "YES";
 -- attribute noreduce of IFclockxCO: signal is  "YES";
begin
  --IFclockxCO <= ClockxC;
  --IFclockxCO <= not IFclock5xC;
  --IFclock5xC <= not IFclock4xC;
  --IFclock4xC <= not IFclock3xC;
  --IFclock3xC <= not IFclock2xC;
  --IFclock2xC <= not ClockxC;
  
  ClockxC  <= ClockxCI;
  -- run the state machines either when reset is high or when in slave mode
  RunxS <= RunMonitorxSI or not TimestampMasterxS;
  
  --Interrupt0xSB0 <= '1';
  Interrupt1xSB0 <= '1';
  
  FifoReadxEBO <= '1';
  FifoOutputEnablexEBO <= '1';

  SyncInxA <= not SyncInxAI;
  
  FifoAddressRegInxD <= MonitorAddressxD;
  FifoAddressxD <= FifoAddressRegOutxD; 
  FifoTimestampRegInxD <= TimestampMSBxD & MonitorTimestampxD;
  FifoTimestampxD <= FifoTimestampRegOutxD;

  uFifoAddressRegister : wordRegister
    generic map (
      width          => 16)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => RunxS,
      WriteEnablexEI => FifoRegWritexE,
      DataInxDI      => FifoAddressRegInxD,
      DataOutxDO     => FifoAddressRegOutxD);
  
 uFifoTimestampRegister : wordRegister
    generic map (
      width          => 16)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => RunxS,
      WriteEnablexEI => FifoRegWritexE,
      DataInxDI      => FifoTimestampRegInxD,
      DataOutxDO     => FifoTimestampRegOutxD);
  
  uMonitorAddressRegister : wordRegister
    generic map (
      width          => 16)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => RunxS,
      WriteEnablexEI => MonitorRegWritexE,
      DataInxDI      => AERMonitorAddressxDI,
      DataOutxDO     => MonitorAddressxD);

  uMonitorTimestampRegister : wordRegister
    generic map (
      width          => 14)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => RunxS,
      WriteEnablexEI => MonitorRegWritexE,
      DataInxDI      => ActualTimestampxD,
      DataOutxDO     => MonitorTimestampxD);


  uEarlyPaketTimer : earlyPaketTimer
    port map (
      ClockxCI        => ClockxC,
      ResetxRBI       => RunxS,
      ClearxSI        => ResetEarlyPaketTimerxS,
      TimerExpiredxSO => EarlyPaketTimerOverflowxS);

  uEventCounter : eventCounter
    port map (
      ClockxCI     => ClockxC,
      ResetxRBI    => ResetxRBI,
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

  CounterResetxRB <= ResetxRBI and SynchronizerResetTimestampxSB;
  
  uSyncStateMachine : synchronizerStateMachine
    port map (
      ClockxCI              => ClockxC,
      ResetxRBI             => ResetxRBI,
      RunxSI => RunxS,
      ConfigxSI             => TimestampTickxSI,
      HostResetTimestampxSI => HostResetTimestampxSI,
      SyncInxAI             => SyncInxA,
      SyncOutxSO            => SyncOutxS,
      MasterxSO             => TimestampMasterxS,
      ResetTimestampxSBO    => SynchronizerResetTimestampxSB,
      IncrementCounterxSO   => IncxS);

  uFifoStateMachine : fifoStateMachine
    port map (
      ClockxCI                   => ClockxC,
      ResetxRBI                  => ResetxRBI,
      FifoTransactionxSO         => FifoTransactionxS,
      FifoInFullxSBI             => FifoInFullxSBI,
      FifoWritexEBO              => FifoWritexEBO,
      FifoPktEndxSBO             => FifoPktEndxSB,
      FifoAddressxDO             => FifoAddressxDO,
      AddressRegWritexEO         => FifoRegWritexE,
      AddressTimestampSelectxSO  => AddressTimestampSelectxS,
      MonitorEventReadyxSI       => MonitorEventReadyxS,
      ClearMonitorEventxSO       => ClearMonitorEventxS,
      IncEventCounterxSO         => IncEventCounterxS,
      ResetEventCounterxSO       => ResetEventCounterxS,
      ResetEarlyPaketTimerxSO    => SMResetEarlyPaketTimerxS,
      TimestampOverflowxSI       => TimestampOverflowxS,
      TimestampMSBxDO          => TimestampMSBxD,
      ResetTimestampxSBI => SynchronizerResetTimestampxSB,
      EarlyPaketTimerOverflowxSI => EarlyPaketTimerOverflowxS);

  uMonitorStateMachine : monitorStateMachine
    port map (
      ClockxCI             => ClockxC,
      ResetxRBI            => ResetxRBI,
      RunxSI               => RunMonitorxS,
      AERREQxABI           => AERMonitorREQxABI,
      AERACKxSBO           => AERMonitorACKxSB,
      FifoInFullxSBI => FifoInFullxSBI,
      RegWritexEO   => MonitorRegWritexE,
      SetEventReadyxSO     => SetMonitorEventReadyxS,
      EventReadyxSI        => MonitorEventReadyxS);

 

  SyncOutxSO <= not SyncOutxS;
  FifoPktEndxSBO <= FifoPktEndxSB;
 
  AERMonitorACKxSBO <= AERMonitorACKxSB;
  
  -- run monitor either when 8051 signals to do so,
  -- or when in slave mode
  RunMonitorxS <= RunMonitorxSI when (TriggerModexSI = '0')
                  else not TimestampMasterxS;

  -- reset early paket timer whenever a paket is sent (short or normal)
  ResetEarlyPaketTimerxS <= (SMResetEarlyPaketTimerxS or ECResetEarlyPaketTimerxS);

  -- mux to select how to drive datalines
  with AddressTimestampSelectxS select
    FifoDataxDIO <=
    FifoAddressxD   when selectaddress,
    FifoTimestampxD when others;

  LEDxSO  <= TimestampMasterxS;
  --LEDxSO <= FifoTransactionxS;
  
  Debug1xSO <= AERMonitorREQxABI;
  Debug2xSO <= AERMonitorACKxSB;
  
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


