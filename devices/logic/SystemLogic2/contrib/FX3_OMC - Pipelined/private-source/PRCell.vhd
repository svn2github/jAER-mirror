
----------------------------------------------------------------------------------
-- Company: University of Seville & INI
-- Engineer: Alejandro Linares & Paco Gomez
-- 
-- Create Date:    17:35:06 05/27/2009 
-- Design Name: 
-- Module Name:    PatternRecognitionCell - Behavioral 
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

entity PRCell is
    Port ( CLK : in STD_LOGIC;
			  RST : in STD_LOGIC;
			  Addi : in  STD_LOGIC_VECTOR (15 downto 0);
           REQi : in  STD_LOGIC;
           ACKi : out  STD_LOGIC;
			  CM: in std_logic_vector (15 downto 0);
           Addo : out  STD_LOGIC_VECTOR (15 downto 0);
           REQo : out  STD_LOGIC;
           ACKo : in  STD_LOGIC;
           RError : out  STD_LOGIC_VECTOR (15 downto 0); -- Object Center of mass
           REQND : out  STD_LOGIC;
			  ACKND : in STD_LOGIC;
			  Mask : in std_logic_vector (63 downto 0);
			  FiringThreshold : in AERFiring (63 downto 0);
			  InitCenterMass : in std_logic_vector (15 downto 0);
			  MaxTime :  in integer);
end PRCell;

architecture Behavioral of PRCell is


Component spblockram is 
 generic (TAM: in integer:= 2048; IL: in integer:=11; WL: in integer:=8);
 port (clk : in std_logic; 
 	we  : in std_logic; 
 	a   : in std_logic_vector(IL-1 downto 0); 
 	di  : in std_logic_vector(WL-1 downto 0); 
 	do  : out std_logic_vector(WL-1 downto 0)); 
 end Component; 

type CellStates is (idle, ReqReceived, EvDiscri, EvPssth, EvProc, InitCell, preSumComp, SumComp, postSumComp, preIDLE, MeanComp);
signal CellCS, CellNS: CellStates;

signal m : STD_LOGIC_VECTOR (15 downto 0); -- center of mass
signal g : STD_LOGIC_VECTOR (7 downto 0); -- radix of cell
signal ev : STD_LOGIC_VECTOR (15 downto 0);
signal RTHxL, RTHxH ,RTHyL, RTHyH : STD_LOGIC_VECTOR (7 downto 0);
signal Evforme,EmptyCell : STD_LOGIC;

signal TC :integer range 0 to 500000000;

signal we: std_logic;
signal di, do : std_logic_vector (7 downto 0);
signal a : std_logic_vector (5 downto 0);
signal ax, ay: std_logic_vector(7 downto 0);

signal CurData: std_logic_vector(7 downto 0 );
signal Fire : std_logic_vector (63 downto 0);
signal FFIRE: std_logic;

signal edir : integer range 0 to 63;
signal maskelem : integer range 0 to 128;
signal BSReult: integer range 0 to 64;


begin

--maskelem <= 48;

u_ram: spblockram 
	GENERIC MAP(64,6,8)
	PORT MAP(
		clk => clk,
		we => we,
		a => a,
		di => di,
		do => do
		);
		
ax<=(ev(15 downto 8)-m(15 downto 8))+3;-- antes +g
ay<=(ev(7 downto 0)-m(7 downto 0))+3;

--ax<=(ev(15 downto 8)-m(15 downto 8))+4;-- antes +g
--ay<=(ev(7 downto 0)-m(7 downto 0))+4;


--BSReult <=  BITSUM((FIRE xor MASK),64);

SYNC_CELL: process(RST, CLK)
begin
	if(RST = '1') then
		CellCS <= idle; 
	elsif rising_edge(clk) then
		CellCS <= CellNS; 		
	end if;
end process;

COMB_CELL: process(ACKND,CellCS, REQi, ACKo, evforme,EmptyCell,fire, edir, maskelem)
begin
	case CellCS is
		when idle =>  
			if EmptyCell ='1' then
				CellNS <= InitCell;
			elsif REQi='0' and ACKND='1' then
				CellNS <= ReqReceived;
			else
				CellNS <= idle;
			end if;
			
			ACKi <= '1';
			REQo <= '1';
			REQND <= '1';
			
			
		when ReqReceived =>
			CellNS <= EvDiscri;
			
			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
			
		when EvDiscri =>
			if evforme = '1' then
				CellNS <= EvProc;
			else
				CellNS <= EvPssth;
			end if;
			
			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
			
		when EvProc =>
				CellNS <= preSumComp;

			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
		
		when preSumComp =>
				CellNS <= SumComp;

			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
		
			when SumComp =>
				CellNS <= postSumComp;

			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
		
		
			
		when InitCell =>
			if REQi = '1' and edir = 63 then
				CellNS <= idle;
			else
				CellNS <= InitCell;
			end if;
			
			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
			
			-- hay que borrar la memoria de los eventos y el FIRE
			
		when postSumComp =>
 
			if maskelem > 72 then
	

				CellNS <= MeanComp;
			else
	
				CellNS <= preIDLE;
			end if;
			
			
			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
			
		when preIDLE => 
			if REQi = '1' and ACKo ='0' then
				CellNS <= idle;
			else
				CellNS <= preIDLE;
			end if;
			
			ACKi <= '0';
			REQo <= '0';
			REQND <= '1';
		
		when MeanComp =>
			if REQi = '1' and ACKND = '0' then
				CellNS <= InitCell; --idle;-- antes 
			else
				CellNS <= MeanComp;
			end if;
			
			ACKi <= '0';
			REQo <= '1';
			REQND <= '0';
			
		when EvPssth =>
			if ACKo ='0' and REQi='1' then
				CellNS <= idle;
			else 
				CellNS <= EvPssth;
			end if;
			
			ACKi <= '0';
			REQo <= '0';
			REQND <= '1';
			
	end case;
end process;



Addo <= Addi;--
RError <=  m(15 downto 8) & m(6 downto 0) & '0';--m;--"0000000000"&a;--x"FFFF";--ev;--


ResetCounterP: process (RST, Clk)
begin
	if RST='1' then
		TC <= 0;
	elsif rising_edge(clk) then
		if CellCS = InitCell then
			TC <= 0;
		else
			TC <= TC +1;
		end if;
	end if;
end process;

OutPutProc: process (RST,clk, InitCenterMass)--, ax, ay)
begin
	if RST='1' then
			EmptyCell <= '1';
			edir <= 0;
			a<= (others=>'0'); -- NOT SURE IF THIS WORKS --ax(2 downto 0)&ay(2 downto 0);
			RTHxH <= (others => '0');
			RTHxL <= (others => '0');
			RTHyH <= (others => '0');
			RTHyL <= (others => '0');
			ev <= (others => '0');
			m <= InitCenterMass;
			di <= (others => '0');
			we <= '1';
			Fire <= (others => '0');
			FFIRE <='0';
			maskelem <= 64;
			Evforme <= '0';
			CurData <= (others => '0');
	elsif clk='1' and clk'event then
		if CellCS = InitCell then 
			EmptyCell <= '0';
		elsif TC = MaxTime then
			EmptyCell <= '1'; 
		--else 
		--	EmptyCell <= EmptyCell;
		end if;
		
		if CellCS = idle then
			edir <= 0;
		elsif CellCS = InitCell then 
			edir <= edir +1;
		--else
		--	edir <= edir;
		end if;
		
		
		if CellCS = InitCell then 
			a<=conv_std_logic_vector(edir,6);--ax(2 downto 0)&ay(2 downto 0);
		else
			a<=ax(2 downto 0)&ay(2 downto 0);
		end if;
		
		
		if CellCS = Idle then
			RTHxH <= m(15 downto 8)+ g-1;-- + RadixThreshold;
			RTHxL <= m(15 downto 8)-g;--- RadixThreshold;
			RTHyH <= m(7 downto 0)+g-1;--+ RadixThreshold;
			RTHyL <= m(7 downto 0)-g;-- - RadixThreshold;
		--else
		--	RTHxH <= RTHxH;
		--	RTHxL <= RTHxL;
		--	RTHyH <= RTHyH;
		--	RTHyL <= RTHyL;
		end if;
		
		if CellCS = idle and REQi='0' then
			ev <= addi(15 downto 8)&'0'&addi(7 downto 1);
		--else
		--	ev <= ev;
		end if;
		
		if CellCS = ReqReceived then
			if  (ev(7 downto 0) <= RTHyH) and (ev(7 downto 0) >= RTHyL) and (ev(15 downto 8) <= RTHxH) and (ev(15 downto 8) >= RTHxL) then --ev (15 downto 8) > g and ev (7 downto 0) > g and  and (ev(7 downto 0) < RTHyH) and (ev(7 downto 0) > RTHyL) then
				Evforme <= '1';
			else 
			Evforme <= '1';  --????????????
			end if;
		--else
		--	Evforme <= Evforme;
		end if;
		
		 
		if CellCS = InitCell then
			m <= CM;
		--else
		--	m <= m;
		end if;
		
		if CellCS = EvProc then
			CurData <= do;
		--else
		--	CurData <= CurData;
		end if;
		
		if CellCS = SumComp then
			di <= CurData+1;
			we <= '1';
			--a<=ax(2 downto 0)&ay(2 downto 0);
		elsif CellCS = InitCell then
			di <= (others => '0');
			we <= '1';
			--a<=(others => '0');
		else
			--di <= di;
			we <= '0';
			--a<=a;
		end if;
		
		if CellCS = preSumComp then
			if CurData = FiringThreshold(conv_integer(a)) then
				Fire(conv_integer(a)) <= '1';
				FFIRE <='1';
			--else
			--	Fire <= Fire;
			--	FFIRE <=FFIRE;
			end if;
		elsif CellCS = InitCell then
			Fire <= (others => '0');
			--FFIRE <=FFIRE;
		elsif CellCS = idle then
			FFIRE <='0';
			--Fire <= Fire;
		--else
			--Fire <= Fire;
			--FFIRE <=FFIRE; 
		end if;
		
		if CellCS = SumComp then
			if  FFIRE = '1' then
				if mask(conv_integer(a))='1' then--
					maskelem <= maskelem + 1;
				--else
				--	maskelem <= maskelem;-- - 1;
				end if;
			--else
			--	maskelem <= maskelem;
			end if;
		elsif CellCS = InitCell then
			maskelem <= 64;
		--else
		--	maskelem <= maskelem;
		end if;
		
		
		
		

	end if;
end process;

g <= x"04";

end Behavioral;

