
-- VHDL Test Bench Created from source file mapper_function.vhd -- 10:05:35 06/28/2004
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

ENTITY mapper_function_test_mapper_function_vhd_tb IS
END mapper_function_test_mapper_function_vhd_tb;

ARCHITECTURE behavior OF mapper_function_test_mapper_function_vhd_tb IS 

	COMPONENT mapper_function
	PORT(
		CLK : IN std_logic;
		RST_N : IN std_logic;
		ENABLE_N : IN std_logic;
		AER_IN_DATA : IN std_logic_vector(15 downto 0);
		AER_IN_REQ_L : IN std_logic;
		AER_OUT_ACK_L : IN std_logic;
		RAM_DATA : INOUT std_logic_vector(31 downto 0);          
		AER_IN_ACK_L : OUT std_logic;
		AER_OUT_DATA : OUT std_logic_vector(15 downto 0);
		AER_OUT_REQ_L : OUT std_logic;
		RAM_ADDRESS : OUT std_logic_vector(18 downto 0);
		RAM_OE : OUT std_logic;
		RAM_WE : OUT std_logic_vector(3 downto 0);
		LED : OUT std_logic_vector(2 downto 0)
		);
	END COMPONENT;

	SIGNAL CLK :  std_logic;
	SIGNAL RST_N :  std_logic;
	SIGNAL ENABLE_N :  std_logic;
	SIGNAL AER_IN_DATA :  std_logic_vector(15 downto 0);
	SIGNAL AER_IN_REQ_L :  std_logic;
	SIGNAL AER_IN_ACK_L :  std_logic;
	SIGNAL AER_OUT_DATA :  std_logic_vector(15 downto 0);
	SIGNAL AER_OUT_REQ_L :  std_logic;
	SIGNAL AER_OUT_ACK_L :  std_logic;
	SIGNAL RAM_ADDRESS :  std_logic_vector(18 downto 0);
	SIGNAL RAM_DATA :  std_logic_vector(31 downto 0);
	SIGNAL RAM_OE :  std_logic;
	SIGNAL RAM_WE :  std_logic_vector(3 downto 0);
	SIGNAL LED :  std_logic_vector(2 downto 0);

BEGIN

	uut: mapper_function PORT MAP(
		CLK => CLK,
		RST_N => RST_N,
		ENABLE_N => ENABLE_N,
		AER_IN_DATA => AER_IN_DATA,
		AER_IN_REQ_L => AER_IN_REQ_L,
		AER_IN_ACK_L => AER_IN_ACK_L,
		AER_OUT_DATA => AER_OUT_DATA,
		AER_OUT_REQ_L => AER_OUT_REQ_L,
		AER_OUT_ACK_L => AER_OUT_ACK_L,
		RAM_ADDRESS => RAM_ADDRESS,
		RAM_DATA => RAM_DATA,
		RAM_OE => RAM_OE,
		RAM_WE => RAM_WE,
		LED => LED
	);

reloj: process
begin
CLK <= '1';
wait for 10 ns;
CLK <= '0';
wait for 10 ns;
end process;

aer_out_ack_l <= aer_out_req_l after 7 ns;


pr: process
begin
RAM_DATA <= x"12345678";
RST_N <= '0';
ENABLE_N <= '1';
AER_IN_DATA <= x"ABCD";
AER_IN_REQ_L <= '1';
wait for 100 ns;
RST_N <= '1';
wait for 100 ns;
ENABLE_N <= '0';
for i in 0 to 255 loop
	AER_IN_REQ_L <= '0';
	wait until AER_IN_ACK_L = '0';
	AER_IN_REQ_L <= '1';
	wait until AER_IN_ACK_L = '1';
end loop;
end process;



END;
