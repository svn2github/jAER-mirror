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
-- Description: testbench for the mergerstatemachine
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
use std.textio.all;

-------------------------------------------------------------------------------

entity mergerStateMachine_tb is

end mergerStateMachine_tb;

-------------------------------------------------------------------------------

architecture behavioural_hardcoded of mergerStateMachine_tb is

  component mergerStateMachine
    port (
	   Clk                  : in   std_logic;                    --Clock
		Rst                  : in   std_logic;                    --Reset
	   SetMonitorEventReady : in   std_logic_vector(1 downto 0); --inputs from monitor SM indicating that there is a new valid event
      ClearEventReady      : in   std_logic;                    --input from FIFO SM indicating the event has been copied to FIFO
	   MonitorEventReady    : out  std_logic_vector(1 downto 0); --output to monitor SM indicating that there is a new valid event
      EventReady           : out  std_logic;                    --output to FIFO SM indicating there is a new valid event
      Sel                  : out  std_logic);                   --output for selecting channel             
  end component;

  signal ClockxC               : std_logic;
  signal ResetxRB              : std_logic;
  signal SetMonitorEventReady  : std_logic_vector(1 downto 0);
  signal ClearEventReady       : std_logic;
  signal MonitorEventReady     : std_logic_vector(1 downto 0);
  signal EventReady            : std_logic;
  signal Sel                   : std_logic;

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
    actResp                      : in std_logic_vector(3 downto 0);
    constant expResp             : in std_logic_vector(3 downto 0)
    ) is
  begin
    if actResp/=expResp then
      report "failure, exp. resp :    " & toString(expResp) & ht & "act. resp. : " & toString(actResp)
        severity note;
    end if;
  end check_response;


begin  -- behavioural_hardcoded

  DUT : mergerStateMachine
    port map (
      Clk                  => ClockxC,
      Rst                  => ResetxRB,
      SetMonitorEventReady => SetMonitorEventReady,
      ClearEventReady      => ClearEventReady,
      MonitorEventReady    => MonitorEventReady,
      EventReady           => EventReady,
      Sel                  => Sel);
		
-------------------------------------------------------------------------------
-- clock process
-------------------------------------------------------------------------------
  p_clockgen : process
  begin

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
    ResetxRB             <= '0';
    SetMonitorEventReady <= "00";
    ClearEventReady      <= '0';
    wait for STIM_APPL;                 --1 reset
    ResetxRB             <= '0';
    SetMonitorEventReady <= "00";
    ClearEventReady      <= '0';
    wait for PERIOD;                    --2 wait
    ResetxRB             <= '1';
    SetMonitorEventReady <= "00";
    ClearEventReady      <= '0';
    wait for PERIOD;                    --3 set monitor 1
    ResetxRB             <= '1';
    SetMonitorEventReady <= "10";
    ClearEventReady      <= '0';
    wait for PERIOD;                    --4 wait
    ResetxRB             <= '1';
    SetMonitorEventReady <= "00";
    ClearEventReady      <= '0';
    wait for PERIOD;                    --5 wait
    ResetxRB             <= '1';
    SetMonitorEventReady <= "00";
    ClearEventReady      <= '0';
    wait for PERIOD;                    --6 set monitor 0 and clear event
    ResetxRB             <= '1';
    SetMonitorEventReady <= "01";
    ClearEventReady      <= '1';
    wait for PERIOD;                    --7 set monitor 1
    ResetxRB             <= '1';
    SetMonitorEventReady <= "10";
    ClearEventReady      <= '0';
    wait for PERIOD;                    --8 wait
    ResetxRB             <= '1';
    SetMonitorEventReady <= "00";
    ClearEventReady      <= '0';
    wait for PERIOD;                    --9 clear event
    ResetxRB             <= '1';
    SetMonitorEventReady <= "00";
    ClearEventReady      <= '1';
    wait for PERIOD;                    --10 wait
    ResetxRB             <= '1';
    SetMonitorEventReady <= "00";
    ClearEventReady      <= '0';
    wait for PERIOD;                    --11 wait
    ResetxRB             <= '1';
    SetMonitorEventReady <= "00";
    ClearEventReady      <= '0';
    wait for PERIOD;                    --12 clear event
    ResetxRB             <= '1';
    SetMonitorEventReady <= "00";
    ClearEventReady      <= '1';
    wait for PERIOD;            





-----------------------------------------------------------------------------
-- report end of simulation run and stop simulator
    report "Simulation run completed, no more stimuli."
      severity note;

    StopSimulationxS <= '1';

    wait;                               -- wait forever to starve event queue

  end process p_stimuli_app;

-------------------------------------------------------------------------------
-- hardcoded expected response vs. actual response comparison process
-------------------------------------------------------------------------------
  p_compare : process
  begin  -- only use addressregwritexE, since
    -- TimestampRegWritexE is equal anyway
    wait for RESP_ACQU;                 --1 reset
    check_response(MonitorEventReady & EventReady & Sel, "0000");
    wait for PERIOD;                    --2 wait 
------------------------------------------------------------------------------
-- insert your expected responses for a complete read and write sequence
    check_response(MonitorEventReady & EventReady & Sel, "0000");
    wait for PERIOD;                    --3 set monitor 1 
    check_response(MonitorEventReady & EventReady & Sel, "0000");
    wait for PERIOD;                    --4 wait
    check_response(MonitorEventReady & EventReady & Sel, "1000");
    wait for PERIOD;                    --5 wait
    check_response(MonitorEventReady & EventReady & Sel, "1001");
    wait for PERIOD;                    --6 set monitor 0 and clear event
    check_response(MonitorEventReady & EventReady & Sel, "1011");
    wait for PERIOD;                    --7 wait
--    check_response(MonitorEventReady & EventReady & Sel, "0000");
    wait for PERIOD;                    --8 wait
--    check_response(MonitorEventReady & EventReady & Sel, "0000");




-------------------------------------------------------------------------
    wait;                               -- wait forever to starve event queue

  end process p_compare;

end behavioural_hardcoded;

-------------------------------------------------------------------------------
