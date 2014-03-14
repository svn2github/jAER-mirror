--------------------------------------------------------------------------------
-- Company: 
-- Engineer: Vicente Villanueva
--
-- Create Date:    12:01:00    09/16/2013
-- Design Name:    
-- Module Name:    Transform TN - Behavioral
-- Project Name:   DevUSB3.0
-- Target Device:  Lattice ECP3
-- Tool versions:  
-- Description: AER FiFO data Transformation to TN AER
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity Transform_TN is
    port (
        Data_fifo: in  std_logic_vector(16 downto 0); 
 --Do you need any extra input like a clock or reset? write it here
       
		Empty: in  std_logic; 
        Full: in  std_logic; 
	
       -- AlmostEmpty: in  std_logic; 
       -- AlmostFull: in  std_logic);
		CxCyA: out std_logic_vector(23 downto 0);
---SPI ports---
    
	sclk         : OUT     STD_LOGIC;  --spi clk from master
    reset_n      : OUT     STD_LOGIC;  --active low reset
    ss_n         : OUT     STD_LOGIC;  --active low slave select
    mosi         : OUT     STD_LOGIC;  --master out, slave in
    rx_req       : OUT     STD_LOGIC;  --'1' while busy = '0' moves data to the rx_data output
    st_load_en   : OUT     STD_LOGIC;  --asynchronous load enable
    st_load_trdy : OUT     STD_LOGIC;  --asynchronous trdy load input
    st_load_rrdy : OUT     STD_LOGIC;  --asynchronous rrdy load input
    st_load_roe  : OUT     STD_LOGIC;  --asynchronous roe load input
    tx_load_en   : OUT     STD_LOGIC;  --asynchronous transmit buffer load enable
    tx_load_data : OUT     STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --asynchronous tx data to load
    trdy         : BUFFER STD_LOGIC := '0';  --transmit ready bit
    rrdy         : BUFFER STD_LOGIC := '0';  --receive ready bit
    roe          : BUFFER STD_LOGIC := '0';  --receive overrun error bit
    rx_data      : IN    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');  --receive register output to logic
    busy         : IN    STD_LOGIC := '0';  --busy signal to logic ('1' during transaction)
    miso         : IN    STD_LOGIC := 'Z'); --master in, slave out
	
end Transform_TN;

architecture Structure of Transfrom_TN is
	
		


	SIGNAL mode    : STD_LOGIC;  --groups modes by clock polarity relation to data
	SIGNAL clk     : STD_LOGIC;  --clock
	SIGNAL bit_cnt : STD_LOGIC_VECTOR(d_width+8 DOWNTO 0);  --'1' for active transaction bit
	SIGNAL wr_add  : STD_LOGIC;  --address of register to write ('0' = receive, '1' = status)
	SIGNAL rd_add  : STD_LOGIC;  --address of register to read ('0' = transmit, '1' = status)
	SIGNAL rx_buf  : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');  --receiver buffer
	SIGNAL tx_buf  : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');  --transmit buffer

----write your code here
begin



end Structure;
