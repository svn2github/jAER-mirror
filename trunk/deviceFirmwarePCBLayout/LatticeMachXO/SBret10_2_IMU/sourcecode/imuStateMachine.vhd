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
--use IEEE.numeric_std.all;

-- State Machine interfacing IMU to I2C Controller
entity IMUStateMachine is
  
	port (
		
		-- Global signals
		ClockxCI    : in std_logic;
		ResetxRBI   : in std_logic;
		
		-- Signals interfacing with I2C Controller 
		I2CINTxSBI  : in std_logic; -- I2C Interrupt
		I2CRWxSBO   : out std_logic; -- I2C Read/Write 
		I2CCSxSBO   : out std_logic; -- I2C Chip Select 
		I2CAddrxDO  : out std_logic_vector(2 downto 0); -- I2C Address for register selection
		I2CDataxDIO : inout std_logic_vector(7 downto 0); --I2C Data Read or Write

		-- Signals interfacing with monitorStateMachine
		IMURunxEI           : in  std_logic; -- Start IMU State Machine
		IMUDataReadyReqxEO  : out std_logic; -- Request Monitor State Machine to write data by signaling that data is ready
		IMUDataReadyAckxEI  : in std_logic;  -- Recieve Acknowledge from Monitor State Machine indicating that we should start writing data
		IMUDataWriteReqxEI  : in std_logic;  -- Recieve Request to start writing IMU Measurement Data
		IMUDataWriteAckxEO  : out std_logic; -- Acknowledge that all IMU Measurement Data have been written
		IMUDataDropxEI		: in std_logic; -- INSERT COMMENTS
		IMURegisterWritexEO : out std_logic; -- Enable IMU Data to be written to IMU Register for FIFO
		IMUDataxDO          : out std_logic_vector(15 downto 0) -- IMU Data to be written to IMU Register for FIFO
	);
	
end IMUStateMachine;


architecture Behavioral of IMUStateMachine is
  
	-- States used for I2C Controller Register Write and Read 
	type stateRW is (
			-- Idle
			stIdle,
			-- Write to I2C Register
			stWriteRegister1, stWriteRegister2, stWriteRegister3, stWriteRegister4, 
			-- Read from I2C Register
			stReadRegister1, stReadRegister2, stReadRegister3, stReadRegister4, stReadRegister5);
	signal StateRWxDP, StateRWxDN : stateRW;

	-- States used to initialize IMU and collect data
	type stateIMU is (
			-- Idle
			stIdle, 
			-- Write Configuration Bits
			stWrWriteAddressRegister, stWrWriteByteCountRegister, stWrWriteCommandRegister,	stWrWaitI2CStart, 
			stWrReadStatusRegister, stWrWriteDataBufferRegister, stWrWaitI2CEnd, stWrCheckDone,
			-- Select Interrupt Data Register
			stRdIntWriteAddressRegister, stRdIntWriteAddrByteCountRegister, stRdIntWriteDataBufferRegister,
			stRdIntWriteCommandRegister, stRdIntWaitI2CStart, stRdIntCheckDone, 
			-- Poll for new data by reading Interrupt Data Register
			stRdIntWriteAddressRegister1, stRdIntWriteByteCountRegister1, stRdIntWriteCommandRegister1, stRdIntWaitI2CStart1, 
			stRdIntReadStatusRegister, stRdIntReadDataBufferRegister, stRdIntWaitI2CEnd1, stRdIntCheckDone1,
			-- Select Initial Data Register
			stRdWriteAddressRegister, stRdWriteAddrByteCountRegister, stRdWriteDataBufferRegister,
			stRdWriteCommandRegister, stRdWaitI2CStart, stRdCheckDone, 
			-- Read Data Registers
			stRdWriteAddressRegister1, stRdWriteByteCountRegister1, stRdWriteCommandRegister1, stRdWaitI2CStart1, 
			stRdReadStatusRegister, stRdReadDataBufferRegister, stRdWaitI2CEnd1, stRdCheckDone1);
	signal StateIMUxDP, StateIMUxDN : stateIMU;

	-- States used for interfacing with Monitor State Machine to write data to FIFO
	type stateIMUWrite is (stIdle, stDataWriteReq, stDataWriteAck);
	signal StateIMUWritexDP, StateIMUWritexDN : stateIMUWrite;

	
	-- I2C Controller Register addresses
	constant data_buf    : std_logic_vector(2 downto 0) := "000"; -- Data Buffer
	constant low_addr    : std_logic_vector(2 downto 0) := "001"; -- Address of I2C Slave Device
	constant upper_addr  : std_logic_vector(2 downto 0) := "010"; -- Reserved
	constant master_code : std_logic_vector(2 downto 0) := "011"; -- Reserved
	constant comm_stat   : std_logic_vector(2 downto 0) := "100"; -- Command / Status Register
	constant byte_count  : std_logic_vector(2 downto 0) := "101"; -- Number of bytes being transmitted
	constant iack_reg    : std_logic_vector(2 downto 0) := "110"; -- Interrupt acknowledge
	
	-- I2C Controller Register addresses and values
	constant I2C_IMU_ADDR 					: std_logic_vector(6 downto 0) :=  "1101000"; -- IMU I2C Address
	constant I2C_IMU_ACCEL_XOUT_H_ADDR 		: std_logic_vector(7 downto 0) := "00111011"; -- First IMU Data Register containing 8 MSB bits from x axis of accelerometer
	constant I2C_IMU_WRITE_BYTE_COUNT 		: std_logic_vector(7 downto 0) := "00001010"; -- Number of configuration bytes to write to IMU, 5 addresses, 5 data
	constant I2C_IMU_INT_READ_BYTE_COUNT	: std_logic_vector(7 downto 0) := "00000001"; -- Number of bytes to write to select IMU Interrupt Register
	constant I2C_IMU_INT_STATUS				: std_logic_vector(7 downto 0) := "00111010"; -- Interrupt Status register, which indicates when new data is available
	constant I2C_IMU_ADDR_READ_BYTE_COUNT 	: std_logic_vector(7 downto 0) := "00000001"; -- Only write to first IMU Data Register, this register gets incremented internally
	constant I2C_IMU_DATA_READ_BYTE_COUNT 	: std_logic_vector(7 downto 0) := "00001110"; -- Read 14 bytes of data, 2 bytes per measurement, 3 for Accel, 3 for Gyro, 1 for Temp
	constant I2C_IMU_COMMAND 				: std_logic_vector(7 downto 0) := "10001000"; -- Continuously poll data at 400 kbits/sec
	
	-- I2C signals
	signal I2CAckCountxDN, I2CAckCountxDP : std_logic_vector(2 downto 0); -- Counter for data to be latched into I2C Controller Register
	constant i2c_ack_length : std_logic_vector(2 downto 0) := "100"; -- Maximum valid value for I2CAckCount: 4 (can be 3?)
	signal I2CAckxE : std_logic; -- I2C Acknowledge 
	signal I2CReqxE : std_logic; -- I2C Request


	signal I2CWaitCountxDN, I2CWaitCountxDP : std_logic_vector(7 downto 0); -- Wait state counter
    constant i2c_wait_time	: std_logic_vector(7 downto 0) := "00101000"; -- Clock cycles to wait for ...: 40 clock cycles
	
	-- I2C mux outputs
	-- FIX COMMENTS
	signal I2CAddrxD : std_logic_vector(2 downto 0) := "000"; -- I2C Controller Address register
	signal I2CDataWritexD : std_logic_vector(7 downto 0); -- I2C Controller Data register 
	signal I2CDataReadxD : std_logic_vector(7 downto 0) := "00000000"; -- I2C Controller Data register 

	-- I2C Handshaking signals to read and write to Controller registers
	signal WriteReqxE : std_logic; -- Send Byte
	signal WriteAckxE : std_logic; -- Byte recieved
	signal ReadReqxE : std_logic;  -- Read Byte
	signal ReadAckxE : std_logic;  -- Byte read


	-- IMU Signals used for iterating through Configuration Registers
	signal IMUInitByteCountxDN, IMUInitByteCountxDP : std_logic_vector(3 downto 0); -- Counts 10 bytes: 5 addresses, 5 data bytes
	constant imu_init_byte_length : std_logic_vector(3 downto 0) := "1001"; -- Maximum valid value for IMUInitByteCount: 9
	constant IMUInitByte01 : std_logic_vector(7 downto 0) := "01101011"; -- ADDR: (0x6b) IMU power management register and clock selection
	constant IMUInitByte02 : std_logic_vector(7 downto 0) := "00000010"; -- DATA: (0x02) Disable sleep, select x axis gyro as clock source 
	constant IMUInitByte03 : std_logic_vector(7 downto 0) := "00011010"; -- ADDR: (0x1A) DLPF
	constant IMUInitByte04 : std_logic_vector(7 downto 0) := "00000001"; -- DATA: (0x01) FS=1kHz, Gyro 188Hz, 1.9ms delay
	constant IMUInitByte05 : std_logic_vector(7 downto 0) := "00011001"; -- ADDR: (0x19) Sample rate divider
	constant IMUInitByte06 : std_logic_vector(7 downto 0) := "00000000"; -- DATA: (0x00) 1 Khz sample rate when DLPF is enabled
	constant IMUInitByte07 : std_logic_vector(7 downto 0) := "00011011"; -- ADDR: (0x1B) Gyro Configuration: Full Scale Range / Sensitivity
	constant IMUInitByte08 : std_logic_vector(7 downto 0) := "00001000"; -- DATA: (0x08) 500 deg/s, 65.5 LSB per deg/s
	constant IMUInitByte09 : std_logic_vector(7 downto 0) := "00011100"; -- ADDR: (0x1C) Accel Configuration: Full Scale Range / Sensitivity
	constant IMUInitByte10 : std_logic_vector(7 downto 0) := "00001000"; -- DATA: (0x08) 4g, 8192 LSB per g
	
	-- IMU Signals used for iterating through Measurement Registers
	signal IMUMeasByteCountxDN, IMUMeasByteCountxDP : std_logic_vector(3 downto 0); -- IMU Measurement Byte counter (1 word is 2 bytes or 16 bits)
	constant imu_meas_byte_length : std_logic_vector(3 downto 0) := "1101"; -- Maximum valid value for IMUMeasByteCount: 13
	signal IMUAccelXxD : std_logic_vector(15 downto 0); -- X Accelerometer Measurement
	signal IMUAccelYxD : std_logic_vector(15 downto 0); -- Y Accelerometer Measurement
	signal IMUAccelZxD : std_logic_vector(15 downto 0); -- Z Accelerometer Measurement
	signal IMUTempxD   : std_logic_vector(15 downto 0); -- Temperature Measurement
	signal IMUGyroXxD  : std_logic_vector(15 downto 0); -- X Gyroscope Measurement
	signal IMUGyroYxD  : std_logic_vector(15 downto 0); -- Y Gyroscope Measurement
	signal IMUGyroZxD  : std_logic_vector(15 downto 0); -- Z Gyroscope Measurement
	signal IMUNewMeasxE : std_logic; -- When polling for data, indicates that a new value is ready to be read
	
	-- IMU Write Signals (interfaces with Monitor State Machine)
	constant imu_data_word_length : std_logic_vector(2 downto 0) := "110"; -- Maximum valid value for IMUDataWordCount: 6 (7 16-bit words)
	signal IMUDataWordCountxDN, IMUDataWordCountxDP : std_logic_vector(2 downto 0); -- IMU Measurement Word counter used while iterating through Data
	
	
	-- Intermediate / routing signals
	signal ResetxRB : std_logic;
	signal ClockxC  : std_logic;
	signal RWL      : std_logic; -- intermediate I2CRWxSBO signal for tristate problem
	

begin
  
	-- Default assignments
	ResetxRB <= ResetxRBI;
	ClockxC <= ClockxCI;  
	
	-- Calculate next state and outputs for I2C Read and Write operations
	p_i2c_read_write : process (StateRWxDP, WriteReqxE, ReadReqxE, I2CAckxE)
	begin 
  
		-- Stay in current state
		StateRWxDN <= StateRWxDP; 
		
		-- START CASE StateRWxDP
		case StateRWxDP is
			
			when stIdle =>
				-- Default and reset assignments
				WriteAckxE <= '0'; 
				ReadAckxE <= '0'; 
				-- Write and Read I2C Register Request signals
				if WriteReqxE = '1' then
					StateRWxDN <= stWriteRegister1;
				elsif ReadReqxE = '1' then 
					StateRWxDN <= stReadRegister1;
				end if;
				
			-- START I2C Write 
			when stWriteRegister1 =>
				I2CDataxDIO <= I2CDataWritexD;  
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '0';
				StateRWxDN <= stWriteRegister2;

			when stWriteRegister2 =>
				I2CCSxSBO <= '0';
				I2CReqxE <= '0'; -- VERIFY
				if I2CAckxE = '1' then 
					I2CReqxE <= '1'; -- VERIFY
					StateRWxDN <= stWriteRegister3;
				end if;
			
			when stWriteRegister3 => 
				I2CCSxSBO <= '1';
				StateRWxDN <= stWriteRegister4;

			when stWriteRegister4 =>
				I2CRWxSBO <= '1';
				WriteAckxE <= '1';
				if WriteReqxE = '0' then
					WriteAckxE <= '0';
					StateRWxDN <= stIdle;
				end if;
			-- END I2C Write
			
			-- START I2C Read
			when stReadRegister1 =>
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				StateRWxDN <= stReadRegister2;

			when stReadRegister2 =>
				I2CCSxSBO <= '0';
				StateRWxDN <= stReadRegister3;
			
			when stReadRegister3 =>
				I2CReqxE <= '1'; -- VERIFY
				if I2CAckxE = '1' then
					I2CReqxE <= '0'; -- VERIFY
					-- Disable tristate after reading I2C data from inout port
					I2CDataxDIO <= (others => 'Z');
					I2CDataReadxD <= I2CDataxDIO;  
					StateRWxDN <= stReadRegister4;
				end if;

			when stReadRegister4 =>
				I2CCSxSBO <= '1';
				I2CRWxSBO <= '1';
				StateRWxDN <= stReadRegister5;

			when stReadRegister5 =>
				if I2CAckxE = '0' then
					ReadAckxE <= '1';
				end if;
				if ReadReqxE = '0' then
					ReadAckxE <= '0';
					StateRWxDN <= stIdle;
				end if;
			-- END I2C Read

		end case; 
		-- END CASE StateRWxDP
		
	end process p_i2c_read_write;

	
	-- Calculate next state and outputs for I2C Controller and IMU transaction
	p_imu : process (StateIMUxDP, IMUInitByteCountxDP, IMUMeasByteCountxDP, I2CWaitCountxDP, 
			IMURunxEI, WriteAckxE, ReadAckxE) 
	begin 
  
		-- Default assignemnts
		StateIMUxDN <= StateIMUxDP;
		IMUInitByteCountxDN	<= IMUInitByteCountxDP;	
		IMUMeasByteCountxDN	<= IMUMeasByteCountxDP;	
		I2CWaitCountxDN <= I2CWaitCountxDP;
		
		
		case StateIMUxDP is
			
			when stIdle =>
				-- Reset counters
				IMUInitByteCountxDN <= (others => '0');
				IMUMeasByteCountxDN	<= (others => '0');
				I2CWaitCountxDN <= (others => '0');
				-- When we get a run signal start writing IMU configuration bits
				if IMURunxEI = '1' then
				  StateIMUxDN <= stWrWriteAddressRegister;
				end if;
						
			-- START Write Configuration Registers to IMU (stWrX)
			-- Write IMU Device Address
			when stWrWriteAddressRegister =>
				-- Set registers and write to them using 4 phase handshaking 
				-- (REQ=1 Write this!; ACK=1 Done!; REQ=0 Thanks!; ACK=0 Anything else, bro?)
				I2CAddrxD <= low_addr;
				I2CDataWritexD <= I2C_IMU_ADDR & '0'; -- IMU Address is only 7 bits, append a 0 at the end to make it 8 bits
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrWriteByteCountRegister;
				end if;
				
			-- Write number of bytes to be written: 10
			-- 5 Address Bytes and 5 Data Bytes  to initialize 5 IMU registers
			when stWrWriteByteCountRegister =>
				I2CAddrxD <= byte_count;
				I2CDataWritexD <= I2C_IMU_WRITE_BYTE_COUNT;  
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrWriteCommandRegister;
				end if;
				
			-- Issue Go command to start data transactions in polling mode
			when stWrWriteCommandRegister =>
				I2CAddrxD <= comm_stat;
				I2CDataWritexD <= I2C_IMU_COMMAND; 
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrWaitI2CStart;
				end if;
					
			-- Wait for I2C Controller to... (?)
			when stWrWaitI2CStart =>
				if I2CWaitCountxDP = i2c_wait_time then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stWrReadStatusRegister;
				else 
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if; 
				
			-- Read Status register: wait for buffer empty flag so we can start writing data words	
			when stWrReadStatusRegister =>
				-- Choose register to read from and get data using 4 phase handshaking 
				-- (REQ=1 Read from this address!; ACK=1 Data ready!; REQ=0 Got it!; ACK=0 Anything else, bro?)
				I2CAddrxD <= comm_stat;
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					-- Check Empty Flag
					if I2CDataReadxD(1) = '1' then 
						StateIMUxDN <= stWrWriteDataBufferRegister;
					end if;
					-- If buffer is not empty, then when ReadAck = 0 we will read again from this register
				end if;
				
			-- Write next data byte, which initialize the IMU registers
			-- Use counter as a select signal to iterate over the different data bytes
			-- Data iterates between address byte and word byte 
			when stWrWriteDataBufferRegister =>
				I2CAddrxD <= data_buf;
				-- Select correct initialization byte to write
				case IMUInitByteCountxDP is 
					when "0000" => I2CDataWritexD <= IMUInitByte01; 
					when "0001" => I2CDataWritexD <= IMUInitByte02; 
					when "0010" => I2CDataWritexD <= IMUInitByte03; 
					when "0011" => I2CDataWritexD <= IMUInitByte04; 
					when "0100" => I2CDataWritexD <= IMUInitByte05; 
					when "0101" => I2CDataWritexD <= IMUInitByte06; 
					when "0110" => I2CDataWritexD <= IMUInitByte07; 
					when "0111" => I2CDataWritexD <= IMUInitByte08; 
					when "1000" => I2CDataWritexD <= IMUInitByte09; 
					when "1001" => I2CDataWritexD <= IMUInitByte10; 
					when others => I2CDataWritexD <= (others => '0');
				end case;
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					-- Iterate over all initialization bytes
					if IMUInitByteCountxDP = imu_init_byte_length then
						IMUInitByteCountxDN <= (others => '0');
						StateIMUxDN <= stWrWaitI2CEnd;
					else
						IMUInitByteCountxDN <= IMUInitByteCountxDP + 1;
						StateIMUxDN <= stWrReadStatusRegister;
					end if;
				end if;
				
			-- Wait for I2C Controller to... (?)
			when stWrWaitI2CEnd =>
				if I2CWaitCountxDP = i2c_wait_time then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stWrCheckDone;
				else
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if; 

			-- Read Status register and wait for transaction done bit
			when stWrCheckDone => 
				I2CAddrxD <= comm_stat;
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					-- Transaction Done Flag
					if I2CDataReadxD(3) = '1' then 
						StateIMUxDN <= stRdIntWriteAddressRegister;
					end if;
				end if;
			-- END Write Configuration Registers to IMU (stWrX)


			-- START Read Interrupt to check when new data is available (stRdIntX)
			-- Write IMU Device Address
			when stRdIntWriteAddressRegister =>
				I2CAddrxD <= low_addr;
				I2CDataWritexD <= I2C_IMU_ADDR & '0';
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWriteAddrByteCountRegister;
				end if;

			-- Write number of bytes to be Read: 1
			-- Write byte corresponding to address of IMU Interrupt Status
			when stRdIntWriteAddrByteCountRegister =>
				I2CAddrxD <= byte_count;
				I2CDataWritexD <= I2C_IMU_INT_READ_BYTE_COUNT;  
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWriteDataBufferRegister;
				end if;

			-- Write address for first data register in IMU that will be read: ACCEL_XOUT_H
			-- As this value becomes read, the IMU will internally increment the register to point to the next data register
			when stRdIntWriteDataBufferRegister =>
				I2CAddrxD <= data_buf;
				I2CDataWritexD <= I2C_IMU_INT_STATUS;  
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWriteCommandRegister;
				end if;

			-- Issue Go command to start data transactions in polling mode
			when stRdIntWriteCommandRegister =>
				I2CAddrxD <= comm_stat;
				I2CDataWritexD <= I2C_IMU_COMMAND; 
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWaitI2CStart;
				end if;
					
			-- Wait for I2C Controller to... (?)
			when stRdIntWaitI2CStart =>
				if I2CWaitCountxDP = i2c_wait_time then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stRdIntCheckDone;
				else
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if; 
				
			-- Read Status register and wait for transaction done bit
			when stRdIntCheckDone =>				
				I2CAddrxD <= comm_stat;
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					if I2CDataReadxD(3) = '1' then 
						StateIMUxDN <= stRdIntWriteAddressRegister1;
					end if;
				end if;
			
			-- Now that the appropriate data register to read from is set, we start process all over again
			-- Write IMU Device Address
			when stRdIntWriteAddressRegister1 =>
				I2CAddrxD <= low_addr;
				I2CDataWritexD <= I2C_IMU_ADDR & '0';
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWriteByteCountRegister1;
				end if;

			-- Write number of bytes to be Read: 1
			-- Read Interrupt Status Register
			when stRdIntWriteByteCountRegister1 =>
				I2CAddrxD <= byte_count;
				I2CDataWritexD <= I2C_IMU_INT_READ_BYTE_COUNT;  
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWriteCommandRegister1;
				end if;

			-- Issue Go command to start data transactions in polling mode
			when stRdIntWriteCommandRegister1 =>
				I2CAddrxD <= comm_stat;
				I2CDataWritexD <= I2C_IMU_COMMAND;
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWaitI2CStart1;
				end if;

			-- Wait for I2C Controller to... (?)
			when stRdIntWaitI2CStart1 =>
				if I2CWaitCountxDP = i2c_wait_time then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stRdIntReadStatusRegister;
				else
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if;
				
			-- Read Status register and wait for full buffer before reading data word	
			when stRdIntReadStatusRegister =>
				I2CAddrxD <= comm_stat;
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					if I2CDataReadxD(0) = '1' then 
						StateIMUxDN <= stRdIntReadDataBufferRegister;
					end if;
				end if;

			-- Read data byte, which is the Interrupt signal indicating when new IMU data is ready
			when stRdIntReadDataBufferRegister =>
				I2CAddrxD <= data_buf;
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					-- Indicate that new data is available to read
					IMUNewMeasxE <= I2CDataReadxD(0);
					StateIMUxDN <= stRdIntReadDataBufferRegister;
				end if;
			
			-- Wait for I2C Controller to... (?)
			when stRdIntWaitI2CEnd1 =>
				if I2CWaitCountxDP = i2c_wait_time then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stRdIntCheckDone1;
				else 
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if; 
				
			-- Read Status register and wait for transaction done bit
			-- If there is new data available then start reading it, otherwise wait for new data to be available
			when stRdIntCheckDone1 =>				
				I2CAddrxD <= comm_stat;
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					if I2CDataReadxD(3) = '1' then 
						-- If new data has become available, then start process of reading data registers
						if IMUNewMeasxE = '1' then 
							StateIMUxDN <= stRdWriteAddressRegister;
						-- Otherwise keep reading interrupt register to poll for new data
						else
							StateIMUxDN <= stRdIntWriteAddressRegister;
						end if; 
					end if;
				end if;
			-- END Read Interrupt to check when new data is available (stRdIntX)			

			-- START Read Data Registers from IMU (stRdX)
			-- Write IMU Device Address
			when stRdWriteAddressRegister =>
				I2CAddrxD <= low_addr;
				I2CDataWritexD <= I2C_IMU_ADDR & '0';
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWriteAddrByteCountRegister;
				end if;

			-- Write number of bytes to be Read: 1
			-- Only need to write byte corresponding to address of first IMU data register
			when stRdWriteAddrByteCountRegister =>
				I2CAddrxD <= byte_count;
				I2CDataWritexD <= I2C_IMU_ADDR_READ_BYTE_COUNT;  
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWriteDataBufferRegister;
				end if;

			-- Write address for first data register in IMU that will be read: ACCEL_XOUT_H
			-- As this value becomes read, the IMU will internally increment the register to point to the next data register
			when stRdWriteDataBufferRegister =>
				I2CAddrxD <= data_buf;
				I2CDataWritexD <= I2C_IMU_ACCEL_XOUT_H_ADDR;  
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWriteCommandRegister;
				end if;

			-- Issue Go command to start data transactions in polling mode
			when stRdWriteCommandRegister =>
				I2CAddrxD <= comm_stat;
				I2CDataWritexD <= I2C_IMU_COMMAND; 
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWaitI2CStart;
				end if;
					
			-- Wait for I2C Controller to... (?)
			when stRdWaitI2CStart =>
				if I2CWaitCountxDP = i2c_wait_time then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stRdCheckDone;
				else
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if; 
				
			-- Read Status register and wait for transaction done bit
			when stRdCheckDone =>				I2CAddrxD <= comm_stat;
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					if I2CDataReadxD(3) = '1' then 
						StateIMUxDN <= stRdWriteAddressRegister;
					end if;
				end if;
			
			-- Now that the appropriate data register to read from is set, we start process all over again
			-- Write IMU Device Address
			when stRdWriteAddressRegister1 =>
				I2CAddrxD <= low_addr;
				I2CDataWritexD <= I2C_IMU_ADDR & '0';
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWriteByteCountRegister1;
				end if;

			-- Write number of bytes to be Read: 14
			-- 2 Bytes per measurement, 3 Measurements for Accel (3 axis), 1 Measurement for Temp, 3 Measurements for Gyro (3 axis)
			when stRdWriteByteCountRegister1 =>
				I2CAddrxD <= byte_count;
				I2CDataWritexD <= I2C_IMU_DATA_READ_BYTE_COUNT;  
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWriteCommandRegister1;
				end if;

			-- Issue Go command to start data transactions in polling mode
			when stRdWriteCommandRegister1 =>
				I2CAddrxD <= comm_stat;
				I2CDataWritexD <= I2C_IMU_COMMAND;
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdWaitI2CStart1;
				end if;
					
			-- Wait for I2C Controller to... (?)
			when stRdWaitI2CStart1 =>
				if I2CWaitCountxDP = i2c_wait_time then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stRdReadStatusRegister;
				else
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if;
				
			-- Read Status register and wait for full buffer before reading data word	
			when stRdReadStatusRegister =>
				I2CAddrxD <= comm_stat;
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					if I2CDataReadxD(0) = '1' then 
						StateIMUxDN <= stRdReadDataBufferRegister;
					end if;
				end if;

			-- Read data byte, which are sensor measurements from the IMU
			-- Use counter to know measurement we are currently reading
			-- We read 1 byte at a time iterating from MSB of Accel X to LSB of Gyro Z
			when stRdReadDataBufferRegister =>
				I2CAddrxD <= data_buf;
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					-- Write data to correct measurement register
					case IMUMeasByteCountxDP is
						when "0000" =>	IMUAccelXxD(15 downto 8) <= I2CDataReadxD;
						when "0001" =>	IMUAccelXxD(7 downto 0)  <= I2CDataReadxD;
						when "0010" =>	IMUAccelYxD(15 downto 8) <= I2CDataReadxD;
						when "0011" =>	IMUAccelYxD(7 downto 0)  <= I2CDataReadxD;
						when "0100" =>	IMUAccelZxD(15 downto 8) <= I2CDataReadxD;
						when "0101" =>	IMUAccelZxD(7 downto 0)  <= I2CDataReadxD;
						when "0110" =>	IMUTempxD(15 downto 8)   <= I2CDataReadxD;
						when "0111" =>	IMUTempxD(7 downto 0)    <= I2CDataReadxD;
						when "1000" =>	IMUGyroXxD(15 downto 8)  <= I2CDataReadxD;
						when "1001" =>	IMUGyroXxD(7 downto 0)   <= I2CDataReadxD;
						when "1010" =>	IMUGyroYxD(15 downto 8)  <= I2CDataReadxD;
						when "1011" =>	IMUGyroYxD(7 downto 0)   <= I2CDataReadxD;
						when "1100" =>	IMUGyroZxD(15 downto 8)  <= I2CDataReadxD;
						when "1101" =>	IMUGyroZxD(7 downto 0)   <= I2CDataReadxD;
						when others => 	null; 
					end case;
					-- Iterate over all measurement bytes
					if IMUMeasByteCountxDP = imu_meas_byte_length then
						IMUMeasByteCountxDN <= (others => '0');
						StateIMUxDN <= stRdWaitI2CEnd1;
					else
						IMUMeasByteCountxDN <= IMUMeasByteCountxDP + 1;
						StateIMUxDN <= stRdReadStatusRegister;
					end if;
				end if;
			
			-- Wait for I2C Controller to... (?)
			when stRdWaitI2CEnd1 =>
				if I2CWaitCountxDP = i2c_wait_time then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stRdCheckDone1;
				else
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if; 
				
			-- Read Status register and wait for transaction done bit
			-- Once all 14 bytes have been read, then go back to set the first data measurement register and reread
			when stRdCheckDone1 =>
				I2CAddrxD <= comm_stat;
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					-- Transaction Done flag
					if I2CDataReadxD(3) = '1' then 
						-- Indicate that Data is ready to be Written to the FIFO using 4 phase handshaking 
						-- Handshake handled by p_imu_write process
						IMUDataReadyReqxEO <= '1'; 
						StateIMUxDN <= stRdWriteAddressRegister;
					end if;
				end if;
			-- END Read Data Registers from IMU (stRdX)
			
		end case;

	end process p_imu;

	
	-- Calculate next state and outputs for handshaking with monitor state machine to write IMU data to FIFO
	-- We handshake 2 different sets of signals. We wait for Monitor state machine to be ready to write IMU data (IMUDataReadyX)
	-- and then we write the data (IMUDataWriteX)
	p_imu_write : process (StateIMUWritexDP, IMUDataReadyAckxEI, IMUDataWriteReqxEI)
	begin 
  
		-- Default Assignments
		StateIMUWritexDN <= StateIMUWritexDP;
		IMUDataWordCountxDN	<= IMUDataWordCountxDP;	
		IMURegisterWritexEO <= '0';
		
		case StateIMUWritexDP is
			
			when stIdle =>
				IMUDataWordCountxDN <= (others => '0');
				IMUDataWriteAckxEO <= '1'; -- CHECK THIS
				-- Wait for Monitor State Machine to be ready to write IMU data
				if IMUDataReadyAckxEI = '1' then
					IMUDataReadyReqxEO <= '0';
					StateIMUWritexDN <= stDataWriteReq;
				end if;
				
			-- Send IMU Data one at a time
			when stDataWriteReq =>
				-- Wait for Monitor State Machine to request writing data
				if IMUDataWriteReqxEI = '1' then
					-- Select correct IMU Data word to write out
					case IMUDataWordCountxDP is 
						when "000" => IMUDataxDO <= IMUAccelXxD; 
						when "001" => IMUDataxDO <= IMUAccelYxD; 
						when "010" => IMUDataxDO <= IMUAccelZxD; 
						when "011" => IMUDataxDO <= IMUTempxD; 
						when "100" => IMUDataxDO <= IMUGyroXxD; 
						when "101" => IMUDataxDO <= IMUGyroYxD; 
						when "110" => IMUDataxDO <= IMUGyroZxD; 
						when others => IMUDataxDO <= (others => '0');
					end case;
					-- Update IMU Register with correct word
					IMURegisterWritexEO <= '1';
					
					-- Iterate over all data words
					if IMUDataWordCountxDP = imu_data_word_length then
						StateIMUWritexDN <= stDataWriteAck;
					else
						IMUDataWordCountxDN <= IMUDataWordCountxDP + 1;
					end if;
				
				end if;
			
			-- Acknowledge that all data has been sent
			when stDataWriteAck =>		
				-- VERIFY THIS! WHEN DO WE SET ACK TO 0, NEED SYNCHRONIZATION?!
				IMUDataWriteAckxEO <= '1';
				IMURegisterWritexEO <= '0';
				StateIMUWritexDN <= stIdle;
					
		end case; 
		-- END case 
		
	end process p_imu_write;


	-- IS THIS THE BEST WAY TO DO THIS?!
	-- CREATE NEW PROCESS FOR I2CAckxSB THAT RETURNS I2C ACK HIGH AFTER 3 CLOCK CYCLES.. MAKE 4 TO BE SAFE?
	p_i2c_ack : process (I2CAckCountxDP)
	begin
		
		-- Default Assignments
		I2CAckCountxDN <= I2CAckCountxDP;
		I2CAckxE <= '0';
		
		-- If I2C Chip Select is asserted then start counting
		if I2CReqxE = '1' then
			I2CAckCountxDN <= I2CAckCountxDP + 1;
		-- Assert I2CAck after i2c_ack_length number of cycles
		elsif I2CAckCountxDP = i2c_ack_length then
			I2CAckxE <= '1';
		-- Else reset counter
		else 
			I2CAckCountxDN <= (others => '0');
		end if;
		
	end process p_i2c_ack;


	-- Change states and increase counters on rising clock edge
	p_memorizing : process (ClockxC, ResetxRB)
	begin  
		if ResetxRB = '0' then -- Asynchronous reset
			StateRWxDP <= stIdle;
			StateIMUxDP <= stIdle;
			StateIMUWritexDP <= stIdle;
			IMUInitByteCountxDP <= (others => '0');
			IMUMeasByteCountxDP <= (others => '0');
			IMUDataWordCountxDP	<= (others => '0');
			I2CWaitCountxDP <= (others => '0');
			I2CAckCountxDP	<= (others => '0');
			
		elsif ClockxC'event and ClockxC = '1' then  -- On rising clock edge   
			StateRWxDP <= StateRWxDN;
			StateIMUxDP <= StateIMUxDN;
			StateIMUWritexDP <= StateIMUWritexDN;
			IMUInitByteCountxDP <= IMUInitByteCountxDN;
			IMUMeasByteCountxDP <= IMUMeasByteCountxDN;
			IMUDataWordCountxDP <= IMUDataWordCountxDN;
			I2CWaitCountxDP <= I2CWaitCountxDN;
			I2CAckCountxDP <= I2CAckCountxDN;
		
		end if;
		
	end process p_memorizing;

end Behavioral;
