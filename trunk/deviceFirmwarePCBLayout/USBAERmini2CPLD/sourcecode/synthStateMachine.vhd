-------------------------------------------------------------------------------
-- Company: 
-- Engineer: Raphael Berner
--
-- Create Date:    14:03:15 10/24/05
-- Design Name:    
-- Module Name:    synthStateMachine - Behavioral
-- Project Name:  USBAERmini2 
-- Target Device:  
-- Tool versions:  
-- Description: handles the handshaking with the receiver, enables writing to
--   synth registers, for more infos on how the statemachine works consult the
--   report in /INI-AE-Baisgen/doc/
-- 
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity synthStateMachine is
  port (
    ClockxCI  : in std_logic;
    ResetxRBI : in std_logic;

    -- enable state machine
    RunxSI : in std_logic;

    -- AER signals
    AERREQxSBO : out std_logic;
    AERACKxABI : in  std_logic;

    -- timestamp saved in register is
    -- equal to actualtime -> send out event
    EqualxSI : in std_logic;

    -- register write enable
    AddressRegWritexEO   : out std_logic;
    TimestampRegWritexEO : out std_logic;

    SequencerResetxRBO : out std_logic;

    -- communication with fifo state machine
    EventRequestxSO    : out std_logic;
    EventRequestACKxSI : in  std_logic);
end synthStateMachine;

architecture Behavioral of synthStateMachine is
  type state is (stIdle, stWaitEvent, stWriteRegisters, stWaitForTime, stWaitForACKrelease, stWaitForACK);
  signal StatexDP, StatexDN : state;    -- present and next state

  -- signals used for synchronizer
  signal AERACKxSB, AERACKSxSB : std_logic;

begin

  -- calculation of next state
  p_memless : process (AERACKxSB, EqualxSI, EventRequestACKxSI, StatexDP, RunxSI)
  begin  -- process p_memless

    -- default assignements: stay in actual state, don't write registers, don't
    -- request an event from fifo
    StatexDN               <= StatexDP;
    AddressRegWritexEO     <= '0';
    TimestampRegWritexEO   <= '0';
    AERREQxSBO             <= '1';      -- active low!!
    EventRequestxSO        <= '0';
    SequencerResetxRBO <= '1';          -- active low!!

    case StatexDP is
      when stIdle      =>
        if RunxSI = '1'then
          StatexDN      <= stWaitEvent;
        end if;
      when stWaitEvent =>
        EventRequestxSO <= '1';         -- request an event from fifo

        if EventRequestACKxSI = '1' then  -- the fifostatemachine declares it
                                        -- has an event stored in it's registers
          StatexDN               <= stWriteRegisters;
          EventRequestxSO        <= '0';
        end if;
        if RunxSI = '0' then            -- go back to idle
          StatexDN               <= stIdle;
        end if;
      when stWriteRegisters    =>
        AddressRegWritexEO       <= '1';  -- write event to registers
        TimestampRegWritexEO     <= '1';
        StatexDN                 <= stWaitForTime;
      when stWaitForTime       =>       -- wait until the timestamp stored
                                        -- equals the actual time
        if EqualxSI = '1' then          -- the time has come to send out event
          if AERACKxSB = '0' then       -- the AER device still hasn't released
                                        -- the ACK of the last event
            StatexDN             <= stWaitForACKrelease;
          else
            StatexDN             <= stWaitForACK;
          end if;
          SequencerResetxRBO <= '0';
        end if;
      when stWaitForACKrelease =>       -- the AER device still hasn't released
                                        -- the ACK of the last event
        if AERACKxSB = '1' then
          StatexDN               <= stWaitForACK;
        end if;
        
      when stWaitForACK        =>       -- sending out an AER request and wait
                                        -- for the aer device to ack
        AERREQxSBO               <= '0';

        if AERACKxSB = '0' then         -- the receiver has acked, so return to
                                        -- stwaitEvent and release request
          StatexDN <= stWaitEvent;
        end if;
      when others => null;
    end case;
  end process p_memless;

  p_memoryzing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      StatexDP <= stIdle;
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      StatexDP <= StatexDN;
    end if;
  end process p_memoryzing;

  -- purpose: synchronize asynchronous inputs
  -- type   : sequential
  -- inputs : ClockxCI
  -- outputs: 
  synchronizer : process (ClockxCI)
  begin
    if ClockxCI'event then              -- using double edge flipflops for synchronizing 
      AERACKSxSB <= AERACKxABI;
      AERACKxSB  <= AERACKSxSB;
    end if;
  end process synchronizer;
end Behavioral;
