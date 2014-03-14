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
-- Description: interface with TN
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity TN_interface is
    port (
        
		--Do you need any extra input like a clock or reste? write it here
 		clkT0: in std_logic;  --clock signal that comes directly from the TN connector      
			
       -- AlmostEmpty: in  std_logic; 
       -- AlmostFull: in  std_logic);
		Transform_TNout: out std_logic_vector(23 downto 0);	
		Transform_fifo: out std_logic_vector(23 downto 0));
		
		

end TN_interface;


architecture Structure of TN_interface is


----write your code here
	begin


end Structure;
