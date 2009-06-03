--------------------------------------------------------------------------------
-- Company: 
-- Engineer: raphael berner
--
-- Create Date:    14:02:00 10/24/05
-- Design Name:    
-- Module Name:    monitorStateMachine - Behavioral
-- Project Name:   USBAERmini2
-- Target Device:  
-- Tool versions:  
-- Description: handles the handshaking with the AER device(s), mealy state machine
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity monitorStateMachine is
  port (
    ClockxCI  : in std_logic;
    ResetxRBI : in std_logic;

    -- enable state machine
    RunxSI : in std_logic;

    -- aer handshake lines
    AERREQxABI     : in  std_logic;
    AERACKxSBO     : out std_logic;

    -- enable register write
    RegWritexEO   : out std_logic;

    -- communication with fifo state machine
    SetEventReadyxSO : out std_logic;
    EventReadyxSI    : in  std_logic);
end monitorStateMachine;

architecture Behavioral of monitorStateMachine is
  type state is (stIdle, stDelay,  stWaitEvent, stWriteReg, stWaitREQrls);

  -- present and next state
  signal StatexDP, StatexDN : state;

-- signals used for synchronizer
  signal AERREQxSB, AERMonitorREQxSBN  : std_logic;

  signal DelayCounterxDN, DelayCounterxDP : std_logic_vector(7 downto 0);
  
begin

  -- calculate next state and outputs
  p_memless              : process (StatexDP, AERREQxSB, EventReadyxSI, RunxSI,  AERREQxABI,DelayCounterxDP)
    constant delay : integer := 6; --47
  begin  -- process p_memless
    -- default assignments: stay in present state, AERACK is high, don't write
    -- to the registers and don't declare that an event is ready
    StatexDN             <= StatexDP;
   
    AERACKxSBO           <= '1';        -- active low!!
    RegWritexEO   <= '0';
    SetEventReadyxSO     <= '0';
    DelayCounterxDN <= DelayCounterxDP;

    case StatexDP is
      when stIdle      =>               -- we are not monitoring
        -- connecting req and ack directly, so
        -- transfers can happen
        AERACKxSBO     <= AERREQxABI;
        if RunxSI = '1' then
          StatexDN     <= stWaitEvent;
        end if;
      when stWaitEvent =>
        if EventReadyxSI = '1' then     -- the fifostatemachine still hasn't
                                        -- read the last event, so we have to wait
          StatexDN     <= stWaitEvent;
        elsif AERREQxSB = '0' then
          StatexDN   <= stDelay; --stWriteReg;
        end if;
        
        if RunxSI = '0' then
          StatexDN           <= stIdle;
        end if;
        DelayCounterxDN <= (others => '0');
      when stDelay =>
        DelayCounterxDN <= DelayCounterxDP+1;

        if DelayCounterxDP > delay then
          StatexDN <= stWriteReg;
        end if;
      when stWriteReg =>                -- write timestamp and address to
                                        -- registers,acknowledge to AER device
                                        -- and set the EventReady flag
        StatexDN             <= stWaitREQrls;
        SetEventReadyxSO     <= '1';
        -- AERACKxSBO           <= '0'; acknowledge only when registers are
        -- written, this will slow down
        RegWritexEO   <= '1';

      when stWaitREQrls =>              -- wait until the AER device releases
                                        -- the REQ line so we can release the
                                        -- ACK line
        AERACKxSBO <= '0';

        if AERREQxSB = '1' then
            StatexDN   <= stWaitEvent;
            --AERACKxSBO <= '1';          -- release ack as soon as possible
        end if;
  
      when others => null;
    end case;
  end process p_memless;

  -- change state on clock edge
  p_memoryzing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      StatexDP        <= stIdle;
      DelayCounterxDP <= (others => '0');
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      StatexDP        <= StatexDN;
      DelayCounterxDP <= DelayCounterxDN;
    end if;
  end process p_memoryzing;

  -- purpose: synchronize asynchronous inputs
  -- type   : sequential
  -- inputs : ClockxCI
  -- outputs: 
  synchronizer : process (ClockxCI)
  begin
    if ClockxCI'event then       -- using double edge flipflops for synchronizing
      AERREQxSB         <= AERMonitorREQxSBN;
      AERMonitorREQxSBN <= AERREQxABI;
    end if;
  end process synchronizer;
end Behavioral;
