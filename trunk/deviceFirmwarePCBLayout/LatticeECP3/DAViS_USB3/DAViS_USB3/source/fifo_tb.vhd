
-- VHDL Test Bench Created from source file fifo.vhd -- Tue Nov 13 14:18:50 2012

--
-- Notes: 
-- 1) This testbench template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the unit under test.
-- Lattice recommends that these types always be used for the top-level
-- I/O of a design in order to guarantee that the testbench will bind
-- correctly to the timing (post-route) simulation model.
-- 2) To use this template as your testbench, change the filename to any
-- name of your choice with the extension .vhd, and use the "source->import"
-- menu in the ispLEVER Project Navigator to import the testbench.
-- Then edit the user defined section below, adding code to generate the 
-- stimulus for your design.
-- 3) VHDL simulations will produce errors if there are Lattice FPGA library 
-- elements in your design that require the instantiation of GSR, PUR, and
-- TSALL and they are not present in the testbench. For more information see
-- the How To section of online help.  
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY testbench IS
END testbench;

ARCHITECTURE behavior OF testbench IS 

	COMPONENT fifo
		Generic(
			ADDR_W	: integer	:= 4;	-- address width in bits
			DATA_W 	: integer	:= 24; -- data width in bits
			BUFF_L		: integer 	:=16;	-- buffer length must be less than address space as in  BUFF_L <= 2^(ADDR_W)
			ALMST_F	: integer 	:= 4;	-- fifo regs away from full fifo
			ALMST_E	: integer	:= 4		-- fifo regs away from empty fifo
			);
	Port ( 
			clk 							: in std_logic;
			n_reset 				: in std_logic;
			rd_en 					: in std_logic; 	-- read enable 
			wr_en					: in std_logic; 	-- write enable 
			data_in 				: in std_logic_vector(DATA_W- 1 downto 0); 
			data_out				: out std_logic_vector(DATA_W- 1 downto 0); 
			data_count			: out std_logic_vector(ADDR_W downto 0);
			empty 					: out std_logic; 
			full							: out std_logic;
			almst_empty 	: out std_logic; 
			almst_full 			: out std_logic; 
			err							: out std_logic
			);
	END COMPONENT;

	SIGNAL clk 							:  std_logic;
	SIGNAL n_reset 				:  std_logic;
	SIGNAL rd_en 					:  std_logic;
	SIGNAL wr_en 					:  std_logic;
	SIGNAL data_in 				:  std_logic_vector(23 downto 0);
	SIGNAL data_out 			:  std_logic_vector(23 downto 0);
	SIGNAL data_count			:  std_logic_vector(4 downto 0);
	SIGNAL empty 					:  std_logic;
	SIGNAL err 							:  std_logic;
	SIGNAL full 						:  std_logic;
	SIGNAL almst_empty 	:  std_logic;
	SIGNAL almst_full 			:  std_logic;	
		constant PERIOD : time := 20 ns;

	

BEGIN

-- Please check and add your generic clause manually
	uut: fifo PORT MAP(
		clk => clk,
		n_reset => n_reset,
		rd_en => rd_en,
		wr_en => wr_en,
		data_in => data_in,
		data_out => data_out,
		data_count => data_count,
		empty => empty,
		almst_empty => almst_empty,
		almst_full => almst_full,
		err => err,
		full => full
	);


	-- PROCESS TO CONTROL THE CLOCK
	clock : PROCESS
	BEGIN
	
		clk <= '1';
		WAIT FOR PERIOD/2;
		clk <= '0';
		WAIT FOR PERIOD/2;

	END PROCESS;



-- *** Test Bench - User Defined Section ***
   tb : PROCESS
   BEGIN

		n_reset <= '0';
		rd_en <= '0';
		
		WAIT FOR 40 NS;
		
		n_reset <= '1';
   		wr_en <= '0';
		
		-- write to fifo
		for test_vec in 0 to 17 loop
			WAIT FOR 20 NS;
			wr_en <= '1';
			data_in <= std_logic_vector(to_unsigned(test_vec,24));
			WAIT FOR 20 NS;
			wr_en <= '0';		
		end loop;	
	
		-- read from fifo	
		for test_vec in 0 to 17 loop
			WAIT FOR 20 NS;
			rd_en <= '1';
			WAIT FOR 20 NS;
			rd_en <= '0';		
		end loop;	

		-- write to fifo		
		for test_vec in 0 to 15 loop
			WAIT FOR 20 NS;
			wr_en <= '1';
			data_in <= std_logic_vector(to_unsigned(test_vec,24));
			WAIT FOR 20 NS;
			wr_en <= '0';		
		end loop;		
	
		-- read from fifo	
		for test_vec in 0 to 11 loop
			WAIT FOR 20 NS;
			rd_en <= '1';
			WAIT FOR 20 NS;
			rd_en <= '0';		
		end loop;	
		
		WAIT FOR 80 NS;

		
		-- read and write to fifo		
		for test_vec in 0 to 11 loop
			WAIT FOR 20 NS;
			wr_en <= '1';
			rd_en <= '1';
			data_in <= std_logic_vector(to_unsigned(test_vec,24));
			WAIT FOR 20 NS;
			wr_en <= '0';
			rd_en <= '0';			
		end loop;			
		
		-- read from fifo
		for test_vec in 0 to 7 loop
			WAIT FOR 20 NS;
			rd_en <= '1';
			WAIT FOR 20 NS;
			rd_en <= '0';		
		end loop;		
	
		-- write to fifo	
		for test_vec in 0 to 13 loop
			WAIT FOR 20 NS;
			wr_en <= '1';
			data_in <= std_logic_vector(to_unsigned(test_vec,24));
			WAIT FOR 20 NS;
			wr_en <= '0';		
		end loop;			
		
		
	

      wait; -- will wait forever
   END PROCESS;
-- *** End Test Bench - User Defined Section ***

END;
