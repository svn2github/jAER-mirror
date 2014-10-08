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
  signal CountxDN, CountxDP : std_logic_vector(16 downto 0); -- 17 bit counter that counts at 60MHz, so it times out after 

  -- clock freq is 60MHz, so to get 1ms early packet timer, we need to count to 1e-3*60e6=60e3=6e4.  We settle for 2^16=65k which give us early packet timer
  -- with timeout of 65k/60e6=1.0833e-3s=1.0833ms. Therefore we use 17 bit timer and look for overflow on bit 16 (highest bit).
  
begin

  -- calculate next state and output
  p_memless              : process (ClearxSI, CountxDP)
  begin  -- process p_memless
    TimerExpiredxSO <= '0';

    if (ClearxSI = '1') then      -- a paket has been sent, so clear counter
      CountxDN        <= (others => '0');
    elsif (CountxDP(16) = '0') then
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
