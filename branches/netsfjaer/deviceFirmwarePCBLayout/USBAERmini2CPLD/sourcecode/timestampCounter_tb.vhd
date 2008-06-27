--------------------------------------------------------------------------------
-- Company: 
-- Engineer: raphael berner
--
-- Create Date:    14:06:46 10/24/05
-- Design Name:    
-- Module Name:    timestampCounter - Behavioral
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description: testbench for timestamp counter
--
-- Dependencies:
-- 
-- Revision: 0.01
-- Revision 0.01 - File Created
--
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

-------------------------------------------------------------------------------

entity timestampCounter_tb is

end timestampCounter_tb;

-------------------------------------------------------------------------------

architecture behavioural_hardcoded of timestampCounter_tb is

  component timestampCounter
    port (
      ClockxCI    : in  std_logic;
      ResetxRBI   : in  std_logic;
      OverflowxSO : out std_logic;
      ConfigxSI   : in  std_logic_vector(1 downto 0);
      DataxDO     : out std_logic_vector(15 downto 0));
  end component;

  signal ClockxC    : std_logic;
  signal ResetxRB   : std_logic;
  signal OverflowxS : std_logic;
  signal ConfigxS   : std_logic_vector(1 downto 0);
  signal DataxD     : std_logic_vector(15 downto 0);
  
  constant PERIOD    : time := 20 ns;   -- clock period
  constant HIGHPHASE : time := 10 ns;   -- high phase of clock
  constant LOWPHASE  : time := 10 ns;   -- low phase of clock
  constant STIM_APPL : time := 5 ns;    -- stimulus application point
  constant RESP_ACQU : time := 15 ns;   -- response acquisition point

  -- stop simulator by starving event queue
  signal StopSimulationxS : std_logic := '0';

begin  -- behavioural_hardcoded

  DUT: timestampCounter
    port map (
        ClockxCI    => ClockxC,
        ResetxRBI   => ResetxRB,
        OverflowxSO => OverflowxS,
        ConfigxSI   => ConfigxS,
        DataxDO     => DataxD);

   p_clockgen : process
  begin

    loop 
      
      ClockxC <= '1'-- Revision 0.02 - deleted SynchxSBI input, because its asynchron and has
--     therefore the same functionality as ResetxRBI; added SynchOutxSO output
--     pin
;
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
    ConfigxS  <= "00";
    wait for STIM_APPL;
    ResetxRB <= '0';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "00";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '0';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS  <= "01";
  

----------------------------------------------------------------------------------
-- report end of simulation run and stop simulator
    report "Simulation run completed, no more stimuli."
      severity note;

    StopSimulationxS <= '1';

    wait;                                               -- wait forever to starve event queue

  end process p_stimuli_app;

end behavioural_hardcoded;

-------------------------------------------------------------------------------
