--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    13:58:57 10/24/05
-- Design Name:    
-- Module Name:    ADCStatemachine - Behavioral
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

entity cDVSResetStateMachine is
  port (
    ClockxCI               : in  std_logic;
    ResetxRBI              : in  std_logic;

    AERackxSBI : in std_logic;
    RxcolGxSI : in std_logic;
    cDVSresetxRBI : in std_logic;
    CDVSresetxRBO : out std_logic
    );
end cDVSResetStateMachine;

architecture Behavioral of cDVSResetStateMachine is
  type state is (stIdle,  stEvent, stResetcDVS);


  -- present and next state
  signal StatexDP, StatexDN : state;

  -- timestamp reset register
  signal CountxDP, CountxDN : std_logic_vector(18 downto 0);

  constant waitTime : integer := 30;  -- ca 200ns
  constant idleTime : integer := 200000;  -- 2ms

begin

-- calculate next state and outputs
  p_memless : process (StatexDP, CountxDP, AERackxSBI, cDVSresetxRBI)
  begin  -- process p_memless
    -- default assignements: stay in present state, don't change address in
    -- FifoAddress register, no Fifo transaction, 
    StatexDN   <= StatexDP;
    CountxDN <= CountxDP;
    CDVSresetxRBO <= '1';
    
    case StatexDP is
      when stIdle =>
        CDVSresetxRBO <= cDVSresetxRBI;
     --   if RxcolGxSI = '1' then
          CountxDN <= CountxDP+1;
     --   else
     --     CountxDN <= (others => '0');
     --   end if;

        if AERackxSBI = '0' then
          StatexDN <= stEvent;
        elsif CountxDP > idleTime  then  -- if no events for a long time, reset
                                        -- state machines
          StatexDN <= stResetcDVS;
          CountxDN <= (others => '0');
        end if;
      when stEvent =>
        if AERackxSBI = '1' then
          StatexDN <= stIdle;
        end if;
        CountxDN <= (others => '0');
--      when stCount =>
--        CountxDN <= CountxDP +1;
--        if AERackxSBI = '0' then
--          StatexDN <= stEvent;
--        elsif RxcolGxSI = '0' then
--          StatexDN <= stIdle;
--        elsif CountxDP > waitTime then
--          StatexDN <= stResetcDVS;
--          CountxDN <= (others => '0');
--        end if;
      when stResetcDVS =>
        CountxDN <= CountxDP +1;
        if CountxDP > 10 then
          StatexDN <= stIdle;
          CountxDN <= (others => '0');
        end if;
        CDVSresetxRBO <= '0';
      when others      => null;
    end case;

  end process p_memless;

  -- change state on clock edge
  p_memoryzing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      StatexDP <= stIdle;
      CountxDP <= (others => '0');
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      StatexDP <= StatexDN;
      CountxDP <= CountxDN;
    end if;
  end process p_memoryzing;


end Behavioral;
