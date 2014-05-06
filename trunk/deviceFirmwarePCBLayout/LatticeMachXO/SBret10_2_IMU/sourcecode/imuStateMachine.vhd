--------------------------------------------------------------------------------
-- Company: ini
-- Engineer: hazael montanaro
--
-- Create Date:    2014
-- Design Name:    
-- Module Name:    IMUStateMachine - Behavioral
-- Project Name:   SBRet10
-- Target Device:  
-- Tool versions:  
-- Description: 
--
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

-- State Machine interfacing IMU to I2C Controller
entity IMUStateMachine is
  
	port (
		
		-- Global signals
		ClockxCI    : in std_logic;
		ResetxRBI   : in std_logic;
		
		-- Signals interfacing with I2C Controller 
		I2CAckxSBI  : in std_logic; -- I2C Acknowledge 
		I2CINTxSBI  : in std_logic; -- I2C Interrupt
		I2CRWxSBI   : out std_logic; -- I2C Read/Write 
		I2CCSxSBI   : out std_logic; -- I2C Chip Select 
		I2CAddrxDO  : out std_logic_vector(2 downto 0); -- I2C Address for register selection
		I2CDataxDIO : inout std_logic_vector(7 downto 0); --I2C Data Read or Write

		-- Signals interfacing with monitorStateMachine
		IMURunxSI           : in  std_logic; -- Start IMU State Machine
		IMURegisterWritexEO : out std_logic; -- Enable I2C Data Write to IMU Register 
		IMUDataxDO          : out std_logic_vector(15 downto 0); -- IMU Data to be written to IMU Register for FIFO
	
		-- Signals interfacing with IMU	
		IMUSDAxSIO : inout std_logic; -- IMU I2C Serial Data Address sends configuration bits and recieves IMU data
		IMUSCLxSO  : out std_logic;   -- IMU I2C Serial Clock

	);
	
end IMUStateMachine;


architecture Behavioral of IMUStateMachine is
  
	-- States used for I2C Controller Register Write and Read 
	type stateRW is (stIdle, 
			stWriteRegister1, stWriteRegister2, stWriteRegister3, stWriteRegister4, 
			stReadRegister1, stReadRegister2, stReadRegister3, stReadRegister4, stReadRegister4);
	signal StateRWxDP, StateRWxDN : stateRW;

	-- States used to initialize IMU and collect data
	type stateIMU is (
			-- Idle
			stIdle, 
			-- Write Configuration Bits
			stWrWriteAddressRegister, stWrWriteByteCountRegister, stWrWriteCommandRegister,
			stWrWaitI2CStart, stWrReadStatusRegister, stWrWriteDataBufferRegister, stWrWaitI2CEnd,
			stWrCheckDone,
			-- Poll for new data
			stRdIntWriteAddressRegister, stRdIntWriteAddrByteCountRegister, stRdIntWriteDataBufferRegister,
			stRdWriteCommandRegister, stRdWaitI2CStart, stRdCheckDone, 			
			-- Select Initial Data Register
			stRdWriteAddressRegister, stRdWriteAddrByteCountRegister, stRdWriteDataBufferRegister,
			stRdWriteCommandRegister, stRdWaitI2CStart, stRdCheckDone, 
			-- Read Data Registers
			stRdWriteAddressRegister1,
			stRdWriteByteCountRegister1, stRdWriteCommandRegister1, stRdWaitI2CStart1, stRdReadStatusRegister,
			stRdReadDataBufferRegister, stRdWaitI2CEnd1, stWrCheckDone);
	signal StateIMUxDP, StateIMUxDN : stateIMU;

	-- States used for interfacing with Monitor State Machine to write data to FIFO
	type stateIMUWrite is (stIdle, 
			stWriteRegister1, stReadRegister4);
	signal StateIMUWritexDP, StateIMUWritexDN : stateIMUWrite;

	
	-- I2C Controller Register addresses
	constant data_buf    : std_logic_vector(2 downto 0) := "000"; -- Data Buffer
	constant low_addr    : std_logic_vector(2 downto 0) := "001"; -- Address of I2C Slave Device
	constant upper_addr  : std_logic_vector(2 downto 0) := "010"; -- Reserved
	constant master_code : std_logic_vector(2 downto 0) := "011"; -- Reserved
	constant comm_stat   : std_logic_vector(2 downto 0) := "100"; -- Command / Status Register
	constant byte_count  : std_logic_vector(2 downto 0) := "101"; -- Number of bytes being transmitted
	constant iack_reg    : std_logic_vector(2 downto 0) := "110"; -- Interrupt acknowledge
	
	-- I2C Controller Register values
	constant I2C_IMU_ADDR 					: std_logic_vector(6 downto 0) :=  "1101000"; -- IMU I2C Address
	constant I2C_IMU_ACCEL_XOUT_H_ADDR 		: std_logic_vector(6 downto 0) := "00111011"; -- First IMU Data Register containing 8 MSB bits from x axis of accelerometer
	constant I2C_IMU_WRITE_BYTE_COUNT 		: std_logic_vector(7 downto 0) := "00001010"; -- Number of configuration bytes to write to IMU, 5 addresses, 5 data
	constant I2C_IMU_ADDR_READ_BYTE_COUNT 	: std_logic_vector(7 downto 0) := "00000001"; -- Only write to first IMU Data Register, this register gets incremented internally
	constant I2C_IMU_DATA_READ_BYTE_COUNT 	: std_logic_vector(7 downto 0) := "00001110"; -- Read 14 bytes of data, 2 bytes per measurement, 3 for Accel, 3 for Gyro, 1 for Temp
	constant I2C_IMU_COMMAND 				: std_logic_vector(7 downto 0) := "10001000"; -- Continuously poll data at 400 kbits/sec
	
	constant I2CWriteWaitTimexS	: natural := 40; -- Clock cycles to wait for ...
	constant I2CReadWaitTimexS	: natural := 80; -- Clock cycles to wait for ...
	
	-- Signals used for iterating through IMU Configuration Registers
	constant IMUInitByteCountLengthxS : natural := 10;  
	variable IMUInitByteCountxDN, IMUInitByteCountxDP : natural range 0 to IMUInitByteCountLengthxS-1;
	type IMUInitArray is array(0 to IMUInitByteCountLengthxS-1) of std_logic_vector(7 downto 0);
	constant IMUInitLUTxD : IMUInitArray := (
			"01101011", 	-- ADDR: IMU power management register and clock selection
			"00000010", 	-- DATA: Disable sleep, select x axis gyro as clock source 
			"00011010", 	-- ADDR: DLPF
			"00000001", 	-- DATA: FS=1kHz, Gyro 188Hz, 1.9ms delay
			"00011001", 	-- ADDR: Sample rate divider
			"00000000", 	-- DATA: 1 Khz sample rate when DLPF is enabled
			"00011011", 	-- ADDR: Gyro Configuration: Full Scale Range / Sensitivity
			"00001000",		-- DATA: 500 deg/s, 65.5 LSB per deg/s
			"00011100", 	-- ADDR: Accel Configuration: Full Scale Range / Sensitivity
			"00001000");	-- DATA: 4g, 8192 LSB per g
	-- Signals used for iterating through IMU measurement Registers
	constant IMUDataByteCountLengthxS : natural := 14;
	variable IMUDataByteCountxDN, IMUDataByteCountxDP : natural range 0 to IMUDataByteCountLengthxS-1;
	type IMUDataArray is array(0 to IMUDataByteCountLengthxS-1) of std_logic_vector(7 downto 0);
	signal IMUDataLUTxD : IMUDataArray;
	
	-- Counter used to control how long to stay in Wait state 
	signal CountxDN, CountxDP : natural range 0 to 100;
  
	
	-- Intermediate / routing signals
	signal ResetxRB : std_logic;
	signal ClockxC  : std_logic;
	signal RWL      : std_logic:= '0'; -- intermediate I2CRWxSBI signal for tristate problem
	
	-- I2C mux outputs
	signal I2CAddrxD std_logic_vector(2 downto 0) := "000"; -- I2C Controller Address register
	signal I2CDataxD std_logic_vector(7 downto 0) := "00000000"; -- I2C Controller Data register


begin
  
	-- Default assignments
	ResetxRB <= ResetxRBI;
	ClockxC <= ClockxCI;  
	
	I2CRWxSBI <= RWL;
	I2CDataxDIO <= I2CDataxD when RWL = '0' else "ZZZZZZZZ";

	
	-- Calculate next state and outputs for I2C Read and Write operations
	p_i2c_read_write : process (StateRWxDP, WriteReqxE, ReadReqxE)
	begin 
  
		-- Stay in current state
		StateRWxDN <= StateRWxDP; 
		
		case StateRWxDP is
			
			when stIdle =>
				WriteAckxE = '0';
				ReadAckxE = '0';
				if WriteReqxE = '1' then
					StateRWxDN <= stWriteRegister1;
				elsif ReadReqxE = '1' then 
					StateRWxDN <= stReadRegister1;
				end if;
				
			-- START I2C Write 
			when stWriteRegister1 =>
				I2CDataxDIO <= I2CDataxD;  
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBI <= '0';
				StateRWxDN <= stWriteRegister2;

			when stWriteRegister2 =>
				I2CCSxSBI <= '0';
				if I2CAckxSBI = '0' then
					StateRWxDN <= stWriteRegister3;
				end if;
			
			when stWriteRegister3 => 
				I2CCSxSBI <= '1';
				StateRWxDN <= stWriteRegister4;

			when stWriteRegister4 =>
				I2CRWxSBI <= '1';
				WriteAckxE <= '1';
				if WriteReq = 0 then
					StateRWxDN <= stIdle;
				end if;
			-- END I2C Write
			
			-- START I2C Read
			when stReadRegister1 =>
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBI <= '1';
				StateRWxDN <= stReadRegister2;

			when stReadRegister2 =>
				I2CCSxSBI <= '0';
				StateRWxDN <= stReadRegister3;
			
			when stReadRegister3 => 
				if I2CAckxSBI = '0' then
					I2CDataxD <= I2CDataxDIO;  
					ReadAckxS <= '1';
					StateRWxDN <= stReadRegister4;
				end if;

			when stReadRegister4 =>
				if ReadReqxS = '0'
					I2CCSxSBI <= '1';
					I2CRWxSBI <= '1';
					StateRWxDN <= stReadRegister5;
				end if;

			when stReadRegister5 =>
				if I2CAckxSBI = '1' then
					StateRWxDN <= stIdle;
				end if;
			-- END I2C Read

		end case 
		-- END case StateRWxDP
		
	end process p_i2c_read_write;

	
	-- Calculate next state and outputs for I2C Controller and IMU transaction
	p_imu : process (StateIMUxDP, IMUByteCountxDP, IMUInitByteCountxDP, IMUDataByteCountxDP, CountxDP, 
			RunIMUxSI, WriteAckxE, ReadAckxE) 
	begin 
  
		-- Hold next states as current states as default
		StateIMUxDN <= StateIMUxDP;
		IMUInitByteCountxDN	<= IMUInitByteCountxDP;	
		IMUDataByteCountxDN	<= IMUDataByteCountxDP;	
		CountxDN <= CountxDP;
					
		case StateIMUxDP is
			
			when stIdle =>
				IMUInitByteCountxDN <= 0;
				IMUDataByteCountxDN	<= 0;
				CountxDN <= 0;
				-- When we get a run signal start writing IMU configuration bits
				if IMURunxSI = '1' then
				  StateIMUxDN <= stWrWriteAddressRegister;
				end if;
						
						
			-- START Write Configuration Registers to IMU (stWrX)
			-- Write IMU Device Address
			when stWrWriteAddressRegister =>
				-- Set registers and write to them using 4 phase handshaking 
				-- (REQ=1 Write this!; ACK=1 Done!; REQ=0 Thanks!; ACK=0 Anything else, bro?)
				-- Make sure that no register read or write processes are running
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= low_addr;
					I2CDataxD <= I2C_IMU_ADDR;
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrWriteByteCountRegister;
				end if;
				
			-- Write number of bytes to be written: 10
			-- 5 Address Bytes and 5 Data Bytes  to initialize 5 IMU registers
			when stWrWriteByteCountRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= byte_count;
					I2CDataxD <= I2C_IMU_WRITE_BYTE_COUNT;  
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrWriteCommandRegister;
				end if;
				
			-- Issue Go command to start data transactions in polling mode
			when stWrWriteCommandRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= comm_stat;
					I2CDataxD <= I2C_IMU_COMMAND; 
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrWaitI2CStart;
				end if;
					
			-- Wait for I2C Controller to... (?)
			when stWrWaitI2CStart =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					CountxDN <= CountxDP + 1;
					if CounterDP = I2CWriteWaitTimexS then
						CountxDN <= (others => '0');
						StateIMUxDN <= stWrReadStatusRegister;
					end if; 
				end if;				
				
			-- Read Status register: wait for buffer empty flag so we can start writing data words	
			when stWrReadStatusRegister =>
				-- Choose register to read from and get data using 4 phase handshaking 
				-- (REQ=1 Read from this address!; ACK=1 Data ready!; REQ=0 Got it!; ACK=0 Anything else, bro?)
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= comm_stat;
					ReadReqxE <= '1';
				elsif ReadAckxE = '1' then
					I2CDataxD <= I2CDataxDIO; 
					ReadReqxE <= '0';
					-- Empty Flag
					if I2CDataxD(1) = '1' then 
						StateIMUxDN <= stWrWriteDataBufferRegister;
					end if;
					-- If buffer is not empty, then when ReadAck = 0 we will read again from this register
				end if;
				
			-- Write next data byte, which initialize the IMU registers
			-- Use counter as a select signal to iterate over the different data bytes
			-- Data iterates between address byte and word byte 
			when stWrWriteDataBufferRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= data_buf;
					I2CDataxD <= IMUInitLUTxD(IMUInitByteCountxDP); 
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					if IMUInitByteCountxDP = IMUInitByteCountLengthxS-1 then
						IMUInitByteCountxDN <= 0;
						StateIMUxDN <= stWrWaitI2CEnd;
					else
						IMUInitByteCountxDN <= IMUInitByteCountxDP + 1;
						StateIMUxDN <= stWrReadStatusRegister;
					end if;
				end if;
			
			-- Wait for I2C Controller to... (?)
			when stWrWaitI2CEnd =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					CountxDN <= CountxDP + 1;
					if CounterDP = I2CWriteWaitTimexS then
						CountxDN <= 0;
						StateIMUxDN <= stWrCheckDone;
					end if; 
				end if;				

			-- Read Status register and wait for transaction done bit
			when stWrCheckDone => 
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= comm_stat;
					ReadReqxE <= '1';
				elsif ReadAckxE = '1' then
					I2CDataxD <= I2CDataxDIO; 
					ReadReqxE <= '0';
					if I2CDataxD(3) = '1' then 
						StateIMUxDN <= stRdIntWriteAddressRegister;
					end if;
				end if;
			-- END Write Configuration Registers to IMU (stWrX)


			-- START Read Interrupt to check when new data is available (stRdIntX)
			-- Write IMU Device Address
			when stRdIntWriteAddressRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= low_addr;
					I2CDataxD <= I2C_IMU_ADDR;
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWriteAddrByteCountRegister;
				end if;

			-- Write number of bytes to be Read: 1
			-- Write byte corresponding to address of IMU Interrupt Status
			when stRdIntWriteAddrByteCountRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= byte_count;
					I2CDataxD <= I2C_IMU_INT_READ_BYTE_COUNT;  
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWriteDataBufferRegister;
				end if;

			-- Write address for first data register in IMU that will be read: ACCEL_XOUT_H
			-- As this value becomes read, the IMU will internally increment the register to point to the next data register
			when stRdIntWriteDataBufferRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= data_buf;
					I2CDataxD <= I2C_IMU_INT_STATUS;  
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWriteCommandRegister;
				end if;

			-- Issue Go command to start data transactions in polling mode
			when stRdIntWriteCommandRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= comm_stat;
					I2CDataxD <= I2C_IMU_COMMAND; 
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWaitI2CStart;
				end if;
					
			-- Wait for I2C Controller to... (?)
			when stRdIntWaitI2CStart =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					CountxDN <= CountxDP + 1;
					if CounterDP = I2CWriteWaitTimexS then
						CountxDN <= 0;
						StateIMUxDN <= stRdIntCheckDone;
					end if; 
				end if;				
				
			-- Read Status register and wait for transaction done bit
			when stRdIntCheckDone =>				
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= comm_stat;
					ReadReqxE <= '1';
				elsif ReadAckxE = '1' then
					I2CDataxD <= I2CDataxDIO; 
					ReadReqxE <= '0';
					if I2CDataxD(3) = '1' then 
						StateIMUxDN <= stRdIntWriteAddressRegister1;
					end if;
				end if;
			
			-- Now that the appropriate data register to read from is set, we start process all over again
			-- Write IMU Device Address
			when stRdIntWriteAddressRegister1 =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= low_addr;
					I2CDataxD <= I2C_IMU_ADDR;
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWriteByteCountRegister1;
				end if;

			-- Write number of bytes to be Read: 1
			-- Read Interrupt Status Register
			when stRdIntWriteByteCountRegister1 =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= byte_count;
					I2CDataxD <= I2C_IMU_INT_READ_BYTE_COUNT;  
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWriteCommandRegister1;
				end if;

			-- Issue Go command to start data transactions in polling mode
			when stRdIntWriteCommandRegister1 =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= comm_stat;
					I2CDataxD <= I2C_IMU_COMMAND;
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWaitI2CStart1;
				end if;
					
			-- Wait for I2C Controller to... (?)
			when stRdWaitI2CStart1 =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					CountxDN <= CountxDP + 1;
					if CounterDP = I2CReadWaitTimexS then
						CountxDN <= (others => '0');
						StateIMUxDN <= stRdIntReadStatusRegister1;
					end if;
				end if;				
				
			-- Read Status register and wait for full buffer before reading data word	
			when stRdIntReadStatusRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= comm_stat;
					ReadReqxE <= '1';
				elsif ReadAckxE = '1' then
					I2CDataxD <= I2CDataxDIO; 
					ReadReqxE <= '0';
					if I2CDataxD(0) = '1' then 
						StateIMUxDN <= stRdIntReadDataBufferRegister;
					end if;
				end if;

			-- Read data byte, which is the Interrupt signal indicating when new IMU data is ready
			when stRdIntReadDataBufferRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= data_buf;
					ReadReqxE <= '1';
				elsif ReadAckxE = '1' then
					I2CDataxD <= I2CDataxDIO; 
					ReadReqxE <= '0';
					InterruptDataReadyxE <= I2CDataxD(0);
					StateIMUxDN <= stRdIntReadDataBufferRegister;
				end if;
			
			-- Wait for I2C Controller to... (?)
			when stRdIntWaitI2CEnd1 =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					CountxDN <= CountxDP + 1;
					if CounterDP = I2CReadWaitTimexS then
						CountxDN <= 0;
						StateIMUxDN <= stRdIntCheckDone;
					end if; 
				end if;				
				
			-- Read Status register and wait for transaction done bit
			-- If there is new data available then start reading it, otherwise wait for new data to be available
			when stRdIntCheckDone =>				
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= comm_stat;
					ReadReqxE <= '1';
				elsif ReadAckxE = '1' then
					I2CDataxD <= I2CDataxDIO; 
					ReadReqxE <= '0';
					if I2CDataxD(3) = '1' then 
						if InterruptDataReadyxE = 1 then 
							StateIMUxDN <= stRdWriteAddressRegister;
						else
							StateIMUxDN <= stRdIntWriteAddressRegister;
						end if; 
					end if;
				end if;
			-- END Read Interrupt to check when new data is available (stRdIntX)			

			-- START Read Data Registers from IMU (stRdX)
			-- Write IMU Device Address
			when stRdWriteAddressRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= low_addr;
					I2CDataxD <= I2C_IMU_ADDR;
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWriteAddrByteCountRegister;
				end if;

			-- Write number of bytes to be Read: 1
			-- Only need to write byte corresponding to address of first IMU data register
			when stRdWriteAddrByteCountRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= byte_count;
					I2CDataxD <= I2C_IMU_ADDR_READ_BYTE_COUNT;  
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWriteDataBufferRegister;
				end if;

			-- Write address for first data register in IMU that will be read: ACCEL_XOUT_H
			-- As this value becomes read, the IMU will internally increment the register to point to the next data register
			when stRdWriteDataBufferRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= data_buf;
					I2CDataxD <= I2C_IMU_ACCEL_XOUT_H_ADDR;  
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWriteCommandRegister;
				end if;

			-- Issue Go command to start data transactions in polling mode
			when stRdWriteCommandRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= comm_stat;
					I2CDataxD <= I2C_IMU_COMMAND; 
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWaitI2CStart;
				end if;
					
			-- Wait for I2C Controller to... (?)
			when stRdWaitI2CStart =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					CountxDN <= CountxDP + 1;
					if CounterDP = I2C_READ_WAIT_TIME then
						CountxDN <= (others => '0');
						StateIMUxDN <= stRdCheckDone;
					end if; 
				end if;				
				
			-- Read Status register and wait for transaction done bit
			when stRdCheckDone =>				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= comm_stat;
					ReadReqxE <= '1';
				elsif ReadAckxE = '1' then
					I2CDataxD <= I2CDataxDIO; 
					ReadReqxE <= '0';
					if I2CDataxD(3) = '1' then 
						StateIMUxDN <= stRdWriteAddressRegister;
					end if;
				end if;
			
			-- Now that the appropriate data register to read from is set, we start process all over again
			-- Write IMU Device Address
			when stRdWriteAddressRegister1 =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= low_addr;
					I2CDataxD <= I2C_IMU_ADDR;
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWriteByteCountRegister1;
				end if;

			-- Write number of bytes to be Read: 14
			-- 2 Bytes per measurement, 3 Measurements for Accel (3 axis), 1 Measurement for Temp, 3 Measurements for Gyro (3 axis)
			when stRdWriteByteCountRegister1 =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= byte_count;
					I2CDataxD <= I2C_IMU_DATA_READ_BYTE_COUNT;  
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWriteCommandRegister1;
				end if;

			-- Issue Go command to start data transactions in polling mode
			when stRdWriteCommandRegister1 =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= comm_stat;
					I2CDataxD <= I2C_IMU_COMMAND;
					WriteReqxE <= '1';
				elsif WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWaitI2CStart1;
				end if;
					
			-- Wait for I2C Controller to... (?)
			when stRdWaitI2CStart1 =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					CountxDN <= CountxDP + 1;
					if CounterDP = I2CReadWaitTimexS then
						CountxDN <= 0;
						StateIMUxDN <= stRdReadStatusRegister1;
					end if;
				end if;				
				
			-- Read Status register and wait for full buffer before reading data word	
			when stRdReadStatusRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= comm_stat;
					ReadReqxE <= '1';
				elsif ReadAckxE = '1' then
					I2CDataxD <= I2CDataxDIO; 
					ReadReqxE <= '0';
					if I2CDataxD(0) = '1' then 
						StateIMUxDN <= stRdReadDataBufferRegister;
					end if;
				end if;

			-- Read data byte, which are sensor measurements from the IMU
			-- Use counter to know measurement we are currently reading
			-- We read 1 byte at a time iterating from MSB of Accel X to LSB of Gyro Z
			when stRdReadDataBufferRegister =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= data_buf;
					ReadReqxE <= '1';
				elsif ReadAckxE = '1' then
					I2CDataxD <= I2CDataxDIO; 
					ReadReqxE <= '0';
					if (IMUDataByteCountxDP mod 2) = '0' then
						IMUDataArray(IMUDataByteCountxDP)(15 downto 8) <= I2CDataxD;
					else
						IMUDataArray(IMUDataByteCountxDP)(7 downto 0) <= I2CDataxD;
					end if;
					if IMUInitByteCountxDP = IMUDataByteCountLengthxS-1 then
						IMUDataByteCountxDN <= 0;
						StateIMUxDN <= stRdWaitI2CEnd1;
					else
						IMUDataByteCountxDN <= IMUDataByteCountxDP + 1;
						StateIMUxDN <= stRdReadStatusRegister;
					end if;
				end if;
			
			-- Wait for I2C Controller to... (?)
			when stRdWaitI2CEnd1 =>
				if WriteAckxE = '0' and ReadAckxE = '0' then
					CountxDN <= CountxDP + 1;
					if CounterDP = I2CReadWaitTimexS then
						CountxDN <= 0;
						StateIMUxDN <= stRdCheckDone;
					end if; 
				end if;				
				
			-- Read Status register and wait for transaction done bit
			-- Once all 14 bytes have been read, then go back to set the first data measurement register and reread
			when stRdCheckDone =>				if WriteAckxE = '0' and ReadAckxE = '0' then
					I2CAddrxD <= comm_stat;
					ReadReqxE <= '1';
				elsif ReadAckxE = '1' then
					I2CDataxD <= I2CDataxDIO; 
					ReadReqxE <= '0';
					if I2CDataxD(3) = '1' then 
						IMUDataReadyReqxE <= '1';
						StateIMUxDN <= stRdWriteAddressRegister;
					end if;
				end if;
			-- END Read Data Registers from IMU (stRdX)
			
			when others => 				StateIMUxDN <= stIdle;
		
		end case;

	end process p_imu;

	
	-- Calculate next state and outputs for I2C Read and Write operations
	p_imu_write : process (StateIMUWritexDP, IMUWriteReqxE)
	begin 
  
		-- Stay in current state
		StateIMUWritexDN <= StateIMUWritexDP; 
		IMURegisterWritexE = '0';
		
		case StateIMUWritexDP is
			
			when stIdle =>
				IMUDataWriteAckxE = '0';
				IMUDataWordCountxDN <= 0;
				-- Wait for Monitor State Machine to be ready to write IMU data
				if IMUDataReadyAckxE = '1' then
					IMUDataReadyReqxE = '0';
					StateIMUWritexDN <= stDataWriteReq;
				end if;
				
			-- Since IMU clock and Monitor State Machine clocks are synchronized,
			-- Send IMU Data one at a time
			when stDataWriteReq =>
				-- Monitor State Machine is ready to Recieve data and is requesting data (redundant signal?)
				if IMUDataReadyAckxE = '0' and IMUDataWriteReqxE = '1' then
					IMUDataxDO <= IMUDataArray(IMUDataWordCountxDP);
					IMURegisterWritexE = '1';
					if IMUDataWordCountxDP = IMUDataWordCountLengthxS-1 then
						-- Acknowledge only once all the data is read 
						IMUDataWriteAckxE = '1';
						StatexDN <= stDataWriteAck;
					else
						IMUDataByteCountxDN <= IMUDataByteCountxDP + 1;
					end if;
				end if;

			when stDataWriteAck =>		
				IMURegisterWritexE = '0';
				IMUDataWriteAckxE = '1';
				StatexDN <= stIdle;
					
		end case 
		-- END case 
		
	end process p_imu_write;


	-- Change states and increase counters on rising clock edge
	p_memorizing : process (ClockxCI, ResetxRBI)
	begin  
		if ResetxRB = '0' then -- Asynchronous reset
			StateRWxDP <= stIdle;
			StateIMUxDP <= stIdle;
			StateIMUWritexDP <= stIdle;
			IMUInitByteCountxDN <= 0;
			IMUDataByteCountxDN	<= 0;
			CountxDN <= 0;
	
		elsif ClockxC'event and ClockxC = '1' then  -- On rising clock edge   
			StateRWxDP <= StateRWxDN;
			StateIMUxDP <= StateIMUxDN;
			IMUInitByteCountxDP <= IMUInitByteCountxDN;
			IMUDataByteCountxDP <= IMUDataByteCountxDN;
			CountxDP <= CountxDN;
		end if;
	end process p_memorizing;

end Behavioral;
