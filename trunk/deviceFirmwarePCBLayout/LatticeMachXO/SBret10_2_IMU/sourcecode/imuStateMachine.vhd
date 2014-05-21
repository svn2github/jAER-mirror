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
		IMUDataDropxEI		: in std_logic;  -- Indicates that DataReadyReq was acknowledged but data don't be written to FIFO
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
			stReadRegister1, stReadRegister2, stReadRegister3, stReadRegister4);
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
	type stateIMUWrite is (stIdle, stDataReadyReq, stDataWriteReq, stDataWriteAck);
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
	constant I2C_IMU_WRITE					: std_logic := '0'; -- Write bit appended to end of IMU I2C Address
	constant I2C_IMU_READ					: std_logic := '1'; -- Read bit appended to end of IMU I2C Address
	constant I2C_IMU_ACCEL_XOUT_H_ADDR 		: std_logic_vector(7 downto 0) := "00111011"; -- First IMU Data Register containing 8 MSB bits from x axis of accelerometer
	constant I2C_IMU_WRITE_BYTE_COUNT 		: std_logic_vector(7 downto 0) := "00001010"; -- Number of configuration bytes to write to IMU, 5 addresses, 5 data
	constant I2C_IMU_INT_READ_BYTE_COUNT	: std_logic_vector(7 downto 0) := "00000001"; -- Number of bytes to write to select IMU Interrupt Register
	constant I2C_IMU_INT_STATUS				: std_logic_vector(7 downto 0) := "00111010"; -- Interrupt Status register, which indicates when new data is available
	constant I2C_IMU_ADDR_READ_BYTE_COUNT 	: std_logic_vector(7 downto 0) := "00000001"; -- Only write to first IMU Data Register, this register gets incremented internally
	constant I2C_IMU_DATA_READ_BYTE_COUNT 	: std_logic_vector(7 downto 0) := "00001110"; -- Read 14 bytes of data, 2 bytes per measurement, 3 for Accel, 3 for Gyro, 1 for Temp
	constant I2C_IMU_COMMAND 				: std_logic_vector(7 downto 0) := "10001000"; -- Continuously poll data at 400 kbits/sec
	
	-- I2C signals
	signal I2CAckCountxDN, I2CAckCountxDP : std_logic_vector(2 downto 0); -- Counter for data to be latched into I2C Controller Register
	constant i2c_ack_length : std_logic_vector(2 downto 0) := "101"; -- Maximum valid value for I2CAckCount: 5 (6 clock cycles)

	signal I2CWaitCountxDN, I2CWaitCountxDP : std_logic_vector(7 downto 0); -- Wait state counter
    constant i2c_wait_time	: std_logic_vector(7 downto 0) := "00101000"; -- Clock cycles to wait for ...: 40 clock cycles
	
	-- I2C mux outputs
	signal I2CAddrxD : std_logic_vector(2 downto 0) := "000"; -- I2C Controller Address register
	signal I2CDataWritexD : std_logic_vector(7 downto 0); -- I2C Controller Data Write register driving I2CDataxDIO
	signal I2CDataReadxD : std_logic_vector(7 downto 0) := "00000000"; -- I2C Controller Data Read register driving I2CDataxDIO

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
	-- IMU Byte Data (Read from I2C)
	signal IMUAccelXMSBxDN, IMUAccelXMSBxDP : std_logic_vector(7 downto 0); -- X Accelerometer Measurement (15 downto 8)
	signal IMUAccelXLSBxDN, IMUAccelXLSBxDP : std_logic_vector(7 downto 0); -- X Accelerometer Measurement (7 downto 0)
	signal IMUAccelYMSBxDN, IMUAccelYMSBxDP : std_logic_vector(7 downto 0); -- Y Accelerometer Measurement (15 downto 8)
	signal IMUAccelYLSBxDN, IMUAccelYLSBxDP : std_logic_vector(7 downto 0); -- Y Accelerometer Measurement (7 downto 0)
	signal IMUAccelZMSBxDN, IMUAccelZMSBxDP : std_logic_vector(7 downto 0); -- Z Accelerometer Measurement (15 downto 8)
	signal IMUAccelZLSBxDN, IMUAccelZLSBxDP : std_logic_vector(7 downto 0); -- Z Accelerometer Measurement (7 downto 0)
	signal IMUTempMSBxDN, IMUTempMSBxDP : std_logic_vector(7 downto 0); -- Temperature Measurement (15 downto 8)
	signal IMUTempLSBxDN, IMUTempLSBxDP : std_logic_vector(7 downto 0); -- Temperature Measurement (7 downto 0)
	signal IMUGyroXMSBxDN, IMUGyroXMSBxDP : std_logic_vector(7 downto 0); -- X Gyroscope Measurement (15 downto 8)
	signal IMUGyroXLSBxDN, IMUGyroXLSBxDP : std_logic_vector(7 downto 0); -- X Gyroscope Measurement (7 downto 0)
	signal IMUGyroYMSBxDN, IMUGyroYMSBxDP : std_logic_vector(7 downto 0); -- Y Gyroscope Measurement (15 downto 8)
	signal IMUGyroYLSBxDN, IMUGyroYLSBxDP : std_logic_vector(7 downto 0); -- Y Gyroscope Measurement (7 downto 0)
	signal IMUGyroZMSBxDN, IMUGyroZMSBxDP : std_logic_vector(7 downto 0); -- Z Gyroscope Measurement (15 downto 8)
	signal IMUGyroZLSBxDN, IMUGyroZLSBxDP : std_logic_vector(7 downto 0); -- Z Gyroscope Measurement (7 downto 0)
	-- IMU Word Data (Written to FIFO)
	signal IMUAccelXxDN, IMUAccelXxDP : std_logic_vector(15 downto 0); -- X Accelerometer Measurement
	signal IMUAccelYxDN, IMUAccelYxDP : std_logic_vector(15 downto 0); -- Y Accelerometer Measurement
	signal IMUAccelZxDN, IMUAccelZxDP : std_logic_vector(15 downto 0); -- Z Accelerometer Measurement
	signal IMUTempxDN, IMUTempxDP : std_logic_vector(15 downto 0); -- Temperature Measurement
	signal IMUGyroXxDN, IMUGyroXxDP : std_logic_vector(15 downto 0); -- X Gyroscope Measurement
	signal IMUGyroYxDN, IMUGyroYxDP : std_logic_vector(15 downto 0); -- Y Gyroscope Measurement
	signal IMUGyroZxDN, IMUGyroZxDP : std_logic_vector(15 downto 0); -- Z Gyroscope Measurement
	
	-- IMU Write Signals (interfaces with Monitor State Machine)
	constant imu_data_word_length : std_logic_vector(2 downto 0) := "110"; -- Maximum valid value for IMUDataWordCount: 6 (7 16-bit words)
	signal IMUDataWordCountxDN, IMUDataWordCountxDP : std_logic_vector(2 downto 0); -- IMU Measurement Word counter used while iterating through Data
	
	-- IMU Data Ready (interfaces p_imu with p_imu_write) 
	signal IMUDataReadyxE : std_logic;
	
	-- Intermediate / routing signals
	signal ResetxRB : std_logic;
	signal ClockxC  : std_logic;
	

begin
  
	-- Default assignments
	ResetxRB <= ResetxRBI;
	ClockxC <= ClockxCI;  
	
	-- Calculate next state and outputs for I2C Read and Write operations
	p_i2c_read_write : process (StateRWxDP, WriteReqxE, ReadReqxE, I2CDataWritexD, I2CAddrxD, I2CDataWritexD, I2CAddrxD, I2CAckCountxDP)
	begin 
  
		-- Default assignments 
		-- Registers
		StateRWxDN <= StateRWxDP; 
		I2CAckCountxDN <= I2CAckCountxDP;
		-- Output Signals
		WriteAckxE <= '0'; 
		ReadAckxE <= '0'; 
		I2CDataReadxD <= (others => '0');
		
		-- START CASE StateRWxDP
		case StateRWxDP is
			
			when stIdle =>
				I2CDataxDIO <= (others => 'Z'); 
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				I2CCSxSBO <= '1';
				
				-- Write and Read I2C Register Request signals
				if WriteReqxE = '1' then
					StateRWxDN <= stWriteRegister1;
				elsif ReadReqxE = '1' then 
					StateRWxDN <= stReadRegister1;
				end if;
				
			-- START I2C Write 
			when stWriteRegister1 => -- Set 
				I2CDataxDIO <= I2CDataWritexD;  
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '0';
				I2CCSxSBO <= '1';

				StateRWxDN <= stWriteRegister2;

			when stWriteRegister2 => -- Wait to latch
				I2CDataxDIO <= I2CDataWritexD;  
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '0';
				I2CCSxSBO <= '0';

				-- Wait in this state for i2c_ack_length clock cycles
				if I2CAckCountxDP = i2c_ack_length then
					I2CAckCountxDN <= (others => '0');
					StateRWxDN <= stWriteRegister3;
				else 
					I2CAckCountxDN <= I2CAckCountxDP + 1;
				end if; 
				
			when stWriteRegister3 => -- Write
				I2CDataxDIO <= I2CDataWritexD;  
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '0';
				I2CCSxSBO <= '1';

				-- Handshaking
				WriteAckxE <= '1';
				if WriteReqxE = '0' then
					StateRWxDN <= stWriteRegister4;
				end if;
			
			when stWriteRegister4 => -- Acknowledge
				I2CDataxDIO <= (others => 'Z'); 
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				I2CCSxSBO <= '1';

				-- Handshaking
				WriteAckxE <= '0';
				
				StateRWxDN <= stIdle;

			-- END I2C Write
			
			-- START I2C Read
			when stReadRegister1 => -- Set 
				I2CDataxDIO <= (others => 'Z'); 
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				I2CCSxSBO <= '1';

				StateRWxDN <= stReadRegister2;

			when stReadRegister2 => -- Wait to latch
				I2CDataxDIO <= (others => 'Z');
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				I2CCSxSBO <= '0';

				-- Wait in this state for i2c_ack_length clock cycles
				if I2CAckCountxDP = i2c_ack_length then
					I2CAckCountxDN <= (others => '0');
					StateRWxDN <= stReadRegister3;
				else 
					I2CAckCountxDN <= I2CAckCountxDP + 1;
				end if; 
			
			when stReadRegister3 => -- Read
				I2CDataReadxD <= I2CDataxDIO;  
				I2CDataxDIO <= (others => 'Z'); -- After reading, set signal back to 'Z' to ensure inout can be written to 
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				I2CCSxSBO <= '0';
				
				-- Handshaking
				ReadAckxE <= '1';
				if ReadReqxE = '0' then
					StateRWxDN <= stReadRegister4;
				end if;
				
			when stReadRegister4 => -- Acknowledge
				I2CDataxDIO <= (others => 'Z'); 
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				I2CCSxSBO <= '1'; 

				-- Handshaking
				ReadAckxE <= '0';
				
				StateRWxDN <= stIdle;
				
			-- END I2C Read

		end case; 
		-- END CASE StateRWxDP
		
	end process p_i2c_read_write;

	
	-- Calculate next state and outputs for I2C Controller and IMU transaction
	p_imu : process (StateIMUxDP, IMUInitByteCountxDP, IMUMeasByteCountxDP, I2CWaitCountxDP, 
			IMUAccelXMSBxDP, IMUAccelXLSBxDP, IMUAccelYMSBxDP, IMUAccelYLSBxDP, IMUAccelZMSBxDP, IMUAccelZLSBxDP,
			IMUTempMSBxDP, IMUTempLSBxDP, IMUGyroXMSBxDP, IMUGyroXLSBxDP, IMUGyroYMSBxDP, IMUGyroYLSBxDP, IMUGyroZMSBxDP, IMUGyroZLSBxDP,   
			IMURunxEI, WriteAckxE, ReadAckxE, I2CDataReadxD) 
	begin 
  
		-- Default assignemnts
		-- Registers
		StateIMUxDN 		<= StateIMUxDP;
		IMUInitByteCountxDN	<= IMUInitByteCountxDP;	
		IMUMeasByteCountxDN	<= IMUMeasByteCountxDP;	
		I2CWaitCountxDN 	<= I2CWaitCountxDP;
		IMUAccelXMSBxDN 	<= IMUAccelXMSBxDP;
		IMUAccelXLSBxDN 	<= IMUAccelXLSBxDP;
		IMUAccelYMSBxDN 	<= IMUAccelYMSBxDP;
		IMUAccelYLSBxDN 	<= IMUAccelYLSBxDP;
		IMUAccelZMSBxDN 	<= IMUAccelZMSBxDP;
		IMUAccelZLSBxDN 	<= IMUAccelZLSBxDP;
		IMUTempMSBxDN 		<= IMUTempMSBxDP;
		IMUTempLSBxDN 		<= IMUTempLSBxDP;
		IMUGyroXMSBxDN 		<= IMUGyroXMSBxDP;
		IMUGyroXLSBxDN 		<= IMUGyroXLSBxDP;
		IMUGyroYMSBxDN 		<= IMUGyroYMSBxDP;
		IMUGyroYLSBxDN 		<= IMUGyroYLSBxDP;
		IMUGyroZMSBxDN 		<= IMUGyroZMSBxDP;
		IMUGyroZLSBxDN 		<= IMUGyroZLSBxDP;
		-- Output Signals
		WriteReqxE <= '0'; 
		ReadReqxE <= '0'; 
		I2CAddrxD <= (others => '0');
		I2CDataWritexD <= (others => '0');
		IMUDataReadyxE <= '0';
		
		-- START CASE StateIMUxDP
		case StateIMUxDP is
			
			when stIdle =>
				-- Default assignments 
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
				I2CDataWritexD <= I2C_IMU_ADDR & I2C_IMU_WRITE; -- IMU Address, Write mode
				
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
				I2CDataWritexD <= I2C_IMU_ADDR & I2C_IMU_WRITE;
				
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
					
					-- Transaction Done flag
					if I2CDataReadxD(3) = '1' then 
						StateIMUxDN <= stRdIntWriteAddressRegister1;
					end if;
					
				end if;
			
			-- Now that the appropriate data register to read from is set, we start process all over again
			-- Write IMU Device Address
			when stRdIntWriteAddressRegister1 =>
				I2CAddrxD <= low_addr;
				I2CDataWritexD <= I2C_IMU_ADDR & I2C_IMU_READ;
				
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
					
					-- Recieve Buffer Full
					if I2CDataReadxD(0) = '1' then 
						StateIMUxDN <= stRdIntReadDataBufferRegister;
					end if;
					
				end if;

			-- Read data byte, which is the IMU Interrupt signal indicating when new IMU data is ready
			when stRdIntReadDataBufferRegister =>
				I2CAddrxD <= data_buf;
				
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';

					-- New data is available to read
					if I2CDataReadxD(0) = '1' then 
						StateIMUxDN <= stRdIntWaitI2CEnd1;
					-- Start over, keep on polling
					else
						StateIMUxDN <= stWrWaitI2CEnd;
					end if;

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
					
					-- Transaction Done
					if I2CDataReadxD(3) = '1' then 
						StateIMUxDN <= stRdWriteAddressRegister;
					end if;
					
				end if;
			-- END Read Interrupt to check when new data is available (stRdIntX)			

			-- START Read Data Registers from IMU (stRdX)
			-- Write IMU Device Address
			when stRdWriteAddressRegister =>
				I2CAddrxD <= low_addr;
				I2CDataWritexD <= I2C_IMU_ADDR & I2C_IMU_WRITE;
				
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
					
					-- Transaction Done
					if I2CDataReadxD(3) = '1' then 
						StateIMUxDN <= stRdWriteAddressRegister1;
					end if;
					
				end if;
			
			-- Now that the appropriate data register to read from is set, we start process all over again
			-- Write IMU Device Address
			when stRdWriteAddressRegister1 =>
				I2CAddrxD <= low_addr;
				I2CDataWritexD <= I2C_IMU_ADDR & I2C_IMU_READ;
				
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
					
					-- Receive Buffer Full
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
					
					--Write data to correct measurement register
					case IMUMeasByteCountxDP is
						when "0000" =>	IMUAccelXMSBxDN	<= I2CDataReadxD;
						when "0001" =>	IMUAccelXLSBxDN	<= I2CDataReadxD;
						when "0010" =>	IMUAccelYMSBxDN	<= I2CDataReadxD;
						when "0011" =>	IMUAccelYLSBxDN	<= I2CDataReadxD;
						when "0100" =>	IMUAccelZMSBxDN	<= I2CDataReadxD;
						when "0101" =>	IMUAccelZLSBxDN	<= I2CDataReadxD;
						when "0110" =>	IMUTempMSBxDN	<= I2CDataReadxD;
						when "0111" =>	IMUTempLSBxDN	<= I2CDataReadxD;
						when "1000" =>	IMUGyroXMSBxDN	<= I2CDataReadxD;
						when "1001" =>	IMUGyroXLSBxDN	<= I2CDataReadxD;
						when "1010" =>	IMUGyroYMSBxDN	<= I2CDataReadxD;
						when "1011" =>	IMUGyroYLSBxDN	<= I2CDataReadxD;
						when "1100" =>	IMUGyroZMSBxDN	<= I2CDataReadxD;
						when "1101" =>	IMUGyroZLSBxDN	<= I2CDataReadxD;
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
						-- Indicate that Data is ready to be Written to the FIFO 
						-- Handshaking with monitor state machine handled by p_imu_write process 
						IMUDataReadyxE <= '1'; 
						StateIMUxDN <= stRdWriteAddressRegister;
					end if;
					
				end if;
			-- END Read Data Registers from IMU (stRdX)
			
		end case;
		-- END CASE StateIMUxDP

	end process p_imu;

	
	-- Calculate next state and outputs for handshaking with monitor state machine to write IMU data to FIFO
	-- We handshake 2 different sets of signals. We wait for Monitor state machine to be ready to write IMU data (IMUDataReadyX)
	-- and then we write the data (IMUDataWriteX)
	p_imu_write : process (StateIMUWritexDP, IMUDataWordCountxDP, IMUDataReadyAckxEI, IMUDataWriteReqxEI,
			IMUAccelXMSBxDP, IMUAccelXLSBxDP, IMUAccelYMSBxDP, IMUAccelYLSBxDP, IMUAccelZMSBxDP, IMUAccelZLSBxDP,
			IMUTempMSBxDP, IMUTempLSBxDP, IMUGyroXMSBxDP, IMUGyroXLSBxDP, IMUGyroYMSBxDP, IMUGyroYLSBxDP, IMUGyroZMSBxDP, IMUGyroZLSBxDP, 
			IMUAccelXxDP, IMUAccelYxDP, IMUAccelZxDP, IMUTempxDP, IMUGyroXxDP, IMUGyroYxDP, IMUGyroZxDP, IMUDataDropxEI, IMUDataReadyxE)
	begin 
  
		-- Default Assignments
		StateIMUWritexDN <= StateIMUWritexDP;
		IMUDataWordCountxDN	<= IMUDataWordCountxDP;	
		IMUAccelXxDN <= IMUAccelXxDP;
		IMUAccelYxDN <= IMUAccelYxDP;
		IMUAccelZxDN <= IMUAccelZxDP;
		IMUTempxDN <= IMUTempxDP;
		IMUGyroXxDN <= IMUGyroXxDP;
		IMUGyroYxDN <= IMUGyroYxDP;
		IMUGyroZxDN <= IMUGyroZxDP;

		IMUDataxDO <= (others => '0');
				
		IMUDataReadyReqxEO <= '0';
		IMUDataWriteAckxEO <= '0'; 
		IMURegisterWritexEO <= '0';
		
		case StateIMUWritexDP is
			
			when stIdle =>
				-- Default Assignments
				IMUDataWordCountxDN <= (others => '0');

				if IMUDataReadyxE = '1' then 
					-- Latch Data to be written
					IMUAccelXxDN <= IMUAccelXMSBxDP & IMUAccelXLSBxDP;
					IMUAccelYxDN <= IMUAccelYMSBxDP & IMUAccelYLSBxDP;
					IMUAccelZxDN <= IMUAccelZMSBxDP & IMUAccelZLSBxDP;
					IMUTempxDN <= IMUTempMSBxDP & IMUTempLSBxDP;
					IMUGyroXxDN <= IMUGyroXMSBxDP & IMUGyroXLSBxDP;
					IMUGyroYxDN <= IMUGyroYMSBxDP & IMUGyroYLSBxDP;
					IMUGyroZxDN <= IMUGyroZMSBxDP & IMUGyroZLSBxDP;
					
					StateIMUWritexDN <= stDataReadyReq;
				end if;

			when stDataReadyReq =>
				-- VERIFY HANDHSAKING HERE FOR COMBINATIONAL LOOPS!!!
				-- WOULDN'T THE SYNTHETIZER COMPLAIN ALREADY ABOUT IT?!
				
				-- Indicate that data is ready and wait for permission from Monitor State Machine to write data
				IMUDataReadyReqxEO <= '1';
				if IMUDataReadyAckxEI = '1' then
					IMUDataReadyReqxEO <= '0';
					
					-- If we don't drop the data, then get ready to write
					if IMUDataDropxEI = '0' then
						StateIMUWritexDN <= stDataWriteReq;
					end if;
				end if;
				
			-- Send IMU Data one at a time
			when stDataWriteReq =>
				-- Wait for Monitor State Machine to request writing data
				if IMUDataWriteReqxEI = '1' then
					-- Select correct IMU Data word to write out
					case IMUDataWordCountxDP is 
						when "000" => IMUDataxDO <= IMUAccelXxDP; 
						when "001" => IMUDataxDO <= IMUAccelYxDP; 
						when "010" => IMUDataxDO <= IMUAccelZxDP; 
						when "011" => IMUDataxDO <= IMUTempxDP; 
						when "100" => IMUDataxDO <= IMUGyroXxDP; 
						when "101" => IMUDataxDO <= IMUGyroYxDP; 
						when "110" => IMUDataxDO <= IMUGyroZxDP; 
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
				IMUDataWriteAckxEO <= '1';
				StateIMUWritexDN <= stIdle;
					
		end case; 
		-- END case 
		
	end process p_imu_write;


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
			IMUAccelXMSBxDP <= (others => '0');
			IMUAccelYMSBxDP <= (others => '0');
			IMUAccelZMSBxDP <= (others => '0');
			IMUTempMSBxDP <= (others => '0');
			IMUGyroXMSBxDP <= (others => '0');
			IMUGyroYMSBxDP <= (others => '0');
			IMUGyroZMSBxDP <= (others => '0');
			IMUAccelXLSBxDP <= (others => '0');
			IMUAccelYLSBxDP <= (others => '0');
			IMUAccelZLSBxDP <= (others => '0');
			IMUTempLSBxDP <= (others => '0');
			IMUGyroXLSBxDP <= (others => '0');
			IMUGyroYLSBxDP <= (others => '0');
			IMUGyroZLSBxDP <= (others => '0');
			IMUAccelXxDP <= (others => '0');
			IMUAccelYxDP <= (others => '0');
			IMUAccelZxDP <= (others => '0');
			IMUTempxDP <= (others => '0');
			IMUGyroXxDP <= (others => '0');
			IMUGyroYxDP <= (others => '0');
			IMUGyroZxDP <= (others => '0');

		elsif ClockxC'event and ClockxC = '1' then  -- On rising clock edge   
			StateRWxDP <= StateRWxDN;
			StateIMUxDP <= StateIMUxDN;
			StateIMUWritexDP <= StateIMUWritexDN;
			IMUInitByteCountxDP <= IMUInitByteCountxDN;
			IMUMeasByteCountxDP <= IMUMeasByteCountxDN;
			IMUDataWordCountxDP <= IMUDataWordCountxDN;
			I2CWaitCountxDP <= I2CWaitCountxDN;
			I2CAckCountxDP <= I2CAckCountxDN;
			IMUAccelXMSBxDP <= IMUAccelXMSBxDN;
			IMUAccelYMSBxDP <= IMUAccelYMSBxDN;
			IMUAccelZMSBxDP <= IMUAccelZMSBxDN;
			IMUTempMSBxDP <= IMUTempMSBxDN;
			IMUGyroXMSBxDP <= IMUGyroXMSBxDN;
			IMUGyroYMSBxDP <= IMUGyroYMSBxDN;
			IMUGyroZMSBxDP <= IMUGyroZMSBxDN;
			IMUAccelXLSBxDP <= IMUAccelXLSBxDN;
			IMUAccelYLSBxDP <= IMUAccelYLSBxDN;
			IMUAccelZLSBxDP <= IMUAccelZLSBxDN;
			IMUTempLSBxDP <= IMUTempLSBxDN;
			IMUGyroXLSBxDP <= IMUGyroXLSBxDN;
			IMUGyroYLSBxDP <= IMUGyroYLSBxDN;
			IMUGyroZLSBxDP <= IMUGyroZLSBxDN;
			IMUAccelXxDP <= IMUAccelXxDN;
			IMUAccelYxDP <= IMUAccelYxDN;
			IMUAccelZxDP <= IMUAccelZxDN;
			IMUTempxDP <= IMUTempxDN;
			IMUGyroXxDP <= IMUGyroXxDN;
			IMUGyroYxDP <= IMUGyroYxDN;
			IMUGyroZxDP <= IMUGyroZxDN;
		
		end if;
		
	end process p_memorizing;

end Behavioral;
