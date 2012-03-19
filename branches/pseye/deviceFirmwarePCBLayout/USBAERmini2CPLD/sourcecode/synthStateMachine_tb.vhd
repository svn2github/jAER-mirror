-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
-------------------------------------------------------------------------------

entity synthStateMachine_tb is

end synthStateMachine_tb;

-------------------------------------------------------------------------------

architecture behavioural_hardcoded of synthStateMachine_tb is

  component synthStateMachine
    port (
      ClockxCI             : in  std_logic;
      ResetxRBI            : in  std_logic;
      RunxSI               : in  std_logic;
      AERREQxSBO           : out std_logic;
      AERACKxABI           : in  std_logic;
      EqualxSI             : in  std_logic;
      AddressRegWritexEO   : out std_logic;
      TimestampRegWritexEO : out std_logic;
      EventRequestxSO      : out std_logic;
      EventRequestACKxSI   : in  std_logic);
  end component;

  signal ClockxC             : std_logic;
  signal ResetxRB            : std_logic;
  signal RunxS               : std_logic;
  signal AERREQxSB           : std_logic;
  signal AERACKxAB           : std_logic;
  signal EqualxS             : std_logic;
  signal AddressRegWritexE   : std_logic;
  signal TimestampRegWritexE : std_logic;
  signal EventRequestxS      : std_logic;
  signal EventRequestACKxS   : std_logic;

  constant PERIOD    : time := 20 ns;   -- clock period
  constant HIGHPHASE : time := 10 ns;   -- high phase of clock
  constant LOWPHASE  : time := 10 ns;   -- low phase of clock
  constant STIM_APPL : time := 5 ns;    -- stimulus application point
  constant RESP_ACQU : time := 15 ns;   -- response acquisition point
-----------------------------------------------------------------------------
-- signal declarations
-----------------------------------------------------------------------------

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

  DUT : synthStateMachine
    port map (
      ClockxCI             => ClockxC,
      ResetxRBI            => ResetxRB,
      RunxSI               => RunxS,
      AERREQxSBO           => AERREQxSB,
      AERACKxABI           => AERACKxAB,
      EqualxSI             => EqualxS,
      AddressRegWritexEO   => AddressRegWritexE,
      TimestampRegWritexEO => TimestampRegWritexE,
      EventRequestxSO      => EventRequestxS,
      EventRequestACKxSI   => EventRequestACKxS);


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
    ResetxRB          <= '0';
    RunxS             <= '0';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for STIM_APPL;                 --1 reset
    ResetxRB          <= '0';
    RunxS             <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --2 idle
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --2 idle
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --3 go to reg write
    ResetxRB          <= '1';
    EventRequestACKxS <= '1';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --4 wait
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --5 equal
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '1';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --6 ack
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '0';
    wait for PERIOD;                    --7 idle
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --8 go to regwrite
    ResetxRB          <= '1';
    EventRequestACKxS <= '1';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --9 regwrite
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --10 wait for time, equal
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '1';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --11 wait for ack, ack
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '0';
    wait for PERIOD;                    --12 idle
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '0';
    wait for PERIOD;                    --13 go to reg write
    ResetxRB          <= '1';
    EventRequestACKxS <= '1';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --14 reg write
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --15 equal
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '1';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --16 ack
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '0';
    wait for PERIOD;                    --17 idle, go to reg write
    ResetxRB          <= '1';
    EventRequestACKxS <= '1';
    EqualxS           <= '0';
    AERACKxAB         <= '0';
    wait for PERIOD;                    --18 regwrite
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '0';
    wait for PERIOD;                    --19 wait for time
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '0';
    wait for PERIOD;                    --20 equal
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '1';
    AERACKxAB         <= '0';
    wait for PERIOD;                    --21 wait ack rls
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '0';
    wait for PERIOD;                    --22 wait ack rls, ack released
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --23 wait ack
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for PERIOD;                    --24  ack 
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '0';
    wait for PERIOD;                    --25  idle 
    ResetxRB          <= '1';
    EventRequestACKxS <= '0';
    EqualxS           <= '0';
    AERACKxAB         <= '1';
    wait for PERIOD;

----------------------------------------------------------------------------------------------------
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
  begin
    wait for RESP_ACQU;                 --1
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0001");
    wait for PERIOD;                    --2 idle
----------------------------------------------------------------------------------------------------
-- insert your expected responses for a complete read and write sequence
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0001");
    wait for PERIOD;                    --2 wait evnet
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0011");
    wait for PERIOD;                    --3 go to regwrite
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0011");
    wait for PERIOD;                    --4 wait
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "1101");
    wait for PERIOD;                    --5 equal
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0001");
    wait for PERIOD;                    --6 ack
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0000");
    wait for PERIOD;                    --7 idle
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0011");
    wait for PERIOD;                    --8 idle, go to regwrite
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0011");
    wait for PERIOD;                    --9 regwrite
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "1101");
    wait for PERIOD;                    --10 equal
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0001");
    wait for PERIOD;                    --11 ack
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0000");
    wait for PERIOD;                    --12 idle 
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0011");
    wait for PERIOD;                    --13 go to regwrite
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0011");
    wait for PERIOD;                    --14 wait 
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "1101");
    wait for PERIOD;                    --15 equal 
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0001");
    wait for PERIOD;                    --16 ack
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0000");
    wait for PERIOD;                    --17 idle, go to regwrite
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0011");
    wait for PERIOD;                    --18 wait
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "1101");
    wait for PERIOD;                    --19 wait for time
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0001");
    wait for PERIOD;                    --20 equal
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0001");
    wait for PERIOD;                    --21 wait ack rls
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0001");
    wait for PERIOD;                    --22 wait ack rls ,ack rls
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0001");
    wait for PERIOD;                    --23 wait ack
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0000");
    wait for PERIOD;                    --24 ack
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0000");
    wait for PERIOD;                    --25 idle
    check_response(AddressRegWritexE & TimestampRegWritexE & EventRequestxS & AERREQxSB, "0011");



----------------------------------------------------------------------------------------------------
    wait;                               -- wait forever to starve event queue

  end process p_compare;


end behavioural_hardcoded;

-------------------------------------------------------------------------------
