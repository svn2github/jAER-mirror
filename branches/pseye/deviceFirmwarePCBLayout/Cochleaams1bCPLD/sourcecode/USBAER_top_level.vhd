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
-- Modified 3/11/08 for Cochleaams1b
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
    FifoDataxDIO         : out std_logic_vector(7 downto 0);
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

	-- biasgen set
    PC0 : in std_logic;
    PC1 : in std_logic;	
	 PE0 : in std_logic;	
	 PE1 : in std_logic;	
	 PE2 : in std_logic;	
	 Configclock : out std_logic;
	 bitin : out std_logic;
	 DataSel : out std_logic;
    AddSel : out std_logic;
    BiasGenSel : out std_logic;
  
	 -- extDAC set
	 PC2 : in std_logic;
    PC3 : in std_logic;	
	 PD0 : in std_logic;	
	 DACBitIn : out std_logic;
	 DACClk : out std_logic;
	 DACnSYNC : out std_logic;
	
	 -- Scanner and config bits set
	 
	 PD1 : in std_logic;	
	 PD2 : in std_logic;	
	 PD3 : in std_logic;	
	 PD4 : in std_logic;	
	 PD5 : in std_logic;	
	 PD6 : in std_logic;	
	 PE3 : in std_logic;	
	 PE4 : in std_logic;	
	 PE5 : in std_logic;	
	 PE6 : in std_logic;		 
	 ScanClk : out std_logic;
	 Ybit : out std_logic;
	 Selaer : out std_logic;
	 bitlatch : out std_logic;
	 powerdown : out std_logic;
	 ResCtr1 : out std_logic;
    ResCtr2 : out std_logic;
    Vreset : out std_logic;
    SelIn : out std_logic;
	 AERKillBit : out std_logic;
  
    RunMonitorxSI : in std_logic;
    HostResetTimestampxSI : in std_logic; 
	 
	 --TimestampTickxSI : in std_logic;
	 
   -- Interrupt0xSB0        : out std_logic;
 --   Interrupt1xSB0        : out std_logic;
   -- PC1xSI                : in  std_logic;                     -- unused
   -- PExDI                 : in  std_logic_vector(3 downto 0);  -- unused

    -- control LED
    LEDxSO : out std_logic;
    --Debug1xSO : out std_logic;
    --Debug2xSO : out std_logic;

    -- sync
    SyncInxABI : in std_logic;
    SyncOutxSBO : out std_logic;
    
    -- AER monitor interface
    AERMonitorREQxABI    : in  std_logic;  -- needs synchronization
    AERMonitorACKxSBO    : out std_logic;
    AERMonitorAddressxDI : in  std_logic_vector(9 downto 0));

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
      AddressTimestampSelectxSO  : out std_logic_vector(1 downto 0);
      
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
  signal MonitorAddressxD                            : std_logic_vector(9 downto 0);
  signal MonitorTimestampxD                          : std_logic_vector(13 downto 0);
  
  signal FifoAddressRegInxD, FifoAddressRegOutxD     : std_logic_vector(9 downto 0);
  signal FifoTimestampRegInxD, FifoTimestampRegOutxD     : std_logic_vector(15 downto 0);
  signal FifoAddressxD : std_logic_vector(9 downto 0);
  signal FifoTimestampxD : std_logic_vector(15 downto 0);
  
  signal ActualTimestampxD                           : std_logic_vector(13 downto 0);

  -- register write enables
  signal FifoRegWritexE      : std_logic;
  signal MonitorRegWritexE   : std_logic;
  
  signal SyncInxA : std_logic;

  signal AERMonitorACKxSB : std_logic;
  
  -- mux control signals
  signal AddressTimestampSelectxS : std_logic_vector(1 downto 0);

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

	signal AckdelayedxD, AckdelayedxD2 : std_logic;
  -- constants used for mux

	signal AERKillBitxDP : std_logic;

  constant selectaddressLSB : std_logic_vector(1 downto 0) := "00";
  constant selectaddressMSB : std_logic_vector(1 downto 0) := "01";  
  constant selecttimestampLSB : std_logic_vector(1 downto 0) := "10";  
  constant selecttimestampMSB : std_logic_vector(1 downto 0) := "11";  
  
 -- constant selectmonitor   : std_logic        := '1';


  

begin
  
  ClockxC  <= ClockxCI;
  -- run the state machines either when reset is high or when in slave mode
  RunxS <= RunMonitorxSI or not TimestampMasterxS;
  
  FifoReadxEBO <= '1';
  FifoOutputEnablexEBO <= '1';

  SyncInxA <= not SyncInxABI;
  
  FifoAddressRegInxD <= MonitorAddressxD;
  FifoAddressxD <= FifoAddressRegOutxD; 
  FifoTimestampRegInxD <= TimestampMSBxD & MonitorTimestampxD;
  FifoTimestampxD <= FifoTimestampRegOutxD;

 --hook up pins specific for cochlea control, scanner, and config bits
 
  Configclock <= PC0;
  bitin <= PC1;
  DACBitIn <= PC2;
  DACClk <= PC3;
  
  DACnSYNC <= PD0;
  ScanClk <= PD1;
  YBit <= PD2;
  Selaer <= PD3;
  bitlatch <= PD4;
  powerdown <= PD5;
  AERKillBit <= AERKillBitxDP; -- fix put in for cochleaams1b chip which has mistake for the aer_req
  
  --this process is only used for cochleaams1b chip which has a bug, aer_req comes from 1st dimension
  p_killbit : process (ClockxC)
  
  begin  -- process p_killbit
    if ClockxC'event and ClockxC = '1' then  -- rising clock edge
		AERKillBitxDP <= PD6 or (not AERMonitorACKxSB); 
    end if;
  end process p_killbit;
  
  DataSel <= PE0;
  AddSel <= PE1;
  BiasGenSel <= PE2;
  ResCtr1 <=PE3;
  ResCtr2 <= PE4;
  Vreset <= PE5;
  SelIn <= PE6;
  
  
  uFifoAddressRegister : wordRegister
    generic map (
      width          => 10)
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
      width          => 10)
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
      ConfigxSI             => '0',
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
      RegWritexEO   => MonitorRegWritexE,
      SetEventReadyxSO     => SetMonitorEventReadyxS,
      EventReadyxSI        => MonitorEventReadyxS);

 
  FifoPktEndxSBO <= FifoPktEndxSB;
 
  AERMonitorACKxSBO <= AERMonitorACKxSB;
  
  -- run monitor either when 8051 signals to do so,
  RunMonitorxS <= RunMonitorxSI;
  


  -- reset early paket timer whenever a paket is sent (short or normal)
  ResetEarlyPaketTimerxS <= (SMResetEarlyPaketTimerxS or ECResetEarlyPaketTimerxS);

  -- mux to select how to drive datalines
  with AddressTimestampSelectxS select
 
	 FifoDataxDIO <=
    FifoAddressxD(7 downto 0)    when selectaddressLSB,
    "000000" & FifoAddressxD(9 downto 8)   when selectaddressMSB,
    FifoTimestampxD(7 downto 0)  when selecttimestampLSB,
    FifoTimestampxD(15 downto 8) when selecttimestampMSB,
    (others => 'Z')                    when others;

  LEDxSO  <= TimestampMasterxS;
  --LEDxSO <= FifoTransactionxS;

  SyncOutxSBO <= not SyncOutxS;
  
  --Debug1xSO <= AERMonitorAckxSB or AckdelayedxD2;
  --Debug2xSO <= ActualTimestampxD(1);


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
		
		AckdelayedxD <= not AERMonitorAckxSB;
		AckdelayedxD2 <= AckdelayedxD;
    end if;
  end process p_eventready;

end Structural;


