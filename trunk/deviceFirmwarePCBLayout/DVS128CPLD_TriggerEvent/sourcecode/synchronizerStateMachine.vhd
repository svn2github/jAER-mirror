--------------------------------------------------------------------------------
-- Company: 
-- Engineer: raphael berner
--
-- Create Date:     1/9/06
-- Design Name:    
-- Module Name:    synchronizerStateMAchine - Behavioral
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description: to synchronize several USBAERmini2 boards
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity synchronizerStateMachine is

  port (
    ClockxCI  : in std_logic;
    ResetxRBI : in std_logic;
    RunxSI : in std_logic;

    -- set temporal resolution
    ConfigxSI : in std_logic;

    --
    TriggerxAI : in std_logic;
    TriggerxSO: out std_logic;
    
    -- host commands to reset timestamps
    HostResetTimestampxSI : in std_logic;

    -- are we master
    MasterxSO : out std_logic;

    -- reset timestamp counter
    ResetTimestampxSBO : out std_logic;

    -- increment timestamp counter
    IncrementCounterxSO : out std_logic);

end synchronizerStateMachine;

architecture Behavioral of synchronizerStateMachine is
  type state is (stMasterIdle, stResetTS, stRunMaster, stTrigger);

  -- present and next state
  signal StatexDP, StatexDN : state;

  -- signals used for synchronizer
  signal TriggerxS, TriggerxSN : std_logic;

  -- used to produce different timestamp ticks and to remain in a certain state
  -- for a certain amount of time
  signal DividerxDN, DividerxDP : std_logic_vector(5 downto 0);

begin  -- Behavioral

  -- calculate next state
  p_memless : process (StatexDP, RunxSI, ConfigxSI, DividerxDP, HostResetTimestampxSI,TriggerxS)
    constant counterInc : integer := 29;  --47
  
  begin  -- process p_memless
    -- default assignements
    StatexDN             <= StatexDP;
    DividerxDN           <= DividerxDP;
    ResetTimestampxSBO   <= '1';        -- active low!!
    IncrementCounterxSO  <= '0';
    MasterxSO            <= '1';        -- we are master

    TriggerxSO <= '0';

  --  if ConfigxSI = '0' then
  --    counterInc :=  47;
  --    syncOutLow2 :=  43;
  --    syncOutLow1 := 44;
  --  elsif ConfigxSI = '1' then
  --    counterInc :=  5;
  --    syncOutLow2 :=  3;
  --    syncOutLow1 :=  2;
  --  end if;
    
    case StatexDP is
      when stMasterIdle               =>  -- waiting for either sync in to go
                                          -- high or run to go high
        ResetTimestampxSBO <= '1';
        DividerxDN         <= (others => '0');
        MasterxSO          <= '1';
       
   
        if RunxSI = '1' then
            StatexDN       <= stRunMaster;
            ResetTimestampxSBO <= '0';
        end if;
      
      when stResetTS              =>  
                                         
        ResetTimestampxSBO <= '0';
        StatexDN <= stRunMaster;

        MasterxSO <= '1';
      when stRunMaster                =>      -- 1us timestamp tick mode
        DividerxDN   <= DividerxDP +1;

        if DividerxDP >= counterInc then     -- increment local timestamp
          DividerxDN          <= (others => '0');
          IncrementCounterxSO <= '1';
        end if;

        if HostResetTimestampxSI = '1' then
          StatexDN   <= stResetTS;
          DividerxDN <= (others => '0');
        elsif TriggerxS = '1' then
          StatexDN <= stTrigger;
          TriggerxSO <= '1';
        end if;        
      when stTrigger                =>      -- 1us timestamp tick mode
        DividerxDN   <= DividerxDP +1;

        if DividerxDP >= counterInc then     -- increment local timestamp
          DividerxDN          <= (others => '0');
          IncrementCounterxSO <= '1';
        end if;

        if HostResetTimestampxSI = '1' then
          StatexDN   <= stResetTS;
          DividerxDN <= (others => '0');
        elsif TriggerxS = '0' then
          StatexDN <= stRunMaster;
        end if;
        
      when others =>
        StatexDN            <= stMasterIdle;
    end case;

  end process p_memless;

  -- change state on clock edge
  p_mem : process (ClockxCI,ResetxRBI)
  begin  -- process p_mem
    if ResetxRBI = '0' then
      StatexDP <= stMasterIdle;
      DividerxDP <= (others => '0');
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      StatexDP   <= StatexDN;
      DividerxDP <= DividerxDN;
    end if;
  end process p_mem;

  -- purpose: synchronize asynchronous inputs
  -- type   : sequential
  -- inputs : ClockxCI
  -- outputs: 
  synchronizer : process (ClockxCI)
  begin
    if ClockxCI'event then              -- using double edge flipflops for synchronizing 
      TriggerxS  <= TriggerxSN;
      TriggerxSN <= TriggerxAI;
    end if;
  end process synchronizer;

end Behavioral;
