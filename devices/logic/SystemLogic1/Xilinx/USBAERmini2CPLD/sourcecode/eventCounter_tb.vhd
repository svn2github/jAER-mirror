-------------------------------------------------------------------------------
-- Company: 
-- Engineer: Raphael Berner
--
-- Create Date:    14:05:27 10/24/05
-- Design Name:    
-- Module Name:    eventCounter_tb 
-- Project Name:   USBAERmini2
-- Target Device:  
-- Tool versions:  
-- Description: testbench for the module eventCounter
--  IMPORTANT: change eventcounter to 5 bit counter before running this
--  testbench! testing is with an 8 bit counter would be cumbersome, and the
--  functional verification is the same with a 5 bit counter.
--
-- Dependencies:
-- 
-- Revision: 0.01
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
-------------------------------------------------------------------------------

entity eventCounter_tb is

end eventCounter_tb;

-------------------------------------------------------------------------------

architecture behavioural_hardcoded of eventCounter_tb is

  component eventCounter
    port (
      ClockxCI     : in  std_logic;
      ResetxRBI    : in  std_logic;
      ClearxSI     : in  std_logic;
      IncrementxSI : in  std_logic;
      OverflowxSO  : out std_logic);
  end component;

  signal ClockxC     : std_logic;
  signal ResetxRB    : std_logic;
  signal ClearxS     : std_logic;
  signal IncrementxS : std_logic;
  signal OverflowxS  : std_logic;

  constant PERIOD    : time := 20 ns;   -- clock period
  constant HIGHPHASE : time := 10 ns;   -- high phase of clock
  constant LOWPHASE  : time := 10 ns;   -- low phase of clock
  constant STIM_APPL : time := 5 ns;    -- stimulus application point
  constant RESP_ACQU : time := 15 ns;   -- response acquisition point

  signal StopSimulationxS : std_logic := '0';

  -- function to convert std_logic_vector in a string
  function toString(value : std_logic) return string is
    variable l : line;
  begin
    write(l, to_bit(value), right, 0);
    return l.all;
  end toString;

  -- procedure to compare actual response vs. expected response
  procedure check_response (
    actResp   : in std_logic;
    constant expResp : in std_logic
    ) is
  begin
    if actResp/=expResp then
      report "failure, exp. resp: " & toString(expResp) & ht & "act. resp.: " & toString(actResp)
        severity note;
    end if;
  end check_response;

begin  -- behavioural_hardcoded

  DUT: eventCounter
    port map (
        ClockxCI     => ClockxC,
        ResetxRBI    => ResetxRB,
        ClearxSI     => ClearxS,
        IncrementxSI => IncrementxS,
        OverflowxSO  => OverflowxS);

   p_clockgen : process
  begin
    
    loop 
      
      ClockxC <= '1';
      wait for HIGHPHASE ;
      ClockxC <= '0';
      wait for LOWPHASE;
      
      if StopSimulationxS = '1' then
        wait;   -- wait forever to starve event queue
      end if;
    end loop;
  end process p_clockgen;
  
  
-------------------------------------------------------------------------------
-- hardcoded stimuli application process
-------------------------------------------------------------------------------

  p_stimuli_app : process
  begin
    -- init
    ResetxRB <= '0';
    ClearxS <= '0';
    IncrementxS <= '0';
    wait for STIM_APPL;                 -- cycle 1
    ResetxRB <= '0';
    ClearxS <= '0';
    IncrementxS <= '0';
    wait for PERIOD;                    -- 2
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 3
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    --4
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '0';
    wait for PERIOD;                    -- 5
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    --6
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '0';
    wait for PERIOD;                    --7
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    --8
    ResetxRB <= '1';
    ClearxS <= '1';
    IncrementxS <= '0';
    wait for PERIOD;                    -- 9
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '0';
    wait for PERIOD;                    -- 10
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '0';
    wait for PERIOD;                    -- 11
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 12
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 13
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 14
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 15
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 16
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 17
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 18
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 19
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 20
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 21
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 22
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 23
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 24
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 25
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 25.2
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '0';
    wait for PERIOD;                    -- 26
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 27
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 28
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 29
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 30
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 31
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 32
    ResetxRB <= '1';
    ClearxS <= '1';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 33
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '0';
    wait for PERIOD;                    -- 34
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 35
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '0';
    wait for PERIOD;                    -- 36
    ResetxRB <= '1';
    ClearxS <= '0';
    IncrementxS <= '1';
    wait for PERIOD;                    -- 37
    ResetxRB <= '0';
    ClearxS <= '0';
    IncrementxS <= '0';
    wait for PERIOD;                    -- 38
    ResetxRB <= '0';
    ClearxS <= '0';
    IncrementxS <= '0';

    wait for PERIOD;

-----------------------------------------------------------------------------
-- report end of simulation run and stop simulator
    report "Simulation run completed, no more stimuli."
      severity note;

    StopSimulationxS <= '1';

    wait;                         -- wait forever to starve event queue

  end process p_stimuli_app;

-------------------------------------------------------------------------------
-- hardcoded expected response vs. actual response comparison process
-------------------------------------------------------------------------------
  p_compare : process
  begin
    wait for RESP_ACQU;                 -- 1
    check_response(OverflowxS, '0');    
    wait for PERIOD;                    --2
------------------------------------------------------------------------------
-- insert your expected responses for a complete read and write sequence
    check_response(OverflowxS, '0');
    wait for PERIOD;                    --3
    check_response(OverflowxS, '0');
    wait for PERIOD;                    --4
    check_response(OverflowxS, '0');
    wait for PERIOD;                    --5
    check_response(OverflowxS, '0');
    wait for PERIOD;                    --6 
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 7
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 8
    check_response(OverflowxS, '0');
    wait for PERIOD;                    --9 
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 10
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 11
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 12
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 13
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 14
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 15
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 16
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 17
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 18
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 19
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 20
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 21
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 22
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 23
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 24
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 25
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 25.2  -- inserted for an extra cycle
                                        -- since inc can actually not be high
                                        -- for to clock cycles in series
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 26
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 27
    check_response(OverflowxS, '1');
    wait for PERIOD;                    -- 28
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 29
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 30
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 31
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 32
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 33
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 34
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 35
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 36
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 37
    check_response(OverflowxS, '0');
    wait for PERIOD;                    -- 38
    check_response(OverflowxS, '0');


----------------------------------------------------------------------------------------------------
    wait;                                               -- wait forever to starve event queue
    
  end process p_compare;

end behavioural_hardcoded;

-------------------------------------------------------------------------------
