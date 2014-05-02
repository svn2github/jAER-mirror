--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    13:58:57 10/24/05
-- Design Name:    
-- Module Name:    fifoStatemachine - Behavioral
-- Project Name:   USBAERmini2
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

entity monitorStateMachine is
  port (
    ClockxCI               : in  std_logic;
    ResetxRBI              : in  std_logic;

    -- aer handshake lines
    AERREQxSBI     : in  std_logic;
    AERACKxSBO     : out std_logic;

    XxDI : in std_logic;
    UseLongAckxSI : in std_logic;
    
    -- fifo flags
    FifoFullxSI         : in  std_logic;

    -- fifo control lines
    FifoWritexEO          : out std_logic;

    -- register write enable
    TimestampRegWritexEO     : out std_logic;
    AddressRegWritexEO       : out std_logic;
	
	--H IMU Register Write Enable signal
	IMURegWritexEO : out std_logic; 
	--H 

    -- mux control	
    --H Change variable name and size
	--AddressTimestampSelectxSO  : out std_logic_vector(1 downto 0);
	-- Selects type of data written to the CPLD FIFO 
	DatatypeSelectxSO : out std_logic_vector(2 downto 0); 
	--H 
	
    -- ADC interface
    ADCvalueReadyxSI : in std_logic;
    ReadADCvaluexEO : out std_logic;
    
    --H IMU interface
    IMUvalueReadyxSI : in std_logic; -- Signals that IMU value is ready to be written into IMU Register
    ReadIMUvaluexEO : out std_logic; -- Enables IMU Register 
	--H 

	-- timestamp overflow, send wrap event
    TimestampOverflowxSI : in std_logic;

    -- trigger event
    TriggerxSI : in std_logic;
    
    -- valid event or wrap event
    AddressMSBxDO : out std_logic_vector(1 downto 0);
	--H
	-- Use this signal to indicate that we have an IMU event using the selecttrigger signal
	-- This will indicate that the following FIFO outputs will be 16 bit IMU sensor data
	--H
	
	--H Is used to indicate that selecttrigger in AddressMSBxDO represents an IMUEvent and not any other external type of event
	IMUEventxSO : out std_logic;
	--H 
	
    -- reset timestamp
    ResetTimestampxSBI : in std_logic
    );
end monitorStateMachine;

architecture Behavioral of monitorStateMachine is
  --H Added states for IMU: stIMUTime, stIMUSignal, stIMUEvent
  type state is (stIdle, stWraddress, stWrTime ,stWait,stOverflow,stResetTimestamp, stFifoFull, stReqRelease, stADC,stADCTime, stIMUTime, stIMUSignal, stIMUEvent, stWrTriggerTime, stWrTrigger);
  --H 

  -- for synchronizing AER Req
  signal AERREQxSB: std_logic;

  -- present and next state
  signal StatexDP, StatexDN : state;
  signal CountxDP, CountxDN : std_logic_vector(7 downto 0);
  signal TriggerxDP, TriggerxDN : std_logic;
  
  -- timestamp overflow register
  signal TimestampOverflowxDN, TimestampOverflowxDP : std_logic_vector(15 downto 0);

  -- timestamp reset register
  signal TimestampResetxDP, TimestampResetxDN : std_logic;

  -- constants for mux
  --H Increased vector length and added another signal 
  constant selectADC : std_logic_vector(2 downto 0) := "011";
  constant selectaddress   : std_logic_vector(2 downto 0) := "001";
  constant selecttimestamp : std_logic_vector(2 downto 0) := "000";
  constant selecttrigger : std_logic_vector(2 downto 0) := "010"; -- Signals external input events, including IMU events
  constant selectIMU : std_logic_vector(2 downto 0) := "100"; -- Signals IMU events
  --H
  
  constant address : std_logic_vector(1 downto 0) := "00"; 
  constant wrap : std_logic_vector(1 downto 0) := "10";
  constant timereset : std_logic_vector(1 downto 0) := "11";
  constant timestamp : std_logic_vector(1 downto 0) := "01";
  
  constant ackExtension : integer := 5;  -- number of clockcycles ack should stay active

begin
  AERREQxSB <= AERREQxSBI;

-- calculate next state and outputs
	--H FIX THIS! Change what it depends on!!! FIGURE OUT IMU SIDE FIRST
  p_memless : process (StatexDP, FifoFullxSI, TimestampOverflowxDP,TimestampOverflowxSI,TimestampResetxDP,ResetTimestampxSBI, AERREQxSB, XxDI, ADCvalueReadyxSI,CountxDP,UseLongAckxSI,TriggerxSI,TriggerxDP)
  begin  -- process p_memless
    -- default assignements: stay in present state, don't change address in
    -- FifoAddress register, no Fifo transaction, 
    StatexDN                  <= StatexDP;
    CountxDN <= (others => '0');
    FifoWritexEO             <= '0';
  
    TimestampRegWritexEO        <= '1';
    --H Change variable name and size
	DatatypeSelectxSO <= selectaddress;
    --H
    
	AddressMSBxDO <= address;
    AddressRegWritexEO <= '1';
    AERACKxSBO <= '1';

    if TimestampResetxDP = '1' then     -- as long as there is a timestamp
                                        -- reset pending, do not send wrap events
      TimestampOverflowxDN <= (others => '0');
    elsif TimestampOverflowxSI = '1' then
      TimestampOverflowxDN <= TimestampOverflowxDP +1;
    else
      TimestampOverflowxDN <= TimestampOverflowxDP;
    end if;
    
    TimestampResetxDN <= (TimestampResetxDP or not ResetTimestampxSBI);

    TriggerxDN <= (TriggerxSI or TriggerxDP);

    ReadADCvaluexEO <= '0';
	
	--H Don't read IMU values into IMU word register by default 
	ReadIMUValuexEO <= '0';
	IMUEventxSO <= '0';
	--H 
	
    case StatexDP is
      when stIdle =>

        if FifoFullxSI = '1' then
          StatexDN <= stFifoFull;
        elsif TimestampResetxDP = '1'  then
          StatexDN <= stResetTimestamp;
        elsif TimestampOverflowxDP > 0 then
          StatexDN <= stOverflow;

          -- if inFifo is not full and there is a monitor event, start a
          -- fifoWrite transaction
        elsif TriggerxDP = '1' then
          StatexDN <= stWrTriggerTime;
        elsif ADCvalueReadyxSI ='1' then
          StatexDN <= stADCTime;
		
		--H Once IMU values become available send appropriate signals to write it to FIFO
	    elsif IMUvalueReadyxSI = '1' then
		  -- First record AER timestamp at which IMU event is collected
		  StatexDN <= stIMUTime;
		--H 
        
		elsif AERREQxSB = '0' then
          if XxDI = '0' then
            TimestampRegWritexEO <= '0';
            StatexDN <= stWrTime;
          else
            StatexDN <= stWraddress;
          end if;
        end if;

        AddressMSBxDO <= address;

        AERACKxSBO <= '1';
      when stOverflow =>           -- send overflow event
        StatexDN <= stIdle;                
        
        if TimestampOverflowxSI = '1' then
          TimestampOverflowxDN <= TimestampOverflowxDP;
        else
          TimestampOverflowxDN <= TimestampOverflowxDP - 1;
        end if;
        
        AddressMSBxDO <= wrap;
		--H Change variable name and size
		DatatypeSelectxSO <= selectaddress;
        --H
		FifoWritexEO <= '1';
   
      when stResetTimestamp =>           -- send timestamp reset event

        StatexDN <= stIdle;       
        TimestampResetxDN <= '0';
        TimestampOverflowxDN <= (others => '0');
        AddressMSBxDO <= timereset;
		--H Change variable name and size
		DatatypeSelectxSO <= selectaddress;
        --H 
		FifoWritexEO <= '1';
      when stADCTime      =>             -- write the timestamp to the fifo

        StatexDN <= stADC;
    
        FifoWritexEO             <= '1';
        TimestampRegWritexEO <= '0';
		--H Change variable name and size
		DatatypeSelectxSO <= selecttimestamp;
        --H 
		AddressMSBxDO <= timestamp;

	  --H Write AER Timestamp corresponding to IMU event
	  when stIMUTime      =>             

		-- Update Next State
		StatexDN <= stIMU;
    
		-- Hold current Timestamp value in register and Enable writing timestamp to the FIFO
        FifoWritexEO <= '1';
		TimestampRegWritexEO <= '0'; 
		
		-- Indicate that we're writing a timestamp and get Timestamp value from register
		DatatypeSelectxSO <= selecttimestamp;
        AddressMSBxDO <= timestamp;
	  --H
	  
	  when stWrTrigger   =>             -- write the address to the fifo
     
        StatexDN                  <= stIdle;
        TriggerxDN <= '0';
        FifoWritexEO             <= '1';
        TimestampRegWritexEO <= '0';
		--H Change variable name and size
		DatatypeSelectxSO <= selecttrigger;
        --H
		AddressMSBxDO <= address;

      when stWrTriggerTime      =>             -- write the timestamp to the fifo

        StatexDN <= stWrTrigger;
        FifoWritexEO             <= '1';
        TimestampRegWritexEO <= '0';
		--H Change variable name and size
		DatatypeSelectxSO <= selecttimestamp;
        --H 
		AddressMSBxDO <= timestamp;
        
      when stADC   =>             -- write the address to the fifo
        
        StatexDN              <= stIdle;
        
        FifoWritexEO             <= '1';
		--H Change variable name and size
		DatatypeSelectxSO <= selectADC;
        --H 
		ReadADCvaluexEO <= '1';
        AddressMSBxDO <= address;

	  --H Send External Event Signal to FIFO indicating that next data word is an IMU event
	  when stIMUSignal =>             
        
		-- Update Next State
		StatexDN <= stIMUEvent;
       
   		-- Enable writing to the FIFO
        FifoWritexEO <= '1';
        
		-- Indicate that we're writing an external event (trigger), indicate that external event is an IMU event
		-- Set MSB of data 
		IMUEventxSO <= '1';
		DatatypeSelectxSO <= selecttrigger;
        AddressMSBxDO <= address; -- Don't think I actually need this
		-- Set count variable to 0
	--H 

	  --H Write IMU events to FIFO
	  when stIMUEvent =>             -- write the address to the fifo
        
		--TODO
		-- Start counting up. If Count reaches 9? 12? Then go back to idle. 
        StatexDN <= stIdle;
        
		
        FifoWritexEO <= '1';
		DatatypeSelectxSO <= selectIMU;
        ReadIMUvaluexEO <= '1';
        AddressMSBxDO <= address;
	  --H 

	  when stWraddress   =>             -- write the address to the fifo
     
        StatexDN                  <= stReqRelease;
        AddressRegWritexEO <= '0';
        FifoWritexEO             <= '1';
        TimestampRegWritexEO <= '0';
		--H Change variable name and size
		DatatypeSelectxSO <= selectaddress;
		--H 
--        AERACKxSBO <= '0';
        AddressMSBxDO <= address;
      when stWrTime      =>             -- write the timestamp to the fifo

        StatexDN <= stWait;
        AddressRegWritexEO <= '0';
--        AERACKxSBO <= '0'; -- don't do that here, sender might take address
--        away already
        FifoWritexEO             <= '1';
        TimestampRegWritexEO <= '0';
		--H Change variable name and size
		DatatypeSelectxSO <= selecttimestamp;
		--H 
        AddressMSBxDO <= timestamp;
        CountxDN <= (others => '0');
        
      when stWait =>
        CountxDN <= CountxDP +1;
      
      
        if CountxDP > ackExtension then
          StatexDN <= stWraddress;
          CountxDN <= (others => '0');
        end if;
        
       
        TimestampRegWritexEO <= '0';
      when stReqRelease =>
        AERACKxSBO <= '0';
        CountxDN <= CountxDP +1;
        if AERREQxSB = '1' then
          if UseLongAckxSI = '0' then
            StatexDN <= stIdle;
            AERACKxSBO <= '1';          -- safe to do here because of syncronization
          elsif CountxDP > ackExtension then
            StatexDN <= stIdle;
          end if;
        end if;

      when stFifoFull =>                -- acknowledge (and trow away) events
                                        -- as long as fifo is full, only go
                                        -- back to idle state when sender is
                                        -- not requesting
        AERACKxSBO <= AERREQxSB;
        if FifoFullxSI = '0' and AERREQxSB = '1' then
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
      CountxDP <= (others => '0');
      TimestampOverflowxDP <= (others => '0');
      TimestampResetxDP <= '0';
      TriggerxDP <= '0';
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      StatexDP <= StatexDN;
      TimestampOverflowxDP <= TimestampOverflowxDN;
      TimestampResetxDP <= TimestampResetxDN;
      CountxDP <= CountxDN;
      TriggerxDP <= TriggerxDN;
    end if;
  end process p_memoryzing;
  
end Behavioral;
