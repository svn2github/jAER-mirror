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
      FifoDataxDIO              : inout std_logic_vector(15 downto 0);
      FifoInFullxSBI            : in    std_logic;
      FifoOutEmptyxSBI          : in    std_logic;
      FifoWritexEBO             : out   std_logic;
      FifoReadxEBO              : out   std_logic;
      FifoOutputEnablexEBO      : out   std_logic;
      FifoPktEndxSBO            : out   std_logic;
      ClockxCI                  : in    std_logic;
      SynchxRI                  : in    std_logic;
      RunMonitorxSI             : in    std_logic;
      RunSynthesizerxSI         : in    std_logic;
      SynchOutxSO               : out   std_logic;
      ResetxRBI                 : in    std_logic;
      ConfigTimestampCounterxSI : in    std_logic_vector(1 downto 0);
      ConfigEarlyPaketTimerxSI  : in    std_logic_vector(1 downto 0);
      AERMonitorREQxABI         : in    std_logic;
      AERSnifACKxABI            : in    std_logic;
      AERSnifREQxSBO            : out   std_logic;
      AERMonitorACKxSBO         : out   std_logic;
      AERSynthREQxSBO           : out   std_logic;
      AERSynthACKxABI           : in    std_logic;
      AERMonitorAddressxDI      : in    std_logic_vector(15 downto 0);
      AERSynthAddressxDO        : out   std_logic_vector(15 downto 0);
      FifoAddressxDO            : out   std_logic_vector(1 downto 0));
  end component;

  signal FifoDataxD               : std_logic_vector(15 downto 0);
  signal FifoInFullxSB            : std_logic;
  signal FifoOutEmptyxSB          : std_logic;
  signal FifoWritexEB             : std_logic;
  signal FifoReadxEB              : std_logic;
  signal FifoOutputEnablexEB      : std_logic;
  signal FifoPktEndxSB            : std_logic;
  signal ClockxC                  : std_logic;
  signal RunMonitorxS             : std_logic;
  signal RunSynthesizerxS         : std_logic;
  signal SynchxR                  : std_logic;
  signal SynchOutxS               : std_logic;
  signal ResetxRB                 : std_logic;
  signal ConfigTimestampCounterxS : std_logic_vector(1 downto 0);
  signal ConfigEarlyPaketTimerxS  : std_logic_vector(1 downto 0);
  signal AERMonitorREQxAB         : std_logic;
  signal AERSnifACKxAB            : std_logic;
  signal AERSnifREQxSB            : std_logic;
  signal AERMonitorACKxSB         : std_logic;
  signal AERSynthREQxSB           : std_logic;
  signal AERSynthACKxAB           : std_logic;
  signal AERMonitorAddressxD      : std_logic_vector(15 downto 0);
  signal AERSynthAddressxD        : std_logic_vector(15 downto 0);
  signal FifoAddressxD            : std_logic_vector(1 downto 0);

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
      FifoDataxDIO              => FifoDataxD,
      FifoInFullxSBI            => FifoInFullxSB,
      FifoOutEmptyxSBI          => FifoOutEmptyxSB,
      FifoWritexEBO             => FifoWritexEB,
      FifoReadxEBO              => FifoReadxEB,
      FifoOutputEnablexEBO      => FifoOutputEnablexEB,
      FifoPktEndxSBO            => FifoPktEndxSB,
      ClockxCI                  => ClockxC,
      RunMonitorxSI             => RunMonitorxS,
      RunSynthesizerxSI         => RunSynthesizerxS,
      SynchxRI                  => SynchxR,
      SynchOutxSO               => SynchOutxS,
      ResetxRBI                 => ResetxRB,
      ConfigTimestampCounterxSI => ConfigTimestampCounterxS,
      ConfigEarlyPaketTimerxSI  => ConfigEarlyPaketTimerxS,
      AERMonitorREQxABI         => AERMonitorREQxAB,
      AERSnifACKxABI            => AERSnifACKxAB,
      AERSnifREQxSBO            => AERSnifREQxSB,
      AERMonitorACKxSBO         => AERMonitorACKxSB,
      AERSynthREQxSBO           => AERSynthREQxSB,
      AERSynthACKxABI           => AERSynthACKxAB,
      AERMonitorAddressxDI      => AERMonitorAddressxD,
      AERSynthAddressxDO        => AERSynthAddressxD,
      FifoAddressxDO            => FifoAddressxD);

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
    SynchxR                  <= '0';
    RunSynthesizerxS         <= '0';
    RunMonitorxS             <= '0';
    ConfigEarlyPaketTimerxS  <= "00";
    ConfigTimestampCounterxS <= "00";
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for STIM_APPL;                 --1 reset
    ResetxRB                 <= '0';
    SynchxR                  <= '0';
    RunMonitorxS             <= '1';
    RunSynthesizerxS         <= '1';
    ConfigEarlyPaketTimerxS  <= "00";
    ConfigTimestampCounterxS <= "00";
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --2 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --3 idle, monitor event
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '0';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(124, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --4 monitor event
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '0';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(124, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --5 monitor event
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '0';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(124, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --6 monitor event
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '0';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --7 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --8 idle, fifo not empty
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --9 setup fifo read
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --10 read addr
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= std_logic_vector(to_unsigned(24, 16));
    wait for PERIOD;                    --11 read timest.
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= std_logic_vector(to_unsigned(4, 16));
    wait for PERIOD;                    --12 write synth reg
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --13 wait
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --14 wait
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --15 wait
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --16 wait
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --17 event out
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --16 wait
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --18 event ack, fifo not empty
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '0';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --19 idle, fifo not empty
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --20 read addr
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= std_logic_vector(to_unsigned(54, 16));
    wait for PERIOD;                    --21 read timestamp
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= std_logic_vector(to_unsigned(1, 16));
    wait for PERIOD;                    --22 wait
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --23 wait
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --24 wait
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --25 event out
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --26 ack
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '0';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --27 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '1';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --28 idle, monitor req
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '0';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(127, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --29 write reg
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '0';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(127, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --30 write fifo reg
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --31 write addr
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --32 write times
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '0';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(24, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --33 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '0';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(24, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --34 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --35 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --36 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --37 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --38 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --39 idle, synch
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --40 idle, fifo not empty
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --41 read add
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= std_logic_vector(to_unsigned(1023, 16));
    wait for PERIOD;                    --42 read timestamp
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= std_logic_vector(to_unsigned(5, 16));
    wait for PERIOD;                    --43 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --44 evt out
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --45 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '0';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --46 idle, event req
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --47 read add
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= std_logic_vector(to_unsigned(3400, 16));
    wait for PERIOD;                    --48 read times
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= std_logic_vector(to_unsigned(2, 16));
    wait for PERIOD;                    --49 write reg
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --50 wait time
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --51 wait aer ack
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '0';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --52 idle, evt request
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --53 read address
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= std_logic_vector(to_unsigned(8000, 16));
    wait for PERIOD;                    --54 read timestamp
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= std_logic_vector(to_unsigned(1, 16));
    wait for PERIOD;                    --55 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --56 write reg
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --57 wait ack
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '1';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '0';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --58 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --59 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;                    --60 idle
    ResetxRB                 <= '1';
    SynchxR                  <= '0';
    FifoInFullxSB            <= '1';
    FifoOutEmptyxSB          <= '0';
    AERMonitorREQxAB         <= '1';
    AERSnifACKxAB            <= '0';
    AERSynthACKxAB           <= '1';
    AERMonitorAddressxD      <= std_logic_vector(to_unsigned(0, 16));
    FifoDataxD               <= (others => 'Z');
    wait for PERIOD;


------------------------------------------------------------------------------------
-- report end of simulation run and stop simulator
    report "Simulation run completed, no more stimuli."
      severity note;

    StopSimulationxS <= '1';

    wait;                               -- wait forever to starve event queue

  end process p_stimuli_app;


end behavioural_hardcoded;

-------------------------------------------------------------------------------
