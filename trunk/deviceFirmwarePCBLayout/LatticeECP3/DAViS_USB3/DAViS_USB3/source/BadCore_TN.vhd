--------------------------------------------------------------------------------
-- Company: 
-- Engineer: Vicente Villanueva
--
-- Create Date:    15:01:00    09/16/2013
-- Design Name:    
-- Module Name:    Transform TN - Behavioral
-- Project Name:   DevUSB3.0
-- Target Device:  Lattice ECP3
-- Tool versions:  
-- Description: LUT with core Addresses
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity BadCore_TN is
    port (
        
 --Do you need any extra input like a clock, timestamp or reset? write it here
       
  		CxCyA: in std_logic_vector(23 downto 0);

		
		Transform_TNout: out std_logic_vector(23 downto 0));	
		

end BadCore_TN;


architecture Structure of BadCore_TN is


----write your code here
begin


end Structure;
