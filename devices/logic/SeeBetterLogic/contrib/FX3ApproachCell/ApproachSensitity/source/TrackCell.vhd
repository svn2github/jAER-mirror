----------------------------------------------------------------------------------
-- Company: University of Seville
-- Engineer: Alejandro Linares & Paco Gomez
-- 
-- Create Date:    18:56:31 01/05/2014 
-- Design Name: 
-- Module Name:    TrackCell - Behavioral 
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

library work;
use work.AERDataPackage.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TrackCell is
 Generic (
	          BASEADDRESS : std_logic_vector (7 downto 0) := (others => '0')
		  );
--    Generic (--PRCell
--	          Mask : std_logic_vector (63 downto 0) := (others => '0');
--				 FiringThreshold : AERFiring (63 downto 0) := (others => x"04");
--				 MaxTime :  integer := 1500000;
--		       --VCell
--				 ITindex : std_logic_vector (3 downto 0):= "0011";--STD_LOGIC_VECTOR (31 downto 0) := x"000F4240";--x"ffffffff");--x"000186A0");--x"00F42400");--
--				 VCellID:std_logic_vector(7 downto 0):=x"FF";
--				 -- CMCell
--	 			 InitCenterMass : std_logic_vector (15 downto 0) := x"1808";
--				 RadixThreshold :  STD_LOGIC_VECTOR (2 downto 0):= "111"; -- for increase the cluster area
--				 InitRadix :  STD_LOGIC_VECTOR (7 downto 0):= x"30");
    Port ( CLK : in STD_LOGIC;
			  RST : in STD_LOGIC;
 			  TRACKCELLID : in std_logic_vector (7 downto 0);

			  -- AER IN
			  Addi : in  STD_LOGIC_VECTOR (15 downto 0);
           REQi : in  STD_LOGIC;
           ACKi : out  STD_LOGIC;
			  -- AER Rejected Events
			  Addo : out  STD_LOGIC_VECTOR (15 downto 0);
           REQo : out  STD_LOGIC;
           ACKo : in  STD_LOGIC;
			  -- AER Processed Events
			  Addpo : out  STD_LOGIC_VECTOR (15 downto 0);
           REQpo : out  STD_LOGIC;
           ACKpo : in  STD_LOGIC;
			  -- Tacking information
			  Velocity : out  STD_LOGIC_VECTOR (31 downto 0);
           ReqVel : out  STD_LOGIC;
			  AckVel : in STD_LOGIC;
           CMVel : out  STD_LOGIC_VECTOR (15 downto 0); -- Object Center of mass periodic
           CenterMasspt : out  STD_LOGIC_VECTOR (15 downto 0); -- Object Center of mass instantaneous
           REQNDpt : out  STD_LOGIC;
			  ACKNDpt : in STD_LOGIC;			  
			  
			  Active: out std_logic;

			  --
			  spiWR: in STD_LOGIC;
			  spiADDRESS: in STD_LOGIC_VECTOR(7 downto 0);		  
			  spiDATA: in STD_LOGIC_VECTOR(7 downto 0)
			 );
end TrackCell;

architecture Behavioral of TrackCell is

COMPONENT CMCell is
    Port ( CLK : STD_LOGIC;
			  RST : STD_LOGIC;
			  
			  Addi : in  STD_LOGIC_VECTOR (15 downto 0);
           REQi : in  STD_LOGIC;
           ACKi : out  STD_LOGIC;
           
			  Addo : out  STD_LOGIC_VECTOR (15 downto 0);
           REQo : out  STD_LOGIC;
           ACKo : in  STD_LOGIC;
			  
			  Addp : out  STD_LOGIC_VECTOR (15 downto 0);
           REQp : out  STD_LOGIC;
           ACKp : in  STD_LOGIC;
			  
			  CenterMass : out  STD_LOGIC_VECTOR (15 downto 0); -- Object Center of mass
           REQND : out  STD_LOGIC;
			  ACKND : in STD_LOGIC;

			  -- AER CM passthrough
           CenterMasspt : out  STD_LOGIC_VECTOR (15 downto 0); -- Object Center of mass
           REQNDpt : out  STD_LOGIC;
			  ACKNDpt : in STD_LOGIC;			  
			  
			  -- config
			  InitCenterMass : in std_logic_vector (15 downto 0) ;
			  RadixThreshold : in STD_LOGIC_VECTOR (2 downto 0); -- for moving the cluster area
			  RadixStep : in STD_LOGIC_VECTOR (2 downto 0); -- for increase/decrease the cluster area
			  RadixMax : in STD_LOGIC_VECTOR (2 downto 0); -- Max size of cluster area radius
			  RadixMin : in STD_LOGIC_VECTOR (2 downto 0); -- Min size of cluster area radius
			  InitRadix :  in STD_LOGIC_VECTOR (7 downto 0);
			  MaxTime: in std_logic_vector (31 downto 0);
			  NevTh : in integer range 0 to 255;
  			  CMcellAVG: in integer range 1 to 8
	 );
           
end COMPONENT;
	
	
	COMPONENT VelocityCell is
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		CenterMassIn : IN std_logic_vector(15 downto 0);
		NewDataReq : IN std_logic;
		NewValueAck : IN std_logic;          
		Velocity : OUT std_logic_vector(31 downto 0);
		NewValueReq : OUT std_logic;
		CenterMassOut : OUT std_logic_vector(15 downto 0);
		--config
		ITindex : in std_logic_vector (3 downto 0);
		VCellID: in std_logic_vector(7 downto 0)
		);
	END COMPONENT;
	
	COMPONENT PRCell is
    Port ( CLK : STD_LOGIC;
			  RST : STD_LOGIC;
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
			  --config
			  Mask : in std_logic_vector (63 downto 0);-- := (others => '0');
			  FiringThreshold : in AERFiring (63 downto 0);-- := (others => x"00");
			  InitCenterMass : in std_logic_vector (15 downto 0);-- := x"1808";
			  MaxTime :  in integer-- := 50000
			  );
           
end COMPONENT;
	
	-- rejected events
	signal ackr,reqr : STD_LOGIC;
	signal addr: STD_LOGIC_VECTOR(15 downto 0);
	
	signal ackp,reqp : STD_LOGIC;
	signal addp: STD_LOGIC_VECTOR(15 downto 0);
	
	signal ackPR,reqPR : STD_LOGIC;
	signal addPR: STD_LOGIC_VECTOR(15 downto 0);
	
	signal ackoPR,reqoPR : STD_LOGIC;
	signal addoPR: STD_LOGIC_VECTOR(15 downto 0);
	
	signal REQND : STD_LOGIC;
	signal CM,CMVelint: STD_LOGIC_VECTOR(15 downto 0);
	
	signal velocityint : std_logic_vector(31 downto 0);
	signal PDetected, spdetected : std_logic_vector(3 downto 0);
	
	signal ACKparb : std_logic;
	
	-- SPI CFG interface signals
	   signal       add: std_logic_vector (7 downto 0);
					 --PRCell
	   signal       Mask : std_logic_vector (63 downto 0);-- := (others => '0');
		signal		 FiringThreshold : AERFiring (63 downto 0) ;--:= (others => x"01");
		signal		 MaxTime :  integer;-- := 500000;
		signal       maxtimev: std_logic_vector (31 downto 0);
		       --VCell
		signal		 ITindex : std_logic_vector (3 downto 0);--:= "0011";--STD_LOGIC_VECTOR (31 downto 0) := x"000F4240";--x"ffffffff");--x"000186A0");--x"00F42400");--
		signal		 VCellID:std_logic_vector(7 downto 0);--:=x"FF";
				 -- CMCell
	 	signal		 InitCenterMass : std_logic_vector (15 downto 0) ;-- := x"1808";
		signal		 RadixThreshold, RadixStep, RadixMin, RadixMax :  STD_LOGIC_VECTOR (2 downto 0);--:= "111"; -- for increase the cluster area
		signal		 InitRadix :  STD_LOGIC_VECTOR (7 downto 0);--:= x"08";
		signal CMCellMaxTime : STD_LOGIC_VECTOR (31 downto 0); -- time limit without new events
		signal CMCellNevTh: integer range 0 to 255;
		signal CMCellAVG: integer range 1 to 8;

		signal ConfigEnabled : std_logic;
		signal irst : std_logic;
		signal ENTRACKER, ACKit, REQit: std_logic;
	 	signal Addit: std_logic_vector (15 downto 0) ;
begin
add <= spiaddress - BASEADDRESS;
Active <= ENTRACKER;
BCFG: process (clk, rst, TRACKCELLID)
begin
   if (rst='1') then
		FiringThreshold <= (others => x"01");
		if (TRACKCELLID=x"01") then 
			Mask <= "0000001100000111000011100001110000111000011100001110000011000000";--(others => '0'),-- diagonal /
			InitCenterMass <= x"503B";
			InitRadix <= x"40";
      end if;
		if (TRACKCELLID=x"02") then 
			Mask <= "0001100000011000000110000001100000011000000110000001100000011000";--(others => '0'),-- vertical line   
			InitCenterMass <= x"504F";
			InitRadix <= x"40";
		end if;
		if (TRACKCELLID=x"03") then 
			Mask <= "1100000011100000011100000011100000011100000011100000011100000011";--(others => '0'),-- diagonal \
			InitCenterMass <= x"5066";
			InitRadix <= x"40";
      end if;
		if (TRACKCELLID=x"04") then 
			Mask <= "1100000011100000011100000011100000011100000011100000011100000011";--(others => '0'),-- diagonal \
			InitCenterMass <= x"5005";
			InitRadix <= x"40";
      end if;
		CMCellMaxTime <= x"01312D00"; -- 200 ms with a 100Mhz clk
		CMCellNevTh <= 15;
		CMCellAVG <= 1; -- Means that 2^4 last events are taken into account for calculating next CM
	   --Mask <= (others =>'0');
		MaxTime <= 100000000;
		maxtimev <= x"05F5E100";
		ITindex <= "0011";
		VCellID <= TRACKCELLID+1;
		--InitCenterMass <= x"1808";
		RadixThreshold <= "011";
		RadixStep <= "011";
		RadixMin <= "001";
		RadixMax <= "111";
		--InitRadix <= x"08";
		ConfigEnabled <= '0';
		ENTRACKER <= '0';
	elsif (clk'event and clk='1') then
	   if (spiwr='1' and add=127 and spidata=TRACKCELLID) then
		    ConfigEnabled <= '1';
		elsif (spiwr='1' and add=127) then
			ConfigEnabled <= '0';
		end if;
	  if (ConfigEnabled='1' and spiwr='1') then
	   if (add >=0 and add <=63) then
		   FiringThreshold(conv_integer(63)) <= spidata;
		end if;
		if (add=64) then
		   Mask(7 downto 0) <= spidata;
		end if;
		if (add=65) then
		   Mask(15 downto 8) <= spidata;
		end if;
		if (add=66) then
		   Mask(23 downto 16) <= spidata;
		end if;
		if (add=67) then
		   Mask(31 downto 24) <= spidata;
		end if;
		if (add=68) then
		   Mask(39 downto 32) <= spidata;
		end if;
		if (add=69) then
		   Mask(47 downto 40) <= spidata;
		end if;
		if (add=70) then
		   Mask(55 downto 48) <= spidata;
		end if;
		if (add=71) then
		   Mask(63 downto 56) <= spidata;
		end if;
		if (add=72) then
		   maxtimev(7 downto 0) <= spidata; MaxTime <= conv_integer ("0" & maxtimev);
		end if;
		if (add=73) then
		   maxtimev(15 downto 8) <= spidata; MaxTime <= conv_integer ("0" & maxtimev);
		end if;
		if (add=74) then
		   maxtimev(23 downto 16) <= spidata; MaxTime <= conv_integer ("0" & maxtimev);
		end if;
		if (add=75) then
		   maxtimev(31 downto 24) <= spidata; MaxTime <= conv_integer ("0" & maxtimev);
		end if;
		if (add=76) then
		   ITindex <= spidata (3 downto 0);
		end if;
		if (add=77) then
		   VCellID <= spidata;
		end if;
		if (add=78) then
		   InitCenterMass (7 downto 0) <= spidata;
		end if;
		if (add=79) then
		   InitCenterMass (15 downto 8) <= spidata;
		end if;
		if (add=80) then
		   RadixThreshold <= spidata (2 downto 0);
		end if;
		if (add=81) then
		   InitRadix <= spidata;
		end if;
		if (add=82) then
		   CMCellMaxTime( 7 downto 0) <= spidata;
		end if;
		if (add=83) then
		   CMCellMaxTime (15 downto 8)<= spidata;
		end if;
		if (add=84) then
		   CMCellMaxTime (23 downto 16)<= spidata;
		end if;
		if (add=85) then
		   CMCellMaxTime (31 downto 24)<= spidata;
		end if;
		if (add=86) then
		   CMCellNevTh <= conv_integer ("0" & spidata);
		end if;
		if (add=87) then
		   if (spidata >0 and spidata <=8) then
				CMCellAVG <= conv_integer ("0" & spidata);
			elsif (spidata=0) then CMCellAVG <= 1;
			else CMCellAVG <= 8;
			end if;
		end if;
		if (add=88 and spidata=x"FF") then 
		  ENTRACKER <='1';
		end if;
		if (add=88 and spidata=x"00") then 
		  ENTRACKER <='0';
		end if;
		if (add=89) then
		   RadixStep <= spidata (2 downto 0);
		end if;
		if (add=90) then
		   RadixMax <= spidata (2 downto 0);
		end if;
		if (add=91) then
		   RadixMin <= spidata (2 downto 0);
		end if;
	  end if;
	end if;
end process;

irst <= rst or ConfigEnabled;

-- salen los rechazados
Addo <= Addr when (ENTRACKER='1') else Addi;
REQo <= REQr when (ENTRACKER='1') else REQi;
ACKr <= ACKo;
ACKi <= ACKo when (ENTRACKER='0') else ACKit;
--salen los procesados
Addpo <= Addp;
REQpo <= REQp when (ENTRACKER ='1') else '1';
ACKp <= ACKparb or ACKpo;

Addit <= Addi;
REQit <= REQi when (ENTRACKER='1') else '1';

-- sale la deteccion del patrón
--Addo <= AddPR;
--REQo <= REQPR;
--ACKPR <= ACKo;

-- sale lo que rechaza la deteccion del patrón
--Addo <= AddoPR;
--REQo <= REQoPR;
--ACKoPR <= ACKo;


Inst_CMCell: CMCell 
	PORT MAP(
		CLK => CLK,
		RST => irst,
		Addi => Addit,
		REQi => REQit,
		ACKi => ACKit,
		Addo => Addr,
		REQo => REQr,
		ACKo => ACKr,--REQr,--
		Addp => Addp,
		REQp => REQp,
		ACKp => ACKp,
		CenterMass => CM,
		REQND => REQND,
		ACKND => REQND,
		CenterMasspt => CenterMasspt,
		REQNDpt => REQNDpt,
		ACKNDpt => ACKNDpt,
		InitCenterMass => InitCenterMass,
		RadixThreshold => RadixThreshold, -- for increase the cluster area
		RadixStep => RadixStep,
		RadixMin => RadixMin,
		RadixMax => RadixMax,
		InitRadix => InitRadix,
		MaxTime => CMCellMaxTime,
		NevTh => CMCellNevTh,
		CMCellAVG => CMCellAVG
	);


Inst_VelocityCell: VelocityCell 
	PORT MAP(
		CLK => CLK,
		RST => irst,
		CenterMassIn => CM,
		NewDataReq => REQND,
		Velocity => Velocityint,
		NewValueReq => REQVel,
		NewValueAck => ACKVel,
		CenterMassOut => CMVelint,
		ITindex => ITindex,--100ms x"000F4240")--10 ms		-- x"000186A0")-- 1ms x"001E8480")--20 ms     -- "01312D00") -- 200 ms x"00000064")--1 us x"000003E8")--10us x"00002710")--100us  -- x"0007A120")--5 ms  -- 
		VCellID => VCellID		
	);

CMVel <= CMVelint;
Velocity <= Velocityint(31 downto 24)&sPDetected&Velocityint(19 downto 0);

Inst_PRCell: PRCell 
	PORT MAP(
		CLK => CLK,
		RST => irst,
		Addi => Addp,
		REQi => REQp,
		ACKi => ACKparb,
		CM => CMVelint,--CM,--
		Addo => AddoPR,
		REQo => REQoPR,
		ACKo => ACKoPR,--REQoPR,--
		RError => AddPR,
		REQND => REQPR,
		ACKND => REQPR,--ACKPR--
		Mask => Mask,
		FiringThreshold => FiringThreshold,
		InitCenterMass => InitCenterMass,
		MaxTime => MaxTime
	);



PRPROC: process (REQPR, ACKVel,pdetected, sPDetected)
begin
	if REQPR='0' then
		PDetected<="1111";
	elsif ACKVel='0' then
		PDetected<="0000";
	else
		PDetected<=sPDetected;
	end if;
end process;

PRSYNC: process (rst,clk)
begin
   if (rst='1') then
	  spdetected <= (others => '0');
	elsif (clk'event and clk='1') then
	  spdetected <= PDetected;
	end if;
end process;


end Behavioral;

