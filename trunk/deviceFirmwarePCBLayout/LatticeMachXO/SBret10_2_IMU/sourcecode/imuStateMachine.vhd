--------------------------------------------------------------------------------
-- Company: ini
-- Engineer: hazael montanaro
--
-- Create Date:    13:58:57 10/24/05
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
		IMUDataxDIO         : inout std_logic_vector(15 downto 0); -- IMU Data to be written to IMU Register
	
		-- Signals interfacing with IMU	
		IMUSDAxSIO : inout std_logic; -- IMU I2C Serial Data Address sends configuration bits and recieves IMU data
		IMUSCLxSO  : out std_logic;   -- IMU I2C Serial Clock

		-- LED Used for debugging	
		--IMULEDxSO : out   std_logic
	);
	
end IMUStateMachine;

architecture Behavioral of IMUStateMachine is
  
	-- States used for I2C Register Write and Read 
	type stateRW is (stIdle, 
			stWriteRegister1, stWriteRegister2, stWriteRegister3, stWriteRegister4, 
			stReadRegister1, stReadRegister2, stReadRegister3, stReadRegister4);
	signal StateRWxDP, StateRWxDN : stateRW;

	-- States used to initialize IMU and collect data
	type stateIMU is (
			-- Idle
			stIdle, 
			-- Write Configuration Bits
			stWrWriteAddressRegister, stWrWriteByteCountRegister, stWrWriteCommandRegister,
			stWrWaitI2CStart, stWrReadStatusRegister, stWrWriteDataBufferRegister, stWrWaitI2CEnd,
			stWrCheckDone, 
			-- Select Initial Data Register
			stRdWriteAddressRegister, stRdWriteAddrByteCountRegister, stRdWriteDataBufferRegister
			stRdWriteCommandRegister, stRdWaitI2CStart, stRdCheckDone, 
			-- Read Data Registers
			stRdWriteAddressRegister1,
			stRdWriteByteCountRegister1, stRdWriteCommandRegister1, stRdWaitI2CStart1, stRdReadStatusRegister,
			stRdReadDataBufferRegister, stRdWaitI2CEnd1, stWrCheckDone);
	signal StateIMUxDP, StateIMUxDN : stateIMU;

	-- Counters used to select appropriate IMU Registers
	signal IMUInitByteCountxDN, IMUInitByteCountxDP : std_logic_vector(3 downto 0); -- Initial Configuration selector
	signal IMUDataByteCountxDN, IMUDataByteCountxDP : std_logic_vector(3 downto 0); -- Sensor Data Output selector
	signal IMUInitBytexD : std_logic_vector(7 downto 0); -- Initial Configuration mux output
	signal IMUDataBytexD : std_logic_vector(7 downto 0); -- Sensor Data Output mux output

	-- Counter used to control how long to stay in Wait state 
	signal CountxDN, CountxDP : std_logic_vector(3 downto 0);
  
	-- Intermediate signals
	signal ResetxRB : std_logic;
	signal ClockxC  : std_logic;
	signal RWL      : std_logic:= '0'; -- intermediate I2CRWxSBI signal for tristate problem

	-- I2C mux outputs
	signal I2CAddrxD std_logic_vector(2 downto 0) := "000"; -- I2C Controller Address register
	signal I2CDataxD std_logic_vector(7 downto 0) := "00000000"; -- I2C Controller Data register

	-- IMU 
	signal IMUDataAxDI    : std_logic(7 downto 0); -- First 8 bits of data output
	signal IMUDataBxDI    : std_logic(7 downto 0); -- Second 8 bits of data output
  
	-- I2C Controller Register addresses
	constant data_buf    : std_logic_vector(2 downto 0) := "000"; -- Data Buffer
	constant low_addr    : std_logic_vector(2 downto 0) := "001"; -- Address of I2C Slave Device
	constant upper_addr  : std_logic_vector(2 downto 0) := "010"; -- Reserved
	constant master_code : std_logic_vector(2 downto 0) := "011"; -- Reserved
	constant comm_stat   : std_logic_vector(2 downto 0) := "100"; -- Command / Status Register
	constant byte_count  : std_logic_vector(2 downto 0) := "101"; -- Number of bytes being transmitted
	constant iack_reg    : std_logic_vector(2 downto 0) := "110"; -- Interrupt acknowledge
	
	-- I2C Controller Register values
	constant I2C_IMU_ADDR : std_logic_vector(6 downto 0) := "1101000"; -- IMU I2C Address
	constant I2C_IMU_ACCEL_XOUT_H_ADDR : std_logic_vector(6 downto 0) := "00111011"; -- First IMU Data Register containing 8 MSB bits from x axis of accelerometer
	constant I2C_IMU_WRITE_BYTE_COUNT : std_logic_vector(7 downto 0) := "00001010"; -- Number of configuration bytes to write to IMU, 5 addresses, 5 data
	constant I2C_IMU_ADDR_READ_BYTE_COUNT : std_logic_vector(7 downto 0) := "00000001"; -- Only write to first IMU Data Register, this register gets incremented internally
	constant I2C_IMU_DATA_READ_BYTE_COUNT : std_logic_vector(7 downto 0) := "00001110"; -- Read 14 bytes of data, 2 bytes per measurement, 3 for Accel, 3 for Gyro, 1 for Temp
	constant I2C_IMU_COMMAND : std_logic_vector(7 downto 0) := "10001000"; -- Continuously poll data at 400 kbits/sec
	constant I2C_IMU_INIT_BYTE_01 : std_logic_vector(7 downto 0) := "01101011"; -- IMU power management register and clock selection
	constant I2C_IMU_INIT_BYTE_02 : std_logic_vector(7 downto 0) := "00000010"; -- Disable sleep, select x axis gyro as clock source 
	constant I2C_IMU_INIT_BYTE_03 : std_logic_vector(7 downto 0) := "00011010"; -- DLPF
	constant I2C_IMU_INIT_BYTE_04 : std_logic_vector(7 downto 0) := "00000001"; -- FS=1kHz, Gyro 188Hz, 1.9ms delay
	constant I2C_IMU_INIT_BYTE_05 : std_logic_vector(7 downto 0) := "00011001"; -- Sample rate divider
	constant I2C_IMU_INIT_BYTE_06 : std_logic_vector(7 downto 0) := "00000000"; -- 1 Khz sample rate when DLPF is enabled
	constant I2C_IMU_INIT_BYTE_07 : std_logic_vector(7 downto 0) := "00011011"; -- Gyro Configuration: Full Scale Range / Sensitivity
	constant I2C_IMU_INIT_BYTE_08 : std_logic_vector(7 downto 0) := "00001000"; -- 500 deg/s, 65.5 LSB per deg/s
	constant I2C_IMU_INIT_BYTE_09 : std_logic_vector(7 downto 0) := "00011100"; -- Accel Configuration: Full Scale Range / Sensitivity
	constant I2C_IMU_INIT_BYTE_10 : std_logic_vector(7 downto 0) := "00001000"; -- 4g, 8192 LSB per g
	constant I2C_WRITE_WAIT_TIME : std_logic_vector(7 downto 0) := "00101000"; -- Clock cycles to wait for ...
	constant I2C_READ_WAIT_TIME : std_logic_vector(7 downto 0) := "01010000"; -- Clock cycles to wait for ...
	

begin
  
	-- Default assignments
	ResetxRB <= ResetxRBI;
	ClockxC <= ClockxCI;  
	
	I2CRWxSBI <= RWL;
	I2CDataxDIO <= I2CDataxD when RWL = '0' else "ZZZZZZZZ";

	--IMULEDxSO <= ...;

	-- Data Word that goes in IMU Register
	-- ADD LOGIC FOR WHEN THIS IS VALID
	IMUoutxDO(7 downto 0)  <= IMUDataAxDI(7 downto 0);
	IMUoutxDO(15 downto 8) <= IMUDataBxDI(7 downto 0);

  
	-- Calculate next state and outputs for I2C Read and Write operations
	p_read_write : process (StateRWxDP, WritexE, ReadxE, DoneReadWritexS)
	begin 
  
		-- Stay in current state
		StateRWxDN <= StateRWxDP; 
		
		case StateRWxDP is
			
			when stIdle =>
				DoneReadWritexS <= '1';
				if WritexE = '1' then
					DoneReadWritexS <= '0';
					StateRWxDN <= stWriteRegister1;
				elsif ReadxE = '1' then 
					DoneReadWritexS <= '0';
					StateRWxDN <= stReadRegister1;
				end if;
				
			-- START I2C Write 
			when stWriteRegister1 =>
				I2CAddrxDO <= I2CAddrxD;
				I2CRWxSBI <= '0';
				I2CDataxDIO <= I2CDataxD;  
				StateRWxDN <= stWriteRegister2;

			when stWriteRegister2 =>
				I2CCSxSBI <= '0';
				StateRWxDN <= stWriteRegister3;
			
			when stWriteRegister3 => 
				if I2CAckxSBI = '0' then
					I2CCSxSBI <= '1';
					StateRWxDN <= stWriteRegister4;
				end if;

			when stWriteRegister4 =>
				I2CRWxSBI <= '1';
				WritexE <= '0';
				StateRWxDN <= stIdle;
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
					StateRWxDN <= stReadRegister4;
				end if;

			when stReadRegister4 =>
				I2CCSxSBI <= '1';
				I2CRWxSBI <= '1';
				ReadxE <= '0';
				StateRWxDN <= stIdle;
			-- END I2C Read

		end case 
		-- END case StateRWxDP
		
	end process p_read_write;

	
	-- Calculate next state and outputs for I2C Controller and IMU transaction
	p_imu : process (StateIMUxDP, IMUByteCountxDP, IMUInitByteCountxDP, IMUDataByteCountxDP, CountxDP, 
			RunIMUxSI, DoneReadWritexS, I2CDataxD) 
	begin 
  
		-- Stay in current state
		StateIMUxDN <= StateIMUxDP;
		IMUInitByteCountxDN	<= IMUInitByteCountxDP;	
		IMUDataByteCountxDN	<= IMUDataByteCountxDP;	
		CountxDN <= CountxDP;
		
		-- Mux used to select which byte to write to configuration register
		with IMUInitByteCountxDP select 
				IMUInitBytexD <= 
					I2C_IMU_INIT_BYTE_01 when "0000",
					I2C_IMU_INIT_BYTE_02 when "0001",
					I2C_IMU_INIT_BYTE_03 when "0010",
					I2C_IMU_INIT_BYTE_04 when "0011",
					I2C_IMU_INIT_BYTE_05 when "0100",
					I2C_IMU_INIT_BYTE_06 when "0101",
					I2C_IMU_INIT_BYTE_07 when "0110",
					I2C_IMU_INIT_BYTE_08 when "0111",
					I2C_IMU_INIT_BYTE_09 when "1000",
					I2C_IMU_INIT_BYTE_10 when "1001";
					

		-- REWRITE!!!
		case IMUDataByteCountxDP is
			when "0000" => -- ACCEL_XOUT_H
				IMUDataBxDI <= I2CDataxD;
			when "0001" => -- ACCEL_XOUT_L
				IMUDataAxDI <= I2CDataxD;
			when "0010" => -- ACCEL_YOUT_H
				IMUDataBxDI <= I2CDataxD;
			when "0011" => -- ACCEL_YOUT_L
				IMUDataAxDI <= I2CDataxD;
			when "0100" => -- ACCEL_ZOUT_H
				IMUDataBxDI <= I2CDataxD;
			when "0101" => -- ACCEL_ZOUT_L
				IMUDataAxDI <= I2CDataxD;
			when "0110" => -- TEMP_OUT_H
				IMUDataBxDI <= I2CDataxD;
			when "0111" => -- TEMP_OUT_L
				IMUDataAxDI <= I2CDataxD;
			when "1000" => -- GYRO_XOUT_H
				IMUDataBxDI <= I2CDataxD;
			when "1001" => -- GYRO_XOUT_L
				IMUDataAxDI <= I2CDataxD;			
			when "1010" => -- GYRO_YOUT_H
				IMUDataBxDI <= I2CDataxD;			
			when "1011" => -- GYRO_YOUT_L
				IMUDataAxDI <= I2CDataxD;			
			when "1100" => -- GYRO_ZOUT_H
				IMUDataBxDI <= I2CDataxD;			
			when "1101" => -- GYRO_ZOUT_L
				IMUDataAxDI <= I2CDataxD;		
		end case;
		
		
		case StateIMUxDP is
			
			when stIdle =>
				IMUInitByteCountxDN <= (others => '0');
				IMUDataByteCountxDN	<= (others => '0');
				CountxDN <= (others => '0');
				-- When we get a run signal start writing IMU configuration bits
				if IMURunxSI = '1' then
				  StateIMUxDN <= stWrWriteAddressRegister;
				end if;
						
			-- START Write Configuration Registers to IMU (stWrX)
			-- Write IMU Device Address
			when stWrWriteAddressRegister =>
				-- If we're not currently reading or writing
				if DoneReadWritexS = 1 then
					-- Set registers and enable writing
					I2CAddrxD <= low_addr;
					I2CDataxD <= I2C_IMU_ADDR;
					WritexE <= '1';
					StateIMUxDN <= stWrWriteByteCountRegister;
				end if;

			-- Write number of bytes to be written: 10
			-- 5 Address Bytes and 5 Data Bytes  to initialize 5 IMU registers
			when stWrWriteByteCountRegister =>
				if DoneReadWritexS = 1 then
					I2CAddrxD <= byte_count;
					I2CDataxD <= I2C_IMU_WRITE_BYTE_COUNT;  
					WritexE <= '1';
					StateIMUxDN <= stWrWriteCommandRegister;
				end if;
				
			-- Issue Go command to start data transactions in polling mode
			when stWrWriteCommandRegister =>
				if DoneReadWritexS = 1 then
					I2CAddrxD <= comm_stat;
					I2CDataxD <= I2C_IMU_COMMAND; 
					WritexE <= '1';
					StateIMUxDN <= stWrWaitI2CStart;
				end if;
					
			-- Wait for I2C Controller to finish writing all the address registers
			when stWrWaitI2CStart =>
				if DoneReadWritexS = 1 then
					CountxDN <= CountxDP + 1;
					if CounterDP = I2C_WRITE_WAIT_TIME then
						CountxDN <= (others => '0');
						StateIMUxDN <= stWrReadStatusRegister;
					end if; 
				end if;				
				
			-- Read Status register and wait for empty flag to write next data word	
			when stWrReadStatusRegister =>
				if DoneReadWritexS = 1 then
					I2CAddrxD <= comm_stat;
					I2CDataxD <= I2CDataxDIO; 
					ReadxE <= '1';
					if I2CDataxD(1) = '1' then 
						StateIMUxDN <= stWrWriteDataBufferRegister;
					end if;
				end if;
				
			-- Write next data byte, which initialize the IMU registers
			-- Use counter as a select signal to iterate over the different data bytes
			-- Data iterates between address byte and word byte 
			when stWrWriteDataBufferRegister =>
				if DoneReadWritexS = 1 then
					I2CAddrxD <= data_buf;
					I2CDataxD <= IMUInitBytexD;  
					WritexE <= '1';
					if IMUInitByteCountxDP = I2C_IMU_WRITE_BYTE_COUNT then
						StateIMUxDN <= stWrWaitI2CEnd;
					else
						IMUInitByteCountxDN <= IMUInitByteCountxDP + 1;
						StateIMUxDN <= stWrReadStatusRegister;
					end if;
				end if;
				
			-- Wait for I2C Controller to finish writing all the configuration registers
			when stWrWaitI2CEnd =>
				if DoneReadWritexS = 1 then
					CountxDN <= CountxDP + 1;
					if CounterDP = I2C_WRITE_WAIT_TIME then
						CountxDN <= (others => '0');
						StateIMUxDN <= stWrCheckDone;
					end if; 
				end if;				

			-- Read Status register and wait for transaction done bit
			when stWrCheckDone => 
				if DoneReadWritexS = 1 then
					I2CAddrxD <= comm_stat;
					I2CDataxD <= I2CDataxDIO; 
					ReadxE <= '1';
					if I2CDataxD(3) = '1' then 
						StateIMUxDN <= stRdWriteAddressRegister;
					end if;
				end if;
			-- END Write Configuration Registers to IMU (stWrX)

			-- START Read Data Registers from IMU (stRdX)
			-- Write IMU Device Address
			when stRdWriteAddressRegister =>
				if DoneReadWritexS = 1 then
					I2CAddrxD <= low_addr;
					I2CDataxD <= I2C_IMU_ADDR;
					WritexE <= '1';
					StateIMUxDN <= stRdWriteAddrByteCountRegister;
				end if;

			-- Write number of bytes to be Read: 1
			-- Only need to write byte corresponding to address of first IMU data register
			when stRdWriteAddrByteCountRegister =>
				if DoneReadWritexS = 1 then
					I2CAddrxD <= byte_count;
					I2CDataxD <= I2C_IMU_ADDR_READ_BYTE_COUNT;  
					WritexE <= '1';
					StateIMUxDN <= stRdWriteDataBufferRegister;
				end if;

			-- Write address for first data register in IMU that will be read: ACCEL_XOUT_H
			-- As this value becomes read, the IMU will internally increment the register to point to the next data register
			when stRdWriteDataBufferRegister =>
				if DoneReadWritexS = 1 then
					I2CAddrxD <= data_buf;
					I2CDataxD <= I2C_IMU_ACCEL_XOUT_H_ADDR;  
					WritexE <= '1';
					StateIMUxDN <= stRdWriteCommandRegister;
				end if;

			-- Issue Go command to start data transactions in polling mode
			when stRdWriteCommandRegister =>
				if DoneReadWritexS = 1 then
					I2CAddrxD <= comm_stat;
					I2CDataxD <= I2C_IMU_COMMAND; 
					WritexE <= '1';
					StateIMUxDN <= stRdWaitI2CStart;
				end if;
					
			-- Wait for I2C Controller to finish writing address registers
			when stRdWaitI2CStart =>
				if DoneReadWritexS = 1 then
					CountxDN <= CountxDP + 1;
					if CounterDP = I2C_READ_WAIT_TIME then
						CountxDN <= (others => '0');
						StateIMUxDN <= stRdCheckDone;
					end if; 
				end if;				
				
			-- Read Status register and wait for transaction done bit
			when stRdCheckDone => 
				if DoneReadWritexS = 1 then
					I2CAddrxD <= comm_stat;
					I2CDataxD <= I2CDataxDIO; 
					ReadxE <= '1';
					if I2CDataxD(3) = '1' then 
						StateIMUxDN <= stRdWriteAddressRegister1;
					end if;
				end if;
			
			-- Now that the appropriate data register to read from is set, we start process all over again
			-- Write IMU Device Address
			when stRdWriteAddressRegister1 =>
				if DoneReadWritexS = 1 then
					I2CAddrxD <= low_addr;
					I2CDataxD <= I2C_IMU_ADDR;
					WritexE <= '1';
					StateIMUxDN <= stRdWriteByteCountRegister1;
				end if;

			-- Write number of bytes to be Read: 14
			-- 2 Bytes per measurement, 3 Measurements for Accel (3 axis), 1 Measurements for Temp, 3 Measurements for Gyro (3 axis)
			when stRdWriteByteCountRegister1 =>
				if DoneReadWritexS = 1 then
					I2CAddrxD <= byte_count;
					I2CDataxD <= I2C_IMU_DATA_READ_BYTE_COUNT;  
					WritexE <= '1';
					StateIMUxDN <= stRdWriteCommandRegister1;
				end if;

			-- Issue Go command to start data transactions in polling mode
			when stRdWriteCommandRegister1 =>
				if DoneReadWritexS = 1 then
					I2CAddrxD <= comm_stat;
					I2CDataxD <= I2C_IMU_COMMAND;
					WritexE <= '1';
					StateIMUxDN <= stRdWaitI2CStart1;
				end if;
					
			-- Wait for I2C Controller to finish writing address registers
			when stRdWaitI2CStart1 =>
				if DoneReadWritexS = 1 then
					CountxDN <= CountxDP + 1;
					if CounterDP = I2C_READ_WAIT_TIME then
						CountxDN <= (others => '0');
						StateIMUxDN <= stRdReadStatusRegister1;
					end if; 
				end if;				
				
			-- Read Status register and wait for full buffer before reading data word	
			when stRdReadStatusRegister =>
				if DoneReadWritexS = 1 then
					I2CAddrxD <= comm_stat;
					I2CDataxD <= I2CDataxDIO; 
					ReadxE <= '1';
					if I2CDataxD(0) = '1' then 
						StateIMUxDN <= stRdReadDataBufferRegister;
					end if;
				end if;
				
			-- Read data byte, which are sensor measurements from the IMU
			-- Use counter to know measurement we are currently reading
			-- We read 1 byte at a time iterating from MSB of Accel X to LSB of Gyro Z
			when stRdReadDataBufferRegister =>
				-- THIS IS WRONG! FIX! FIX ALL READS! 
				if DoneReadWritexS = 1 then
					I2CAddrxD <= data_buf;
					I2CDataxD <= I2CDataxDIO;  
					if IMUDataByteCountxDN(0) = 0
						IMUDataAxDI <= I2CDataxD;
					else
						IMUDataBxDI <= I2CDataxD;
						IMUWordReadyxS <= '1';
					end if;
					ReadxE <= '1';
					if IMUInitByteCountxDP = I2C_IMU_WRITE_BYTE_COUNT then
						StateIMUxDN <= stRdWaitI2CEnd1;
					else
						IMUDataByteCountxDN <= IMUDataByteCountxDP + 1;
						StateIMUxDN <= stRdReadStatusRegister;
					end if;
				end if;
			
			-- Wait for I2C Controller to finish reading all the data registers
			when stRdWaitI2CEnd1 =>
				if DoneReadWritexS = 1 then
					CountxDN <= CountxDP + 1;
					if CounterDP = I2C_WRITE_WAIT_TIME then
						CountxDN <= (others => '0');
						StateIMUxDN <= stWrCheckDone;
					end if; 
				end if;				
				
			-- Read Status register and wait for transaction done bit
			when stRdCheckDone => 
				if DoneReadWritexS = 1 then
					I2CAddrxD <= comm_stat;
					I2CDataxD <= I2CDataxDIO; 
					ReadxE <= '1';
					if I2CDataxD(3) = '1' then 
						StateIMUxDN <= stRdWriteAddressRegister1;
					end if;
				end if;
			-- END Read Data Registers from IMU (stRdX)
			
			when others => 				StateIMUxDN <= stIdle;
		
		end case;

	end process p_imu;

	
	-- Change states and increase counters on rising clock edge
	p_memorizing : process (ClockxCI, ResetxRBI)
	begin  
		if ResetxRB = '0' then -- Asynchronous reset
			StateRWxDP <= stIdle;
			StateIMUxDP <= stIdle;
			IMUInitByteCountxDN <= (others => '0');
			IMUDataByteCountxDN	<= (others => '0');
			CountxDN <= (others => '0');
	
		elsif ClockxC'event and ClockxC = '1' then  -- On rising clock edge   
			StateRWxDP <= StateRWxDN;
			StateIMUxDP <= StateIMUxDN;
			IMUInitByteCountxDP <= IMUInitByteCountxDN;
			IMUDataByteCountxDP <= IMUDataByteCountxDN;
			CountxDP <= CountxDN;
		end if;
	end process p_memorizing;

end Behavioral;
