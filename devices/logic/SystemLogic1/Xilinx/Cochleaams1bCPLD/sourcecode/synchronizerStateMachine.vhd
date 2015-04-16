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

    -- host commands to reset timestamps
    HostResetTimestampxSI : in std_logic;

    -- synchronisation in- and output
    SyncInxAI  : in  std_logic;
    SyncOutxSO : out std_logic;

    -- are we master
    MasterxSO : out std_logic;

    -- reset timestamp counter
    ResetTimestampxSBO : out std_logic;

    -- increment timestamp counter
    IncrementCounterxSO : out std_logic);

end synchronizerStateMachine;

architecture Behavioral of synchronizerStateMachine is
  type state is (stMasterIdle, stResetSlaves, stSlaveIdle, stResetTS, stRunMaster, stSyncInLow, stSInc);

  -- present and next state
  signal StatexDP, StatexDN : state;

  -- signals used for synchronizer
  signal SyncInxS, SyncInxSN : std_logic;

  -- used to produce different timestamp ticks and to remain in a certain state
  -- for a certain amount of time
  signal DividerxDN, DividerxDP : std_logic_vector(5 downto 0);

begin  -- Behavioral

  -- calculate next state
  p_memless : process (StatexDP, SyncInxS, SyncInxAI, RunxSI, DividerxDP, HostResetTimestampxSI)
    variable counterInc : integer := 29;
    variable syncOutLow1 : integer := 25;
    variable syncOutLow2 : integer := 26;
  begin  -- process p_memless
    -- default assignements
    StatexDN             <= StatexDP;
    DividerxDN           <= DividerxDP;
    ResetTimestampxSBO   <= '1';        -- active low!!
    SyncOutxSO           <= '1';        -- we are master
    IncrementCounterxSO  <= '0';
    MasterxSO            <= '1';        -- we are master

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
        SyncOutxSO         <= SyncInxAI;
        if SyncInxS = '1' then
          StatexDN         <= stSlaveIdle;
          ResetTimestampxSBO <= '0';
        elsif RunxSI = '1' then
            StatexDN       <= stRunMaster;
            ResetTimestampxSBO <= '0';
        end if;
      when stResetSlaves              =>  -- reset potential slave usbaermini2
                                          -- devices
        DividerxDN         <= DividerxDP+1;

        if DividerxDP >= 8 then         -- stay four cycles in this state
          DividerxDN <= (others => '0');
          ResetTimestampxSBO <= '0';
          StatexDN <= stRunMaster;
        end if;
        if SyncInxS = '1' then
          StatexDN   <= stResetTS;
          DividerxDN <= (others => '0');
        end if;

        SyncOutxSO         <= '0';
        --ResetTimestampxSBO <= '0'; assign this for only one cycle

        MasterxSO <= '1';               -- we are master

      when stResetTS =>                 -- reset local timestamp and wrap-add
        SyncOutxSO           <= SyncInxAI;
        ResetTimestampxSBO   <= '0';

        MasterxSO <= '0';               -- we are not master
    
        DividerxDN <= (others => '0');
        if SyncInxS = '1' then
          StatexDN <= stSlaveIdle;
        else
          StatexDN <= stMasterIdle;
        end if;
        
      when stRunMaster                =>      -- 1us timestamp tick mode
        DividerxDN   <= DividerxDP +1;

        if DividerxDP = syncOutLow2 or DividerxDP = syncOutLow1 then  -- hold SyncOutxSO low for
                                        -- two clockcycles to tell
                                        -- other boards to
                                        -- increment their timestamps
          SyncOutxSO          <= '0';
        elsif DividerxDP >= counterInc then     -- increment local timestamp
          DividerxDN          <= (others => '0');
          IncrementCounterxSO <= '1';
        end if;

        if SyncInxS = '1' then
          StatexDN   <= stResetTS;
          DividerxDN <= (others => '0');
        elsif RunxSI = '0' then
          StatexDN   <= stMasterIdle;
        elsif HostResetTimestampxSI = '1' then
          StatexDN   <= stResetSlaves;
          DividerxDN <= (others => '0');
        end if;

      when stSlaveIdle        =>        -- wait for sync in to go low
        SyncOutxSO <= SyncInxAI;
        DividerxDN <= (others => '0');
        if SyncInxS = '0' then
          StatexDN <= stSyncInLow;
        end if;
        MasterxSO  <= '0';              -- we are not master
      when stSyncInLow        =>        -- wait for sync in to go high again,
                                        -- if this not happens after three
                                        -- cycles, change to master mode  
        SyncOutxSO <= SyncInxAI;
        MasterxSO  <= '0';
        DividerxDN <= DividerxDP +1;

        if SyncInxS = '1' then
          StatexDN <= stSInc;
        elsif DividerxDP >= 2 then
          StatexDN   <= stResetTS;
          DividerxDN <= (others => '0');
        end if;

      when stSInc      =>               -- increment counter
        SyncOutxSO          <= SyncInxAI;
        IncrementCounterxSO <= '1';
        StatexDN            <= stSlaveIdle;
        MasterxSO           <= '0';     -- we are not master

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
      SyncInxS  <= SyncInxSN;
      SyncInxSN <= SyncInxAI;
    end if;
  end process synchronizer;

end Behavioral;
