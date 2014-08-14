--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_MISC.ALL;


package AERDataPackage is

  type AERDir is array ( NATURAL range <>) of std_logic_vector(16 downto 0);
  type AERFiring is array (NATURAL range <>) of std_logic_vector(7 downto 0); 
  type AERData is array (NATURAL range <>) of std_logic_vector(31 downto 0); 
  function BITSUM(ARG: STD_LOGIC_VECTOR; SIZE: integer) return integer;


end AERDataPackage;


package body AERDataPackage is

function BITSUM(ARG:STD_LOGIC_VECTOR; SIZE: INTEGER) return INTEGER is

 
  
  


	variable result1: integer range 0 to 7;
	variable result2: integer range 0 to 7;
	variable result3: integer range 0 to 7;
	variable result4: integer range 0 to 7;
	variable result5: integer range 0 to 7;
	variable result6: integer range 0 to 7;
	variable result7: integer range 0 to 7;
	variable result8: integer range 0 to 7;
	
    begin
			
			
			
			result1:=0;
			result2:=0;
			result3:=0;
			result4:=0;
			result5:=0;
			result6:=0;
			result7:=0;
			result8:=0;
			for i in 0 to 7 loop
				--if ARG(i)='1' then
					result1:=result1+conv_integer(ARG(i)); 
			  		result2:=result2+conv_integer(ARG(8+i)); 
					result3:=result3+conv_integer(ARG(16+i)); 
					result4:=result4+conv_integer(ARG(24+i)); 
					result5:=result5+conv_integer(ARG(32+i)); 
					result6:=result6+conv_integer(ARG(40+i)); 
					result7:=result7+conv_integer(ARG(48+i)); 
					result8:=result8+conv_integer(ARG(56+i)); 
					--end if;
			end loop;
			RETURN result1+result2+result3+result4+result5+result6+result7+result8;
	 end;


 
end AERDataPackage;
