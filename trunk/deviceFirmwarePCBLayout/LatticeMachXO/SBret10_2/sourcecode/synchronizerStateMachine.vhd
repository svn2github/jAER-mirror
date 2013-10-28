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

    -- if config==1 trigger event master mode, config==0 slave mode
    ConfigxSI : in std_logic;
--------------------------------------------------
    -- input ports to synchronize other USBAER boards (slave mode)
    --SyncInSWxABI   : in  std_logic;     --pin A3  needs synchronization
    --SyncIN1xABI : in std_logic;		--pin A2
	--SyncIN2xABI : in std_logic;		--pin A4
	
	-- output ports to synchronize other USBAER boards (master mode)
    --SyncOutSWxABI   : in  std_logic;    --pin A14 needs synchronization
    --SyncOut1xSBO : out std_logic;		--pin A13
	--SyncOut2xSBO : out std_logic;		--pin A15
	------------------------------------------------------
	   SyncIn1xABI			 : in  std_logic;      
--	   SyncIn2xABI 		  	: in  std_logic;
--	   SyncInSWxEI  		: in  std_logic;
	   SyncOut1xSBO 		: out std_logic;
--	   SyncOut2xSBO 		: out std_logic;
--	   SyncOutSWxEI 		: out std_logic;
    TriggerxSO: out std_logic;
    
    -- host commands to reset timestamps
    HostResetTimestampxSI : in std_logic;

    -- reset timestamp counter
    ResetTimestampxSBO : out std_logic;

    -- increment timestamp counter
    IncrementCounterxSO : out std_logic);

end synchronizerStateMachine;

architecture Behavioral of synchronizerStateMachine is
  type state is (stIdle, stTriggerInHigh, stTriggerInLow, stResetSlaves, stRunSlave, stSlaveWaitEdge);

  -- present and next state
  signal StatexDP, StatexDN : state;

  -- signals used for synchronizer
  signal SyncIn1xSB, SyncIn1xSBN : std_logic;

  -- used to produce different timestamp ticks and to remain in a certain state
  -- for a certain amount of time
  signal DividerxDN, DividerxDP : std_logic_vector(6 downto 0);
  signal CounterxDN, CounterxDP : std_logic_vector(13 downto 0);

begin  -- Behavioral

  -- calculate next state
  p_memless : process (StatexDP, RunxSI, ConfigxSI, DividerxDP, CounterxDP, HostResetTimestampxSI, SyncIn1xSB, SyncIn1xABI)
    constant counterInc : integer := 89;  --47
    constant squareWaveHighTime : integer := 50;
    constant squareWavePeriod : integer := 100;
    constant timeout : integer := 1000;
    constant resetSlavesTime : integer := 6000;
  
  begin  -- process p_memless
    -- default assignements
    StatexDN             <= StatexDP;
    DividerxDN           <= DividerxDP;
    CounterxDN <= CounterxDP;
    ResetTimestampxSBO   <= '1';        -- active low!!
    IncrementCounterxSO  <= '0';

    TriggerxSO <= '0';
 

    SyncOut1xSBO <= '1';
      
    case StatexDP is
      when stIdle               =>  -- waiting for either sync in to go
                                          -- high or run to go high
        ResetTimestampxSBO <= '1';
        DividerxDN         <= (others => '0');
        CounterxDN <= (others => '0');
 
        SyncOut1xSBO <= SyncIn1xABI;
        
        if ConfigxSI = '0' and SyncIn1xSB ='0' then
          StatexDN         <= stRunSlave;
          ResetTimestampxSBO <= '0';
      
        elsif ConfigxSI='1' and RunxSI='1' then
          StatexDN <= stTriggerInHigh;
          ResetTimestampxSBO <= '0';
        end if;
     when stResetSlaves              =>  -- reset  slaves
        DividerxDN         <= (others => '0');

        if CounterxDP > resetSlavesTime then         -- stay 6000 (200us) cycles in this state
          CounterxDN <= (others => '0');
          ResetTimestampxSBO <= '0';
          StatexDN <= stTriggerInHigh;
        end if;
    
        CounterxDN <= CounterxDP+1;
        SyncOut1xSBO   <= '1';
        
      when stTriggerInHigh      =>      
        DividerxDN   <= DividerxDP +1;
    
        if DividerxDP > counterInc -1 then     -- increment local timestamp
          DividerxDN          <= (others => '0');
          IncrementCounterxSO <= '1';
          CounterxDN <= CounterxDP+1;
          if CounterxDP > squareWavePeriod - 2 then
            CounterxDN <= (others => '0');
            --TriggerxSO <= '1';  --------------------------- debug
          end if;
        end if;

        if SyncIn1xSB = '0' then
            StatexDN <= stTriggerInLow;
            TriggerxSO <= '1';
        end if;

        if CounterxDP < squareWaveHighTime then
          SyncOut1xSBO <= '0';
        else
          SyncOut1xSBO <= '1';
        end if;

        if RunxSI = '0' or ConfigxSI='0'  then
          StatexDN   <= stIdle;
        elsif HostResetTimestampxSI = '1' then
          StatexDN   <= stResetSlaves;
          DividerxDN <= (others => '0');
          CounterxDN <= (others => '0');
        end if;

        
      when stTriggerInLow   =>      
        DividerxDN   <= DividerxDP +1;
    
        if DividerxDP > counterInc -1 then     -- increment local timestamp
          DividerxDN          <= (others => '0');
          IncrementCounterxSO <= '1';
          CounterxDN <= CounterxDP+1;
          if CounterxDP > squareWavePeriod - 2 then
            CounterxDN <= (others => '0');
          end if;
        end if;

        if SyncIn1xSB = '1' then
            StatexDN <= stTriggerInHigh;
        end if;
        
        if CounterxDP < squareWaveHighTime then
          SyncOut1xSBO <= '0';
        else
          SyncOut1xSBO <= '1';
        end if;
            
        if RunxSI = '0' or ConfigxSI='0'  then
          StatexDN   <= stIdle;
        elsif HostResetTimestampxSI = '1' then
          StatexDN   <= stResetSlaves;
          DividerxDN <= (others => '0');
          CounterxDN <= (others => '0');
        end if;
        
      when stRunSlave =>

        --SyncOut1xSBO <= '0';
        SyncOut1xSBO <= SyncIn1xSB;
        
        DividerxDN   <= DividerxDP +1;

        if DividerxDP > counterInc -1 then     -- increment local timestamp
          DividerxDN          <= (others => '0');
          IncrementCounterxSO <= '1';
          CounterxDN <= CounterxDP+1;
        end if;

        
        if CounterxDP > squareWavePeriod - 2 then
          StatexDN <= stSlaveWaitEdge;
        end if;
        
        if ConfigxSI='1'  then
          StatexDN   <= stIdle;
          CounterxDN <= (others => '0');
        end if;

      when stSlaveWaitEdge =>

        --SyncOut1xSBO <= '1';
        SyncOut1xSBO <= SyncIn1xSB;
        
        DividerxDN          <= (others => '0');
        CounterxDN <= CounterxDP + 1;
        if SyncIn1xSB = '0' then
          IncrementCounterxSO <= '1';
          StatexDN <= stRunSlave;
          CounterxDN <= (others => '0');
          --TriggerxSO <= '1'; --------------------------- debug
        end if;

        if ConfigxSI='1' or CounterxDP > timeout then
          StatexDN   <= stIdle;
        end if;
        
      when others =>
        StatexDN            <= stIdle;
    
    end case;

  end process p_memless;

  -- change state on clock edge
  p_mem : process (ClockxCI,ResetxRBI)
  begin  -- process p_mem
    if ResetxRBI = '0' then
      StatexDP <= stIdle;
      DividerxDP <= (others => '0');
      CounterxDP <= (others => '0');
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      StatexDP   <= StatexDN;
      DividerxDP <= DividerxDN;
      CounterxDP <= CounterxDN;
    end if;
  end process p_mem;

  -- purpose: synchronize asynchronous inputs
  -- type   : sequential
  -- inputs : ClockxCI
  -- outputs: 
  synchronizer : process (ClockxCI)
  begin
    if ClockxCI'event  and ClockxCI = '1' then   
      SyncIn1xSB  <= SyncIn1xSBN;
      SyncIn1xSBN <= SyncIn1xABI;
    end if;
  end process synchronizer;

end Behavioral;
