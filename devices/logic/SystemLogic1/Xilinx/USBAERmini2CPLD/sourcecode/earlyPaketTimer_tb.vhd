-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity earlyPaketTimer_tb is

end earlyPaketTimer_tb;

-------------------------------------------------------------------------------

architecture behavioral_hardcoded of earlyPaketTimer_tb is

  component earlyPaketTimer
    port (
      ClockxCI        : in  std_logic;
      ResetxRBI       : in  std_logic;
      ClearxSI        : in  std_logic;
      ConfigxSI       : in  std_logic_vector(1 downto 0);
      TimerExpiredxSO : out std_logic);
  end component;

  signal ClockxC        : std_logic;
  signal ResetxRB       : std_logic;
  signal ClearxS        : std_logic;
  signal ConfigxS       : std_logic_vector(1 downto 0);
  signal TimerExpiredxS : std_logic;

  constant PERIOD    : time := 20 ns;   -- clock period
  constant HIGHPHASE : time := 10 ns;   -- high phase of clock
  constant LOWPHASE  : time := 10 ns;   -- low phase of clock
  constant STIM_APPL : time := 5 ns;    -- stimulus application point
  constant RESP_ACQU : time := 15 ns;   -- response acquisition point

  -- stop simulator by starving event queue
  signal StopSimulationxS : std_logic := '0';

begin  -- behavioral_hardcoded

  DUT: earlyPaketTimer
    port map (
        ClockxCI        => ClockxC,
        ResetxRBI       => ResetxRB,
        ClearxSI        => ClearxS,
        ConfigxSI       => ConfigxS,
        TimerExpiredxSO => TimerExpiredxS);

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
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for STIM_APPL;
    ResetxRB <= '0';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '1';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '1';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    ResetxRB <= '1';
    ConfigxS <= "00";
    ClearxS <= '0';
    wait for PERIOD;
    

----------------------------------------------------------------------------------------------------
-- report end of simulation run and stop simulator
    report "Simulation run completed, no more stimuli."
      severity note;

    StopSimulationxS <= '1';

    wait;                                               -- wait forever to starve event queue

  end process p_stimuli_app;


end behavioral_hardcoded;

-------------------------------------------------------------------------------
