--------------------------------------------------------------------------------
-- Company: Universidad de Sevilla
-- Engineer: Raphael Berner
--
-- Create Date:    11:54:08 10/24/05
-- Design Name:    
-- Module Name:    USBAER_top_level_tb - Structural
-- Project Name:   USBAERmini2
-- Target Device:  CoolrunnerII XC2C256
-- Tool versions:  
-- Description: testbench for top level
--
-- Dependencies:
-- 
-- Revision: 0.01
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------

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
      FifoDataxDIO          : out std_logic_vector(15 downto 0);
      FifoInFullxSBI        : in  std_logic;
      FifoWritexEBO         : out std_logic;
      FifoReadxEBO          : out std_logic;
      FifoOutputEnablexEBO  : out std_logic;
      FifoPktEndxSBO        : out std_logic;
      FifoAddressxDO        : out std_logic_vector(1 downto 0);
      IFclockxCO            : out std_logic;
      ClockxCI              : in  std_logic;
      ResetxRBI             : in  std_logic;
      SyncInxAI             : in  std_logic;
      SyncOutxSO            : out std_logic;
      TimestampTickxSI      : in  std_logic;
      TriggerModexSI        : in  std_logic;
      TimestampMasterxSO    : out std_logic;
      HostResetTimestampxSI : in  std_logic;
      RunMonitorxSI         : in  std_logic;
      Interrupt1xSB0        : out std_logic;
      LEDxSO                : out std_logic;
      Debug1xSO             : out std_logic;
      Debug2xSO             : out std_logic;
      AERMonitorREQxABI     : in  std_logic;
      AERMonitorACKxSBO     : out std_logic;
      AERMonitorAddressxDI  : in  std_logic_vector(15 downto 0));
  end component;

  signal FifoDataxD           : std_logic_vector(15 downto 0);
  signal FifoInFullxSB        : std_logic;
  signal FifoWritexEB         : std_logic;
  signal FifoReadxEB          : std_logic;
  signal FifoOutputEnablexEB  : std_logic;
  signal FifoPktEndxSB        : std_logic;
  signal FifoAddressxD        : std_logic_vector(1 downto 0);
  signal IFclockxC            : std_logic;
  signal ClockxC              : std_logic;
  signal ResetxRB             : std_logic;
  signal SyncInxA             : std_logic;
  signal SyncOutxS            : std_logic;
  signal TimestampTickxS      : std_logic;
  signal TriggerModexS        : std_logic;
  signal TimestampMasterxS    : std_logic;
  signal HostResetTimestampxS : std_logic;
  signal RunMonitorxS         : std_logic;
  signal Interrupt1xSB0       : std_logic;
  signal LEDxS                : std_logic;
  signal Debug1xS             : std_logic;
  signal Debug2xS             : std_logic;
  signal AERMonitorREQxAB     : std_logic;
  signal AERMonitorACKxSB     : std_logic;
  signal AERMonitorAddressxD  : std_logic_vector(15 downto 0);

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

  DUT: USBAER_top_level
    port map (
      FifoDataxDIO          => FifoDataxD,
      FifoInFullxSBI        => FifoInFullxSB,
      FifoWritexEBO         => FifoWritexEB,
      FifoReadxEBO          => FifoReadxEB,
      FifoOutputEnablexEBO  => FifoOutputEnablexEB,
      FifoPktEndxSBO        => FifoPktEndxSB,
      FifoAddressxDO        => FifoAddressxD,
      IFclockxCO            => IFclockxC,
      ClockxCI              => ClockxC,
      ResetxRBI             => ResetxRB,
      SyncInxAI             => SyncInxA,
      SyncOutxSO            => SyncOutxS,
      TimestampTickxSI      => TimestampTickxS,
      TriggerModexSI        => TriggerModexS,
      TimestampMasterxSO    => TimestampMasterxS,
      HostResetTimestampxSI => HostResetTimestampxS,
      RunMonitorxSI         => RunMonitorxS,
      Interrupt1xSB0        => Interrupt1xSB0,
      LEDxSO                => LEDxS,
      Debug1xSO             => Debug1xS,
      Debug2xSO             => Debug2xS,
      AERMonitorREQxABI     => AERMonitorREQxAB,
      AERMonitorACKxSBO     => AERMonitorACKxSB,
      AERMonitorAddressxDI  => AERMonitorAddressxD);
  
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
    ResetxRB                 <= '0';
    SyncInxA                  <= '1';
    RunMonitorxS             <= '0';
    FifoInFullxSB            <= '1';
    AERMonitorREQxAB         <= '1';
    TimestampTickxS <= '0';
    TriggerModexS <= '0';
    HostResetTimestampxS <= '0';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    
    wait for STIM_APPL;                 --1 reset

    ResetxRB                 <= '0';
    RunMonitorxS             <= '0';
  

    wait for PERIOD;                    --2 idle

    ResetxRB <= '0';
    RunMonitorxS <= '0';
    
    wait for PERIOD;                    --3 idle, monitor event

    ResetxRB <= '1';
    RunMonitorxS <= '0';
    wait for PERIOD;                    --4 monitor event
    ResetxRB <= '1';
    RunMonitorxS <= '0'; 
    wait for PERIOD;                    --5 monitor event
    ResetxRB <= '1';
    RunMonitorxS <= '0'; 
    wait for PERIOD;                    --6 monitor event
    ResetxRB <= '1';
    RunMonitorxS <= '0';
    wait for PERIOD;                    --7 idle
     ResetxRB <= '1';
    RunMonitorxS <= '0'; 
    wait for PERIOD;                    --8 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '0';  
    wait for PERIOD;                    --9 setup fifo read
     ResetxRB <= '1';
    RunMonitorxS <= '0';    
    wait for PERIOD;                    --10 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --11 read timest.
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --12 write synth reg
      ResetxRB <= '1';
    RunMonitorxS <= '1'; 
    wait for PERIOD;                    --13 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --14 wait
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --15 wait
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --16 wait
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --17 event out
     ResetxRB <= '1';
    RunMonitorxS <= '1';   
    wait for PERIOD;                    --18 event ack, fifo not empty
       ResetxRB <= '1';
    RunMonitorxS <= '1'; 
    wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --20 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --22 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1'; 
   wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --20 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --22 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1';  
   wait for PERIOD;                    --14 wait
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --15 wait
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --16 wait
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --17 event out
     ResetxRB <= '1';
    RunMonitorxS <= '1';   
    wait for PERIOD;                    --18 event ack, fifo not empty
       ResetxRB <= '1';
    RunMonitorxS <= '1'; 
    wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --20 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --22 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1'; 
   wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --20 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --22 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1'; 
   wait for PERIOD;                    --14 wait
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --15 wait
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --16 wait
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --17 event out
     ResetxRB <= '1';
    RunMonitorxS <= '1';   
    wait for PERIOD;                    --18 event ack, fifo not empty
       ResetxRB <= '1';
    RunMonitorxS <= '1'; 
    wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --20 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --22 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1'; 
   wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --20 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --22 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1';
        wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --20 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --22 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1'; 
   wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --20 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --22 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1';  
   wait for PERIOD;                    --14 wait
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --15 wait
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --16 wait
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --17 event out
     ResetxRB <= '1';
    RunMonitorxS <= '1';   
    wait for PERIOD;                    --18 event ack, fifo not empty
       ResetxRB <= '1';
    RunMonitorxS <= '1'; 
    wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --20 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --22 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1'; 
   wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --20 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --22 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1'; 
   wait for PERIOD;                    --14 wait
       ResetxRB <= '1';
    RunMonitorxS <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(255, 16));
     AERMonitorREQxAB         <= '0';
    wait for PERIOD;                    --15 wait
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --16 wait
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
   
     wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1'; 
    wait for PERIOD;                    --20 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';
     AERMonitorREQxAB         <= '1';
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
 
     wait for PERIOD;                    --22 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(96, 16));
     AERMonitorREQxAB         <= '0';
    wait for PERIOD;                    --15 wait
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --16 wait
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --17 event out
     ResetxRB <= '1';
    RunMonitorxS <= '1';   
    wait for PERIOD;                    --18 event ack, fifo not empty
       ResetxRB <= '1';
    RunMonitorxS <= '1'; 
    wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';
     AERMonitorREQxAB         <= '1';
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --22 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1'; 
   wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --20 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';
    wait for PERIOD;                    --16 wait
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --17 event out
     ResetxRB <= '1';
    RunMonitorxS <= '1';   
    wait for PERIOD;                    --18 event ack, fifo not empty
       ResetxRB <= '1';
    RunMonitorxS <= '1'; 
    wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';
    HostResetTimestampxS <= '1';
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --22 wait
     ResetxRB <= '1';
    RunMonitorxS <= '1'; 
   wait for PERIOD;                    --19 idle, fifo not empty
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --20 read addr
      ResetxRB <= '1';
    RunMonitorxS <= '1';
    HostResetTimestampxS <= '0';
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';
    wait for PERIOD;                    --16 wait
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --17 event out
     ResetxRB <= '1';
    RunMonitorxS <= '1';   
    wait for PERIOD;                    --18 event ack, fifo not empty
       ResetxRB <= '1';
    RunMonitorxS <= '1';
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';
    wait for PERIOD;                    --21 read timestamp
       ResetxRB <= '1';
    RunMonitorxS <= '1';
    wait for PERIOD;                    --16 wait
      ResetxRB <= '1';
    RunMonitorxS <= '1';  
    wait for PERIOD;                    --17 event out
     ResetxRB <= '1';
    RunMonitorxS <= '1';   
    wait for PERIOD;                    --18 event ack, fifo not empty
       ResetxRB <= '1';
    RunMonitorxS <= '1';  
------------------------------------------------------------------------------------
-- report end of simulation run and stop simulator
    report "Simulation run completed, no more stimuli."
      severity note;

    StopSimulationxS <= '1';

    wait;                               -- wait forever to starve event queue

  end process p_stimuli_app;


end behavioural_hardcoded;

-------------------------------------------------------------------------------
