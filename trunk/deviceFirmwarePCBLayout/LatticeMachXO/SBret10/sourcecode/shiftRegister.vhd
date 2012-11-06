--------------------------------------------------------------------------------
-- Company: 
-- Engineer: raphael berner
--
-- Create Date:    17:10:41 10/24/05
-- Design Name:    
-- Module Name:    shiftRegister - Behavioral
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

entity shiftRegister is
  generic (
    width          :     natural := 32);
  port (
    ClockxCI       : in  std_logic;
    ResetxRBI      : in  std_logic;
    LatchxEI       : in  std_logic;
    DxDI           : in  std_logic;
    QxDO           : out std_logic;
    DataOutxDO     : out std_logic_vector((width-1) downto 0));
end shiftRegister;

architecture Behavioral of shiftRegister is

  -- present and next state
  signal StatexD : std_logic_vector((width-1) downto 0);


begin

  p_latch: process (LatchxEI, ResetxRBI)
  begin  -- process p_latch\
    if ResetxRBI = '0' then
      DataOutxDO <= (others => '0');
    elsif LatchxEI'event and LatchxEI='0' then
      DataOutxDO <= StatexD;
    end if;
  end process p_latch;
  
 
  QxDO <= StatexD(width -1);

  -- change state on clock edge
  p_memorizing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memorizing
    if ResetxRBI = '0' then
      StatexD <= (others => '0');
    elsif ClockxCI'event and ClockxCI = '1' then
      StatexD((width-1) downto 1) <= StatexD((width-2) downto 0);
      StatexD(0) <= DxDI;
    end if;
  end process p_memorizing;

end Behavioral;
