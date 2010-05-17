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

    -- if config==1 trigger event mode, config==0 sync mode
    ConfigxSI : in std_logic;

    --
    TriggerxABI : in std_logic;
    TriggerxSO: out std_logic;
    SyncOutxSBO : out std_logic;
    
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
  type state is (stMasterIdle, stResetTS, stRunMaster, stTrigger, stResetSlaves, stSlaveIdle, stSyncInHigh, stSInc);

  -- present and next state
  signal StatexDP, StatexDN : state;

  -- signals used for synchronizer
  signal TriggerxSB, TriggerxSBN : std_logic;

  -- used to produce different timestamp ticks and to remain in a certain state
  -- for a certain amount of time
  signal DividerxDN, DividerxDP : std_logic_vector(5 downto 0);

begin  -- Behavioral

  -- calculate next state
  p_memless : process (StatexDP, RunxSI, ConfigxSI, DividerxDP, HostResetTimestampxSI,TriggerxSB, TriggerxABI)
    constant counterInc : integer := 29;  --47
    constant syncOutLow1 : integer := 25;  --43
    constant syncOutLow2 : integer := 26;  --44
  
  begin  -- process p_memless
    -- default assignements
    StatexDN             <= StatexDP;
    DividerxDN           <= DividerxDP;
    ResetTimestampxSBO   <= '1';        -- active low!!
    IncrementCounterxSO  <= '0';
    MasterxSO            <= '1';        -- we are master

    TriggerxSO <= '0';
    SyncOutxSBO           <= '0';        -- we are master

      
    case StatexDP is
      when stMasterIdle               =>  -- waiting for either sync in to go
                                          -- high or run to go high
        ResetTimestampxSBO <= '1';
        DividerxDN         <= (others => '0');
        MasterxSO          <= '1';

        SyncOutxSBO         <= TriggerxABI;
   
        if TriggerxSB = '0' and ConfigxSI = '0' then
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
        if TriggerxSB = '0' then
          StatexDN   <= stResetTS;
          DividerxDN <= (others => '0');
        end if;

        SyncOutxSBO         <= '1';
        --ResetTimestampxSBO <= '0'; assign this for only one cycle

        MasterxSO <= '1';               -- we are master
  
      when stResetTS              =>  
        SyncOutxSBO           <= TriggerxABI;                                
        ResetTimestampxSBO <= '0';
     

        MasterxSO <= '1';

        DividerxDN <= (others => '0');
        if TriggerxSB = '0' and ConfigxSI = '0' then
          StatexDN <= stSlaveIdle;
        else
          StatexDN <= stRunMaster;
        end if;
      when stRunMaster                =>      -- 1us timestamp tick mode
        DividerxDN   <= DividerxDP +1;
        SyncOutxSBO <= '0';

        if DividerxDP = syncOutLow2 or DividerxDP = syncOutLow1 then  -- hold SyncOutxSBO high for
                                        -- two clockcycles to tell
                                        -- other boards to
                                        -- increment their timestamps
          SyncOutxSBO          <= '1';
        elsif DividerxDP >= counterInc then     -- increment local timestamp
          DividerxDN          <= (others => '0');
          IncrementCounterxSO <= '1';
        end if;

        if TriggerxSB = '0' and ConfigxSI = '0' then
          StatexDN   <= stResetTS;
          DividerxDN <= (others => '0');
        elsif RunxSI = '0' then
          StatexDN   <= stMasterIdle;
        elsif HostResetTimestampxSI = '1' then
          StatexDN   <= stResetSlaves;
          DividerxDN <= (others => '0');
        elsif TriggerxSB = '0' and ConfigxSI = '1' then
          StatexDN <= stTrigger;
          TriggerxSO <= '1';
        end if;        
      when stTrigger                =>      
        DividerxDN   <= DividerxDP +1;
        SyncOutxSBO <= '0';
        if DividerxDP = syncOutLow2 or DividerxDP = syncOutLow1 then  -- hold SyncOutxSBO high for
                                        -- two clockcycles to tell
                                        -- other boards to
                                        -- increment their timestamps
          SyncOutxSBO          <= '1';
        elsif DividerxDP >= counterInc then     -- increment local timestamp
          DividerxDN          <= (others => '0');
          IncrementCounterxSO <= '1';
        end if;

        if HostResetTimestampxSI = '1' then
          StatexDN   <= stResetTS;
          DividerxDN <= (others => '0');
        elsif TriggerxSB = '1' then
          StatexDN <= stRunMaster;
        end if;

      when stSlaveIdle        =>        -- wait for sync in to go low
        SyncOutxSBO <= TriggerxABI;
        DividerxDN <= (others => '0');
        if TriggerxSB = '1' then
          StatexDN <= stSyncInHigh;
        end if;
        MasterxSO  <= '0';              -- we are not master
      when stSyncInHigh        =>        -- wait for sync in to go low again,
                                        -- if this not happens after three
                                        -- cycles, change to master mode  
        SyncOutxSBO <= TriggerxABI;
        MasterxSO  <= '0';
        DividerxDN <= DividerxDP +1;

        if TriggerxSB = '0' then
          StatexDN <= stSInc;
        elsif DividerxDP >= 2 then
          StatexDN   <= stResetTS;
          DividerxDN <= (others => '0');
        end if;

      when stSInc      =>               -- increment counter
        SyncOutxSBO          <= TriggerxABI;
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
      TriggerxSB  <= TriggerxSBN;
      TriggerxSBN <= TriggerxABI;
    end if;
  end process synchronizer;

end Behavioral;
