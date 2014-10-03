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
		ClockxCI	: in  std_logic;
		ResetxRBI   : in  std_logic;

		-- aer handshake lines
		AERREQxSBI	: in  std_logic;
		AERACKxSBO  : out std_logic;

		XxDI 			: in std_logic;
		UseLongAckxSI 	: in std_logic;

		-- fifo flags
		FifoFullxSI	: in  std_logic;

		-- fifo control lines
		FifoWritexEO	: out std_logic;
		FifoCountxDI 	: in std_logic_vector(9 downto 0); --H Number of words (16 bits) currently in the CPLD FIFO

		-- register write enable
		TimestampRegWritexEO	: out std_logic;
		AddressRegWritexEO		: out std_logic;
		
		-- mux control	
		--H Selects type of data written to the CPLD FIFO 
		--H Change variable name and size
		DatatypeSelectxSO : out std_logic_vector(2 downto 0); --H AddressTimestampSelectxSO : out std_logic_vector(1 downto 0);
		
		-- ADC interface
		ADCvalueReadyxSI : in std_logic;
		ReadADCvaluexEO : out std_logic;
		
		--H IMU Interface
		IMUDataReadyReqxEI	: in std_logic;  -- Hey, got new IMU Data, can I write to Fifo? 
		IMUDataReadyAckxEO 	: out std_logic; -- Sure, man! Let me get ready, give me a sec..
		IMUDataWriteReqxEO  : out std_logic; -- Start writing the data!
		IMUDataWriteAckxEI  : in std_logic;  -- Done!
		IMUEventxEO 	   	: out std_logic; -- Indicates IMU Event data type, used to set triggereventtype (CHECK COMMENT!)
		IMUDataDropxEO		: out std_logic; -- Indicates that we are dropping a particular IMU Event and not reading it because another read is in progress (CHECK!)
		--H 

		-- timestamp overflow, send wrap event
		TimestampOverflowxSI : in std_logic;

		-- trigger event
		TriggerxSI : in std_logic;
		
		-- valid event or wrap event
		AddressMSBxDO : out std_logic_vector(1 downto 0);
		WrapCounterxDO : out std_logic_vector(7 downto 0);

		-- reset timestamp
		ResetTimestampxSBI : in std_logic;
		
		Alex : out std_logic_vector (2 downto 0);
		
		DebugLEDxEO : out std_logic
		
	);
end monitorStateMachine;

architecture Behavioral of monitorStateMachine is
	--H Added states for IMU: stIMUTime, stIMUEvent, stIMUData
	type state is (stIdle, stWraddress, stWrTime ,stWait,stOverflow,stResetTimestamp, stFifoFull, stReqRelease, stADC,stADCTime, stIMUTime, stIMUEvent, stIMUData, stWrTriggerTime, stWrTrigger);
	--H 

	-- for synchronizing AER Req
	signal AERREQxSB: std_logic;

	-- present and next state
	signal StatexDP, StatexDN : state;
	signal CountxDP, CountxDN : std_logic_vector(7 downto 0);
	signal TriggerxDP, TriggerxDN : std_logic;
  
	--H
	-- Counter for keeping track number of data words (16 bits) in FIFO 
	constant fifo_depth : std_logic_vector(10 downto 0) := "01000000000"; -- FIFO has depth of 1024 words
	constant imu_fifo_write_space : std_logic_vector(9 downto 0) := "0000001010"; -- Number of free space (in words) in FIFO before IMU data can be written: 10
	--H 

	-- timestamp overflow register
	signal TimestampOverflowxDN, TimestampOverflowxDP : std_logic_vector(15 downto 0);

	-- timestamp reset register
	signal TimestampResetxDP, TimestampResetxDN : std_logic;
	signal WrapCounterxDP, WrapCounterxDN : std_logic_vector(7 downto 0);
	signal lastWrapCounterxD : std_logic_vector(7 downto 0);
	signal NeedWrapEventxDP, NeedWrapEventxDN: std_logic;
	
	-- constants for mux
	--H Increased vector length and added another signal (selectIMU)
	constant selectADC : std_logic_vector(2 downto 0) := "011";
	constant selectaddress   : std_logic_vector(2 downto 0) := "001";
	constant selecttimestamp : std_logic_vector(2 downto 0) := "000";
	constant selecttrigger : std_logic_vector(2 downto 0) := "010"; -- Signals external / special input events, including IMU events
	constant selectIMU : std_logic_vector(2 downto 0) := "100"; -- Signals IMU events
	constant selectwrap	: std_logic_vector(2 downto 0) := "101"; --Alex New constant indicating wrap event + counter wrap
	--H

	constant address : std_logic_vector(1 downto 0) := "00"; 
	constant wrap : std_logic_vector(1 downto 0) := "10";
	constant timereset : std_logic_vector(1 downto 0) := "11";
	constant timestamp : std_logic_vector(1 downto 0) := "01";

	constant ackExtension : integer := 5;  -- number of clockcycles ack should stay active

begin
	AERREQxSB <= AERREQxSBI;
	WrapCounterxDO <= WrapCounterxDP;

	-- calculate next state and outputs
	--H Added Sensititivy to IMU Hand shaking signals
	p_memless : process (StatexDP, FifoFullxSI, TimestampOverflowxDP,TimestampOverflowxSI,TimestampResetxDP,ResetTimestampxSBI, AERREQxSB, XxDI, ADCvalueReadyxSI,CountxDP,UseLongAckxSI,TriggerxSI,TriggerxDP, IMUDataReadyReqxEI, IMUDataWriteAckxEI, FifoCountxDI) -- Added FifoCountxDI
	begin  -- process p_memless
		-- default assignements: stay in present state, don't change address in
		-- FifoAddress register, no Fifo transaction, 
		StatexDN                <= StatexDP;
		CountxDN 				<= (others => '0');
		FifoWritexEO            <= '0';

		TimestampRegWritexEO    <= '1';
		
		DatatypeSelectxSO 		<= selectaddress; --H AddressTimestampSelectxSO <= selectaddress;
		WrapCounterxDN			<= WrapCounterxDP;
		NeedWrapEventxDN	    <= NeedWrapEventxDP;
		AddressMSBxDO 			<= address;
		AddressRegWritexEO 		<= '1';
    	--Alex. AERACKxSBO 				<= '1';

		DebugLEDxEO <= '0'; --H

		if TimestampResetxDP = '1' then -- as long as there is a timestamp reset pending, do not send wrap events
		  --TimestampOverflowxDN <= (others => '0');
		  NeedWrapEventxDN <= '0';
		elsif TimestampOverflowxSI = '1' then
		  --TimestampOverflowxDN <= TimestampOverflowxDP +1;
		  WrapCounterxDN <= WrapCounterxDP +1;
		  NeedWrapEventxDN <= '1';
		--else
		  --TimestampOverflowxDN <= TimestampOverflowxDP;
		end if;

		TimestampResetxDN <= (not ResetTimestampxSBI); --TimestampResetxDP or --Alex

		TriggerxDN <= (TriggerxSI); -- or TriggerxDP); --Alex has modified this. This or will block the monitor sm into trigger states!!

		ReadADCvaluexEO <= '0';

		--H IMU Default signals
		IMUDataReadyAckxEO <= '0';
		IMUDataWriteReqxEO <= '0';
		IMUEventxEO <= '0';
		IMUDataDropxEO <= '0';
		--H 
		Alex <= "000";
		case StatexDP is

			when stIdle =>
				Alex <= "000";

				if FifoFullxSI = '1' then
					StatexDN <= stFifoFull;

				elsif TimestampResetxDP = '1'  then
					StatexDN <= stResetTimestamp;
				
				elsif NeedWrapEventxDP = '1' or NeedWrapEventxDN = '1' then --TimestampOverflowxDP > 0 then
					StatexDN <= stOverflow;

				-- if inFifo is not full and there is a monitor event, start a
				-- fifoWrite transaction
				elsif TriggerxDP = '1' then
					StatexDN <= stWrTriggerTime;
				
				elsif ADCvalueReadyxSI ='1' then
				  StatexDN <= stADCTime;
				
				--H Once IMU values become available and Monitor State Machine captures, them
				--  begin handshaking to write it to FIFO
				elsif IMUDataReadyReqxEI = '1' then
					
					-- If there is enough space to write 9 data words (1 Timestamp word, 1 IMU Event word, 7 IMU Measurement Words)
					if (fifo_depth - ('0' & FifoCountxDI) >= imu_fifo_write_space) then 
						-- First record AER timestamp at which IMU event is collected
						StatexDN <= stIMUTime;
					
					-- Otherwise, indicate that we are dropping IMU data
					else
						-- DOESNT SEEM TO EVER GET HERE!! IS THAT GOOD OR BAD?!
						IMUDataReadyAckxEO <= '1'; -- CHECK IF THIS CREATES COMBINATIONAL LOOP.. PROBABLY
						IMUDataDropxEO <= '1';
					
					end if;
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

				--Alex. AERACKxSBO <= '1';
				IMUDataReadyAckxEO <= '0';
			
			when stOverflow => -- send overflow event
				Alex <= "001";

				StatexDN <= stIdle;                
			
				if TimestampOverflowxSI = '1' then
					--TimestampOverflowxDN <= TimestampOverflowxDP;
					NeedWrapEventxDN <= '1';
				else
					--TimestampOverflowxDN <= TimestampOverflowxDP - 1;
					NeedWrapEventxDN <= '0';
				end if;
			
				AddressMSBxDO <= wrap;
				DatatypeSelectxSO <= selectwrap; --selectaddress; --H AddressTimestampSelectxSO <= selectaddress;
				FifoWritexEO <= '1';

			when stResetTimestamp => -- send timestamp reset event
				Alex <= "010";

				StatexDN <= stIdle;       
				
				TimestampResetxDN <= '0';
				--TimestampOverflowxDN <= (others => '0');
				NeedWrapEventxDN <= '0';
				AddressMSBxDO <= timereset;
				DatatypeSelectxSO <= selectaddress; --H AddressTimestampSelectxSO <= selectaddress;
				FifoWritexEO <= '1';

			when stADCTime => -- write the timestamp to the fifo
				Alex <= "011";

				StatexDN <= stADC;

				FifoWritexEO <= '1';
				TimestampRegWritexEO <= '0';
				DatatypeSelectxSO <= selecttimestamp; --H AddressTimestampSelectxSO <= selecttimestamp;
				AddressMSBxDO <= timestamp;

			when stWrTrigger => -- write the address to the fifo
				Alex <= "100";

				StatexDN <= stIdle;

				TriggerxDN <= '0';
				FifoWritexEO <= '1';
				TimestampRegWritexEO <= '0';
				DatatypeSelectxSO <= selecttrigger; --H AddressTimestampSelectxSO <= selecttrigger;
				AddressMSBxDO <= address;

			when stWrTriggerTime => -- write the timestamp to the fifo
				Alex <= "100";
				StatexDN <= stWrTrigger;

				FifoWritexEO <= '1';
				TimestampRegWritexEO <= '0';
				DatatypeSelectxSO <= selecttimestamp; --H AddressTimestampSelectxSO <= selecttimestamp;
				AddressMSBxDO <= timestamp;
			
			when stADC => -- write the address to the fifo
				Alex <= "011";

				StatexDN <= stIdle;

				FifoWritexEO <= '1';
				DatatypeSelectxSO <= selectADC; --H AddressTimestampSelectxSO <= selectADC;
				ReadADCvaluexEO <= '1';
				AddressMSBxDO <= address;

			--H Write AER Timestamp corresponding to IMU event
			when stIMUTime =>             
				Alex <= "101";
				-- Update Next State
				StatexDN <= stIMUEvent;

				-- Indicate that we're writing a timestamp and select timestamp value from mux register
				AddressMSBxDO <= timestamp;
				DatatypeSelectxSO <= selecttimestamp;

				-- Hold current Timestamp value in register and Enable writing timestamp to the FIFO
				FifoWritexEO <= '1';
				TimestampRegWritexEO <= '0'; 

				-- Acknowledge that we have recieved the IMU Event
				-- THIS DOESN'T SEEM TO DO ANYTHING ... WHY?!
				-- IS THIS OK BECAUSE OF SYNCHRONIZATION?
				IMUDataReadyAckxEO <= '1';
			--H
		  
		  --H Send External Event Signal to FIFO indicating that next data word is an IMU event
			when stIMUEvent =>             
				Alex <= "101";
				-- Update Next State
				StatexDN <= stIMUData;
				
				-- Indicate that we're writing an external event (trigger) and indicate that this external event is an IMU event
				AddressMSBxDO <= address; 
				DatatypeSelectxSO <= selecttrigger;
				IMUEventxEO <= '1';
				
				-- Enable writing IMU Event to the FIFO
				FifoWritexEO <= '1';
				
				-- Request to start writing IMU Measurement Data
				IMUDataWriteReqxEO <= '1';
				
				--IMUDataReadyAckxEO <= '1'; --NEW
			--H 

			--H Write IMU Measurement Data to FIFO
			when stIMUData => 
				Alex <= "101";
				
				-- STUCK HERE!!! NOT ANYMORE! ADDED READYACK IN PREVIOUS STATE.. WHY THOUGH?!
				DebugLEDxEO <= '1'; --H
				
				--IMUDataReadyAckxEO <= '1';
				
				-- Stay in current state until all IMU Measurement Data are written to IMU Register
				IMUDataWriteReqxEO <= '1'; -- CHECK!
				if IMUDataWriteAckxEI = '1' then
					IMUDataWriteReqxEO <= '0';
					StatexDN <= stIdle;
				end if;
				
				-- Indicate that we're writing an external event (trigger) and indicate that this external event is an IMU event
				DatatypeSelectxSO <= selectIMU;
				AddressMSBxDO <= address;
				
				-- Enable writing IMU Measurement Data to the FIFO
				FifoWritexEO <= '1';
			--H 

			when stWraddress => -- write the address to the fifo
				Alex <= "110";
				StatexDN <= stReqRelease;	

				AddressRegWritexEO <= '0';
				FifoWritexEO <= '1';
				TimestampRegWritexEO <= '0';
				DatatypeSelectxSO <= selectaddress; --H AddressTimestampSelectxSO <= selectaddress;
				-- AERACKxSBO <= '0';
				AddressMSBxDO <= address;
				
			when stWrTime => -- write the timestamp to the fifo
				Alex <= "110";
				StatexDN <= stWait;			
				AddressRegWritexEO <= '0';
				-- AERACKxSBO <= '0'; -- don't do that here, sender might take address away already
				FifoWritexEO <= '1';
				TimestampRegWritexEO <= '0';
				DatatypeSelectxSO <= selecttimestamp; --H AddressTimestampSelectxSO <= selecttimestamp;
				AddressMSBxDO <= timestamp;
				CountxDN <= (others => '0');
			
			when stWait =>
				Alex <= "110";
				CountxDN <= CountxDP +1;
				if CountxDP > ackExtension then
					StatexDN <= stWraddress;
					CountxDN <= (others => '0');
				end if;
			
				TimestampRegWritexEO <= '0';

			when stReqRelease =>
				Alex <= "110";
				--Alex. AERACKxSBO <= '0';
				CountxDN <= CountxDP +1;
				if AERREQxSB = '1' then
					if UseLongAckxSI = '0' then
						StatexDN <= stIdle;
						--Alex. AERACKxSBO <= '1'; -- safe to do here because of syncronization
					elsif CountxDP > ackExtension then
						StatexDN <= stIdle;
					end if;
				end if;

			when stFifoFull =>  -- acknowledge (and trow away) events as long as fifo is full, only go
								-- back to idle state when sender is not requesting
				Alex <= "111";
				--Alex. AERACKxSBO <= AERREQxSB;
				if FifoFullxSI = '0' and AERREQxSB = '1' then
					StatexDN <= stIdle;
					AddressMSBxDO <= wrap;
					DatatypeSelectxSO <= selectwrap; 
					FifoWritexEO <= '1';
				end if;
				
			when others => StatexDN <= stIdle;
		end case;

	end process p_memless;

	-- change state on clock edge
	p_memoryzing : process (ClockxCI, ResetxRBI)
	begin  -- process p_memoryzing
		if ResetxRBI = '0' then             -- asynchronous reset (active low)
			StatexDP <= stIdle;
			CountxDP <= (others => '0');
	        --TimestampOverflowxDP <= (others => '0');
			TimestampResetxDP <= '0';
			TriggerxDP <= '0';
			AERACKxSBO <= '1';
			WrapCounterxDP <= (others => '0');
			lastWrapCounterxD <= (others => '0');
			NeedWrapEventxDP <= '0';
		elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
			StatexDP <= StatexDN;
			--TimestampOverflowxDP <= TimestampOverflowxDN;
			NeedWrapEventxDP <= NeedWrapEventxDN;
			TimestampResetxDP <= TimestampResetxDN;
			CountxDP <= CountxDN;
			TriggerxDP <= TriggerxDN;
			WrapCounterxDP <= WrapCounterxDN;
			if (StatexDP = stReqRelease) then 
				AERACKxSBO <= '0';
			elsif (StatexDP = stFifoFull) then 
				AERACKxSBO <= AERREQxSB;
			else 
				AERACKxSBO <= '1';
			end if;
			--if (TimestampOverflowxSI='1') then --(StatexDP=stOverflow) then
			--    lastWrapCounterxD <= WrapCounterxDN+1;
			--end if;
		end if;
	end process p_memoryzing;
  
end Behavioral;
