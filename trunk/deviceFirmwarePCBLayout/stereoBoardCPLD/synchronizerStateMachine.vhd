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

    -- reset host wrap add, interrupt 0 on 8051
    ResetHostWrapAddxSBO : out std_logic;

    -- increment timestamp counter
    IncrementCounterxSO : out std_logic);

end synchronizerStateMachine;

architecture Behavioral of synchronizerStateMachine is
  type state is (stMasterIdle, stResetSlaves, stSlaveIdle, stResetTS, st1us, stSyncInLow, stSInc, stSlaveFast, stFastInit, stFastLow, stFast);

  -- present and next state
  signal StatexDP, StatexDN : state;

  -- signals used for synchronizer
  signal SyncInxS, SyncInxSN : std_logic;

  -- used to produce different timestamp ticks and to remain in a certain state
  -- for a certain amount of time
  signal DividerxDN, DividerxDP : std_logic_vector(4 downto 0);

begin  -- Behavioral

  -- calculate next state
  p_memless : process (StatexDP, SyncInxS, SyncInxAI, ResetxRBI, ConfigxSI, DividerxDP, HostResetTimestampxSI)
  begin  -- process p_memless
    -- default assignements
    StatexDN             <= StatexDP;
    DividerxDN           <= DividerxDP;
    ResetHostWrapAddxSBO <= '1';        -- active low!!
    ResetTimestampxSBO   <= '1';        -- active low!!
    SyncOutxSO           <= '1';        -- we are master
    IncrementCounterxSO  <= '0';
    MasterxSO            <= '1';        -- we are master

    case StatexDP is
      when stMasterIdle               =>  -- waiting for either sync in to go
                                          -- high or reset to go high
        ResetTimestampxSBO <= '0';
        DividerxDN         <= (others => '0');
        MasterxSO          <= '1';
        SyncOutxSO         <= SyncInxAI;
        if SyncInxS = '1' then
          StatexDN         <= stSlaveIdle;
        elsif ResetxRBI = '1' then
          if ConfigxSI = '0'then
            StatexDN       <= st1us;
          elsif ConfigxSI = '1'then
            StatexDN       <= stFastInit;
          end if;
        end if;
      when stResetSlaves              =>  -- reset potential slave usbaermini2
                                          -- devices
        DividerxDN         <= DividerxDP+1;

        if DividerxDP >= 3 then         -- stay four cycles in this state
          DividerxDN <= (others => '0');

          if ConfigxSI = '0'then
            StatexDN <= st1us;
          elsif ConfigxSI = '1'then
            StatexDN <= stFastInit;
          end if;

        end if;
        if SyncInxS = '1' then
          StatexDN   <= stResetTS;
          DividerxDN <= (others => '0');
        end if;

        SyncOutxSO         <= '0';
        ResetTimestampxSBO <= '0';

        MasterxSO <= '1';               -- we are master

      when stResetTS =>                 -- reset local timestamp and wrap-add
        SyncOutxSO           <= SyncInxAI;
        ResetTimestampxSBO   <= '0';
        ResetHostWrapAddxSBO <= '0';

        MasterxSO <= '0';               -- we are not master

        DividerxDN   <= DividerxDP+1;   -- we need to assert interrupt pin for
                                        -- at least three cycles
        if DividerxDP >= 2 then
          DividerxDN <= (others => '0');
          if SyncInxS = '1' then
            StatexDN <= stSlaveIdle;
          else
            StatexDN <= stMasterIdle;
          end if;
        end if;
      when st1us                =>      -- 1us timestamp tick mode
        DividerxDN   <= DividerxDP +1;

        if SyncInxS = '1' then
          StatexDN   <= stResetTS;
          DividerxDN <= (others => '0');
        elsif ResetxRBI = '0' then
          StatexDN   <= stMasterIdle;
        elsif HostResetTimestampxSI = '1' then
          StatexDN   <= stResetSlaves;
          DividerxDN <= (others => '0');
        elsif ConfigxSI = '1' then
          StatexDN   <= stMasterIdle;
          DividerxDN <= (others => '0');
        end if;

        if DividerxDP = 25 or DividerxDP = 26 then  -- hold SyncOutxSO low for
                                        -- two clockcycles to tell
                                        -- other boards to
                                        -- increment their timestamps
          SyncOutxSO          <= '0';
        elsif DividerxDP >= 29 then     -- increment local timestamp
          DividerxDN          <= (others => '0');
          IncrementCounterxSO <= '1';
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
          if ConfigxSI = '0' then
            StatexDN <= stSInc;
          else
            StatexDN <= stSlaveFast;
          end if;
        elsif DividerxDP >= 2 then
          StatexDN   <= stResetTS;
        end if;

        if ConfigxSI = '1' then         -- already start counting
          IncrementCounterxSO <= '1';
        end if;

      when stSInc      =>               -- increment counter
        SyncOutxSO          <= SyncInxAI;
        IncrementCounterxSO <= '1';
        StatexDN            <= stSlaveIdle;
        MasterxSO           <= '0';     -- we are not master
      when stSlaveFast =>               -- slave fast timestamp mode, increment
                                        -- counter every cycle, when sync in
                                        -- low, master is disabled
        SyncOutxSO          <= SyncInxAI;
        IncrementCounterxSO <= '1';
        if SyncInxS = '0' then
          StatexDN          <= stResetTS;
        end if;

        MasterxSO    <= '0';
      when stFastInit           =>      -- signal slaves to initialise
        DividerxDN   <= DividerxDP +1;
        if DividerxDP >= 4 then
          StatexDN   <= stFastLow;
          DividerxDN <= (others => '0');
        end if;
        MasterxSO    <= '1';
        SyncOutxSO   <= '1';
      when stFastLow            =>      -- signal slaves to reset timestamp
        DividerxDN   <= DividerxDP +1;
        SyncOutxSO   <= '0';
        if DividerxDP >= 1 then
          StatexDN   <= stFast;
          DividerxDN <= (others => '0');
        end if;

        MasterxSO <= '1';

      when stFast =>                    -- fast timestamp mode, increment
                                        -- coutner every cycle

        if SyncInxS = '1' then
          StatexDN   <= stResetTS;
          DividerxDN <= (others => '0');
        elsif ResetxRBI = '0' then
          StatexDN   <= stMasterIdle;
        elsif HostResetTimestampxSI = '1' then
          StatexDN   <= stResetSlaves;
          DividerxDN <= (others => '0');
        elsif ConfigxSI = '0' then
          StatexDN   <= stMasterIdle;
          DividerxDN <= (others => '0');
        end if;

        MasterxSO           <= '1';
        SyncOutxSO          <= '1';
        IncrementCounterxSO <= '1';
      when others =>
        StatexDN            <= stMasterIdle;
    end case;

  end process p_memless;

  -- change state on clock edge
  p_mem : process (ClockxCI)
  begin  -- process p_mem
    if ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
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
