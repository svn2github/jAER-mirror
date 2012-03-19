
--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:17:15 10/31/2005
-- Design Name:   usb_aer
-- Module Name:   prueba1.vhd
-- Project Name:  usbaer_mapper
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: usb_aer
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends 
-- that these types always be used for the top-level I/O of a design in order 
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
 library UNISIM;
use UNISIM.vcomponents.all;

ENTITY prueba1_vhd IS
END prueba1_vhd;

ARCHITECTURE behavior OF prueba1_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT usb_aer
	PORT(
		clk : IN std_logic;
		rst_l : IN std_logic;
		aer_in_data : IN std_logic_vector(15 downto 0);
		aer_in_req_l : IN std_logic;
		aer_out_ack_l : IN std_logic;
		micro_vdata : IN std_logic;
		micro_prog : IN std_logic;
		micro_control : IN std_logic;
		micro_rw : IN std_logic;    
		sram_data : INOUT std_logic_vector(31 downto 0);
		micro_data : INOUT std_logic_vector(7 downto 0);      
		led : OUT std_logic_vector(2 downto 0);
		aer_in_ack_l : OUT std_logic;
		aer_out_req_l : OUT std_logic;
		aer_out_data : OUT std_logic_vector(15 downto 0);
		sram_oe_l : OUT std_logic;
		sram_we_l : OUT std_logic_vector(3 downto 0);
		address : OUT std_logic_vector(18 downto 0);
		micro_busy : OUT std_logic;
		enable_out_buffers_l : OUT std_logic;
		enable_in_buffers_l : OUT std_logic
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk :  std_logic := '0';
	SIGNAL rst_l :  std_logic := '0';
	SIGNAL aer_in_req_l :  std_logic := '0';
	SIGNAL aer_out_ack_l :  std_logic := '0';
	SIGNAL micro_vdata :  std_logic := '0';
	SIGNAL micro_prog :  std_logic := '0';
	SIGNAL micro_control :  std_logic := '0';
	SIGNAL micro_rw :  std_logic := '0';
	SIGNAL aer_in_data :  std_logic_vector(15 downto 0) := (others=>'0');

	--BiDirs
	SIGNAL sram_data :  std_logic_vector(31 downto 0);
	SIGNAL micro_data :  std_logic_vector(7 downto 0);

	--Outputs
	SIGNAL led :  std_logic_vector(2 downto 0);
	SIGNAL aer_in_ack_l :  std_logic;
	SIGNAL aer_out_req_l :  std_logic;
	SIGNAL aer_out_data :  std_logic_vector(15 downto 0);
	SIGNAL sram_oe_l :  std_logic;
	SIGNAL sram_we_l :  std_logic_vector(3 downto 0);
	SIGNAL address :  std_logic_vector(18 downto 0);
	SIGNAL micro_busy :  std_logic;
	SIGNAL enable_out_buffers_l :  std_logic;
	SIGNAL enable_in_buffers_l :  std_logic;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: usb_aer PORT MAP(
		clk => clk,
		rst_l => rst_l,
		led => led,
		aer_in_data => aer_in_data,
		aer_in_req_l => aer_in_req_l,
		aer_in_ack_l => aer_in_ack_l,
		aer_out_req_l => aer_out_req_l,
		aer_out_ack_l => aer_out_ack_l,
		aer_out_data => aer_out_data,
		sram_oe_l => sram_oe_l,
		sram_we_l => sram_we_l,
		address => address,
		sram_data => sram_data,
		micro_vdata => micro_vdata,
		micro_prog => micro_prog,
		micro_control => micro_control,
		micro_rw => micro_rw,
		micro_busy => micro_busy,
		micro_data => micro_data,
		enable_out_buffers_l => enable_out_buffers_l,
		enable_in_buffers_l => enable_in_buffers_l
	);

	tb : PROCESS
	BEGIN
			rst_l <= '1';
		-- Wait 100 ns for global reset to finish
		wait for 1000 ns;

	rst_l <= '0';
	wait for 100 ns;
	rst_l <= '1';
		wait; -- will wait forever
	END PROCESS;

	reloj: process
begin
	CLK <= '0';
	wait for 10 ns;
	CLK <= '1';
	wait for 10 ns;
end process;

END;
