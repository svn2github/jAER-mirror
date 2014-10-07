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

entity EventBeforeOverflow is
  port (
    ClockxCI       : in  std_logic;
    ResetxRBI      : in  std_logic;
    OverflowxDI : in  std_logic;
    EventxDI      : in  std_logic;
    EventBeforeOverflowxDO     : out std_logic);
end EventBeforeOverflow;

architecture Behavioral of EventBeforeOverflow is
  type state is (stIdle, stEvent, stOverflow);
  -- present and next state
  signal StatexDP, StatexDN : state;

begin

  -- calculate the next state
  p_memless : process (OverflowxDI,EventxDI, StatexDP)
  begin  -- process p_memless
    EventBeforeOverflowxDO <= '0';             -- stay in present state
    StatexDN   <= StatexDP;

    case StatexDP is
      when stIdle =>
        if EventxDI ='1' then
          StatexDN <= stEvent;
        end if;
      when stEvent =>
        if EventxDI = '0' then
          StatexDN <= stIdle;
        elsif OverflowxDI = '1' then
          StatexDN <= stOverflow;
        end if;
      when stOverflow =>
        if EventxDI ='0' then
          StatexDN <= stIdle;
        end if;
        EventBeforeOverflowxDO <= '1';
      when others => null;
    end case;

  end process p_memless;

  -- change state on clock edge
  p_memorizing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memorizing
    if ResetxRBI = '0' then
      StatexDP <= stIdle;
    elsif ClockxCI'event and ClockxCI = '1' then
      StatexDP <= StatexDN;
    end if;
  end process p_memorizing;

end Behavioral;
