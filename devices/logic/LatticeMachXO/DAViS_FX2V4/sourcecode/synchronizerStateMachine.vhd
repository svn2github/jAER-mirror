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
    --SyncInCLKxABI : in std_logic;		--pin A2
	--SyncInSIGxSBO : in std_logic;		--pin A4
	
	-- output ports to synchronize other USBAER boards (master mode)
    --SyncOutSWxABI   : in  std_logic;    --pin A14 needs synchronization
    --SyncOutCLKxCBO : out std_logic;		--pin A13
	--SyncOutSIGxSBIxSO : out std_logic;		--pin A15
	------------------------------------------------------
	
	
	--for the synchronizing input:
	--SyncIn1 => SyncInCLKxCBI	--pin A2
	--SyncInSIGxSBO => SyncInSIGxSBO	--pin A4

	--for the synchronizing output:
	--SyncOut1 => SyncOutCLKxCBO	--pin A13
	--SyncOut2 => SyncOutSIGxSBI	--pin A4
----------------------------------------------------------	
	   SyncInCLKxABI		: in  std_logic;    -- sychronizer input from other boards//
--	   SyncInSIGxSBO 		  	: in  std_logic;
--	   SyncInSWxEI  		: in  std_logic;
	   SyncOutCLKxCBO 		: out std_logic; 	-- sync output to other boards
--	   SyncOutSIGxSBI 			: out std_logic;
--	   SyncOutSWxEI 		: out std_logic;
    TriggerxSO: out std_logic; -- debugging output
    
    -- host commands to reset timestamps
    HostResetTimestampxSI : in std_logic;  -- input from FX2 to reset timestamps, causes extended pulse on output to slaves

    -- reset timestamp counter
    ResetTimestampxSBO : out std_logic;
	Alex : out std_logic_vector (2 downto 0);

    -- increment timestamp counter
    IncrementCounterxSO : out std_logic);

end synchronizerStateMachine;

architecture Behavioral of synchronizerStateMachine is
  type state is (stIdle, stTriggerInHigh, stTriggerInLow, stResetSlaves, stRunSlave, stSlaveWaitEdge);

  -- present and next state
  signal StatexDP, StatexDN : state;

  -- signals used for synchronizer
  signal SyncInCLKxCB, SyncInCLKxCBN : std_logic;

  -- used to produce different timestamp ticks and to remain in a certain state
  -- for a certain amount of time
  signal DividerxDN, DividerxDP : std_logic_vector(6 downto 0);
  signal CounterxDN, CounterxDP : std_logic_vector(13 downto 0);
  signal ResetTimestampxSBN, ResetTimestampxSBP : std_logic;
begin  -- Behavioral

  -- calculate next state
  p_memless : process (StatexDP, ConfigxSI, DividerxDP, CounterxDP, HostResetTimestampxSI, SyncInCLKxCB, SyncInCLKxABI) --RunxSI,
    constant counterInc : integer := 89;  --47
    constant squareWaveHighTime : integer := 50;
    constant squareWavePeriod : integer := 100;
    constant timeout : integer := 1000;
    constant resetSlavesTime : integer := 18000;
  
  begin  -- process p_memless
    -- default assignements
    StatexDN             <= StatexDP;
    DividerxDN           <= DividerxDP;
    CounterxDN <= CounterxDP;
    ResetTimestampxSBN   <= '1';        -- active low!!
    IncrementCounterxSO  <= '0';

    TriggerxSO <= '0';
 
	Alex <= "111";
    SyncOutCLKxCBO <= '1';
      
    case StatexDP is
      when stIdle               =>  -- waiting for either sync in to go
                                          -- high or run to go high
		Alex <= "000";
        --ResetTimestampxSBN <= '1';
        DividerxDN         <= (others => '0');
        CounterxDN <= (others => '0');
 
        SyncOutCLKxCBO <= SyncInCLKxABI;
        
        if ConfigxSI = '0' and SyncInCLKxCB ='0' then
          StatexDN         <= stRunSlave;
          ResetTimestampxSBN <= '0';
      
        elsif ConfigxSI='1' then -- and RunxSI='1' then
          StatexDN <= stTriggerInHigh;
         -- ResetTimestampxSBO <= '0'; --Alex: I have removed this timestamp reset condition
        end if;
     when stResetSlaves              =>  -- reset  slaves by generating 200us clock on output, which slaves should detect
		Alex <= "001";
        DividerxDN         <= (others => '0');

        if CounterxDP > resetSlavesTime then         -- stay 18000 (200us) cycles in this state
          CounterxDN <= (others => '0');
          ResetTimestampxSBN <= '0';
          StatexDN <= stTriggerInHigh;
        end if;
    
        CounterxDN <= CounterxDP+1;
        SyncOutCLKxCBO   <= '1';
        
      when stTriggerInHigh      =>      
		Alex <= "100";
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

        --if SyncInCLKxCB = '0' then
            --StatexDN <= stTriggerInLow;
            --TriggerxSO <= '1';
        --end if;

        if CounterxDP < squareWaveHighTime then
          SyncOutCLKxCBO <= '0';
        else
          SyncOutCLKxCBO <= '1';
        end if;

        if ConfigxSI='0'  then --RunxSI = '0' or 
          StatexDN   <= stIdle;
        elsif HostResetTimestampxSI = '1' then
          StatexDN   <= stResetSlaves;
          DividerxDN <= (others => '0');
          CounterxDN <= (others => '0');
		elsif SyncInCLKxCB = '0' then  -- Alex. I have moved this code from above to here. Only one if sentence must take care of next state for each case-when 
            StatexDN <= stTriggerInLow;
            TriggerxSO <= '1';
        end if;

        
      when stTriggerInLow   =>      
		Alex <= "101";
        DividerxDN   <= DividerxDP +1;
    
        if DividerxDP > counterInc -1 then     -- increment local timestamp
          DividerxDN          <= (others => '0');
          IncrementCounterxSO <= '1';
          CounterxDN <= CounterxDP+1;
          if CounterxDP > squareWavePeriod - 2 then
            CounterxDN <= (others => '0');
          end if;
        end if;

        --if SyncInCLKxCB = '1' then
            --StatexDN <= stTriggerInHigh;
        --end if;
        
        if CounterxDP < squareWaveHighTime then
          SyncOutCLKxCBO <= '0';
        else
          SyncOutCLKxCBO <= '1';
        end if;
            
        if ConfigxSI='0'  then --RunxSI = '0' or 
          StatexDN   <= stIdle;
        elsif HostResetTimestampxSI = '1' then
          StatexDN   <= stResetSlaves;
          DividerxDN <= (others => '0');
          CounterxDN <= (others => '0');
        elsif SyncInCLKxCB = '1' then -- Alex. I have moved this code from above to here. Only one if sentence must take care of next state for each case-when 
            StatexDN <= stTriggerInHigh;
       end if;
        
      when stRunSlave =>
		Alex <= "001";

        --SyncOutCLKxCBO <= '0';
        SyncOutCLKxCBO <= SyncInCLKxCB;
        
        DividerxDN   <= DividerxDP +1;

        if DividerxDP > counterInc -1 then     -- increment local timestamp
          DividerxDN          <= (others => '0');
          IncrementCounterxSO <= '1';
          CounterxDN <= CounterxDP+1;
        end if;

        
        --if CounterxDP > squareWavePeriod - 2 then
          --StatexDN <= stSlaveWaitEdge;
        --end if;
        
        if ConfigxSI='1'  then
          StatexDN   <= stIdle;
          CounterxDN <= (others => '0');
		elsif CounterxDP > squareWavePeriod - 2 then -- Alex. I have moved this code from above to here. Only one if sentence must take care of next state for each case-when 
          StatexDN <= stSlaveWaitEdge;
        end if;

      when stSlaveWaitEdge =>
		Alex <= "010";

        --SyncOutCLKxCBO <= '1';
        SyncOutCLKxCBO <= SyncInCLKxCB;
        
        DividerxDN          <= (others => '0');
        CounterxDN <= CounterxDP + 1;
        if ConfigxSI='1' or CounterxDP > timeout then -- Alex. I have moved this code from below to here. Only one if sentence must take care of next state for each case-when 
          StatexDN   <= stIdle;
        elsif SyncInCLKxCB = '0' then
          IncrementCounterxSO <= '1';
          StatexDN <= stRunSlave;
          CounterxDN <= (others => '0');
          --TriggerxSO <= '1'; --------------------------- debug
        end if;

        --if ConfigxSI='1' or CounterxDP > timeout then
          --StatexDN   <= stIdle;
        --end if;
        
    end case;

  end process p_memless;

  -- change state on clock edge
  p_mem : process (ClockxCI,ResetxRBI, RunxSI)
  begin  -- process p_mem
    if ResetxRBI = '0'  or RunxSI = '0' then
      StatexDP <= stIdle;
      DividerxDP <= (others => '0');
      CounterxDP <= (others => '0');
	  ResetTimestampxSBP <= '0';   -- Alex: I have moved the ResetTimestamp signal to be sequential to avoid possible glitches. Also under reset or cpld disabled, timestamp will be reset.
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      StatexDP   <= StatexDN;
      DividerxDP <= DividerxDN;
      CounterxDP <= CounterxDN;
	  ResetTimestampxSBP <= ResetTimestampxSBN;
    end if;
  end process p_mem;
  ResetTimestampxSBO <= ResetTimestampxSBP;
  
  -- purpose: synchronize asynchronous inputs
  -- type   : sequential
  -- inputs : ClockxCI
  -- outputs: 
  synchronizer : process (ClockxCI,ResetxRBI)
  begin
    if ResetxRBI = '0' then
	  SyncInCLKxCB <= '1';
	  SyncInCLKxCBN <= '1';
	elsif ClockxCI'event  and ClockxCI = '1' then   
      SyncInCLKxCB  <= SyncInCLKxCBN;
      SyncInCLKxCBN <= SyncInCLKxABI;
    end if;
  end process synchronizer;

end Behavioral;
