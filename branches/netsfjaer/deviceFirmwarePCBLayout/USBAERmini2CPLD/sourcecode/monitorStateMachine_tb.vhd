--------------------------------------------------------------------------------
-- Company: 
-- Engineer: raphael berner
--
-- Create Date:    14:02:00 10/24/05
-- Design Name:    
-- Module Name:    monitorStateMachine_tb
-- Project Name:   USBAERmini2
-- Target Device:  
-- Tool versions:  
-- Description: testbench for the monitorstatemachine
--
-- Important: to simulate timeout behaviour, set the timeout counter in
--   monitorstatemachine.vhd only 3 bits wide
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

entity monitorStateMachine_tb is

end monitorStateMachine_tb;

-------------------------------------------------------------------------------

architecture behavioural_hardcoded of monitorStateMachine_tb is

  component monitorStateMachine
    port (
      ClockxCI             : in  std_logic;
      ResetxRBI            : in  std_logic;
      RunxSI               : in  std_logic;
      AERREQxABI           : in  std_logic;
      AERSnifACKxABI       : in  std_logic;
      AERACKxSBO           : out std_logic;
      AERSnifREQxSBO       : out std_logic;
      AddressRegWritexEO   : out std_logic;
      TimestampRegWritexEO : out std_logic;
      SetEventReadyxSO     : out std_logic;
      EventReadyxSI        : in  std_logic);
  end component;

  signal ClockxC             : std_logic;
  signal ResetxRB            : std_logic;
  signal RunxS               : std_logic;
  signal AERREQxAB           : std_logic;
  signal AERSnifACKxAB       : std_logic;
  signal AERACKxSB           : std_logic;
  signal AERSnifREQxSB       : std_logic;
  signal AddressRegWritexE   : std_logic;
  signal TimestampRegWritexE : std_logic;
  signal SetEventReadyxS     : std_logic;
  signal EventReadyxS        : std_logic;

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

  DUT : monitorStateMachine
    port map (
      ClockxCI             => ClockxC,
      ResetxRBI            => ResetxRB,
      RunxSI               => RunxS,
      AERREQxABI           => AERREQxAB,
      AERSnifACKxABI       => AERSnifACKxAB,
      AERACKxSBO           => AERACKxSB,
      AERSnifREQxSBO       => AERSnifREQxSB,
      AddressRegWritexEO   => AddressRegWritexE,
      TimestampRegWritexEO => TimestampRegWritexE,
      SetEventReadyxSO     => SetEventReadyxS,
      EventReadyxSI        => EventReadyxS);

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
    ResetxRB      <= '0';
    RunxS         <= '0';
    AERREQxAB     <= '1';
    AERSnifACKxAB <= '1';
    EventReadyxS  <= '0';
    wait for STIM_APPL;                 --1 reset
    ResetxRB      <= '0';
    RunxS         <= '1';
    AERREQxAB     <= '1';
    AERSnifACKxAB <= '1';
    EventReadyxS  <= '0';
    wait for PERIOD;                    --2 idle
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '1';
    AERSnifACKxAB <= '1';
    EventReadyxS  <= '0';
    wait for PERIOD;                    --2 idle
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '1';
    AERSnifACKxAB <= '1';
    EventReadyxS  <= '0';
    wait for PERIOD;                    --3 idle, req
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '1';
    EventReadyxS  <= '0';
    wait for PERIOD;                    --4 write reg snif
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '1';
    EventReadyxS  <= '0';
    wait for PERIOD;                    --5 wait snif ack
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '1';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --6 wait snif ack, snif ack
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --7 wait req rls
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --8 wait req rls, req rls
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '1';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --9 wait snif ack rls, snif ack rls
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '1';
    AERSnifACKxAB <= '1';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --10 idle, no sniffing device
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '1';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --11 idle, req & event ready
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --12 idle, req & event ready
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --13 idle, req
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '0';
    wait for PERIOD;                    --14 write reg
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '0';
    wait for PERIOD;                    --15 wait req rls
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --16 wait req rls, req rls
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '1';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --17 idle, req
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '1';
    EventReadyxS  <= '0';
    wait for PERIOD;                    --18 snif write reg, snif ack 
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '0';
    wait for PERIOD;                    --19 wait req rls, req rls, snif ack rls
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '1';
    AERSnifACKxAB <= '1';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --20 idle
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '1';
    AERSnifACKxAB <= '1';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --21 idle
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '1';
    AERSnifACKxAB <= '1';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --22 reset
    ResetxRB      <= '0';
    RunxS         <= '1';
    AERREQxAB     <= '1';
    AERSnifACKxAB <= '1';
    EventReadyxS  <= '0';
    wait for PERIOD;                    --23 reset: start testing timeout:
                                        --simulating unpowered aer sender
    ResetxRB      <= '0';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '0';
    wait for PERIOD;                    --24 idle, req
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '0';
    wait for PERIOD;                    --25 write reg
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '0';
    wait for PERIOD;                    --26 wait req release
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --27 wait req release
    ResetxRB      <= '1';
    RunxS         <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --28 wait req release
    ResetxRB      <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --29 wait req release
    ResetxRB      <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --30 wait req release
    ResetxRB      <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --31 wait req release
    ResetxRB      <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --32 wait req release
    ResetxRB      <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --33 wait req release
    ResetxRB      <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --34 should reset now, idle
    ResetxRB      <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
    wait for PERIOD;                    --35 idle
    ResetxRB      <= '1';
    AERREQxAB     <= '0';
    AERSnifACKxAB <= '0';
    EventReadyxS  <= '1';
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
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0011");
    wait for PERIOD;                    --2 idle 
------------------------------------------------------------------------------
-- insert your expected responses for a complete read and write sequence
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0011");
    wait for PERIOD;                    --2 idle 
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0011");
    wait for PERIOD;                    --3 idle, req
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0011");
    wait for PERIOD;                    --4 write reg snif
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "1110");
    wait for PERIOD;                    --5 wait snif ack
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0010");
    wait for PERIOD;                    --6 waif snif ack, snif ack
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0000");
    wait for PERIOD;                    --7 wait req rls
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0001");
    wait for PERIOD;                    --8 wait req rls, req rls
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0001");
    wait for PERIOD;                    --9 wait snif ack rls, snif ack rls
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0001");
    wait for PERIOD;                    --10 idle, no snif
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0011");
    wait for PERIOD;                    --11 idle, req & evt rdy 
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0011");
    wait for PERIOD;                    --12 idle, req & evt rdy
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0011");
    wait for PERIOD;                    --13 idle, req
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0011");
    wait for PERIOD;                    --14 write reg
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "1101");
    wait for PERIOD;                    --15 wait req rls
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0001");
    wait for PERIOD;                    --16 wait req rls, req rls
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0001");
    wait for PERIOD;                    --17 idle req
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0011");
    wait for PERIOD;                    --18 snif write req,snif ack
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "1110");
    wait for PERIOD;                    --19 wait req rls, req rls, snif ack rls
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0001");
    wait for PERIOD;                    --20 idle
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0011");
    wait for PERIOD;                    --21 idle 
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0011");
    wait for PERIOD;                    --22 reset
    check_response(AddressRegWritexE & SetEventReadyxS & AERACKxSB & AERSnifREQxSB, "0011");





-------------------------------------------------------------------------
    wait;                               -- wait forever to starve event queue

  end process p_compare;

end behavioural_hardcoded;

-------------------------------------------------------------------------------
