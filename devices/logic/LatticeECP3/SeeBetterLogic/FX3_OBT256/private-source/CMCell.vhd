----------------------------------------------------------------------------------
-- Company: University of Seville & INI
-- Engineer: Alejandro Linares & Paco Gomez
-- 
-- Create Date:    17:35:06 05/27/2009 
-- Design Name: 
-- Module Name:    CenterofMassCell - Behavioral 
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


---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CMCell is
    Port ( CLK : in STD_LOGIC;
	 	   RST : in STD_LOGIC;
		   -- AER IN
		   Addi : in  STD_LOGIC_VECTOR (15 downto 0);
           REQi : in  STD_LOGIC;
           ACKi : out  STD_LOGIC;
		   -- AER Rejected Events
		   Addo : out  STD_LOGIC_VECTOR (15 downto 0);
           REQo : out  STD_LOGIC;
           ACKo : in  STD_LOGIC;
		   -- AER Processed Events
		   Addp : out  STD_LOGIC_VECTOR (15 downto 0);
           REQp : out  STD_LOGIC;
           ACKp : in  STD_LOGIC;
		   -- AER CM
           CenterMass : out  STD_LOGIC_VECTOR (15 downto 0); -- Object Center of mass
           REQND : out  STD_LOGIC;
		   ACKND : in STD_LOGIC;
		   -- AER CM passthrough
           CenterMasspt : out  STD_LOGIC_VECTOR (15 downto 0); -- Object Center of mass
           REQNDpt : out  STD_LOGIC;
		   ACKNDpt : in STD_LOGIC;			  
		   -- config
		   InitCenterMass : in std_logic_vector (15 downto 0);
		   RadixThreshold : in STD_LOGIC_VECTOR (2 downto 0); -- for increase the cluster area
		   RadixStep : in std_logic_vector (2 downto 0);
		   RadixMax : in std_logic_vector (7 downto 0);
		   RadixMin : in std_logic_vector (7 downto 0);
		   InitRadix : in STD_LOGIC_VECTOR (7 downto 0);
		   MaxTime: in std_logic_vector (31 downto 0);
		   NevTh : in integer range 0 to 255;
		   CMcellAVG: in integer range 1 to 8
		);
end CMCell;

architecture Behavioral of CMCell is

type CellStates is (InitCell, idle, ReqReceived, EvDiscri, EvPssth, EvProc, EvNoProc, preSumComp, SumComp, MeanComp, MeanCompPT);
signal CellCS, CellNS: CellStates;

signal m : STD_LOGIC_VECTOR (15 downto 0); -- center of mass
signal mxaux, myaux :STD_LOGIC_VECTOR (9 downto 0);
signal g : STD_LOGIC_VECTOR (7 downto 0); -- radix of cell
signal ev,avgev : STD_LOGIC_VECTOR (15 downto 0);
signal RTHxL, RTHxH ,RTHyL, RTHyH : STD_LOGIC_VECTOR (8 downto 0);
signal RTHxLG, RTHxHG ,RTHyLG, RTHyHG : STD_LOGIC_VECTOR (8 downto 0);
signal Evforme,EmptyCell : STD_LOGIC;
signal TC, TC2 : STD_LOGIC_VECTOR (31 downto 0); -- time limit without new events

signal numevent: integer;
signal f:std_logic;

signal nevnog: integer range 0 to 7;
signal ADXMAX, ADYMAX: integer := 256; -- this was 128 in Paco's filters for max resolution of DVS of 128x128
signal iNevTh: integer range 0 to 255;

signal lastdiff,lastc,newtc, diftc, zeros: std_logic_vector (31 downto 0);

begin

SYNC_CELL: process(RST, CLK)
begin
	if(RST = '1') then
		CellCS <= InitCell;
		zeros <= (others => '1');
		ADXMAX <= 0;
		ADYMAX <= 0;
	elsif rising_edge(clk) then
		CellCS <= CellNS; 		
		zeros <= (others => '0');
		ADXMAX <= 256; -- this was 128 in Paco's filters for max resolution of DVS of 128x128 
		ADYMAX <= 256; -- this was 128 in Paco's filters for max resolution of DVS of 128x128
	end if;
end process;

COMB_CELL: process(ACKp,numevent,ACKND,ACKNDpt,CellCS, REQi, ACKo, evforme,EmptyCell, iNevTh)
begin
	CellNS <= CellCS;
			ACKi <= '1';
			REQo <= '1';
			REQND <= '1';
			REQNDpt <= '1';
			REQp <= '1';
	case CellCS is
		when idle =>  
		   if EmptyCell ='1' then
				CellNS <= InitCell;
			elsif REQi='0' and ACKND='1' and ACKNDpt='1' then
				CellNS <= ReqReceived;
			else
				CellNS <= idle;
			end if;
			ACKi <= '1';
			REQo <= '1';
			REQND <= '1';
			REQNDpt <= '1';
			REQp <= '1';
		when ReqReceived =>
			CellNS <= EvDiscri;
			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
			REQNDpt <= '1';
			REQp <= '1';
		when EvDiscri =>
			if evforme = '1' then
				if numevent >= iNevTh then
					CellNS <= EvProc;
				else
					CellNS <= EvNoProc;
				end if;
			else
				CellNS <= EvPssth;
			end if;
			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
			REQNDpt <= '1';
			REQp <= '1';
		when EvProc =>
			if EmptyCell ='1' then
				CellNS <= InitCell;
			else
				CellNS <= preSumComp;
			end if;
			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
			REQNDpt <= '1';
			REQp <= '1';
		when InitCell =>
			if REQi = '1' then
				CellNS <= idle;
			else
				CellNS <= InitCell;
			end if;
			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
			REQNDpt <= '1';
			REQp <= '1';
		when preSumComp =>
			CellNS <= SumComp;
			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
			REQNDpt <= '1';
		    REQp <= '1';
		when SumComp =>
			CellNS <= MeanComp;
			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
			REQNDpt <= '1';
			REQp <= '1';
		when EvNoProc =>
			if REQi = '1' and   ACKp ='0'  then
				CellNS <= idle;
			else
				CellNS <= EvNoProc;
			end if;
			ACKi <= '0';
			REQo <= '1';
			REQND <= '1';
			REQNDpt <= '1';
			REQp <= '0';	
		when MeanComp =>
			if REQi = '1' and   ACKND = '0' and ACKp ='0'  then
				CellNS <= MeanCompPT;
			else
				CellNS <= MeanComp;
			end if;
			ACKi <= '0';
			REQo <= '1';
			REQND <= '0';
			REQNDpt <= '1';
			REQp <= '0';
		when MeancompPT =>
		   if ACKNDPT ='0' then
			  CellNS<= idle;
			else CellNS <= MeanCompPT;
			end if;
			ACKi <= '1';
			REQo <= '1';
			REQND <= '1';
			REQNDpt <= '0';
			REQp <= '1';
		when EvPssth =>
			if ACKo ='0' and REQi='1' then
				CellNS <= idle;
			else 
				CellNS <= EvPssth;
			end if;
			ACKi <= '0';
			REQo <= '0';
			REQND <= '1';
			REQNDpt <= '1';
			REQp <= '1';
	end case;
end process;



Addo <= Addi;
Addp <= ev; 
			
CenterMass <= m;
CenterMasspt <= m;

ResetCounterP: process (RST, Clk)
begin
	if RST='1' then
		TC <= (others => '0');
		lastc <= (others =>'0');
		TC2 <= (others => '0');
		newtc <= (others =>'0');
		diftc <= (others =>'0');
		lastdiff <= (others =>'0');
	elsif rising_edge(clk) then
		if CellCS = EvProc then
			TC <= (others => '0');
		else
			TC <= TC +1;
		end if;
		if CellCS = InitCell then
		   TC2 <= (others => '0');
			lastc <= (others =>'0');
			newtc <= (others =>'0');
			diftc <= (others =>'0');
			lastdiff <= (others =>'0');
		else
		   TC2 <= TC2+1;			
			if CellCS = PreSumComp then
				lastc <= newtc;
				newtc <= TC2;
				lastdiff <= diftc;
				if (TC2>lastc) then
					diftc <= conv_std_logic_vector(conv_integer("0"&TC2)-conv_integer("0"&lastc),32);
				end if;
			end if;
		end if;
	end if;
end process;

OutPutProc: process (RST,clk, InitCenterMass, InitRadix, NevTh)
variable tmxaux, tmyaux, tavgevx, tavgevy :STD_LOGIC_VECTOR (17 downto 0);

begin
	if (RST='1') then
			EmptyCell <= '1';
			RTHxH <= (others => '0');
			RTHxL <= (others => '0');
			RTHyH <= (others => '0');
			RTHyL <= (others => '0');
			RTHxHG <= (others => '0');
			RTHxLG <= (others => '0');
			RTHyHG <= (others => '0');
			RTHyLG <= (others => '0');
			ev <= (others => '0');
			Evforme <= '0';
			numevent <= 0;
			m <= InitCenterMass;
			g <= InitRadix;
			f <= '0';
			nevnog<=0;
			mxaux <= (others => '0');
			myaux <= (others => '0');
			iNevTh <= NevTh;
	elsif clk='1' and clk'event then
		if CellCS = InitCell then 
			EmptyCell <= '0';
		elsif TC = MaxTime then
			EmptyCell <= '1'; 
		end if;
		
		if CellCS = Idle then
			if (conv_integer ('0'&m(15 downto 8) + ('0'& g) + RadixThreshold) < ADXMAX) then
				RTHxH <= conv_std_logic_vector(conv_integer ('0'&m(15 downto 8)+('0'& g)+ RadixThreshold),9);
			else RTHxH <= conv_std_logic_vector(ADXMAX-1,9);
			end if;
			if ('0'&m(15 downto 8) >= ('0'& g) + RadixThreshold) then
				RTHxL <= conv_std_logic_vector(conv_integer ('0'&m(15 downto 8)-('0'& g)- RadixThreshold),9);
			else RTHxL <= (others =>'0');
			end if;
			if (conv_integer ('0'&m(7 downto 0) + ('0' & g) + RadixThreshold) < ADYMAX) then
				RTHyH <= conv_std_logic_vector(conv_integer ('0'&m(7 downto 0)+('0'& g)+ RadixThreshold),9);
			else RTHyH <= conv_std_logic_vector(ADYMAX-1,9);
			end if;
			if ('0'&m(7 downto 0) > ('0' & g)+ RadixThreshold) then
				RTHyL <= conv_std_logic_vector(conv_integer ('0'&m(7 downto 0)-('0'& g)- RadixThreshold),9);
			else 
				RTHyL <= (others =>'0');
			end if;
			if (conv_integer('0'&m(15 downto 8) + ('0'& g)) < ADXMAX) then
				RTHxHG <= conv_std_logic_vector(conv_integer ('0'&m(15 downto 8)+ ('0'& g)),9);
			else 
			   RTHxHG <= conv_std_logic_vector(ADXMAX-1,9);
			end if;
			if ('0'&m(15 downto 8) > ('0'& g)) then
				RTHxLG <= conv_std_logic_vector(conv_integer ('0'&m(15 downto 8)-('0'& g)),9);
			else RTHxLG <= (others => '0');
			end if;
			if (conv_integer('0'&m(7 downto 0) + ('0'& g)) > ADYMAX) then
				RTHyHG <= conv_std_logic_vector(conv_integer ('0'&m(7 downto 0)+('0'& g)),9);
			else
				RTHyHG <= conv_std_logic_vector(ADYMAX-1,9);
			end if;
			if ('0'&m(7 downto 0) > g) then
				RTHyLG <= conv_std_logic_vector(conv_integer ('0'&m(7 downto 0)-('0'& g)),9);
			else
				RTHyLG <= (others =>'0');
			end if;
		end if;
		
		if CellCS = idle and REQi='0' then
			ev <= addi; 
			end if;
		if CellCS = InitCell then
			Evforme <= '0';
			numevent <= 0;
		elsif CellCS = ReqReceived then
			if ev /= x"0000" and ('0'& ev(7 downto 0) < RTHyH) and ('0'& ev(7 downto 0) > RTHyL) and ('0'& ev(15 downto 8) < RTHxH) and ('0'& ev(15 downto 8) > RTHxL) then 
				Evforme <= '1';
				numevent <= numevent+1;
			else 
				Evforme <= '0';
			end if;
		elsif CellCS = EvProc then
			numevent <= 0;
		end if;
		
		if CellCS = InitCell then
			m <= InitCenterMass;
		elsif CellCS = MeanComp then
			m(15 downto 8) <= mxaux(8 downto 1);
			m(7 downto 0) <= myaux(8 downto 1);
		end if;
		
		if CellCS = InitCell then
			g <= InitRadix;
			f <= '0';
			nevnog<=0;
		elsif CellCS = EvProc then
			if f='0' then
				g<=InitRadix; 
			elsif (('0'& ev(7 downto 0) > RTHyHG) or ('0'& ev(7 downto 0) < RTHyLG) or ('0'& ev(15 downto 8) > RTHxHG) or ('0'& ev(15 downto 8) < RTHxLG)) then
				if (g+RadixStep<RadixMax) then
					g<=g+RadixStep;
				else g <= RadixMax;
				end if;
				nevnog<=0;
			elsif	 nevnog > 6 and g-RadixStep > RadixMin then -- JUGAR CON EL LIMITE DE 6??
				g <= g - RadixStep;
				nevnog<=0;
			elsif nevnog >6 then 
			    g <= RadixMin;
				nevnog<= 0;
			else
				nevnog<=nevnog+1;
			end if;
			f <= '1';
		end if;
		
		if (CellCS = InitCell) then
		   avgev <= InitCenterMass;
		elsif (CellCS = EvNoProc) then
		    tavgevx := x"00" & "00" & avgev(15 downto 8);
		    tavgevy := x"00" & "00" & avgev(7 downto 0);
		    for i in 1 to 8 loop
			   if (i <= CMCellAVG) then
				tavgevx := tavgevx (16 downto 0) & '0';
				tavgevy := tavgevy (16 downto 0) & '0';
			   end if;
			end loop;
		    tavgevx := conv_std_logic_vector(conv_integer('0'&ev(15 downto 8)) + conv_integer('0'& tavgevx) - conv_integer('0'&avgev(15 downto 8)),18);
			avgev(15 downto 8) <= tavgevx(7+CMCellAVG downto CMCellAVG);
			tavgevy := conv_std_logic_vector(conv_integer('0'&ev(7 downto 0)) + conv_integer('0'& tavgevy) - conv_integer('0'&avgev(7 downto 0)),18);
			avgev(7 downto 0) <= tavgevy(7+CMCellAVG downto CMCellAVG);
		end if;
		
		if CellCS = InitCell then
			iNevTh <= NevTh;	
		elsif CellCS = SumComp then 
			if f = '0' then
				mxaux<='0'&ev(15 downto 8)&'0';
				myaux<='0'&ev(7 downto 0)&'0';
			else	
		    tmxaux := x"00" & "00" & m(15 downto 8);
		    tmyaux := x"00" & "00" & m(7 downto 0);
		    for i in 1 to 8 loop
			   if (i <= CMCellAVG) then
				tmxaux := tmxaux (16 downto 0) & '0';
				tmyaux := tmyaux (16 downto 0) & '0';
			   end if;
			end loop;
				tmxaux := conv_std_logic_vector(conv_integer('0'&avgev(15 downto 8)) + conv_integer('0'& tmxaux) - conv_integer('0'&m(15 downto 8)),18);
				mxaux <= '0'&tmxaux(7+CMCellAVG downto CMCellAVG)&'0';
				tmyaux := conv_std_logic_vector(conv_integer('0'&avgev(7 downto 0)) + conv_integer('0'& tmyaux) - conv_integer('0'&m(7 downto 0)),18);
				myaux <= '0'&tmyaux(7+CMCellAVG downto CMCellAVG)&'0';
			end if;
				if (diftc>(lastdiff(30 downto 0)&"0") and iNevTh > NevTh) then iNevTh <= iNevTh/2;
				elsif (diftc<lastdiff(31 downto 1) and iNevTh < 1000) then iNevTh <= iNevTh*2;
				end if;
		end if;
	end if;
end process;
end Behavioral;