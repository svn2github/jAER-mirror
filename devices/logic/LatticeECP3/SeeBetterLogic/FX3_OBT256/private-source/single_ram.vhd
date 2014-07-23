library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

 
-- Only XST supports RAM inference
-- Infers Single Port Block Ram 
 
 entity spblockram is 
 generic (TAM: in integer:= 2048; IL: in integer:=11; WL: in integer:=8);
 port (clk : in std_logic; 
 	we  : in std_logic; 
 	a   : in std_logic_vector(IL-1 downto 0); 
 	di  : in std_logic_vector(WL-1 downto 0); 
 	do  : out std_logic_vector(WL-1 downto 0)); 
 end spblockram; 
 
 architecture syn of spblockram is 
 
 type ram_type is array (TAM-1 downto 0) of std_logic_vector (WL-1 downto 0); 
 signal RAM : ram_type; 
 --signal read_a : std_logic_vector(IL-1 downto 0); 
 
 begin 
 process (clk) 
 begin 
 	if (clk'event and clk = '1') then  
 		if (we = '1') then 
 			RAM(conv_integer(a)) <= di; 
 		end if; 
 		--read_a <= a; 
		do <= RAM(conv_integer(a));
 	end if; 
 end process; 
 
 --do <= (others =>'0') when (RAM(conv_integer(read_a))="UUUUUUUU") else RAM(conv_integer(read_a)) ;
 
 end syn;
 
