--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    13:58:57 10/24/05
-- Design Name:    
-- Module Name:    IMUvalueReady - Behavioral
-- Project Name:   cDVSTest20
-- Target Device:  
-- Tool versions:  
-- Description: Indicates when an IMU value is ready to be written into the IMU 
--   word register 
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity IMUvalueReady is
  port (
    ClockxCI : in  std_logic;
    ResetxRBI : in  std_logic;

    RegisterWritexEI : in std_logic;
    ReadValuexEI : in std_logic;
    ValueReadyxSO : out std_logic 
    );
end IMUvalueReady;

architecture Behavioral of IMUvalueReady is
  type state is (stIdle, stIMUvalueReady, stRead, stIMUvalueReady2);

  -- present and next state
  signal StatexDP, StatexDN : state;

begin
  -- calculate next state and outputs
  p_memless : process (StatexDP, RegisterWritexEI, ReadValuexEI)
  begin -- process p_memless

	StatexDN <= StatexDP;
    ValueReadyxSO <= '0';
    
    case StatexDP is
	  -- Wait for IMU Register write to be enabled
      when stIdle =>
        if RegisterWritexEI = '1' then
          StatexDN <= stIMUvalueReady;
        end if;
		
	  -- Indicate that IMU value is already in register
      when stIMUvalueReady =>
        ValueReadyxSO <= '1';
        
		if ReadValuexEI = '1' then
          StatexDN <= stRead;
        elsif RegisterWritexEI = '0' then
          StatexDN <= stIMUvalueReady2;
        end if;

	  -- Wait for IMU Register write to be disabled to go back to idle state
	  when stRead =>
        if RegisterWritexEI ='0' then
          StatexDN <= stIdle;
        end if;
	
	  -- What exactly does this extra state do?! Avoid Metastability??
      when stIMUvalueReady2 =>
        ValueReadyxSO <= '1';
        if ReadValuexEI ='1' then
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
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      StatexDP <= StatexDN;   
    end if;
  end process p_memoryzing;

end Behavioral;
