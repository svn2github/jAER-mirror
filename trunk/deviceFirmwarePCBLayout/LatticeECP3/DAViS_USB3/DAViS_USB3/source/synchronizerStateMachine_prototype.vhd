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

    SyncInCLKxABI   : in  std_logic;    -- Pin T2. Input for 10kHz clock. Used when the DVS is slave
	SyncInSIGxSBO   : in  std_logic;	-- Pin T4. Sends an acknowledge signal to the Master
	SyncInSWxEI   : in  std_logic;		-- Pin T3. Says to the host that a cable is attached, so the DVS is a slave.
    SyncOutCLKxCBO : out std_logic;		-- Pin T13. Generates a 10kHz clock when the DVS is Master
	SyncOutSIGxSBI : out std_logic;		-- Pin P12. Receives and acknowledge signal from the Slave
	SyncOutSWxEI : out std_logic;		-- Pin P11. Says to the Host a cable is attached, so the DVS is Master
    
	-- flags
	flagMaster 	: out boolean;  		-- if the camera is master the bit is set to 1
	flagSlave	: out boolean;			-- if the camera is slave is set to 1
	TriggerxSO: out std_logic; -- debugging output
    
    -- host commands to reset timestamps
    HostResetTimestampxSI : in std_logic;  -- input from FX2 to reset timestamps, causes extended pulse on output to slaves

    -- reset timestamp counter
    ResetTimestampxSBO : out std_logic;

    -- increment timestamp counter
    IncrementCounterxSO : out std_logic);

end synchronizerStateMachine;

architecture Behavioral of synchronizerStateMachine is
  type state is (stIdle, stTriggerInHigh, stTriggerInLow, stResetSlaves, stRunSlave, stSlaveWaitEdge);

  -- present and next state
  signal StatexDP, StatexDN : state;

  -- signals used for synchronizer system
  signal SyncInCLKxCB, SyncInCLKxCBN : std_logic;
  signal SyncOutCLKxCB, SyncOutCLKxCBN : std_logic;
  

  -- signals used for connection acknowledge on the synchronizer system
  -- signal SyncInSIGxSBO, SyncOutSIGxSBI : std_logic;
 
  -- used to produce different timestamp ticks and to remain in a certain state
  -- for a certain amount of time
  signal DividerxDN, DividerxDP : std_logic_vector(6 downto 0);
  signal CounterxDN, CounterxDP : std_logic_vector(13 downto 0);

begin  -- Behavioral

  -- calculate next state
  p_memless : process (StatexDP, RunxSI, ConfigxSI, DividerxDP, CounterxDP, HostResetTimestampxSI, SyncInCLKxCB, SyncInCLKxABI)
    constant counterInc : integer := 89;  --47
    constant squareWaveHighTime : integer := 50;
    constant squareWavePeriod : integer := 100;
    constant timeout : integer := 1000;
    constant resetSlavesTime : integer := 18000;
------------------------------------------------------------------------------------------------------------  
    --constant ctIncSlv : integer := 3;  --47 ????
    --constant sqWaveHighTimeSlv : integer := 10;
    --constant sqWavePeriodSlv : integer := 20;
    --constant timeoutSlv : integer := 100;
    --constant resetSlavesTime : integer := 18000; ????????
-------------------------------------------------------------------------------------------------------------    
  begin  -- process p_memless
    -- default assignements
    StatexDN             <= StatexDP;
    DividerxDN           <= DividerxDP;
    CounterxDN <= CounterxDP;
    ResetTimestampxSBO   <= '1';        -- active low!!
    IncrementCounterxSO  <= '0';

    TriggerxSO <= '0';
	
	
 --------------------------------------------------------------------------
   -- IT's MASTER
   -- make sure cable is plugged in the Master. While SyncOutCLKxCBO and SyncOutSWxEI are equal, remains on the loop. 
   -- when SyncOutSWxEI and SyncOutCLKxCBO are different the program continues with the synchronization process.
    SyncWaitOut: while SyncOutSWxEI xor SyncOutCLKxCBO loop  --clk period = 50us
		stIdle <= true;
	end loop SyncWaitOut;
	-- when the cable is plugged send an acknowledge 
	if (syncOutSWxEI = '1') then 
		-- SyncInSIGxSBO is by defect high level, when a cable is plugged into IN plug, syncInSIGxSBO goes low
		-- after receive the clock signal from the Master
		if SyncOutSIGxSBI = '0';
		stIdle = false;
		else stIdle = true;
		flagMaster = true;
		end if:
	end if;
	-- IT's SLAVE
	-- make sure the cable is plugged in the slave. If SyncINCLKxCI is a 10kHz clk. There is a camera plugged. 
	-- If there is a frequency different to 10KHz, there is an external device (external device events)
	-- If SyncInSWxEI /= 1, then there is a cable plugged	
	SyncWaitIn: while SyncInSWxEI='1' xor SyncInCLKxABI='1' loop  --clk period = 50us
		stIdle = true;
	end loop SyncWaitIn;
	
	
--------------------------------------------------------------------------	
    SyncOutCLKxCBO <= '1';
      
    case StatexDP is
      when stIdle               =>  	-- waiting for either sync in to go
                                          -- high or run to go high
        ResetTimestampxSBO <= '1';
        DividerxDN         <= (others => '0');
        CounterxDN <= (others => '0');
 
        SyncOutCLKxCBO <= SyncInCLKxABI;
        
        if ConfigxSI = '0' and SyncInCLKxCB ='0' then
          StatexDN         <= stRunSlave;
          ResetTimestampxSBO <= '0';
      
        elsif ConfigxSI='1' and RunxSI='1' then
          StatexDN <= stTriggerInHigh;
          ResetTimestampxSBO <= '0';
        end if;
     when stResetSlaves              =>  -- reset  slaves by generating 200us clock on output, which slaves should detect
        DividerxDN         <= (others => '0');

        if CounterxDP > resetSlavesTime then         -- stay 18000 (200us) cycles in this state
          CounterxDN <= (others => '0');
          ResetTimestampxSBO <= '0';
          StatexDN <= stTriggerInHigh;
        end if;
    
        CounterxDN <= CounterxDP+1;
        SyncOutCLKxCBO   <= '1';
        
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

        if SyncInCLKxCB = '0' then
            StatexDN <= stTriggerInLow;
            TriggerxSO <= '1';
        end if;

        if CounterxDP < squareWaveHighTime then
          SyncOutCLKxCBO <= '0';
        else
          SyncOutCLKxCBO <= '1';
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

        if SyncInCLKxCB = '1' then
            StatexDN <= stTriggerInHigh;
        end if;
        
        if CounterxDP < squareWaveHighTime then
          SyncOutCLKxCBO <= '0';
        else
          SyncOutCLKxCBO <= '1';
        end if;
            
        if RunxSI = '0' or ConfigxSI='0'  then
          StatexDN   <= stIdle;
        elsif HostResetTimestampxSI = '1' then
          StatexDN   <= stResetSlaves;
          DividerxDN <= (others => '0');
          CounterxDN <= (others => '0');
        end if;
        
      when stRunSlave =>

        --SyncOutCLKxCBO <= '0';
        SyncOutCLKxCBO <= SyncInCLKxCB;
        
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

        --SyncOutCLKxCBO <= '1';
        SyncOutCLKxCBO <= SyncInCLKxCB;
        
        DividerxDN          <= (others => '0');
        CounterxDN <= CounterxDP + 1;
        if SyncInCLKxCB = '0' then
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
      SyncInCLKxCB  <= SyncInCLKxCBN;
      SyncInCLKxCBN <= SyncInCLKxABI;
    end if;
  end process synchronizer;

end Behavioral;
