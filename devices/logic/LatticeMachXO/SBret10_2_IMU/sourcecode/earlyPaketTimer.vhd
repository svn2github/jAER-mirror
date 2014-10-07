--------------------------------------------------------------------------------
-- Company: ATC.US
-- Engineer: Raphael Berner
--
-- Create Date:    14:07:33 10/24/05
-- Design Name:    
-- Module Name:    earlyPaketTimer - Behavioral
-- Project Name:  USBAERmini2  
-- Target Device:  
-- Tool versions:  
-- Description: this times makes sure there is a paket commited to the USB on a
--              regular basis
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

entity earlyPaketTimer is
  port (
    ClockxCI        : in  std_logic;
    ResetxRBI       : in  std_logic;
    ClearxSI        : in  std_logic;
    TimerExpiredxSO : out std_logic);
end earlyPaketTimer;

architecture Behavioral of earlyPaketTimer is

  -- present and next state
  signal CountxDN, CountxDP : std_logic_vector(17 downto 0); -- 18 bit counter that counts at 90MHz, so it times out after 

  -- clock freq is 90MHz, so to get 1ms early packet timer, we need to count to 1e-3*90e6=90e3=9e4.  We settle for 2^17=131k which give us early packet timer
  -- with timeout of 131k/90e6=1.456e-3s=1.456ms. Therefore we use 18 bit timer and look for overflow on bit 17.
  
begin

  -- calculate next state and output
  p_memless              : process (ClearxSI, CountxDP)
  begin  -- process p_memless
    TimerExpiredxSO <= '0';

    if (ClearxSI = '1') then      -- a paket has been sent, so clear counter
      CountxDN        <= (others => '0');
    elsif (CountxDP(17) = '0') then
      CountxDN        <= CountxDP + 1;
    else                                -- stay in this state until cleared
      CountxDN        <= CountxDP;
      TimerExpiredxSO <= '1';
    end if;
  end process p_memless;

  p_memoryzing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      CountxDP <= (others => '0');
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      CountxDP <= CountxDN;
    end if;
  end process p_memoryzing;
end Behavioral;
