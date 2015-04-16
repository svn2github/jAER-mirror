--------------------------------------------------------------------------------
-- Company: 
-- Engineer: raphael berner
--
-- Create Date:    14:06:46 10/24/05
-- Design Name:    
-- Module Name:    timestampCounter - Behavioral
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description: counter to create the timestamp for incoming events and to
--    time outgoing events
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

entity timestampCounter is

  port (
    ClockxCI      : in  std_logic;
    ResetxRBI     : in  std_logic;
    IncrementxSI  : in  std_logic;
                                        -- see report for more details
    OverflowxSO   : out std_logic;      -- increment MSB on host
    DataxDO       : out std_logic_vector(13 downto 0));  --actual timestamp
end timestampCounter;

architecture Behavioral of timestampCounter is
  -- present and next state
  signal CountxDP, CountxDN           : std_logic_vector(14 downto 0);
  -- bit 15 delayed, to calculate overflow
  signal MSbDelayedxDN, MSbDelayedxDP : std_logic;

begin

  DataxDO <= CountxDP(13 downto 0);

  -- the 14 bit timestamp used for
  -- monitoring had an overflow, so send
  -- wrap event to host
  OverflowxSO <= ( CountxDP(14) xor MSbDelayedxDP);

  -- timestamp counter, calculation of next state
  p_memless : process (CountxDP, IncrementxSI, MSbDelayedxDP)

  begin  -- process p_memless
    MSbDelayedxDN <= CountxDP(14);
    CountxDN      <= CountxDP;

    if IncrementxSI = '1' then
      CountxDN <= CountxDP +1;
    end if;
  end process p_memless;

  -- change state on clock edge
  p_memoryzing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      CountxDP      <= (others => '0');
      MSbDelayedxDP <= '0';
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      CountxDP      <= CountxDN;
      MSbDelayedxDP <= MSbDelayedxDN;
    end if;
  end process p_memoryzing;
end Behavioral;

