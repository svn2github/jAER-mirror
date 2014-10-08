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
    AERSnifACKxABI : in  std_logic;
    AERACKxSBO     : out std_logic;
    AERSnifREQxSBO : out std_logic;

    -- enable register write
    AddressRegWritexEO   : out std_logic;
    TimestampRegWritexEO : out std_logic;

    -- communication with fifo state machine
    SetEventReadyxSO : out std_logic;
    EventReadyxSI    : in  std_logic;

    -- connected to interrupt 1 on 8051
    MissedEventxSO : out std_logic;

    -- EP6 full
    FifoFullxSBI : in std_logic;

    MissEventsEnabledxEI : in std_logic;
    -- was used for timeout mechanism, not used anymore
    OverflowxSI : in std_logic);
end monitorStateMachine;

architecture Behavioral of monitorStateMachine is
  type state is (stIdle, stWaitEvent, stWriteReg, stWaitREQrls, stSnfWriteReg, stSnfWaitAERack, stSnfWaitAERReqrls, stSnfWaitACKrls, stFifoFull, stSnfFifoFull, stSnfMissedEvent, stMissedEvent);
  --Snf: sniffer mode states

  -- present and next state
  signal StatexDP, StatexDN : state;

-- signal TimeoutxDP, TimeoutxDN : std_logic_vector(1 downto 0);
  signal MissedEventsxDP, MissedEventsxDN : std_logic_vector(3 downto 0);

-- signals used for synchronizer
  signal AERREQxSB, AERMonitorREQxSBN  : std_logic;
  signal AERSnifACKxSB, AERSnifACKxSBN : std_logic;
begin

  -- calculate next state and outputs
  p_memless              : process (StatexDP, AERREQxSB, AERSnifACKxSB, EventReadyxSI, RunxSI, OverflowxSI, AERREQxABI, AERSnifACKxABI, FifoFullxSBI, MissedEventsxDP,MissEventsEnabledxEI) 
  begin  -- process p_memless
    -- default assignments: stay in present state, AERACK is high, don't write
    -- to the registers and don't declare that an event is ready
    StatexDN             <= StatexDP;
    MissedEventsxDN      <= MissedEventsxDP;
    AERACKxSBO           <= '1';        -- active low!!
    AERSnifREQxSBO       <= '1';        -- active low!!
    AddressRegWritexEO   <= '0';
    TimestampRegWritexEO <= '0';
    SetEventReadyxSO     <= '0';
    MissedEventxSO       <= MissedEventsxDP(3);

    case StatexDP is
      when stIdle      =>               -- we are not monitoring
        -- connecting req and ack directly, so
        -- transfers can happen
        AERSnifREQxSBO <= AERREQxABI;
        AERACKxSBO     <= AERSnifACKxABI;
        if RunxSI = '1' then
          StatexDN     <= stWaitEvent;
        end if;
      when stWaitEvent =>
        if EventReadyxSI = '1' then     -- the fifostatemachine still hasn't
                                        -- read the last event, so we have to wait
          StatexDN     <= stWaitEvent;
        elsif AERREQxSB = '0' then
          if AERSnifACKxSB = '1' then   -- if SnifAck is high, this means a
                                        -- device is attached, we are in
                                        -- sniffing mode. use a big pull-down
                                        -- resistor to assure snifack=0 if no
                                        -- device is attached
            StatexDN   <= stSnfWriteReg;
          else
            StatexDN   <= stWriteReg;
          end if;
        end if;
        AERSnifREQxSBO <= AERREQxSB;

        if RunxSI = '0' then
          StatexDN           <= stIdle;
        end if;
      when stWriteReg =>                -- write timestamp and address to
                                        -- registers,acknowledge to AER device
                                        -- and set the EventReady flag
        StatexDN             <= stWaitREQrls;
        SetEventReadyxSO     <= '1';
        AERACKxSBO           <= '0';
        AddressRegWritexEO   <= '1';
        TimestampRegWritexEO <= '1';

      when stWaitREQrls =>              -- wait until the AER device releases
                                        -- the REQ line so we can release the
                                        -- ACK line
        AERACKxSBO <= '0';

        if AERREQxSB = '1' then
          if FifoFullxSBI = '0' and MissEventsEnabledxEI = '1' then    -- when the fifo is full
            StatexDN   <= stFifoFull;
          else
            StatexDN   <= stWaitEvent;
            AERACKxSBO <= '1';          -- release ack as soon as possible
          end if;
        end if;

      when stSnfWriteReg =>             -- write timestamp and address to
                                        -- registers
                                        -- and set the EventReady flag and set
                                        -- AER REQ to receiving device
        AddressRegWritexEO   <= '1';
        TimestampRegWritexEO <= '1';
        SetEventReadyxSO     <= '1';
        AERSnifREQxSBO       <= '0';

        if AERSnifACKxSB = '0' then     -- if receiving device has already acked
          statexDN   <= stSnfWaitAERReqrls;
          AERACKxSBO <= '0';
        else
          StatexDN   <= stSnfWaitAERack;  -- we have to wait for the
                                        -- receiving AER device to ACK
        end if;

      when stSnfWaitAERack    =>        -- wait for the receiving AER device to
                                        -- ACK
        AERSnifREQxSBO   <= '0';
        if AERSnifACKxSB = '0' then     -- release AERreq as soon as the device
                                        -- acks -> mealy machine: this way
                                        -- faster operation should be possible
          StatexDN       <= stSnfWaitAERReqrls;
          AERSnifREQxSBO <= '1';     
          AERACKxSBO     <= '0';
        end if;
      when stSnfWaitAERReqrls =>        -- wait for the sending AER device to
                                        -- release ACK, release AERSnifREQxSBO
        AERACKxSBO       <= '0';

        if AERREQxSB = '1' and AERSnifACKxSB = '1' then
          StatexDN   <= stWaitEvent;
          AERACKxSBO <= '1';            -- release ack as soon as possible
        elsif AERREQxSB = '1' then      -- request released, so we have to wait
                                        -- until the receiving device releases
                                        -- the ACK
          StatexDN   <= stSnfWaitACKrls;
        end if;

      when stSnfWaitACKrls =>           -- wait for the receiving device to
                                        -- release ACK
        AERACKxSBO <= '0';

        if AERSnifACKxSB = '1' then     -- receiving device released ACK, so
                                        -- back to idle
          if FifoFullxSBI = '0' and MissEventsEnabledxEI = '1' then
            StatexDN   <= stSnfFifoFull;
          else
            StatexDN   <= stWaitEvent;
            AERACKxSBO <= '1';          --release ack as soon as possible
          end if;
        end if;
      when stFifoFull =>
        AERACKxSBO     <= AERREQxSB;    -- ack events as long as fifo is full

        if FifoFullxSBI = '1' then

          StatexDN        <= stWaitEvent;
        elsif AERREQxSB = '0' then
          StatexDN        <= stMissedEvent;
          MissedEventsxDN <= MissedEventsxDP + 1;
        end if;
      when stSnfFifoFull =>
        AERACKxSBO        <= AERSnifACKxSB;  -- pass through events as long as fifo
        AERSnifREQxSBO    <= AERREQxSB;  -- is full

        if FifoFullxSBI = '1' then
          StatexDN        <= stWaitEvent;
        elsif AERREQxSB = '0' then
          StatexDN        <= stSnfMissedEvent;
          MissedEventsxDN <= MissedEventsxDP + 1;
        end if;
      when stMissedEvent =>
        AERACKxSBO        <= AERREQxSB;  -- ack events as long as fifo full

        if AERREQxSB = '1' then
          StatexDN     <= stFifoFull;
        end if;
      when stSnfMissedEvent =>
        AERACKxSBO     <= AERSnifACKxSB;  -- pass through events as long as fifo
        AERSnifREQxSBO <= AERREQxSB;    -- is full

        if AERREQxSB = '1' then
          StatexDN <= stSnfFifoFull;
        end if;
      when others => null;
    end case;
  end process p_memless;

  -- change state on clock edge
  p_memoryzing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      StatexDP        <= stIdle;
      MissedEventsxDP <= (others => '0');
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      StatexDP        <= StatexDN;
      MissedEventsxDP <= MissedEventsxDN;
    end if;
  end process p_memoryzing;

  -- purpose: synchronize asynchronous inputs
  -- type   : sequential
  -- inputs : ClockxCI
  -- outputs: 
  synchronizer : process (ClockxCI)
  begin
    if ClockxCI'event then              -- using double edge flipflops for synchronizing
      AERREQxSB         <= AERMonitorREQxSBN;
      AERMonitorREQxSBN <= AERREQxABI;
      AERSnifACKxSB     <= AERSnifACKxSBN;
      AERSnifACKxSBN    <= AERSnifACKxABI;

    end if;
  end process synchronizer;
end Behavioral;
