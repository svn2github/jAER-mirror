
-- VHDL Test Bench Created from source file program_ram.vhd -- 00:16:53 06/28/2004
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
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.ALL;

ENTITY program_ram_test_program_ram_vhd_tb IS
END program_ram_test_program_ram_vhd_tb;

ARCHITECTURE behavior OF program_ram_test_program_ram_vhd_tb IS 

	COMPONENT program_ram
	PORT(
		RST_N : IN std_logic;
		CLK : IN std_logic;
		ENABLE_N : IN std_logic;
		DATA_VALID : IN std_logic;
		DATA : IN std_logic_vector(7 downto 0);    
		RAM_DATA : INOUT std_logic_vector(31 downto 0);      
		BUSY : OUT std_logic;
		RAM_ADDRESS : OUT std_logic_vector(18 downto 0);
		RAM_OE : OUT std_logic;
		RAM_WE : OUT std_logic_vector(3 downto 0);
		LED : OUT std_logic_vector(2 downto 0)
		);
	END COMPONENT;

	SIGNAL RST_N :  std_logic;
	SIGNAL CLK :  std_logic;
	SIGNAL ENABLE_N :  std_logic;
	SIGNAL DATA_VALID :  std_logic;
	SIGNAL DATA :  std_logic_vector(7 downto 0);
	SIGNAL BUSY :  std_logic;
	SIGNAL RAM_ADDRESS :  std_logic_vector(18 downto 0);
	SIGNAL RAM_DATA :  std_logic_vector(31 downto 0);
	SIGNAL RAM_OE :  std_logic;
	SIGNAL RAM_WE :  std_logic_vector(3 downto 0);
	SIGNAL LED :  std_logic_vector(2 downto 0);
	signal pepe: std_logic_vector(31 downto 0);

BEGIN

	uut: program_ram PORT MAP(
		RST_N => RST_N,
		CLK => CLK,
		ENABLE_N => ENABLE_N,
		DATA_VALID => DATA_VALID,
		DATA => DATA,
		BUSY => BUSY,
		RAM_ADDRESS => RAM_ADDRESS,
		RAM_DATA => RAM_DATA,
		RAM_OE => RAM_OE,
		RAM_WE => RAM_WE,
		LED => LED
	);


RELOJ: process
begin
	CLK <= '0';
	wait for 10 ns;
	CLK <= '1';
	wait for 10 ns;
end process;

ESCRIBE: process
variable i: integer range 0 to 255;
begin	 
	RST_N <= '0';
	ENABLE_N <= '1';
	wait for 100 ns;
	RST_N <= '1';
	wait for 100 ns;
	ENABLE_N <= '0';

for i in 0 to 255 loop
	DATA <= x"55";
	DATA_VALID <= '1';
	wait until rising_edge(CLK);
	--wait until BUSY ='0';
	DATA_VALID <= '0';
	wait until rising_edge(CLK);
end loop;
end process;


END;
