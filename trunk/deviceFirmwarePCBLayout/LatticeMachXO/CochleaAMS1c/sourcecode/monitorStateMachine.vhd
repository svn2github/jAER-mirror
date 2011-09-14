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

entity monitorStateMachine is
  port (
    ClockxCI               : in  std_logic;
    ResetxRBI              : in  std_logic;

   -- aer handshake lines
    AERREQxSBI     : in  std_logic;
    AERACKxSBO     : out std_logic;

   -- XxDI : in std_logic;
    UseLongAckxSI : in std_logic;
    
    -- fifo flags
    FifoFullxSI         : in  std_logic;

    -- fifo control lines
    FifoWritexEO          : out std_logic;

    -- register write enable
    TimestampRegWritexEO     : out std_logic;
    
    -- mux control
    AddressTimestampSelectxSO  : out std_logic_vector(1 downto 0);

    -- ADC interface
    ADCvalueReadyxSI : in std_logic;
    ReadADCvaluexEO : out std_logic;
    
    -- timestamp overflow, send wrap event
    TimestampOverflowxSI : in std_logic;

    -- valid event or wrap event
    AddressMSBxDO : out std_logic_vector(1 downto 0);

    -- reset timestamp
    ResetTimestampxSBI : in std_logic
    );
end monitorStateMachine;

architecture Behavioral of monitorStateMachine is
  type state is (stIdle,  stWraddress, stWrTime ,stOverflow,stResetTimestamp, stFifoFull, stReqRelease, stADC, stADCTime);

  -- for synchronizing AER Req
  signal AERREQxSB: std_logic;

  -- present and next state
  signal StatexDP, StatexDN : state;
  signal CountxDP, CountxDN : std_logic_vector(4 downto 0);

  -- timestamp overflow register
  signal TimestampOverflowxDN, TimestampOverflowxDP : std_logic;

  -- timestamp reset register
  signal TimestampResetxDP, TimestampResetxDN : std_logic;

  -- constants for mux
  constant selectADC : std_logic_vector(1 downto 0) := "11";
  constant selectaddress   : std_logic_vector(1 downto 0) := "01";
  constant selecttimestamp : std_logic_vector(1 downto 0) := "00";

  constant address : std_logic_vector(1 downto 0) := "00";
  constant wrap : std_logic_vector(1 downto 0) := "10";
  constant timereset : std_logic_vector(1 downto 0) := "11";
  constant timestamp : std_logic_vector(1 downto 0) := "01";

  constant ackExtension : integer := 8;  -- number of clockcycles ack should stay active

begin
  AERREQxSB <= AERREQxSBI;

-- calculate next state and outputs
  p_memless : process (StatexDP, FifoFullxSI, TimestampOverflowxDP,TimestampOverflowxSI,TimestampResetxDP,ResetTimestampxSBI, AERREQxSB, ADCvalueReadyxSI,CountxDP,UseLongAckxSI)
  begin  -- process p_memless
    -- default assignements: stay in present state, don't change address in
    -- FifoAddress register, no Fifo transaction, 
    StatexDN                  <= StatexDP;
    CountxDN <= (others => '0');
    FifoWritexEO             <= '0';
  
    TimestampRegWritexEO        <= '1';
    AddressTimestampSelectxSO <= selectaddress;
    
    AddressMSBxDO <= address;

    AERACKxSBO <= '1';

    TimestampOverflowxDN <= (TimestampOverflowxDP or TimestampOverflowxSI);
    TimestampResetxDN <= (TimestampResetxDP or not ResetTimestampxSBI);

    ReadADCvaluexEO <= '0';

    case StatexDP is
      when stIdle =>

        if FifoFullxSI = '1' then
          StatexDN <= stFifoFull;
        
        elsif TimestampOverflowxDP= '1' then
          StatexDN <= stOverflow;
        elsif TimestampResetxDP = '1'  then
          StatexDN <= stResetTimestamp;
          -- if inFifo is not full and there is a monitor event, start a
          -- fifoWrite transaction
        elsif ADCvalueReadyxSI ='1' then
          StatexDN <= stADCTime;
        elsif AERREQxSB = '0' then
       --   if XxDI = '0' then
            TimestampRegWritexEO <= '0';
            StatexDN <= stWrTime;
      --    else
       --     StatexDN <= stWraddress;
       --   end if;
        end if;

        AddressMSBxDO <= address;

        AERACKxSBO <= '1';
   
      when stOverflow =>           -- send overflow event
        StatexDN <= stIdle;                
        TimestampOverflowxDN <= '0';

        AddressMSBxDO <= wrap;
        AddressTimestampSelectxSO <= selectaddress;
        FifoWritexEO <= '1';
   
      when stResetTimestamp =>           -- send timestamp reset event

        StatexDN <= stIdle;       
        TimestampResetxDN <= '0';
        TimestampOverflowxDN <= '0';
        AddressMSBxDO <= timereset;
        AddressTimestampSelectxSO <= selectaddress;
        FifoWritexEO <= '1';
      when stADCTime      =>             -- write the timestamp to the fifo

        StatexDN <= stADC;
    
        FifoWritexEO             <= '1';
        TimestampRegWritexEO <= '0';
        AddressTimestampSelectxSO <= selecttimestamp;
        AddressMSBxDO <= timestamp;
     when stADC   =>             -- write the ADC word to the fifo
        
        StatexDN              <= stIdle;
        
        FifoWritexEO             <= '1';
        AddressTimestampSelectxSO <= selectADC;
        ReadADCvaluexEO <= '1';
        AddressMSBxDO <= address;
      when stWraddress   =>             -- write the address to the fifo
     
        StatexDN                  <= stReqRelease;
     
        FifoWritexEO             <= '1';
        TimestampRegWritexEO <= '0';
        AddressTimestampSelectxSO <= selectaddress;
        AERACKxSBO <= '0';
        AddressMSBxDO <= address;
      when stWrTime      =>             -- write the timestamp to the fifo

        StatexDN <= stWraddress;

        AERACKxSBO <= '0';
        FifoWritexEO             <= '1';
        TimestampRegWritexEO <= '0';
        AddressTimestampSelectxSO <= selecttimestamp;
        AddressMSBxDO <= timestamp;

      when stReqRelease =>
        AERACKxSBO <= '0';
        CountxDN <= CountxDP +1;
        if AERREQxSB = '1' then
          if UseLongAckxSI = '0' then
            StatexDN <= stIdle;
          elsif CountxDP > ackExtension then
            StatexDN <= stIdle;
          end if;
        end if;

      when stFifoFull =>                -- acknowledge (and trow away) events
                                        -- as long as fifo is full, only go
                                        -- back to idle state when sender is
                                        -- not requesting
        AERACKxSBO <= AERREQxSB;
        if FifoFullxSI = '0' and AERREQxSB = '1' then
          StatexDN <= stIdle;
        end if;
      when others      => null;
    end case;

  end process p_memless;

  -- change state on clock edge
  p_memoryzing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      StatexDP <= stIdle;
      CountxDP <= (others => '0');
      TimestampOverflowxDP <= '0';
      TimestampResetxDP <= '0';
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      StatexDP <= StatexDN;
      TimestampOverflowxDP <= TimestampOverflowxDN;
      TimestampResetxDP <= TimestampResetxDN;
      CountxDP <= CountxDN;
    end if;
  end process p_memoryzing;
  
end Behavioral;
