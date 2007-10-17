--------------------------------------------------------------------------------
-- Company:        Institute of Neuroinformatics Uni/ETHZ
-- Engineer:       Rico Möckel
--
-- Create Date:    14:02:00 10/24/05
-- Design Name:    
-- Module Name:    monitorStateMachine_tb
-- Project Name:   USBAERmini2
-- Target Device:  
-- Tool versions:  
-- Description: testbench for USBAER_top_level
--
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
-------------------------------------------------------------------------------

entity USBAER_top_level_tb is

end USBAER_top_level_tb;

-------------------------------------------------------------------------------

architecture behavioural_hardcoded of USBAER_top_level_tb is

  component USBAER_top_level
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
    AERMonitorAddressxDI2 : in  std_logic_vector(14 downto 0);

    -- AER pass-through interface
    AERSnifACKxABI : in  std_logic;     -- needs synchronization
    AERSnifREQxSBO : out std_logic);
  end component;

    -- communication ports to FX2 Fifos
  signal  FifoDataxDIO         :  std_logic_vector(15 downto 0);
  signal  FifoInFullxSBI       :     std_logic;
  signal  FifoOutEmptyxSBI     :     std_logic;
  signal  FifoWritexEBO        :    std_logic;
  signal  FifoReadxEBO         :    std_logic;
  signal  FifoOutputEnablexEBO :    std_logic;
  signal  FifoPktEndxSBO       :    std_logic;
  signal  FifoAddressxDO       :    std_logic_vector(1 downto 0);

    -- clock and reset inputs
  signal  ClockxC  :  std_logic;
  signal  ResetxRB :  std_logic;

    -- ports to synchronize other USBAER boards
  signal  SyncInxAI   :   std_logic;        -- needs synchronization
  signal  SynchOutxSO :  std_logic;

    -- communication with 8051
  signal  RunMonitorxSI         :   std_logic;
  signal  RunSynthesizerxSI     :   std_logic;
  signal  TimestampTickxSI      :   std_logic;
  signal  TriggerModexSI        :   std_logic;
  signal  TimestampMasterxSO    :  std_logic;
  signal  HostResetTimestampxSI :   std_logic;
  signal  Interrupt0xSB0        :  std_logic;
  signal  Interrupt1xSB0        :  std_logic;
  signal  PC1xSI                :   std_logic;                     -- unused
  signal  PExDI                 :   std_logic_vector(3 downto 0);  -- unused

    -- control LED
  signal  LEDxSO : std_logic;

    -- AER monitor interface
  signal  AERMonitorREQxABI    :   std_logic;  -- needs synchronization
  signal  AERMonitorACKxSBO    :  std_logic;
  signal  AERMonitorAddressxDI :   std_logic_vector(14 downto 0);

    -- AER monitor interface 2
  signal  AERMonitorREQxABI2    :   std_logic;  -- needs synchronization
  signal  AERMonitorACKxSBO2    :  std_logic;
  signal  AERMonitorAddressxDI2 :   std_logic_vector(14 downto 0);

    -- AER pass-through interface
  signal  AERSnifACKxABI :  std_logic; 
  signal  AERSnifREQxSBO :  std_logic;

  constant PERIOD    : time := 20 ns;   -- clock period
  constant HIGHPHASE : time := 10 ns;   -- high phase of clock
  constant LOWPHASE  : time := 10 ns;   -- low phase of clock
  constant STIM_APPL : time := 5 ns;    -- stimulus application point
  constant RESP_ACQU : time := 15 ns;   -- response acquisition point

  -- stop simulator by starving event queue
  signal StopSimulationxS : std_logic := '0';

  -- function to convert std_logic_vector in a string
  function toString(value : std_logic_vector) return string is
    variable l            : line;
  begin
    write(l, to_bitVector(value), right, 0);
    return l.all;
  end toString;

  -- procedure to compare actual response vs. expected response
  procedure check_response (
    actResp                      : in std_logic_vector(2 downto 0);
    constant expResp             : in std_logic_vector(2 downto 0)
    ) is
  begin
    if actResp/=expResp then
      report "failure, exp. resp :    " & toString(expResp) & ht & "act. resp. : " & toString(actResp)
        severity note;
    end if;
  end check_response;

begin  -- behavioural_hardcoded

  DUT : USBAER_top_level
    port map (
      FifoDataxDIO          => FifoDataxDIO,
      FifoInFullxSBI        => FifoInFullxSBI,
      FifoOutEmptyxSBI      => FifoOutEmptyxSBI,
      FifoWritexEBO         => FifoWritexEBO,
      FifoReadxEBO          => FifoReadxEBO,
      FifoOutputEnablexEBO  => FifoOutputEnablexEBO,
      FifoPktEndxSBO        => FifoPktEndxSBO,
      FifoAddressxDO        => FifoAddressxDO,
      ClockxCI              => ClockxC,
      ResetxRBI             => ResetxRB,
      SyncInxAI             => SyncInxAI,
      SynchOutxSO           => SynchOutxSO,
      RunMonitorxSI         => RunMonitorxSI,
      RunSynthesizerxSI     => RunSynthesizerxSI,
      TimestampTickxSI      => TimestampTickxSI,
      TriggerModexSI        => TriggerModexSI,
      TimestampMasterxSO    => TimestampMasterxSO,
      HostResetTimestampxSI => HostResetTimestampxSI,
      Interrupt0xSB0        => Interrupt0xSB0,
      Interrupt1xSB0        => Interrupt1xSB0,
      PC1xSI                => PC1xSI,
      PExDI                 => PExDI,
      LEDxSO                => LEDxSO,
      AERMonitorREQxABI     => AERMonitorREQxABI,
      AERMonitorACKxSBO     => AERMonitorACKxSBO,
      AERMonitorAddressxDI  => AERMonitorAddressxDI,
      AERMonitorREQxABI2    => AERMonitorREQxABI2,
      AERMonitorACKxSBO2    => AERMonitorACKxSBO2,
      AERMonitorAddressxDI2 => AERMonitorAddressxDI2,
      AERSnifACKxABI        => AERSnifACKxABI, 
      AERSnifREQxSBO        => AERSnifREQxSBO);

  p_clockgen : process
  begin

------------------------
    loop

      ClockxC <= '1';
      wait for HIGHPHASE;
      ClockxC <= '0';
      wait for LOWPHASE;

      if StopSimulationxS = '1' then
        wait;                           -- wait forever to starve event queue
      end if;
    end loop;
  end process p_clockgen;


-------------------------------------------------------------------------------
-- hardcoded stimuli application process
-------------------------------------------------------------------------------

  p_stimuli_app : process
  begin
    -- init
    ResetxRB               <= '0';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '0';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(0, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(0, 15));
    AERSnifACKxABI         <= '1';
    wait for STIM_APPL;                 --1 reset
    ResetxRB               <= '0';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '0';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(0, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(0, 15));
    AERSnifACKxABI         <= '1';
    wait for PERIOD;                 --1 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(0, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(0, 15));
    AERSnifACKxABI         <= '1';
    wait for PERIOD;                    --2 event on monitor 0
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '0';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(12, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(0, 15));
    AERSnifACKxABI         <= '1';
    wait for PERIOD;                    --3 event on monitor 0
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '0';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(12, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(0, 15));
    AERSnifACKxABI         <= '1';
    wait for PERIOD;                    --4 event on monitor 0, ack on sniff
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '0';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(12, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(0, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --5 take away request
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(12, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(0, 15));
    AERSnifACKxABI         <= '1';
    wait for PERIOD;                    --6 disable sniff
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(12, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(0, 15));
    AERSnifACKxABI         <= '0';
    wait for 20*PERIOD;                    --7 event on monitor 0
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '0';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(0, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --8 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '0';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(0, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --9 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '0';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(0, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --10 take request back
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(0, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --11 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(0, 15));
    AERSnifACKxABI         <= '0';
    wait for 20*PERIOD;                    --7 event on monitor 1
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '0';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(122, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --8 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '0';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(122, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --9 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '0';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(122, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --10 take request back
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(122, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --11 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(122, 15));
    AERSnifACKxABI         <= '0';
    wait for 20*PERIOD;                    --7 event on monitor 0 and 1
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '0';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(533, 15));
    AERMonitorREQxABI2     <= '0';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(712, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --8 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '0';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(533, 15));
    AERMonitorREQxABI2     <= '0';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(712, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --9 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(533, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(712, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --10 take request back
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(533, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(712, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --11 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(533, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(712, 15));
    AERSnifACKxABI         <= '0';
    wait for 5*PERIOD;                    --7 event on monitor 0
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '0';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(712, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --8 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '0';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(712, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --9 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '0';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(712, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --10 take request back
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(712, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --11 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(40, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(712, 15));
    AERSnifACKxABI         <= '0';
    wait for 10*PERIOD;                    --7 event on monitor 0 and 1
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '0';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(21, 15));
    AERMonitorREQxABI2     <= '0';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(100, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --8 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '0';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(21, 15));
    AERMonitorREQxABI2     <= '0';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(100, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --9 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(21, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(100, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --10 take request back
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(21, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(100, 15));
    AERSnifACKxABI         <= '0';
    wait for PERIOD;                    --11 idle
    ResetxRB               <= '1';
	 SyncInxAI              <= '0';
    FifoDataxDIO           <= (others => 'Z');
    FifoInFullxSBI         <= '1';
    FifoOutEmptyxSBI       <= '0';
    RunMonitorxSI          <= '1';
    RunSynthesizerxSI      <= '0';
    TimestampTickxSI       <= '0';
    TriggerModexSI         <= '0';
    HostResetTimestampxSI  <= '0';
    PC1xSI                 <= '0';
    PExDI                  <= "0000";
    AERMonitorREQxABI      <= '1';
    AERMonitorAddressxDI   <= std_logic_vector(to_unsigned(21, 15));
    AERMonitorREQxABI2     <= '1';
    AERMonitorAddressxDI2  <= std_logic_vector(to_unsigned(100, 15));
    AERSnifACKxABI         <= '0';
    wait for 30*PERIOD;                    --2 idle


------------------------------------------------------------------------------------
-- report end of simulation run and stop simulator
    report "Simulation run completed, no more stimuli."
      severity note;

    StopSimulationxS <= '1';

    wait;                               -- wait forever to starve event queue

  end process p_stimuli_app;


end behavioural_hardcoded;

-------------------------------------------------------------------------------

configuration USBAER_top_level_cfg of USBAER_top_level_tb is
  for behavioural_hardcoded
  end for;
end USBAER_top_level_cfg;
