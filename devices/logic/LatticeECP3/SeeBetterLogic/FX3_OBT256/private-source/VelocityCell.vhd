----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:41:35 05/31/2009 
-- Design Name: 
-- Module Name:    VelocityCell - Behavioral 
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
use IEEE.STD_LOGIC_UNSIGNED."+";
use IEEE.STD_LOGIC_UNSIGNED."-";
use IEEE.STD_LOGIC_UNSIGNED."=";
use IEEE.STD_LOGIC_UNSIGNED.conv_integer;
use IEEE.NUMERIC_STD.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity VelocityCell is
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
           CenterMassIn : in  STD_LOGIC_VECTOR (15 downto 0);
           NewDataReq : in  STD_LOGIC;
			  Velocity : out  STD_LOGIC_VECTOR (31 downto 0);
           NewValueReq : out  STD_LOGIC;
			  NewValueAck : in STD_LOGIC;
           CenterMassOut : out  STD_LOGIC_VECTOR (15 downto 0);
			  ITindex : in std_logic_vector (3 downto 0);
			  VCellID: in std_logic_vector(7 downto 0));
end VelocityCell;

architecture Behavioral of VelocityCell is

type CMHT is array (0 to 7) of STD_LOGIC_VECTOR (10 downto 0);
signal CenterMassHistoryX,CenterMassHistoryY : CMHT;

type VelCompStates is (idlevc, Readm, Storem, Summ, Meanm, Velcomp, SendNewValue);
signal VelCompCS, VelCompNS: VelCompStates;

signal n : integer range 0 to 7;
signal i : std_logic_vector (0 downto 0);
signal instanm : STD_LOGIC_VECTOR (15 downto 0);
signal oldmx, newmx,oldmy, newmy :STD_LOGIC_VECTOR (7 downto 0);
signal sum8mx, sum8my : STD_LOGIC_VECTOR (10 downto 0);--integer;--
signal vx, vy: IEEE.STD_LOGIC_ARITH.signed (7 downto 0); 
signal IntegrationTime : std_logic_vector(31 downto 0);
--signal ITind : std_logic_vector(3 downto 0);
signal ITind : integer range 2 to 13;


signal Timer : STD_LOGIC_VECTOR (31 downto 0);

type IntTime is array (0 to 13) of STD_LOGIC_VECTOR (31 downto 0);  -- tipo de datos para la conversion a 7-segmentos
signal CountITValue: IntTime := (x"0BEBC200",-- 2 seg
											  x"05F5E100",-- 1 seg
											  x"02FAF080",-- 500 ms
											  x"00989680",-- 100 ms
											  x"004C4B40",-- 50 ms
											  x"000F4240",-- 10 ms
											  x"0007A120",-- 5 ms
											  x"000186A0",-- 1 ms
											  x"0000C350",-- 500 us
											  x"00002710",-- 100 us
											  x"00001388",--50 us
											  x"000003E8",-- 10 us
											  x"000001F4",-- 5 us
											  x"00000064");-- 1 us
begin

--- Implentation of Velocity Computation State Machine

SYNC_VEL: process(RST, CLK)
begin
	if(RST = '1') then
		VelCompCS <= idlevc;
	elsif rising_edge(clk) then
		VelCompCS <= VelCompNS;
		
	end if;
end process;

NEVP: process (clk,RST)
begin
	if RST='1' then
		n<= 0;
		i<= (others => '0');
	elsif rising_edge(clk) then
		if VelCompCS = Readm then
			n <= n+1;
			i <= i+1;
		else
			n<=n;
			i<=i;
		end if;
	end if;
	
end process;


--ITp: process(clk, rst, VelCompCS)
--begin 
--	if rst='1' then
--		ITind <= x"3";--conv_integer(ITindex);
--	elsif rising_edge (clk) then
--		if VelCompCS=SendNewValue then
--			if ITind < x"D" and (abs(vx) > 20 or abs(vy) > 20) then
--				ITind <= ITind +1;
--			
--			elsif ITind > x"0" and (abs(vx) < 2 and abs(vy) < 2) then
--				ITind <= ITind-1;
--			else
--			  ITind <= ITind;
--			end if;
--		else
--			ITind <= ITind;
--		end if;
--	end if;
--end process;
CountITValue <= (x"0BEBC200",-- 2 seg
											  x"05F5E100",-- 1 seg
											  x"02FAF080",-- 500 ms
											  x"00989680",-- 100 ms
											  x"004C4B40",-- 50 ms
											  x"000F4240",-- 10 ms
											  x"0007A120",-- 5 ms
											  x"000186A0",-- 1 ms
											  x"0000C350",-- 500 us
											  x"00002710",-- 100 us
											  x"00001388",--50 us
											  x"000003E8",-- 10 us
											  x"000001F4",-- 5 us
											  x"00000064");

TimerP: process(RST,CLK, CountITValue)
begin
	if RST='1' then
	
		timer <= CountITValue(3);-- 100 ms
		ITind <= 3;
	elsif rising_edge(clk) then
		if timer = 0 THEN
			timer <= CountITValue((ITind));
			if ITind < 12 and (abs(vx) + abs(vy) > 20) then
				ITind <= ITind +1;
			
			elsif ITind > 3 and (abs(vx) + abs(vy) < 3) then
				ITind <= ITind-1;
			--else
			--  ITind <= ITind;
			end if;
		else
			timer <= timer -1 ;
			--ITind <= ITind;
		end if;
	end if;
end process;
		
	


COMB_VEL: process(Timer,NewValueAck,VelCompCS)
begin
	case VelCompCS is
		when idlevc =>
			if timer = 0 and NewValueAck = '1'then
			--if timer = 0 then
				VelCompNS <= Readm;
			else 
				VelCompNS <= idlevc;
			end if;
			
			NewValueReq <= '1';			

		when Readm =>
			VelCompNS <= Storem;
			
			NewValueReq <= '1';
			
		when Storem =>
		--	if n < 7 then  -- sin estos los primeros datos tas un reinicio son erroneos
		
		--		VelCompNS <= idlevc;
		--	else
				VelCompNS <= Summ;
		--	end if;
			
			NewValueReq <= '1';
			
		when Summ =>
			VelCompNS <= Meanm;
			
			NewValueReq <= '1';
			
		when Meanm =>
			VelCompNS <= Velcomp;
			
			NewValueReq <= '1';
			
		when Velcomp =>
--		   if vx = 0 and vy = 0 then  
--				VelCompNS <= idlevc;
--			else
				VelCompNS <= SendNewValue;
--			end if;
			   NewValueReq <= '1';
		
		when SendNewValue =>
		   if NewValueAck = '0' then  
				VelCompNS <= idlevc;
			else
				VelCompNS <=  SendNewValue;
			end if;
			NewValueReq <= '0';
			
	end case;
end process;


CenterMassOut<= oldmx&oldmy;--newmx&newmy;--;x"3232";--instanm(15 downto 8)&instanm(7 downto 0);--
Velocity<= VCellID&conv_std_logic_vector(ITind, 8)&conv_std_logic_vector(vx, 8)& conv_std_logic_vector(vy, 8);

VelCOMPS : process (rst,clk)
begin
	if (rst='1') then
		instanm <= (others =>'0');
		sum8mx<= (others =>'0');
		sum8my<= (others =>'0');
		oldmx<= (others =>'0');
		oldmy<= (others =>'0');
		newmx<= (others =>'0');
		newmy<= (others =>'0');
		vx<= (others =>'0');
		vy<= (others =>'0');
	elsif rising_edge(clk) then
		if VelCompCS = Readm then
			instanm <=CenterMassIn;
		else
			instanm <= instanm;
		end if;
			
		if VelCompCS = Storem then
			CenterMassHistoryX(conv_integer(i)) <= "000"&instanm(15 downto 8);
			CenterMassHistoryY(conv_integer(i)) <= "000"&instanm(7 downto 0);
		end if;
		
		if VelCompCS = Summ then
--			sum8mx <= conv_integer (CenterMassHistoryX(0)+CenterMassHistoryX(1)+CenterMassHistoryX(2)+CenterMassHistoryX(3)+CenterMassHistoryX(4)+CenterMassHistoryX(5)+CenterMassHistoryX(6)+CenterMassHistoryX(7));
--			sum8my <= conv_integer (CenterMassHistoryY(0)+CenterMassHistoryY(1)+CenterMassHistoryY(2)+CenterMassHistoryY(3)+CenterMassHistoryY(4)+CenterMassHistoryY(5)+CenterMassHistoryY(6)+CenterMassHistoryY(7));
			sum8mx <=  (CenterMassHistoryX(0)+CenterMassHistoryX(1));--+CenterMassHistoryX(2)+CenterMassHistoryX(3));--+CenterMassHistoryX(4)+CenterMassHistoryX(5)+CenterMassHistoryX(6)+CenterMassHistoryX(7));
			sum8my <=  (CenterMassHistoryY(0)+CenterMassHistoryY(1));--+CenterMassHistoryY(2)+CenterMassHistoryY(3));--+CenterMassHistoryY(4)+CenterMassHistoryY(5)+CenterMassHistoryY(6)+CenterMassHistoryY(7));
		
		else
			sum8mx <= sum8mx;
			sum8my <= sum8my;
		end if;
		
		if VelCompCS = Meanm then
			oldmx <= newmx;
			oldmy <= newmy;
			newmx <= sum8mx (8 downto 1);--instanm(15 downto 8);-- -conv_std_logic_vector (sum8mx ,8);-- 
			newmy <= sum8my (8 downto 1);--instanm(7 downto 0);-- --conv_std_logic_vector (sum8my ,8);-- 
		else
			oldmx <= oldmx;
			newmx <= newmx;
			oldmy <= oldmy;
			newmy <= newmy;
		end if;
		
		if VelCompCS = Velcomp then
			vx <= IEEE.STD_LOGIC_ARITH.signed (newmx-oldmx);
			vy <= IEEE.STD_LOGIC_ARITH.signed (newmy-oldmy);
		else
			vx <= vx;
			vy <= vy;
		end if;
		
	end if;
end process;

end Behavioral;

