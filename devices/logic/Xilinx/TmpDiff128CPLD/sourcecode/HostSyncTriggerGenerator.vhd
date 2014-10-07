-------------------------------------------------------------------------------
-- Title      : HostSyncTriggerGenerator
-- Project    : 
-------------------------------------------------------------------------------
-- File       : HostSyncTriggerGenerator.vhd
-- Author     :   <raphael@ZORA>
-- Company    : 
-- Created    : 2011-12-20
-- Last update: 2011-12-20
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2011 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2011-12-20  1.0      raphael	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity HostSyncTriggerGenerator is

  port (
    ClockxCI       : in  std_logic;
    ResetxRBI      : in  std_logic;
    HostSyncxSI : in std_logic;
    HostTriggerxSO : out std_logic);

end HostSyncTriggerGenerator;

-------------------------------------------------------------------------------

architecture str of HostSyncTriggerGenerator is
  type state is (stIdle,stEdge,stHigh);

  signal StatexDP, StatexDN : state;

  signal HostSyncxSN, HostSyncxS : std_logic;

begin  -- str

  p_memless: process (StatexDP, HostSyncxS)
  begin  -- process p-memless
    HostTriggerxSO <= '0';
    StatexDN <= StatexDP;
    
    case StatexDP is
      when stIdle =>
        if HostSyncxS = '1' then
          StatexDN <= stEdge;
        end if;
      when stEdge =>
        HostTriggerxSO <= '1';
        StatexDN <= stHigh;
      when stHigh =>
        if HostSyncxS ='0' then
          StatexDN <= stIdle;
        end if;
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
      HostSyncxSN <= HostSyncxSI;
      HostSyncxS <= HostSyncxSN;
    end if;
  end process p_memorizing;
  
end str;

-------------------------------------------------------------------------------
