----------------------------------------------------------------------------------
-- Company: University of Seville. RTC lab. http://www.atc.us.es
-- Engineer: Paco Gomez
-- 
-- Create Date:    09:35:24 06/25/2009 
-- Design Name: 
-- Module Name:    AERArbriter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_MISC.ALL;

library work;
use work.AERDataPackage.ALL;
---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity AERArbriter is
	 generic (N : integer := 8);
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
			  Reqi : in  STD_LOGIC_VECTOR (N-1 downto 0);
           Acki : out  STD_LOGIC_VECTOR (N-1 downto 0);
			  datai : in AERdata (N-1 downto 0);
			  diri: in AERDir (N-1 downto 0);
			  Reqo : out  STD_LOGIC;
           Acko : in  STD_LOGIC;
			  datao : out std_logic_vector  (31 downto 0);
			  diro : out std_logic_vector(16 downto 0));
end AERArbriter;

architecture Behavioral of AERArbriter is

type states is (idle,  connection,waitack);
signal CState, NState: states;
--signal ackiaux: std_logic_vector (7 downto 0);
--signal reqoaux: std_logic; 

signal dataoaux: std_logic_vector (31 downto 0);-- := (others => '0');
signal diroaux: std_logic_vector (16 downto 0);-- :=(others => '0');

signal ireq: integer:=9;

--signal winner: std_logic_vector(2 downto 0);

begin

datao <= dataoaux;

diro <= diroaux;
--reqo<=reqoaux;
--acki<=ackiaux;

SYNC: process (clk, rst)
begin
	if rst = '1' then
		CState <= idle;
		dataoaux <= (others => '1');
		diroaux <= (others => '1');
			reqo <= '1';
			acki <= (others =>'1');
	elsif rising_edge(clk) then
		CState <= Nstate;

	if CState = idle then
		dataoaux<= (others => '1');
		diroaux <= (others => '1');
			reqo <= '1';
			acki <= (others =>'1');
	
	elsif CState = connection then
		if Reqi(0)='0'  then
				dataoaux <= datai(0);
				diroaux <= diri(0);
				reqo <= '0'; 
				acki(0)<='1';
				ireq <= 0;
				
		elsif Reqi(1)='0' then
				dataoaux <= datai(1);
				diroaux <= diri(1);
				reqo <= '0'; 
				acki(1)<='1';
				ireq <= 1;
			elsif Reqi(2)='0' then
				dataoaux <= datai(2);
				diroaux <= diri(2);
				reqo <= '0'; 
				acki(2)<='1';
				ireq <= 2;
			elsif Reqi(3)='0' then
				dataoaux <= datai(3);
				diroaux <= diri(3);
				reqo <= '0'; 
				acki(3)<='1';
				ireq <= 3;
			elsif Reqi(4)='0'  then
				dataoaux <= datai(4);
				diroaux <= diri(4);
				reqo <= '0'; 
				acki(4)<='1';
				ireq <= 4;
			elsif Reqi(5)='0' then
				dataoaux <= datai(5);
				diroaux <= diri(5);
				reqo <= '0'; 
				acki(5)<='1';
				ireq <= 5;
			elsif Reqi(6)='0' then
				dataoaux <= datai(6);
				diroaux <= diri(6);
				reqo <= '0'; 
				acki(6)<='1';
				ireq <= 6;
			elsif Reqi(7)='0' then
				dataoaux <= datai(7);
				diroaux <= diri(7);
				reqo <= '0'; 
				acki(7)<='1';
				ireq <= 7;
			else
				dataoaux <= dataoaux;
				diroaux <= diroaux;
				reqo <= '1'; 
				acki<= (others => '1');
				ireq <= 9;	
			end if;
	elsif CState = waitack then
	
		dataoaux<=dataoaux;
		diroaux <=diroaux;
			--datao <= datai(conv_integer(winner));
			reqo <= '1';-- 
			acki(ireq) <='0';-- 				
	
	end if;
	end if;	

	
	
	
	
end process;

COMB: process (CState,acko,reqi, ireq)--,datai)

--variable i: integer range 0 to N-1;

begin

	case Cstate is
		when idle =>
			if and_reduce(reqi)='0' then
				NState <= connection;
			else
				NState <= idle;
			end if;
				
			
		when connection =>
		
			if acko='0' then
			   NState <= waitack;
			else
				Nstate <= connection;
			end if;
									
		when waitack =>
			if  acko='1' and reqi(ireq) = '1' then
				NState <= idle;
			else
				NState <= waitack;
			end if;
					
	end case;
end process;




end Behavioral;

