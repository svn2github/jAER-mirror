--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    13:58:57 10/24/05
-- Design Name:    
-- Module Name:    ADCvalueReady - Behavioral
-- Project Name:   cDVSTest20
-- Target Device:  
-- Tool versions:  
-- Description: handles the fifo transactions with the FX2
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

entity ADCvalueReady is
  port (
    ClockxCI               : in  std_logic;
    ResetxRBI              : in  std_logic;

    RegisterWritexEI : in std_logic;
    ReadValuexEI : in std_logic;
    ValueReadyxSO : out std_logic 
    );
end ADCvalueReady;

architecture Behavioral of ADCvalueReady is
  type state is (stIdle, stADCvalueReady, stRead, stADCvalueReady2);

  -- present and next state
  signal StatexDP, StatexDN : state;

begin
-- calculate next state and outputs
  p_memless : process (StatexDP, RegisterWritexEI, ReadValuexEI)
  begin  -- process p_memless
    -- default assignements: stay in present state, don't change address in
    -- FifoAddress register, no Fifo transaction, 
    StatexDN                  <= StatexDP;
    ValueReadyxSO <= '0';
    
    case StatexDP is
      when stIdle =>
        if RegisterWritexEI = '1' then
          StatexDN <= stADCvalueReady;
        end if;
      when stADCvalueReady =>
        ValueReadyxSO <= '1';
        if ReadValuexEI = '1' then
          StatexDN <= stRead;
        elsif RegisterWritexEI = '0' then
          StatexDN <= stADCvalueReady2;
        end if;
      when stRead =>
        if RegisterWritexEI ='0' then
          StatexDN <= stIdle;
        end if;
      when stADCvalueReady2 =>
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
