--------------------------------------------------------------------------------
-- Company: 
-- Engineer: Raphael Berner
--
-- Create Date:    14:05:27 10/24/05
-- Design Name:    
-- Module Name:    eventCounter - Behavioral
-- Project Name:   USBAERmini2
-- Target Device:  
-- Tool versions:  
-- Description:  used to count the monitored events. if the counter reaches 128
-- (512 bytes), it resets the earlypaketcounter
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

entity eventCounter is
  port (
    ClockxCI     : in  std_logic;
    ResetxRBI    : in  std_logic;
    ClearxSI     : in  std_logic;
    IncrementxSI : in  std_logic;
    OverflowxSO  : out std_logic);
end eventCounter;

architecture Behavioral of eventCounter is
 -- present and  next state
  signal CountxDP, CountxDN : std_logic_vector(7 downto 0);  
begin

  -- calculate next state and output
  p_memoryless : process (ClearxSI, IncrementxSI, CountxDP)
  begin  -- process p_memoryless
    OverflowxSO <= '0';
    CountxDN    <= CountxDP;

    if ClearxSI = '1' then              -- a paket 
                                        -- has been sent, so reset counter
      CountxDN <= (others => '0');

    elsif CountxDP = 128 then            -- 128 events have been sent to the host,
                                        -- so clear earlypakettimer 
      OverflowxSO <= '1';
    elsif IncrementxSI = '1' then
      CountxDN <= CountxDP +1;
    end if;
  end process p_memoryless;

  p_memoryzing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      CountxDP <= (others => '0');
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      CountxDP <= CountxDN;
    end if;
  end process p_memoryzing;
end Behavioral;
