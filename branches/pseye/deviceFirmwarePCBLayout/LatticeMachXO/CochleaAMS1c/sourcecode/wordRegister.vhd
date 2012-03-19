--------------------------------------------------------------------------------
-- Company: 
-- Engineer: raphael berner
--
-- Create Date:    17:10:41 10/24/05
-- Design Name:    
-- Module Name:    wordRegister - Behavioral
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description: generic register used for addresses and timestamps
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
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

entity wordRegister is
  generic (
    width          :     natural := 14);
  port (
    ClockxCI       : in  std_logic;
    ResetxRBI      : in  std_logic;
    WriteEnablexEI : in  std_logic;
    DataInxDI      : in  std_logic_vector(width-1 downto 0);
    DataOutxDO     : out std_logic_vector(width-1 downto 0));
end wordRegister;

architecture Behavioral of wordRegister is

  -- present and next state
  signal StatexDP, StatexDN : std_logic_vector(width-1 downto 0);

begin

  -- calculate the next state
  p_memless : process (WriteEnablexEI, DataInxDI, StatexDP)
  begin  -- process p_memless
    DataOutxDO <= StatexDP;             -- stay in present state
    StatexDN   <= StatexDP;

    if WriteEnablexEI = '1' then        -- write input to the register
      StatexDN <= DataInxDI;
    end if;

  end process p_memless;

  -- change state on clock edge
  p_memorizing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memorizing
    if ResetxRBI = '0' then
      StatexDP <= (others => '0');
    elsif ClockxCI'event and ClockxCI = '1' then
      StatexDP <= StatexDN;
    end if;
  end process p_memorizing;

end Behavioral;
