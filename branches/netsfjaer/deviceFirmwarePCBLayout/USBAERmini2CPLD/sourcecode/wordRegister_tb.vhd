-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
-------------------------------------------------------------------------------

entity wordRegister_tb is

end wordRegister_tb;

-------------------------------------------------------------------------------

architecture behavioral of wordRegister_tb is

  component wordRegister
    port (
      ClockxCI       : in  std_logic;
      ResetxRBI      : in  std_logic;
      WriteEnablexEI : in  std_logic;
      DataInxDI      : in  std_logic_vector(15 downto 0);
      DataOutxDO     : out std_logic_vector(15 downto 0));
  end component;

  signal ClockxC       : std_logic;
  signal ResetxRB      : std_logic;
  signal WriteEnablexE : std_logic;
  signal DataInxD      : std_logic_vector(15 downto 0);
  signal DataOutxD     : std_logic_vector(15 downto 0);
 
  signal StopSimulationxS : std_logic := '0';

  constant PERIOD    : time := 20 ns;   -- clock period
  constant HIGHPHASE : time := 10 ns;   -- high phase of clock
  constant LOWPHASE  : time := 10 ns;   -- low phase of clock
  constant STIM_APPL : time := 5 ns;    -- stimulus application point
  constant RESP_ACQU : time := 15 ns;   -- response acquisition point

  -- function to convert std_logic_vector in a string
  function toString(value : std_logic_vector) return string is
    variable l            : line;
  begin
    write(l, to_bitVector(value), right, 0);
    return l.all;
  end toString;

  -- procedure to compare actual response vs. expected response
  procedure check_response (
    actResp                      : in std_logic_vector(15 downto 0);
    constant expResp             : in std_logic_vector(15 downto 0)
    ) is
  begin
    if actResp/=expResp then
      report "failure, exp. resp :    " & toString(expResp) & ht & "act. resp. : " & toString(actResp)
        severity note;
    end if;
  end check_response;

begin  -- behavioral

  DUT : wordRegister
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => WriteEnablexE,
      DataInxDI      => DataInxD,
      DataOutxDO     => DataOutxD);

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

  p_stimuli_app : process
  begin
    -- init
    ResetxRB      <= '0';
    DataInxD      <= "0000000000000000";
    WriteEnablexE <= '0';
    wait for STIM_APPL;
    ResetxRB      <= '0';
    DataInxD      <= "0000000000000000";
    WriteEnablexE <= '0';
    wait for PERIOD;
    ResetxRB      <= '1';
    DataInxD      <= "0000000000000000";
    WriteEnablexE <= '0';
    wait for PERIOD;
    ResetxRB      <= '1';
    DataInxD      <= "0000010000100000";
    WriteEnablexE <= '0';
    wait for PERIOD;
    ResetxRB      <= '1';
    DataInxD      <= "0000010000100000";
    WriteEnablexE <= '1';
    wait for PERIOD;
    ResetxRB      <= '1';
    DataInxD      <= "0100000000000100";
    WriteEnablexE <= '0';
    wait for PERIOD;
    ResetxRB      <= '1';
    DataInxD      <= "0010111111110000";
    WriteEnablexE <= '1';
    wait for PERIOD;
    ResetxRB      <= '1';
    DataInxD      <= "1110010000100110";
    WriteEnablexE <= '1';
    wait for PERIOD;
    ResetxRB      <= '1';
    DataInxD      <= "1110010010100110";
    WriteEnablexE <= '0';
    wait for PERIOD;
    ResetxRB      <= '1';
    DataInxD      <= "1110010010100110";
    WriteEnablexE <= '1';

    wait for PERIOD;
    ResetxRB      <= '0';
    DataInxD      <= "1110010111100110";
    WriteEnablexE <= '1';

    wait for PERIOD;
    ResetxRB      <= '0';
    DataInxD      <= "1110011010100110";
    WriteEnablexE <= '0';

    wait for PERIOD;

------------------------------------------------------------------------------
-- report end of simulation run and stop simulator
---------------------------------------------------------------------------
    report "Simulation run completed, no more stimuli."
      severity note;

    StopSimulationxS <= '1';

    wait;                               -- wait forever to starve event queue

  end process p_stimuli_app;

-------------------------------------------------------------------------------
-- hardcoded expected response vs. actual response comparison process
-------------------------------------------------------------------------------
  p_compare : process
  begin
    wait for RESP_ACQU;
    check_response(DataOutxD, "0000000000000000");
    wait for PERIOD;
------------------------------------------------------------------------------
-- insert your expected responses for a complete read and write sequence
    check_response(DataOutxD, "0000000000000000");
    wait for PERIOD;
    check_response(DataOutxD, "0000000000000000");
    wait for PERIOD;
    check_response(DataOutxD, "0000000000000000");
    wait for PERIOD;
    check_response(DataOutxD, "0000010000100000" );
    wait for PERIOD;
    check_response(DataOutxD, "0000010000100000");
    wait for PERIOD;
    check_response(DataOutxD, "0010111111110000");
    wait for PERIOD;
    check_response(DataOutxD, "1110010000100110");
    wait for PERIOD;
    check_response(DataOutxD, "1110010000100110");
    wait for PERIOD;
    check_response(DataOutxD, "0000000000000000");
    wait for PERIOD;
    check_response(DataOutxD, "0000000000000000");


------------------------------------------------------------------------------
    wait;                               -- wait forever to starve event queue

  end process p_compare;

end behavioral;

-------------------------------------------------------------------------------
