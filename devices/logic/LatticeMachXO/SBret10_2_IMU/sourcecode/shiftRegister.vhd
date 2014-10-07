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
	SRClockxCI 	   : in  std_logic; -- this clock signal is connected to a FX2 pin, it needs synchronization.
    LatchxEI       : in  std_logic; -- this signal comes directly from FX2. It needs synchronization.
    DxDI           : in  std_logic;
    QxDO           : out std_logic;
    DataOutxDO     : out std_logic_vector((width-1) downto 0));
end shiftRegister;

architecture Behavioral of shiftRegister is

  -- present and next state
  signal StatexD : std_logic_vector((width-1) downto 0);
  -- Alex: LatchxEI should not be used as a clock signal.
  signal dLatchxEI, d1LatchxEI, d2LatchxEI: std_logic;
  signal dSRClockxCI, d1SRClockxCI, d2SRClockxCI: std_logic;

begin

  --p_latch: process (LatchxEI, ResetxRBI)
  --begin  -- process p_latch\
    --if ResetxRBI = '0' then
      --DataOutxDO <= (others => '0');
    --elsif LatchxEI'event and LatchxEI='0' then
      --DataOutxDO <= StatexD;
    --end if;
  --end process p_latch;
  
 
  QxDO <= dLatchxEI; --StatexD(width -1);

  -- change state on clock edge
  p_memorizing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memorizing
    if ResetxRBI = '0' then
      StatexD <= (others => '0');
	  dLatchxEI <= '0';
	  d1LatchxEI <= '0';
	  d2LatchxEI <= '0';
	  dSRClockxCI <= '1';
	  d1SRClockxCI <= '1';
	  d2SRClockxCI <= '1';
	  DataOutxDO <= (others => '0'); -- Added by Alex.
    elsif ClockxCI'event and ClockxCI = '1' then
	  d1LatchxEI <= LatchxEI;
	  d2LatchxEI <= d1LatchxEI;
	  dLatchxEI <= d2LatchxEI;
	  if (d2LatchxEI='0' and dLatchxEI='1') then
	     DataOutxDO <= StatexD;
	  end if;
	  d1SRClockxCI <= SRClockxCI;
	  d2SRClockxCI <= d1SRClockxCI;
	  dSRClockxCI <= d2SRClockxCI;
	  if (d2SRClockxCI='1' and dSRClockxCI='0') then
		StatexD((width-1) downto 1) <= StatexD((width-2) downto 0);
		StatexD(0) <= DxDI;
	  end if;
    end if;
  end process p_memorizing;

end Behavioral;
