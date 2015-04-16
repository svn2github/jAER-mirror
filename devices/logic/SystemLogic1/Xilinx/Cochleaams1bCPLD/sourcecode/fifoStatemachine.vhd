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

    -- fifo control lines
    FifoWritexEBO          : out std_logic;
    FifoPktEndxSBO         : out std_logic;
    FifoAddressxDO         : out std_logic_vector(1 downto 0);

    -- register write enable
    AddressRegWritexEO     : out std_logic;
    
    -- mux control
    AddressTimestampSelectxSO  : out std_logic_vector(1 downto 0);

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
    
    -- short paket timer overflow
    EarlyPaketTimerOverflowxSI : in  std_logic);
end fifoStatemachine;

architecture Behavioral of fifoStatemachine is
  type state is (stIdle, stEarlyPaket, stWraddressLSB, stWraddressMSB, stWrTimeLSB , stWrTimeMSB ,stOverflow,stResetTimestamp,stWrAddressNoEventLSB);

  -- present and next state
  signal StatexDP, StatexDN : state;

  component EventBeforeOverflow
    port (
      ClockxCI               : in  std_logic;
      ResetxRBI              : in  std_logic;
      OverflowxDI            : in  std_logic;
      EventxDI               : in  std_logic;
      EventBeforeOverflowxDO : out std_logic);
  end component;

  signal EventBeforeOverflowxD : std_logic;
  -- timestamp overflow register
  signal TimestampOverflowxDN, TimestampOverflowxDP : std_logic;

  -- timestamp reset register
  signal TimestampResetxDP, TimestampResetxDN : std_logic;

  -- constants for mux
  
  constant selectaddressLSB : std_logic_vector(1 downto 0) := "00";
  constant selectaddressMSB : std_logic_vector(1 downto 0) := "01";  
  constant selecttimestampLSB : std_logic_vector(1 downto 0) := "10";  
  constant selecttimestampMSB : std_logic_vector(1 downto 0) := "11";  

  -- fifo addresses
  constant EP2             : std_logic_vector := "00";
  constant EP6             : std_logic_vector := "10";

  constant timestamp : std_logic_vector(1 downto 0) := "00";
  constant wrap : std_logic_vector(1 downto 0) := "10";
  constant timereset : std_logic_vector(1 downto 0) := "01";
begin

  EventBeforeOverflow_1: EventBeforeOverflow
    port map (
      ClockxCI               => ClockxCI,
      ResetxRBI              => ResetxRBI,
      OverflowxDI            => TimestampOverflowxSI,
      EventxDI               => MonitorEventReadyxSI,
      EventBeforeOverflowxDO => EventBeforeOverflowxD);
  
  -- calculate next state and outputs
  p_memless : process (StatexDP, FifoInFullxSBI, MonitorEventReadyxSI,  EarlyPaketTimerOverflowxSI, TimestampOverflowxDP,TimestampOverflowxSI,TimestampResetxDP,ResetTimestampxSBI,EventBeforeOverflowxD)
  begin  -- process p_memless
    -- default assignements: stay in present state, don't change address in
    -- FifoAddress register, no Fifo transaction, write registers, don't reset the counters
    StatexDN                  <= StatexDP;
    FifoWritexEBO             <= '1';
    FifoPktEndxSBO            <= '1';
    AddressRegWritexEO        <= '1';
    AddressTimestampSelectxSO <= selectaddressLSB;
    ClearMonitorEventxSO      <= '0';
    IncEventCounterxSO        <= '0';
    ResetEventCounterxSO      <= '0';
    ResetEarlyPaketTimerxSO   <= '0';
    FifoAddressxDO            <= EP6;
    TimestampMSBxDO <= timestamp;

    TimestampOverflowxDN <= (TimestampOverflowxDP or TimestampOverflowxSI);
    TimestampResetxDN <= (TimestampResetxDP or not ResetTimestampxSBI);
    
    FifoTransactionxSO <= '1';          -- is zero only in idle state

    case StatexDP is
      when stIdle =>
        if EventBeforeOverflowxD ='1' and FifoInFullxSBI = '1' then
          StatexDN <= stWraddressLSB;
        elsif EarlyPaketTimerOverflowxSI = '1' and FifoInFullxSBI = '1' then
                       -- we haven't commited a paket for a long time
          StatexDN <= stEarlyPaket;
        elsif TimestampOverflowxDP= '1' and FifoInFullxSBI = '1' then
          StatexDN <= stOverflow;
        elsif TimestampResetxDP = '1' and FifoInFullxSBI = '1' then
          StatexDN <= stResetTimestamp;
          -- if inFifo is not full and there is a monitor event, start a
          -- fifoWrite transaction
        elsif MonitorEventReadyxSI = '1' and FifoInFullxSBI = '1' then
          StatexDN <= stWraddressLSB;
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
        StatexDN <= stWrAddressNoEventLSB;                
        TimestampOverflowxDN <= '0';
    
        TimestampMSBxDO <= wrap;
     
        
   
      when stResetTimestamp =>           -- send timestamp reset event

        StatexDN <= stWrAddressNoEventLSB;       
        TimestampResetxDN <= '0';
     
        TimestampMSBxDO <= timereset;
     
        when stWrAddressNoEventLSB   =>             -- write the address to the fifo
       
        StatexDN                 <= stWrAddressMSB;
       
        FifoWritexEBO             <= '0';
        AddressRegWritexEO <= '0';
        AddressTimestampSelectxSO <= selectaddressLSB;
        IncEventCounterxSO <= '1';
  
     
      when stWraddressLSB   =>             -- write the address to the fifo
       
        StatexDN                 <= stWraddressMSB;
       
        FifoWritexEBO             <= '0';
        AddressRegWritexEO <= '0';
        AddressTimestampSelectxSO <= selectaddressLSB;
        IncEventCounterxSO <= '1';
        ClearMonitorEventxSO <= '1';
		  
		 when stWraddressMSB   =>             -- write the address to the fifo
       
        StatexDN                 <= stWrTimeLSB;
       
        FifoWritexEBO             <= '0';
        AddressRegWritexEO <= '0';
        AddressTimestampSelectxSO <= selectaddressMSB;
        
      when stWrTimeLSB      =>             -- write the timestamp to the fifo
      
        StatexDN                <= stWrTimeMSB ;
    
        FifoWritexEBO             <= '0';
        AddressRegWritexEO <= '0';
        AddressTimestampSelectxSO <= selecttimestampLSB;
		  
		        when stWrTimeMSB      =>             -- write the timestamp to the fifo
      
        StatexDN                <= stIdle;
    
        FifoWritexEBO             <= '0';
        AddressRegWritexEO <= '0';
        AddressTimestampSelectxSO <= selecttimestampMSB;
    
      when others      => null;
    end case;

  end process p_memless;

  -- change state on clock edge
  p_memoryzing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      StatexDP <= stIdle;
      TimestampOverflowxDP <= '0';
      TimestampResetxDP <= '0';
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      StatexDP <= StatexDN;
      TimestampOverflowxDP <= TimestampOverflowxDN;
      TimestampResetxDP <= TimestampResetxDN;
    end if;
  end process p_memoryzing;
  
end Behavioral;
