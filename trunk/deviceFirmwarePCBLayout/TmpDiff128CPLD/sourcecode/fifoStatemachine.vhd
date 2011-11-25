--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    13:58:57 10/24/05
-- Design Name:    
-- Module Name:    fifoStatemachine - Behavioral
-- Project Name:   USBAERmini2
-- Target Device:  
-- Tool versions:  
-- Description: handles the fifo transactions with the FX2
--
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

entity fifoStatemachine is
  port (
    ClockxCI               : in  std_logic;
    ResetxRBI              : in  std_logic;

    -- signal if transaction is going on
    FifoTransactionxSO         : out std_logic;

    -- fifo flags
    FifoInFullxSBI         : in  std_logic;
    FifoAlmostFullxSBI  : in  std_logic;

    -- fifo control lines
    FifoWritexEBO          : out std_logic;
    FifoPktEndxSBO         : out std_logic;
    FifoAddressxDO         : out std_logic_vector(1 downto 0);

    -- register write enable
    AddressRegWritexEO     : out std_logic;
    
    -- mux control
    AddressTimestampSelectxSO  : out std_logic;

    -- communication with other state machines
    MonitorEventReadyxSI       : in  std_logic;
    ClearMonitorEventxSO       : out std_logic;

    -- short paket stuff
    IncEventCounterxSO         : out std_logic;
    ResetEventCounterxSO       : out std_logic;
    ResetEarlyPaketTimerxSO    : out std_logic;

    -- timestamp overflow, send wrap event
    TimestampOverflowxSI : in std_logic;

    -- valid event or wrap event
    TimestampMSBxDO : out std_logic_vector(1 downto 0);

    -- reset timestamp
    ResetTimestampxSBI : in std_logic;

    -- Trigger stuff
    AddressMSBxSO : out std_logic;
    TriggerxSI : in std_logic;

    -- short paket timer overflow
    EarlyPaketTimerOverflowxSI : in  std_logic);
end fifoStatemachine;

architecture Behavioral of fifoStatemachine is
  type state is (stIdle, stEarlyPaket, stWraddress, stWrTime ,stOverflow,stResetTimestamp,stWrAddressNoEvent,stTrigger);

  -- present and next state
  signal StatexDP, StatexDN : state;

--  component EventBeforeOverflow
--    port (
--      ClockxCI               : in  std_logic;
--      ResetxRBI              : in  std_logic;
--      OverflowxDI            : in  std_logic;
--      EventxDI               : in  std_logic;
--      EventBeforeOverflowxDO : out std_logic);
--  end component;

--  signal EventBeforeOverflowxD : std_logic;
  -- timestamp overflow register
  signal TimestampOverflowxDN, TimestampOverflowxDP : std_logic_vector(15 downto 0);

  -- timestamp reset register
  signal TimestampResetxDP, TimestampResetxDN : std_logic;
  signal TriggerxDP, TriggerxDN : std_logic;
  
  -- constants for mux
  constant selectaddress   : std_logic:= '1';
  constant selecttimestamp : std_logic := '0';

  -- fifo addresses
  constant EP2             : std_logic_vector := "00";
  constant EP6             : std_logic_vector := "10";

  constant timestamp : std_logic_vector(1 downto 0) := "00";
  constant wrap : std_logic_vector(1 downto 0) := "10";
  constant timereset : std_logic_vector(1 downto 0) := "01";
begin

--  EventBeforeOverflow_1: EventBeforeOverflow
--    port map (
--      ClockxCI               => ClockxCI,
--      ResetxRBI              => ResetxRBI,
--      OverflowxDI            => TimestampOverflowxSI,
--      EventxDI               => MonitorEventReadyxSI,
--      EventBeforeOverflowxDO => EventBeforeOverflowxD);
  
  -- calculate next state and outputs
  p_memless : process (StatexDP, FifoInFullxSBI,FifoAlmostFullxSBI, MonitorEventReadyxSI,  EarlyPaketTimerOverflowxSI, TimestampOverflowxDP,TimestampOverflowxSI,TimestampResetxDP,ResetTimestampxSBI, TriggerxDP, TriggerxSI)
  begin  -- process p_memless
    -- default assignements: stay in present state, don't change address in
    -- FifoAddress register, no Fifo transaction, write registers, don't reset the counters
    StatexDN                  <= StatexDP;
    FifoWritexEBO             <= '1';
    FifoPktEndxSBO            <= '1';
    AddressRegWritexEO        <= '1';
    AddressTimestampSelectxSO <= selectaddress;
    ClearMonitorEventxSO      <= '0';
    IncEventCounterxSO        <= '0';
    ResetEventCounterxSO      <= '0';
    ResetEarlyPaketTimerxSO   <= '0';
    FifoAddressxDO            <= EP6;
    TimestampMSBxDO <= timestamp;

    if TimestampResetxDP = '1' then     -- as long as there is a timestamp
                                        -- reset pending, do not send wrap events
      TimestampOverflowxDN <= (others => '0');
    elsif TimestampOverflowxSI = '1' then
      TimestampOverflowxDN <= TimestampOverflowxDP +1;
    else
      TimestampOverflowxDN <= TimestampOverflowxDP;
    end if;
                        
    TimestampResetxDN <= (TimestampResetxDP or not ResetTimestampxSBI);
    TriggerxDN <= (TriggerxSI or TriggerxDP);

    AddressMSBxSO <= '0';

    FifoTransactionxSO <= '1';          -- is zero only in idle state

    case StatexDP is
      when stIdle =>
    --    if EventBeforeOverflowxD ='1' and FifoInFullxSBI = '1' then
    --      StatexDN <= stWraddress;
        if EarlyPaketTimerOverflowxSI = '1' and FifoAlmostFullxSBI = '1' then
                       -- we haven't commited a paket for a long time
          StatexDN <= stEarlyPaket;
        elsif TimestampResetxDP = '1' and FifoInFullxSBI = '1' then
          StatexDN <= stResetTimestamp;
        elsif TimestampOverflowxDP > 0 and FifoInFullxSBI = '1' then 
          StatexDN <= stOverflow;
        elsif TimestampOverflowxSI = '1' and FifoInFullxSBI = '1' then 
          StatexDN <= stOverflow;
          -- if inFifo is not full and there is a monitor event, start a
          -- fifoWrite transaction
        elsif TriggerxDP = '1' and FifoInFullxSBI ='1' then
          StatexDN <= stTrigger;
        elsif MonitorEventReadyxSI = '1' and FifoInFullxSBI = '1' then
          StatexDN <= stWraddress;
          --ClearMonitorEventxSO <= '1'; -- problems if we do it here
        end if;

        TimestampMSBxDO <= timestamp;
        FifoTransactionxSO        <= '0';  -- no fifo transaction running
   
      when stEarlyPaket  =>             -- ordering the FX2 to send a paket
                                         -- even if it's not full
        StatexDN                  <= stIdle;
        ResetEarlyPaketTimerxSO   <= '1';
        ResetEventCounterxSO      <= '1';
        FifoPktEndxSBO            <= '0';
      when stOverflow =>           -- send overflow event
        StatexDN <= stWrAddressNoEvent;                
        
        if TimestampOverflowxSI = '1' then
          TimestampOverflowxDN <= TimestampOverflowxDP;
        else
          TimestampOverflowxDN <= TimestampOverflowxDP - 1;
        end if;
    
        TimestampMSBxDO <= wrap;     
   
      when stResetTimestamp =>           -- send timestamp reset event

        StatexDN <= stWrAddressNoEvent;       
        TimestampResetxDN <= '0';
     
        TimestampMSBxDO <= timereset;

      when stTrigger =>           -- send trigger event

        StatexDN <= stWrAddressNoEvent;       
        TriggerxDN <= '0';
        AddressMSBxSO <= '1';
     
        TimestampMSBxDO <= timestamp;
      when stWrAddressNoEvent   =>             -- write the address to the fifo
       
        StatexDN                 <= stWrTime;
       
        FifoWritexEBO             <= '0';
        AddressRegWritexEO <= '0';
        AddressTimestampSelectxSO <= selectaddress;
        IncEventCounterxSO <= '1';
     

      when stWraddress   =>             -- write the address to the fifo
       
        StatexDN                 <= stWrTime;
       
        FifoWritexEBO             <= '0';
        AddressRegWritexEO <= '0';
        AddressTimestampSelectxSO <= selectaddress;
        IncEventCounterxSO <= '1';
        ClearMonitorEventxSO <= '1';
        
      when stWrTime      =>             -- write the timestamp to the fifo
      
        StatexDN                <= stIdle;
    
        FifoWritexEBO             <= '0';
        AddressRegWritexEO <= '0';
        AddressTimestampSelectxSO <= selecttimestamp;
    
      when others      => null;
    end case;

  end process p_memless;

  -- change state on clock edge
  p_memoryzing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      StatexDP <= stIdle;
      TimestampOverflowxDP <= (others => '0');
      TimestampResetxDP <= '0';
      TriggerxDP <= '0';
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      StatexDP <= StatexDN;
      TimestampOverflowxDP <= TimestampOverflowxDN;
      TimestampResetxDP <= TimestampResetxDN;
      TriggerxDP <= TriggerxDN;
    end if;
  end process p_memoryzing;
  
end Behavioral;
