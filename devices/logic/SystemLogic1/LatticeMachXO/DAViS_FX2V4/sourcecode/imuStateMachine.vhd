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

		-- Global (?) Signals
		IMURunxEI           : in  std_logic; -- Start IMU State Machine
		IMUInitDataxDI		: in std_logic_vector(39 downto 0); -- 
	
		-- Signals interfacing with monitorStateMachine
		IMUDataReadyReqxEO  : out std_logic; -- Request Monitor State Machine to write data by signaling that data is ready
		IMUDataReadyAckxEI  : in std_logic;  -- Recieve Acknowledge from Monitor State Machine indicating that we should start writing data
		IMUDataWriteReqxEI  : in std_logic;  -- Recieve Request to start writing IMU Measurement Data
		IMUDataWriteAckxEO  : out std_logic; -- Acknowledge that all IMU Measurement Data have been written
		IMUDataDropxEI		: in std_logic;  -- Indicates that DataReadyReq was acknowledged but data don't be written to FIFO
		IMURegisterWritexEO : out std_logic; -- Enable IMU Data to be written to IMU Register for FIFO
		IMUDataxDO          : out std_logic_vector(15 downto 0); -- IMU Data to be written to IMU Register for FIFO
	
		DebugLEDxEO			: out std_logic
	);
	
end IMUStateMachine;


architecture Behavioral of IMUStateMachine is
  
	-- States used for I2C Controller Register Write and Read 
	type stateRW is (
			-- Idle
			stIdle,
			-- Write to I2C Register
			stWriteRegister1, stWriteRegister2, stWriteRegister3, stWriteRegister4, stWriteRegister5,
			-- Read from I2C Register
			stReadRegister1, stReadRegister2, stReadRegister3, stReadRegister4, stReadRegister5);
	signal StateRWxDP, StateRWxDN : stateRW;

	-- States used to initialize IMU and collect data
	type stateIMU is (
			-- Idle
			stIdle, 
			-- Write Configuration Bits 
			stWrInitWriteAddressRegister, stWrInitWriteByteCountRegister, stWrInitWriteAddrDataBufferRegister, stWrInitWriteCommandRegister,	
			stWrInitWaitI2C1, stWrInitReadStatusRegister, stWrInitWriteDataBufferRegister, stWrInitWaitI2C2, stWrInitCheckDone,
			-- Select Interrupt Data Register
			stWrIntWriteAddressRegister, stWrIntWriteAddrByteCountRegister, stWrIntWriteDataBufferRegister,
			stWrIntWriteCommandRegister, stWrIntWaitI2C, stWrIntCheckDone, 
			-- Poll for new data by reading Interrupt Data Register
			stRdIntWriteAddressRegister, stRdIntWriteByteCountRegister, stRdIntWriteCommandRegister, stRdIntWaitI2C1, stRdIntWaitI2C2,
			stRdIntReadStatusRegister, stRdIntReadDataBufferRegister, stRdIntWaitI2C3, stRdIntCheckDone,
			-- Select Initial Data Register
			stWrDataWriteAddressRegister, stWrDataWriteAddrByteCountRegister, stWrDataWriteDataBufferRegister,
			stWrDataWriteCommandRegister, stWrDataWaitI2C, stWrDataCheckDone, 
			-- Read Data Registers
			stRdDataWriteAddressRegister, stRdDataWriteByteCountRegister, stRdDataWriteCommandRegister, stRdDataWaitI2C1, stRdDataWaitI2C2,
			stRdDataReadStatusRegister, stRdDataReadDataBufferRegister, stRdDataWaitI2C3, stRdDataCheckDone);
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
	constant I2C_IMU_COMMAND 				: std_logic_vector(7 downto 0) := "10001000"; -- Continuously poll data at 400 kbits/sec
	constant I2C_IMU_WRITE_BYTE_COUNT 		: std_logic_vector(7 downto 0) := "00000010"; -- Number of configuration bytes to write to IMU at a time: 1 address, 1 word
	constant I2C_IMU_INT_READ_BYTE_COUNT	: std_logic_vector(7 downto 0) := "00000001"; -- Number of bytes to write to select IMU Interrupt Register
	constant I2C_IMU_INT_STATUS				: std_logic_vector(7 downto 0) := "00111010"; -- Interrupt Status register, which indicates when new data is available
	constant I2C_IMU_ADDR_READ_BYTE_COUNT 	: std_logic_vector(7 downto 0) := "00000001"; -- Only write to first IMU Data Register, this register gets incremented internally
	constant I2C_IMU_ACCEL_XOUT_H_ADDR 		: std_logic_vector(7 downto 0) := "00111011"; -- First IMU Data Register containing 8 MSB bits from x axis of accelerometer
	constant I2C_IMU_DATA_READ_BYTE_COUNT 	: std_logic_vector(7 downto 0) := "00001110"; -- Read 14 bytes of data, 2 bytes per measurement, 3 for Accel, 3 for Gyro, 1 for Temp
	
	-- I2C signals
	signal I2CCountxDN, I2CCountxDP : std_logic_vector(2 downto 0); -- Counter for data to be latched into I2C Controller Register
	constant i2c_ack_length : std_logic_vector(2 downto 0) := "100"; -- Maximum valid value for I2C Acknowledge: 4 (5 clock cycles)
	constant i2c_kill_time : std_logic_vector(2 downto 0) := "010"; -- Maximum valid value for I2C Kill Time: 2 (3 clock cycles)
	signal I2CWaitCountxDN, I2CWaitCountxDP : std_logic_vector(14 downto 0); -- Counter for data to be latched from I2C Controller to IMU Register
    constant i2c_wait_time_short : std_logic_vector(14 downto 0) := "001011101110000"; -- Clock cycles to wait: 6000 clock cycles at 60 MHz: 100000ns    001011101110000
    constant i2c_wait_time_long	 : std_logic_vector(14 downto 0) := "010111011100000"; -- Clock cycles to wait: 12000 clock cycles at 60 MHz: 200000ns   010111011100000
	constant i2c_wait_time_very_short : std_logic_vector(14 downto 0) := "000000000000010"; -- Clock cycles to wait: 2 - 000000000000010
	-- I2C mux outputs
	signal I2CAddrxD : std_logic_vector(2 downto 0); -- I2C Controller Address register
	signal I2CDataWritexD : std_logic_vector(7 downto 0); -- I2C Controller Data Write register driving I2CDataxDIO
	signal I2CDataReadxD : std_logic_vector(7 downto 0); -- I2C Controller Data Read register driving I2CDataxDIO

	-- I2C Handshaking signals to read and write to Controller registers
	signal WriteReqxE : std_logic; -- Send Byte
	signal WriteAckxE : std_logic; -- Byte received
	signal ReadReqxE : std_logic;  -- Read Byte
	signal ReadAckxE : std_logic;  -- Byte read


	-- IMU Signals used for iterating through Configuration Registers
	signal IMUInitByteCountxDN, IMUInitByteCountxDP : std_logic_vector(3 downto 0); -- Counts 10 bytes: 5 addresses, 5 data bytes - REWORK COMMENT
	constant imu_init_byte_length : std_logic_vector(3 downto 0) := "1010"; -- Maximum valid value for IMUInitByteCount: 9
	--constant IMUInitAddr0 : std_logic_vector(7 downto 0) := "01101011"; -- ADDR: (0x6b) IMU power management register and clock selection
	--constant IMUInitData0 : std_logic_vector(7 downto 0) := "00000001"; -- DATA: (0x02) Disable sleep, select x axis gyro as clock source  
	--constant IMUInitAddr1 : std_logic_vector(7 downto 0) := "00011010"; -- ADDR: (0x1A) DLPF
	--constant IMUInitData1 : std_logic_vector(7 downto 0) := "00000001"; -- DATA: (0x01) FS=1kHz, Gyro 188Hz, 1.9ms delay
	--constant IMUInitAddr2 : std_logic_vector(7 downto 0) := "00011001"; -- ADDR: (0x19) Sample rate divider
	--constant IMUInitData2 : std_logic_vector(7 downto 0) := "00000000"; -- DATA: (0x00) 1 Khz sample rate when DLPF is enabled
	--constant IMUInitAddr3 : std_logic_vector(7 downto 0) := "00011011"; -- ADDR: (0x1B) Gyro Configuration: Full Scale Range / Sensitivity
	--constant IMUInitData3 : std_logic_vector(7 downto 0) := "00001000"; -- DATA: (0x08) 500 deg/s, 65.5 LSB per deg/s 
	--constant IMUInitAddr4 : std_logic_vector(7 downto 0) := "00011100"; -- ADDR: (0x1C) Accel Configuration: Full Scale Range / Sensitivity
	--constant IMUInitData4 : std_logic_vector(7 downto 0) := "00001000"; -- DATA: (0x08) 4g, 8192 LSB per g 
	constant IMUInitAddr0 : std_logic_vector(7 downto 0) := "01101011"; -- ADDR: (0x6b) IMU power management register and clock selection
	constant IMUInitAddr1 : std_logic_vector(7 downto 0) := "00011010"; -- ADDR: (0x1A) DLPF
	constant IMUInitAddr2 : std_logic_vector(7 downto 0) := "00011001"; -- ADDR: (0x19) Sample rate divider
	constant IMUInitAddr3 : std_logic_vector(7 downto 0) := "00011011"; -- ADDR: (0x1B) Gyro Configuration: Full Scale Range / Sensitivity
	constant IMUInitAddr4 : std_logic_vector(7 downto 0) := "00011100"; -- ADDR: (0x1C) Accel Configuration: Full Scale Range / Sensitivity
	signal IMUInitData0 : std_logic_vector(7 downto 0); 
	signal IMUInitData1 : std_logic_vector(7 downto 0); 
	signal IMUInitData2 : std_logic_vector(7 downto 0); 
	signal IMUInitData3 : std_logic_vector(7 downto 0); 
	signal IMUInitData4 : std_logic_vector(7 downto 0); 
	
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
	
begin
  
	IMUInitData0 <= IMUInitDataxDI(7 downto 0);
	IMUInitData1 <= IMUInitDataxDI(15 downto 8);
	IMUInitData2 <= IMUInitDataxDI(23 downto 16);
	IMUInitData3 <= IMUInitDataxDI(31 downto 24);
	IMUInitData4 <= IMUInitDataxDI(39 downto 32);
	
	-- Calculate next state and outputs for I2C Read and Write operations
	p_i2c_read_write : process (StateRWxDP, WriteReqxE, ReadReqxE, I2CDataWritexD, I2CAddrxD, I2CDataWritexD, I2CAddrxD, I2CCountxDP)
	begin 
  
		-- Test Signal
		--DebugLEDxEO <= '0';
		
		-- Default assignments 
		-- Registers 
		StateRWxDN <= StateRWxDP; 
		I2CCountxDN <= I2CCountxDP;
		-- Output Signals
		WriteAckxE <= '0'; 
		ReadAckxE <= '0'; 
		I2CDataReadxD <= (others => 'Z');
				
		-- START CASE StateRWxDP
		case StateRWxDP is
			
			when stIdle =>
				I2CDataxDIO <= (others => 'Z'); 
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				I2CCSxSBO <= '1';
				
				I2CCountxDN <= (others => '0');
				
				-- Write and Read I2C Register Request signals
				if WriteReqxE = '1' then
					StateRWxDN <= stWriteRegister1;
				elsif ReadReqxE = '1' then 
					StateRWxDN <= stReadRegister1;
				end if;
				
				--DebugLEDxEO <= '1';
				
				
			-- START I2C Write 
			when stWriteRegister1 => -- Kill Time
				I2CDataxDIO <= (others => 'Z'); 
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				I2CCSxSBO <= '1';

				-- Wait in this state for i2c_kill_time clock cycles
				if I2CCountxDP = i2c_kill_time then
					I2CCountxDN <= (others => '0');
					StateRWxDN <= stWriteRegister2;
				else 
					I2CCountxDN <= I2CCountxDP + 1;
				end if; 

			when stWriteRegister2 => -- Set 
				I2CDataxDIO <= I2CDataWritexD;  
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '0';
				I2CCSxSBO <= '1';

				StateRWxDN <= stWriteRegister3;

			when stWriteRegister3 => -- Run and wait to latch
				I2CDataxDIO <= I2CDataWritexD;  
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '0';
				I2CCSxSBO <= '0';

				-- Wait in this state for i2c_ack_length clock cycles
				if I2CCountxDP = i2c_ack_length then
					I2CCountxDN <= (others => '0');
					StateRWxDN <= stWriteRegister4;
				else 
					I2CCountxDN <= I2CCountxDP + 1;
				end if; 
				
			when stWriteRegister4 => -- Write
				I2CDataxDIO <= I2CDataWritexD;  
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '0';
				I2CCSxSBO <= '1';

				-- Handshaking
				WriteAckxE <= '1';
				if WriteReqxE = '0' then
					StateRWxDN <= stWriteRegister5;
				end if;
			
			when stWriteRegister5 => -- Acknowledge
				I2CDataxDIO <= (others => 'Z'); 
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				I2CCSxSBO <= '1';

				-- Handshaking
				WriteAckxE <= '0';
				
				StateRWxDN <= stIdle;
			-- END I2C Write
			
			-- START I2C Read
			when stReadRegister1 => -- Kill time
				I2CDataxDIO <= (others => 'Z'); 
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				I2CCSxSBO <= '1';

				StateRWxDN <= stReadRegister2;

				if I2CCountxDP = i2c_kill_time then
					I2CCountxDN <= (others => '0');
					StateRWxDN <= stReadRegister2;
				else 
					I2CCountxDN <= I2CCountxDP + 1;
				end if; 
				
			when stReadRegister2 => -- Set 
				I2CDataxDIO <= (others => 'Z'); 
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				I2CCSxSBO <= '1';

				StateRWxDN <= stReadRegister3;

			when stReadRegister3 => -- Run and wait to latch
				I2CDataxDIO <= (others => 'Z');
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				I2CCSxSBO <= '0';

				-- Wait in this state for i2c_ack_length clock cycles
				if I2CCountxDP = i2c_ack_length then
					I2CCountxDN <= (others => '0');
					StateRWxDN <= stReadRegister4;
				else 
					I2CCountxDN <= I2CCountxDP + 1;
				end if; 
			
			when stReadRegister4 => -- Read
				I2CDataReadxD <= I2CDataxDIO;  
				I2CDataxDIO <= (others => 'Z'); -- After reading, set signal back to 'Z' to ensure inout can be written to 
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBO <= '1';
				I2CCSxSBO <= '0';
				
				-- Handshaking
				ReadAckxE <= '1';
				if ReadReqxE = '0' then
					StateRWxDN <= stReadRegister5;
				end if;
				
			when stReadRegister5 => -- Acknowledge
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
			IMURunxEI, WriteAckxE, ReadAckxE, I2CDataReadxD, IMUInitData0, IMUInitData1, IMUInitData2, IMUInitData3, IMUInitData4) 
	begin 
  
		-- Test Signal
		--DebugLEDxEO <= '0';
		
		-- Default assignments
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
		I2CAddrxD <= (others => 'Z');
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
				  StateIMUxDN <= stWrInitWriteAddressRegister;
				end if;
						
			-- START Write Configuration Registers to IMU (stWrX)
			-- Write IMU Device Address
			when stWrInitWriteAddressRegister =>
				-- Set registers and write to them using 4 phase handshaking 
				-- (REQ=1 Write this!; ACK=1 Done!; REQ=0 Thanks!; ACK=0 Anything else, bro?)
				I2CAddrxD <= low_addr;
				I2CDataWritexD <= I2C_IMU_ADDR & I2C_IMU_WRITE; -- IMU Address, Write mode
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrInitWriteByteCountRegister;
				end if;
				
			-- Write number of bytes to be written: 10
			-- 5 Address Bytes and 5 Data Bytes  to initialize 5 IMU registers
			when stWrInitWriteByteCountRegister =>
				I2CAddrxD <= byte_count;
				I2CDataWritexD <= I2C_IMU_WRITE_BYTE_COUNT;  
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrInitWriteAddrDataBufferRegister;
				end if;
							
			-- Write address data byte to select IMU register to be written to
			when stWrInitWriteAddrDataBufferRegister =>
				I2CAddrxD <= data_buf;
				-- Write current address byte
				case IMUInitByteCountxDP is 
					when "0000" => I2CDataWritexD <= IMUInitAddr0; 
					when "0010" => I2CDataWritexD <= IMUInitAddr1; 
					when "0100" => I2CDataWritexD <= IMUInitAddr2; 
					when "0110" => I2CDataWritexD <= IMUInitAddr3; 
					when "1000" => I2CDataWritexD <= IMUInitAddr4;
					when others => I2CDataWritexD <= (others => '1');
				end case;
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';

					IMUInitByteCountxDN <= IMUInitByteCountxDP + 1;
					StateIMUxDN <= stWrInitWriteCommandRegister;
				end if;
			
			-- Issue Go command to start data transactions in polling mode
			when stWrInitWriteCommandRegister =>
				I2CAddrxD <= comm_stat;
				I2CDataWritexD <= I2C_IMU_COMMAND; 
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrInitWaitI2C1;
				end if;
					
			-- Wait for I2C Controller to... (?)
			when stWrInitWaitI2C1 =>
				if I2CWaitCountxDP = i2c_wait_time_long then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stWrInitReadStatusRegister;
				else 
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if; 
			
			-- Read Status register: wait for buffer empty flag to make sure data words	are written
			when stWrInitReadStatusRegister =>
				-- Choose register to read from and get data using 4 phase handshaking 
				-- (REQ=1 Read from this address!; ACK=1 Data ready!; REQ=0 Got it!; ACK=0 Anything else, bro?)
				I2CAddrxD <= comm_stat;
				
				--DebugLEDxEO <= '1';
				
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					
					-- Check Empty Flag 
					if I2CDataReadxD(1) = '1' then 
						StateIMUxDN <= stWrInitWriteDataBufferRegister;
					end if;
					-- If buffer is not empty, then when ReadAck = 0 we will read again from this register

				end if;
				
			-- Write data byte, which initializes the currently selected IMU register
			when stWrInitWriteDataBufferRegister =>
				I2CAddrxD <= data_buf;
				-- Select correct initialization byte to write
				case IMUInitByteCountxDP is 
					when "0001" => I2CDataWritexD <= IMUInitData0; 
					when "0011" => I2CDataWritexD <= IMUInitData1; 
					when "0101" => I2CDataWritexD <= IMUInitData2; 
					when "0111" => I2CDataWritexD <= IMUInitData3; 
					when "1001" => I2CDataWritexD <= IMUInitData4;
					when others => I2CDataWritexD <= (others => '0');
				end case;
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';

					-- Iterate over initialization bytes 
					IMUInitByteCountxDN <= IMUInitByteCountxDP + 1;
					StateIMUxDN <= stWrInitWaitI2C2;
				end if;
				
			-- Wait for I2C Controller to... (?)
			-- Come to this state between interrupt operations
			when stWrInitWaitI2C2 =>
				if I2CWaitCountxDP = i2c_wait_time_long then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stWrInitCheckDone;
				else
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if; 

			-- Read Status register and wait for transaction done bit
			when stWrInitCheckDone => 
				I2CAddrxD <= comm_stat;
				
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					
					-- Transaction Done Flag
					if I2CDataReadxD(3) = '1' then 
						-- COMMMENT
						if IMUInitByteCountxDP = imu_init_byte_length then
							IMUInitByteCountxDN <= (others => '0');
							StateIMUxDN <= stWrIntWriteAddressRegister;
						else
							StateIMUxDN <= stWrInitWriteAddressRegister;
						end if;
					end if;
					
				end if;
			-- END Write Configuration Registers to IMU (stWrX)


			-- START Read Interrupt to check when new data is available (stWrIntX & stRdIntX)
			-- Write IMU Device Address
			when stWrIntWriteAddressRegister =>
				I2CAddrxD <= low_addr;
				I2CDataWritexD <= I2C_IMU_ADDR & I2C_IMU_WRITE;
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrIntWriteAddrByteCountRegister;
				end if;

			-- Write number of bytes to be Read: 1
			-- Write byte corresponding to address of IMU Interrupt Status
			when stWrIntWriteAddrByteCountRegister =>
				I2CAddrxD <= byte_count;
				I2CDataWritexD <= I2C_IMU_INT_READ_BYTE_COUNT;  
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrIntWriteDataBufferRegister;
				end if;

			-- Write address for interrupt status register in IMU that will be 1 when new data is available 
			when stWrIntWriteDataBufferRegister =>
				I2CAddrxD <= data_buf;
				I2CDataWritexD <= I2C_IMU_INT_STATUS;  
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrIntWriteCommandRegister;
				end if;

			-- Issue Go command to start data transactions in polling mode
			when stWrIntWriteCommandRegister =>
				I2CAddrxD <= comm_stat;
				I2CDataWritexD <= I2C_IMU_COMMAND; 
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrIntWaitI2C;
				end if;
					
			-- Wait for I2C Controller to... (?)
			when stWrIntWaitI2C =>
				if I2CWaitCountxDP = i2c_wait_time_long then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stWrIntCheckDone;
				else
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if; 
				
			-- Read Status register and wait for transaction done bit
			when stWrIntCheckDone =>				
				I2CAddrxD <= comm_stat;
				
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					
					-- Transaction Done flag
					if I2CDataReadxD(3) = '1' then 
						StateIMUxDN <= stRdIntWriteAddressRegister;
					end if;
					
				end if;
			
			-- Now that the appropriate data register to read from is set, we start process all over again
			-- Write IMU Device Address
			when stRdIntWriteAddressRegister =>
				I2CAddrxD <= low_addr;
				I2CDataWritexD <= I2C_IMU_ADDR & I2C_IMU_READ;
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdIntWriteByteCountRegister;
				end if;

			-- Write number of bytes to be Read: 1
			-- Read Interrupt Status Register
			when stRdIntWriteByteCountRegister =>
				I2CAddrxD <= byte_count;
				I2CDataWritexD <= I2C_IMU_INT_READ_BYTE_COUNT;  
				
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
					StateIMUxDN <= stRdIntWaitI2C1;
				end if;

			-- Wait for I2C Controller to... (?)
			when stRdIntWaitI2C1 =>
				if I2CWaitCountxDP = i2c_wait_time_short then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stRdIntWaitI2C2;
				else
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if;
				
			-- Wait for I2C Controller to... (?)
			-- Come to this state between interrupt operations
			-- CHECK
			when stRdIntWaitI2C2 =>
				if I2CWaitCountxDP = i2c_wait_time_short then
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
				
				--DebugLEDxEO <= '1';

				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';

					-- New data is available to read
					if I2CDataReadxD(0) = '1' then 
						StateIMUxDN <= stRdIntWaitI2C3;
						
					-- Start over, keep on polling
					-- NOT CLEAN CODE! NAME NOT INTUITIVE 
					-- SHOULD I START ALL OVER OR JUST FROM READ PART?!
					else
						StateIMUxDN <= stRdIntWaitI2C3;
					end if;

				end if;
			
			-- Wait for I2C Controller to... (?)
			when stRdIntWaitI2C3 =>
				if I2CWaitCountxDP = i2c_wait_time_long then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stRdIntCheckDone;
				else 
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if; 
				
			-- Read Status register and wait for transaction done bit
			-- If there is new data available then start reading it, otherwise wait for new data to be available
			when stRdIntCheckDone =>				
				I2CAddrxD <= comm_stat;
				
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					
					-- Transaction Done
					if I2CDataReadxD(3) = '1' then 
						StateIMUxDN <= stWrDataWriteAddressRegister;
					end if;
					
				end if;
			-- END Read Interrupt to check when new data is available (stRdIntX)

			-- START Read Data Registers from IMU (stRdX)
			-- Write IMU Device Address
			when stWrDataWriteAddressRegister =>
				I2CAddrxD <= low_addr;
				I2CDataWritexD <= I2C_IMU_ADDR & I2C_IMU_WRITE;
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrDataWriteAddrByteCountRegister;
				end if;

			-- Write number of bytes to be Read: 1
			-- Only need to write byte corresponding to address of first IMU data register
			when stWrDataWriteAddrByteCountRegister =>
				I2CAddrxD <= byte_count;
				I2CDataWritexD <= I2C_IMU_ADDR_READ_BYTE_COUNT;
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrDataWriteDataBufferRegister;
				end if;

			-- Write address for first data register in IMU that will be read: ACCEL_XOUT_H
			-- As this value becomes read, the IMU will internally increment the register to point to the next data register
			when stWrDataWriteDataBufferRegister =>
				I2CAddrxD <= data_buf;
				I2CDataWritexD <= I2C_IMU_ACCEL_XOUT_H_ADDR;  
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrDataWriteCommandRegister;
				end if;

			-- Issue Go command to start data transactions in polling mode
			when stWrDataWriteCommandRegister =>
				I2CAddrxD <= comm_stat;
				I2CDataWritexD <= I2C_IMU_COMMAND; 
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stWrDataWaitI2C;
				end if;
					
			-- Wait for I2C Controller to... (?)
			when stWrDataWaitI2C =>
				if I2CWaitCountxDP = i2c_wait_time_long then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stWrDataCheckDone;
				else
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if; 
				
			-- Read Status register and wait for transaction done bit
			when stWrDataCheckDone =>				I2CAddrxD <= comm_stat;
				
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					
					-- Transaction Done
					if I2CDataReadxD(3) = '1' then 
						StateIMUxDN <= stRdDataWriteAddressRegister;
					end if;
					
				end if;
			
			-- Now that the appropriate data register to read from is set, we start process all over again
			-- Write IMU Device Address
			when stRdDataWriteAddressRegister =>
				I2CAddrxD <= low_addr;
				I2CDataWritexD <= I2C_IMU_ADDR & I2C_IMU_READ;
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdDataWriteByteCountRegister;
				end if;

			-- Write number of bytes to be Read: 14
			-- 2 Bytes per measurement, 3 Measurements for Accel (3 axis), 1 Measurement for Temp, 3 Measurements for Gyro (3 axis)
			when stRdDataWriteByteCountRegister =>
				I2CAddrxD <= byte_count;
				I2CDataWritexD <= I2C_IMU_DATA_READ_BYTE_COUNT;  
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdDataWriteCommandRegister;
				end if;

			-- Issue Go command to start data transactions in polling mode
			when stRdDataWriteCommandRegister =>
				I2CAddrxD <= comm_stat;
				I2CDataWritexD <= I2C_IMU_COMMAND;
				
				WriteReqxE <= '1';
				if WriteAckxE = '1' then
					WriteReqxE <= '0';
					StateIMUxDN <= stRdDataWaitI2C1;
				end if;
					
			-- Wait for I2C Controller to... (?)
			when stRdDataWaitI2C1 =>
				if I2CWaitCountxDP = i2c_wait_time_short then 
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stRdDataWaitI2C2;
				else
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if;
				
			-- Wait for I2C Controller to... (?)
			-- Come to this state between read operations
			when stRdDataWaitI2C2 =>
				if I2CWaitCountxDP = i2c_wait_time_short then
				--if I2CWaitCountxDP = i2c_wait_time_very_short then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stRdDataReadStatusRegister;
				else
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if;
				
			-- Read Status register and wait for full buffer before reading data word	
			when stRdDataReadStatusRegister =>
				I2CAddrxD <= comm_stat;
				
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					
					-- Receive Buffer Full
					if I2CDataReadxD(0) = '1' then 
						StateIMUxDN <= stRdDataReadDataBufferRegister;
					end if;
					
				end if;

			-- Read data byte, which are sensor measurements from the IMU
			-- Use counter to know measurement we are currently reading
			-- We read 1 byte at a time iterating from MSB of Accel X to LSB of Gyro Z
			when stRdDataReadDataBufferRegister =>
				I2CAddrxD <= data_buf;

				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';

					-- Write data to correct measurement register
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
						StateIMUxDN <= stRdDataWaitI2C3;
					else
						IMUMeasByteCountxDN <= IMUMeasByteCountxDP + 1;
						StateIMUxDN <= stRdDataWaitI2C2;
					end if;
					
				end if;
			
			-- Wait for I2C Controller to... (?)
			when stRdDataWaitI2C3 =>
				if I2CWaitCountxDP = i2c_wait_time_long then
					I2CWaitCountxDN <= (others => '0');
					StateIMUxDN <= stRdDataCheckDone;
				else
					I2CWaitCountxDN <= I2CWaitCountxDP + 1;
				end if; 
				
			-- Read Status register and wait for transaction done bit
			-- Once all 14 bytes have been read, then go back to set the first data measurement register and reread
			when stRdDataCheckDone =>
				I2CAddrxD <= comm_stat;
				
				ReadReqxE <= '1';
				if ReadAckxE = '1' then
					ReadReqxE <= '0';
					
					-- Transaction Done flag
					if I2CDataReadxD(3) = '1' then 
						-- Indicate that Data is ready to be Written to the FIFO 
						-- Handshaking with monitor state machine handled by p_imu_write process 
						IMUDataReadyxE <= '1'; 
						
						--DebugLEDxEO <= '1';
						
						StateIMUxDN <= stWrIntWriteAddressRegister;
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
  
		--DebugLEDxEO <= '0';
		
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
			
			-- Wait for Data to be ready 
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

			-- Once data is ready then send a request signal to monitor state machine telling that data is ready to be written
			when stDataReadyReq =>
				-- VERIFY THIS LOGIC!!!!
				-- Indicate that data is ready and wait for permission from Monitor State Machine to write data
				IMUDataReadyReqxEO <= '1';
				if IMUDataReadyAckxEI = '1' then
					IMUDataReadyReqxEO <= '0';
									
					--DebugLEDxEO <= '1';
					
					-- If we don't drop the data, then get ready to write
					-- VERIFY THIS!
					--if IMUDataDropxEI = '0' then --Alex removed this unused condition.
						StateIMUWritexDN <= stDataWriteReq;
					--end if;
					-- WHAT SHOULD WE DO IF WE DO DROP DATA
					-- IF WE DROP DATA WE SHOULD JUST GO BACK TO IDLE STATE AND WAIT FOR NEW DATA
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
						--when "000" => IMUDataxDO <= IMUAccelZxDP; 
						--when "001" => IMUDataxDO <= IMUAccelZxDP; 
						--when "010" => IMUDataxDO <= IMUAccelZxDP; 
						--when "011" => IMUDataxDO <= IMUAccelZxDP; 
						--when "100" => IMUDataxDO <= IMUAccelZxDP; 
						--when "101" => IMUDataxDO <= IMUAccelZxDP; 
						--when "110" => IMUDataxDO <= IMUAccelZxDP; 
						--when others => IMUDataxDO <= (others => '0');
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
	p_memorizing : process (ClockxCI, ResetxRBI, IMURunxEI)
	begin  
		if ResetxRBI = '0' or IMURunxEI = '0' then -- Asynchronous reset
			StateRWxDP <= stIdle;
			StateIMUxDP <= stIdle;
			StateIMUWritexDP <= stIdle;
			IMUInitByteCountxDP <= (others => '0');
			IMUMeasByteCountxDP <= (others => '0');
			IMUDataWordCountxDP	<= (others => '0');
			I2CWaitCountxDP <= (others => '0');
			I2CCountxDP	<= (others => '0');
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

		elsif ClockxCI'event and ClockxCI = '1' then  -- On rising clock edge   
			StateRWxDP <= StateRWxDN;
			StateIMUxDP <= StateIMUxDN;
			StateIMUWritexDP <= StateIMUWritexDN;
			IMUInitByteCountxDP <= IMUInitByteCountxDN;
			IMUMeasByteCountxDP <= IMUMeasByteCountxDN;
			IMUDataWordCountxDP <= IMUDataWordCountxDN;
			I2CWaitCountxDP <= I2CWaitCountxDN;
			I2CCountxDP <= I2CCountxDN;
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
