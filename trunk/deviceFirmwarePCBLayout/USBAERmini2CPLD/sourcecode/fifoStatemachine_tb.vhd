-------------------------------------------------------------------------------
-- Company: 
-- Engineer: raphael berner
--
-- Create Date:    13:58:57 10/24/05
-- Design Name:    
-- Module Name:    fifoStatemachine - Behavioral
-- Project Name:   USBAERmini2
-- Target Device:  
-- Tool versions:  
-- Description: testbench for the fifo statemachine
--
-- Dependencies:
-- 
-- Revision: 0.02
-- Revision 0.01 - File Created
-- Revision 0.02 - don't use extra wait cycles anymore
-- Additional Comments:
-- 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

-------------------------------------------------------------------------------

entity fifoStatemachine_tb is

end fifoStatemachine_tb;

-------------------------------------------------------------------------------

architecture behavioural_hardcoded of fifoStatemachine_tb is

  component fifoStatemachine
    port (
      ClockxCI                   : in  std_logic;
      ResetxRBI                  : in  std_logic;
      FifoInFullxSBI             : in  std_logic;
      FifoOutEmptyxSBI           : in  std_logic;
      FifoWritexEBO              : out std_logic;
      FifoReadxEBO               : out std_logic;
      FifoOutputEnablexEBO       : out std_logic;
      FifoPktEndxSBO             : out std_logic;
      FifoAddressxDO             : out std_logic_vector(1 downto 0);
      AddressRegWritexEO         : out std_logic;
      TimestampRegWritexEO       : out std_logic;
      RegisterInputSelectxSO     : out std_logic;
      AddressTimestampSelectxSO  : out std_logic_vector(1 downto 0);
      MonitorEventReadyxSI       : in  std_logic;
      ClearMonitorEventxSO       : out std_logic;
      EventRequestxSI            : in  std_logic;
      EventRequestACKxSO         : out std_logic;
      FifoTransactionxSO         : out std_logic;
      IncEventCounterxSO         : out std_logic;
      ResetEventCounterxSO       : out std_logic;
      ResetEarlyPaketTimerxSO    : out std_logic;
      TimestampOverflowxSI       : in  std_logic;
      TimestampBit15xDO          : out std_logic;
      ResetTimestampxSBI         : in  std_logic;
      TimestampBit14xDO          : out std_logic;
      EarlyPaketTimerOverflowxSI : in  std_logic);
  end component;
  
  signal ClockxC                   : std_logic;
  signal ResetxRB                  : std_logic;
  signal FifoInFullxSB             : std_logic;
  signal FifoOutEmptyxSB           : std_logic;
  signal FifoWritexEB              : std_logic;
  signal FifoReadxEB               : std_logic;
  signal FifoOutputEnablexEB       : std_logic;
  signal FifoPktEndxSB             : std_logic;
  signal FifoAddressxD             : std_logic_vector(1 downto 0);
  signal AddressRegWritexE         : std_logic;
  signal TimestampRegWritexE       : std_logic;
  signal RegisterInputSelectxS     : std_logic;
  signal AddressTimestampSelectxS  : std_logic_vector(1 downto 0);
  signal MonitorEventReadyxS       : std_logic;
  signal ClearMonitorEventxS       : std_logic;
  signal EventRequestxS            : std_logic;
  signal EventRequestACKxS         : std_logic;
  signal FifoTransactionxS         : std_logic;
  signal IncEventCounterxS         : std_logic;
  signal ResetEventCounterxS       : std_logic;
  signal ResetEarlyPaketTimerxS    : std_logic;
  signal TimestampOverflowxS       : std_logic;
  signal TimestampBit15xD          : std_logic;
  signal ResetTimestampxSB         : std_logic;
  signal TimestampBit14xD          : std_logic;
  signal EarlyPaketTimerOverflowxS : std_logic;
  
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
    actResp                      : in std_logic_vector(13 downto 0);
    constant expResp             : in std_logic_vector(13 downto 0)
    ) is
  begin
    if actResp/=expResp then
      report "failure, exp. resp :    " & toString(expResp) & ht & "act. resp. : " & toString(actResp)
        severity note;
    end if;
  end check_response;

begin  -- behavioural_hardcoded

  DUT: fifoStatemachine
    port map (
      ClockxCI                   => ClockxC,
      ResetxRBI                  => ResetxRB,
      FifoInFullxSBI             => FifoInFullxSB,
      FifoOutEmptyxSBI           => FifoOutEmptyxSB,
      FifoWritexEBO              => FifoWritexEB,
      FifoReadxEBO               => FifoReadxEB,
      FifoOutputEnablexEBO       => FifoOutputEnablexEB,
      FifoPktEndxSBO             => FifoPktEndxSB,
      FifoAddressxDO             => FifoAddressxD,
      AddressRegWritexEO         => AddressRegWritexE,
      TimestampRegWritexEO       => TimestampRegWritexE,
      RegisterInputSelectxSO     => RegisterInputSelectxS,
      AddressTimestampSelectxSO  => AddressTimestampSelectxS,
      MonitorEventReadyxSI       => MonitorEventReadyxS,
      ClearMonitorEventxSO       => ClearMonitorEventxS,
      EventRequestxSI            => EventRequestxS,
      EventRequestACKxSO         => EventRequestACKxS,
      FifoTransactionxSO         => FifoTransactionxS,
      IncEventCounterxSO         => IncEventCounterxS,
      ResetEventCounterxSO       => ResetEventCounterxS,
      ResetEarlyPaketTimerxSO    => ResetEarlyPaketTimerxS,
      TimestampOverflowxSI       => TimestampOverflowxS,
      TimestampBit15xDO          => TimestampBit15xD,
      ResetTimestampxSBI         => ResetTimestampxSB,
      TimestampBit14xDO          => TimestampBit14xD,
      EarlyPaketTimerOverflowxSI => EarlyPaketTimerOverflowxS);

-------------------------------------------------------------------------------
-- clock process
-------------------------------------------------------------------------------
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
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for STIM_APPL;                 -- 1 reset
    ResetxRB <= '0';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 2 idle, early paket timer overflow
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 3 early paket timer overflow
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 4 idle
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 5 idle, fifo full, evt ready
    ResetxRB <= '1';
    FifoInFullxSB <= '0';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 6 idle, evt ready
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 7 setup write transf
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 8 write address
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 9 write timestamp, fifo not empty
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '1';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 10 setup read, monitor event ready
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '1';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 12 read address, overflow
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '1';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '1';
    wait for PERIOD;                 -- 13 read timestamp
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '1';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 14 idle
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '0';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 15 setup write event
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 16 write address 
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 17 write timestamp
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 18 idle
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    wait for PERIOD;                 -- 19 setup overflow
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '0';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 20 write address overflow
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '0';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 21 write timestamp overflow
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '0';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 22 idle
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '0';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 23 idle, mon event ready, overflow
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '0';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '1';
    wait for PERIOD;                 -- 24 stsetupOverflow
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '0';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 25 idle, mon event ready
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '0';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                  -- 26 idle, mon event ready
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '0';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 27 idle, mon event ready
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '0';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 28 idle, mon event ready
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '0';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                 -- 29 idle, mon event ready
    ResetxRB <= '1';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '1';
    EventRequestxS <= '0';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;                -- 30 reset
    ResetxRB <= '0';
    FifoInFullxSB <= '1';
    FifoOutEmptyxSB <= '0';
    MonitorEventReadyxS <= '0';
    EventRequestxS <= '1';
    EarlyPaketTimerOverflowxS <= '0';
    ResetTimestampxSB <= '1';
    TimestampOverflowxS <= '0';
    wait for PERIOD;


---------------------------------------------------------------------
-- report end of simulation run and stop simulator
    report "Simulation run completed, no more stimuli."
      severity note;

    StopSimulationxS <= '1';

    wait;                            -- wait forever to starve event queue

  end process p_stimuli_app;

-------------------------------------------------------------------------------
-- hardcoded expected response vs. actual response comparison process
-------------------------------------------------------------------------------
  p_compare : process
  begin
    wait for RESP_ACQU;                 --1 reset
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "11110000000000");
    wait for PERIOD;                    --2 idle, early paket timer overflow
---------------------------------------------------------------------------
-- insert your expected responses for a complete read and write sequence
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "11110000000000");
    wait for PERIOD;                    --3 early paket timer overflow
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "11010000000011");
    wait for PERIOD;                    --4 idle
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "11110000000000");
    wait for PERIOD;                    --5 idle, fifo full, evt rdy
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "11110000000000");
    wait for PERIOD;                    --6 idle,  evt rdy
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "11110000000000");
    wait for PERIOD;                    --7 setup wr
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "11111110010100");
    wait for PERIOD;                    --8 write address
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "01110001000000");
    wait for PERIOD;                    --9 write timestamp
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "01110000100000");
    wait for PERIOD;                    --10 setup rd
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "11100000000000");
    wait for PERIOD;                    --12 read address
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "10101000000000");
    wait for PERIOD;                    --13 read timestamp
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "10100100001000");
    wait for PERIOD;                    --14 idle
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "11110000000000");
    wait for PERIOD;                    --15 idle, evt request
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "11110000000000");
    wait for PERIOD;                    --16 setup rd
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "11100000000000");
    wait for PERIOD;                    --17 read address
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "10101000000000");
    wait for PERIOD;                    --18 read timestamp
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "10100100001000");
    wait for PERIOD;                    --19 idle
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "11110000000000");
    wait for PERIOD;                    --20 reset
    check_response(FifoWritexEB & FifoReadxEB & FifoPktEndxSB & FifoAddressxD(1) & AddressRegWritexE & TimestampRegWritexE & RegisterInputSelectxS & AddressTimestampSelectxS & ClearMonitorEventxS & EventRequestACKxS & IncEventCounterxS & ResetEventCounterxS & ResetEarlyPaketTimerxS, "11110000000000");
    wait for PERIOD;                    --4
    


--------------------------------------------------------------------
    wait;                         -- wait forever to starve event queue
    
  end process p_compare;

end behavioural_hardcoded;

-------------------------------------------------------------------------------
