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

entity sequencerCounter is

  port (
    ClockxCI      : in  std_logic;
    ResetxRBI     : in  std_logic;
    SyncResetxRBI : in std_logic;
    IncrementxSI  : in  std_logic;
    DataxDO       : out std_logic_vector(16 downto 0));  --actual timestamp
end sequencerCounter;

architecture Behavioral of sequencerCounter is
  -- present and next state
  signal CountxDP, CountxDN           : std_logic_vector(16 downto 0);
  -- bit 15 delayed, to calculate overflow

begin

  DataxDO <= CountxDP;

 
  -- timestamp counter, calculation of next state
  p_memless : process (CountxDP, IncrementxSI,SyncResetxRBI)

  begin  -- process p_memless
    CountxDN      <= CountxDP;

    if SyncResetxRBI = '0' then
       CountxDN      <= (others => '0');
     --  CountxDN(0) <= '1';
    elsif IncrementxSI = '1' then
      CountxDN <= CountxDP +1;
    end if;
  end process p_memless;

  -- change state on clock edge
  p_memoryzing : process (ClockxCI,ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then
       CountxDP      <= (others => '0');
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      CountxDP      <= CountxDN;
    end if;
  end process p_memoryzing;
end Behavioral;

