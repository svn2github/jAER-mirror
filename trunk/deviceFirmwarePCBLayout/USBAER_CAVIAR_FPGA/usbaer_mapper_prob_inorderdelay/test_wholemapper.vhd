
-- VHDL Test Bench Created from source file usb_aer.vhd -- 11:49:29 06/28/2004
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends 
-- that these types always be used for the top-level I/O of a design in order 
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY usb_aer_test_wholemapper_vhd_tb IS
END usb_aer_test_wholemapper_vhd_tb;

ARCHITECTURE behavior OF usb_aer_test_wholemapper_vhd_tb IS 

	COMPONENT usb_aer
	PORT(
		clk : IN std_logic;
		rst_l : IN std_logic;
		aer_in_data : IN std_logic_vector(15 downto 0);
		aer_in_req_l : IN std_logic;
		aer_out_ack_l : IN std_logic;
		micro_vdata : IN std_logic;
		micro_prog : IN std_logic;
		micro_data : IN std_logic_vector(7 downto 0);    
		sram_data : INOUT std_logic_vector(31 downto 0);      
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

	SIGNAL clk :  std_logic;
	SIGNAL rst_l :  std_logic;
	SIGNAL led :  std_logic_vector(2 downto 0);
	SIGNAL aer_in_data :  std_logic_vector(15 downto 0);
	SIGNAL aer_in_req_l :  std_logic;
	SIGNAL aer_in_ack_l :  std_logic;
	SIGNAL aer_out_req_l :  std_logic;
	SIGNAL aer_out_ack_l :  std_logic;
	SIGNAL aer_out_data :  std_logic_vector(15 downto 0);
	SIGNAL sram_oe_l :  std_logic;
	SIGNAL sram_we_l :  std_logic_vector(3 downto 0);
	SIGNAL address :  std_logic_vector(18 downto 0);
	SIGNAL sram_data :  std_logic_vector(31 downto 0);
	SIGNAL micro_vdata :  std_logic;
	SIGNAL micro_prog :  std_logic;
	SIGNAL micro_control :  std_logic;
	SIGNAL micro_busy :  std_logic;
	SIGNAL micro_data :  std_logic_vector(7 downto 0);
	SIGNAL enable_out_buffers_l :  std_logic;
	SIGNAL enable_in_buffers_l :  std_logic;

BEGIN

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
		micro_busy => micro_busy,
		micro_data => micro_data,
		enable_out_buffers_l => enable_out_buffers_l,
		enable_in_buffers_l => enable_in_buffers_l
	);

reloj: process
begin
	CLK <= '0';
	wait for 10 ns;
	CLK <= '1';
	wait for 10 ns;
end process;

--AER_OUT_ACK_L <= AER_OUT_REQ_L after 10 ns;

--testea: process
--begin
--	rst_l <= '0';
--	wait for 100 ns;
--	rst_l <= '1';
--	AER_IN_REQ_L <= '1';
--	micro_prog <= '1';
--	micro_data <= x"55";
--	aer_in_data <= x"ABCD";
--	for i in 0 to 15 loop
--		if (micro_busy = '1') then
--			wait until micro_busy = '0';
--		else
--		micro_vdata <= '1';
--		wait until rising_edge(CLK);
--		micro_vdata<= '0';
--		wait until rising_edge(CLK);
--		end if;
--	end loop;
--	micro_prog <= '0';
--	for i in 0 to 15 loop
--		aer_in_req_l <= '0';
--		wait until aer_in_ack_l = '0';
--		aer_in_req_l <= '1';
--		wait until aer_in_ack_l = '1';
--	end loop;
--	wait;
--end process;
--	sram_data <= x"55555555" when sram_oe_l = '0' else (others =>'Z');
END;
