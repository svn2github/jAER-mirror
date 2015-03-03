----------------------------------------------------------------------------------
-- Company: University of Seville & INI
-- Engineer: Alejandro Linares & Paco Gomez
-- 
-- Create Date:    09:55:15 05/31/2009 
-- Design Name: 
-- Module Name:    Object Tracker top module - Behavioral 
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

use work.AERDataPackage.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ObjectTracker is
    Generic (
	          BASEADDRESS : std_logic_vector (7 downto 0) := (others => '0')
		      );
    Port ( 
	 	  	  aer_in_data : in std_logic_vector(16 downto 0);
           aer_in_req_l : in std_logic;
           aer_in_ack_l : out std_logic;
			  aer_out_data : out std_logic_vector(16 downto 0);
           aer_out_req_l : out std_logic;
           aer_out_ack_l : in std_logic;
           rst_l : in std_logic;
           clk50 : in std_logic;
			  OT_active: out std_logic_vector (3 downto 0);
			  spiWR: in STD_LOGIC;
			  spiADDRESS: in STD_LOGIC_VECTOR(7 downto 0);		  
			  spiDATA: in STD_LOGIC_VECTOR(7 downto 0);
			  LED: out std_logic_vector (2 downto 0)
			);
end ObjectTracker;

architecture Behavioral of ObjectTracker is

COMPONENT TrackCell is

	Generic ( BASEADDRESS : std_logic_vector (7 downto 0) := (others => '0')
			  );
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		TRACKCELLID : std_logic_vector (7 downto 0) := (others => '0');
		Addi : IN std_logic_vector(15 downto 0);
		REQi : IN std_logic;
		ACKo : IN std_logic;
		AckVel : IN std_logic;          
		ACKi : OUT std_logic;
		Addo : OUT std_logic_vector(15 downto 0);
		REQo : OUT std_logic;
		-- AER Processed Events
		Addpo : out  STD_LOGIC_VECTOR (15 downto 0);
      REQpo : out  STD_LOGIC;
      ACKpo : in  STD_LOGIC;
		-- 
		Velocity : OUT std_logic_vector(31 downto 0);
		ReqVel : OUT std_logic;
		CMVel : OUT std_logic_vector(15 downto 0);
           CenterMasspt : out  STD_LOGIC_VECTOR (15 downto 0); -- Object Center of mass instantaneous
           REQNDpt : out  STD_LOGIC;
			  ACKNDpt : in STD_LOGIC;		

		Active: out std_logic;
		--
  	   spiWR: in STD_LOGIC;
		spiADDRESS: in STD_LOGIC_VECTOR(7 downto 0);		  
		spiDATA: in STD_LOGIC_VECTOR(7 downto 0)
		);
	END COMPONENT;


	COMPONENT ExtRAMController
	PORT(
		clk : IN std_logic;
		rst : IN std_logic;
		req : IN std_logic;
		Vdir : IN std_logic_vector(13 downto 0);
		Vx : IN std_logic_vector(7 downto 0);
		Vy : IN std_logic_vector(7 downto 0);
		Scale : IN std_logic_vector(7 downto 0);
		CellID : IN std_logic_vector(7 downto 0);
		dir : IN std_logic_vector(13 downto 0);
		ReadReq : IN std_logic;    
		ack : OUT std_logic;
		data : OUT std_logic_vector(31 downto 0);
		ReadACK : OUT std_logic
		);
	END COMPONENT;
	

	COMPONENT AERArbriter
		GENERIC (N : integer);
	PORT(
		clk : IN std_logic;
		rst : IN std_logic;
		Reqi : IN std_logic_vector(7 downto 0);
		datai : IN AERData(7 downto 0);
		diri : IN AERDir(7 downto 0);
		Acko : IN std_logic;          
		Acki : OUT std_logic_vector(7 downto 0);
		Reqo : OUT std_logic;
		datao : OUT std_logic_vector(31 downto 0);
		diro : OUT std_logic_vector(16 downto 0)
		);
	END COMPONENT;

	signal clk,reset:std_logic; --,clk50int,clk0B,clk100int,not_lockdll1,lockdll1
	signal iaer_in_req_l, saer_in_req_l, iaer_out_ack_l,saer_out_ack_l: std_logic;
	signal ncommand: integer range 0 to 15;
	
	-- arbiter
	
	signal	Reqi :  std_logic_vector(7 downto 0);
	signal	Acko :  std_logic;          
	signal	Acki :  std_logic_vector(7 downto 0);
	signal	Reqo :  std_logic;
	signal	datao :  std_logic_vector(31 downto 0);
	signal   diro: std_logic_vector (16 downto 0);
	signal 	datai: AERdata (7 downto 0);
	signal 	diri: AERdir (7 downto 0);
	
	--signal   datai: std_logic_vector(127 downto 0);
	signal aer_in_dataint:  std_logic_vector(15 downto 0);
	
	-- signal for internal memory for store velocity data .
	signal we: std_logic;
	signal a, dpra :std_logic_vector(11 downto 0);
	signal Vdir: std_logic_vector(13 downto 0);
	signal Vx,Vy,CellID,Scale: std_logic_vector (7 downto 0);
	
	 signal USBAddressCount: std_logic_vector(13 downto 0);
	 signal USBDataCount: Std_logic_vector (1 downto 0);
	 signal USBDataint: std_logic_vector (31 downto 0);
 
	-- USB
	type USB_states is (USBIDLE, WAIT_COMMAND,WAIT_NO_COMMAND, WAIT_VALID, WAIT_NOVALID,USBEND,USBReadRAM);
	signal USBCurrentState, USBNextState: USB_states;

	
	--Track cells
	--TC0      
	   --result
	signal V0 : std_logic_vector(31 downto 0);
	signal NewVelReq0 , ACKND0: std_logic;
	signal CM0, CMT0:  std_logic_vector(15 downto 0);
	signal CM0req, CM0ack: std_logic;
		--refused
	signal ackr0,reqr0: STD_LOGIC;
	signal addr0: STD_LOGIC_VECTOR(15 downto 0);
		-- processed
	signal	ackpo0 :  std_logic;          
	signal	reqpo0 :  std_logic;
	signal	datapo0 :  std_logic_vector(15 downto 0);
	
	--TC1
	   --result
	signal V1 : std_logic_vector(31 downto 0);
	signal NewVelReq1 , ACKND1: std_logic;
	signal CM1, CMT1:  std_logic_vector(15 downto 0);
	signal CM1req, CM1ack: std_logic;
		--refused
	signal ackr1,reqr1: STD_LOGIC;
	signal addr1: STD_LOGIC_VECTOR(15 downto 0);
		-- processed
	signal	ackpo1 :  std_logic;          
	signal	reqpo1 :  std_logic;
	signal	datapo1 :  std_logic_vector(15 downto 0);
	
	--TC2
	   --result
	signal V2 : std_logic_vector(31 downto 0);
	signal NewVelReq2 , ACKND2: std_logic;
	signal CM2, CMT2:  std_logic_vector(15 downto 0);
	signal CM2req, CM2ack: std_logic;
		--refused
	signal ackr2,reqr2: STD_LOGIC;
	signal addr2: STD_LOGIC_VECTOR(15 downto 0);
		-- processed
	signal	ackpo2 :  std_logic;          
	signal	reqpo2 :  std_logic;
	signal	datapo2 :  std_logic_vector(15 downto 0);
	
	--TC3
	   --result
	signal V3 : std_logic_vector(31 downto 0);
	signal NewVelReq3 , ACKND3: std_logic;
	signal CM3, CMT3:  std_logic_vector(15 downto 0);
	signal CM3req, CM3ack: std_logic;
		--refused
	signal ackr3,reqr3: STD_LOGIC;
	signal addr3: STD_LOGIC_VECTOR(15 downto 0);
		-- processed
	signal	ackpo3 :  std_logic;          
	signal	reqpo3 :  std_logic;
	signal	datapo3 :  std_logic_vector(15 downto 0);
     
	--signal IntegrationTime : std_logic_vector(31 downto 0);
   -- USB state machine interface
     signal data: std_logic_vector (31 downto 0);
	  signal dir: std_Logic_vector (13 downto 0); 
	  signal ReadReq, ReadACK: std_logic;
   
	  signal ID1, ID2, ID3, ID4: std_logic_vector (7 downto 0);

   --signal V1 : std_logic_vector(7 downto 0);	
     signal tOT_active : std_logic_vector (3 downto 0);
	  signal taer_in_ack_l : std_logic;

begin
--clk50buf : IBUFG port map (I => clk50, O => clk50int);
--DLL1 : CLKDLL port map (CLKIN => Clk50int, CLKFB => Clk100int, RST => RESET, CLK0 => OPEN,			   --Reset alto o bajo?
--	       		CLK90 => OPEN, CLK180 => OPEN, CLK270 => OPEN, CLK2X => Clk0B, 
--			CLKDV => OPEN, LOCKED => OPEN);
--bufg0 : BUFG port map (O => Clk100int, I => Clk0B);

--clk <=clk50int;
clk<=clk50;--clk100int;

reset <= not rst_l;


   --IntegrationTime <= x"00989680";
	--a <= CMint1(13 downto 8)&CMint1(5 downto 0);
	--a <= cm1(13 downto 8)&cm1(5 downto 0);
	--dir <= (64-datao(14 downto 9))&(64-datao(6 downto 1));--CMint0(13 downto 8)&CMint0(5 downto 0);-----datai(0)(13 downto 8)&datai(0)(5 downto 0);--

	--aer_in_dataint <= (255-aer_in_data(15 downto 8)) & '0' &(127-aer_in_data(7 downto 1));
	--aer_in_dataint <= aer_in_data(15 downto 8) & '0' & aer_in_data(7 downto 1) when aer_in_data(0)='1' else (others=>'0');--retina ini
	--aer_in_dataint <= aer_in_data(15 downto 8) & '0' & aer_in_data(7 downto 1) ;--retina ini
	aer_in_dataint <= aer_in_data(16 downto 1);-- & aer_in_data(7 downto 0) ;--retina ini
	
--ID1 <= x"01";	
TrackCell0: TrackCell 
	Generic map( BASEADDRESS => BASEADDRESS
			  )

--	GENERIC MAP(--PRCell
--	          --Mask =>  (others => '1'),-- 
--				 --Mask =>   "0001100000011000000110000001100000011000000110000001100000011000",--(others => '0'),-- vertical line
--				 --Mask => "0000000000000000000000001111111111111111000000000000000000000000",--(others => '0'),-- Horizontal line
--				 --Mask => "1100000011100000011100000011100000011100000011100000011100000011",--(others => '0'),-- diagonal \
--				 Mask => "0000001100000111000011100001110000111000011100001110000011000000",--(others => '0'),-- diagonal /
--				 FiringThreshold => (others => x"01"),--(x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"),
--				 MaxTime => 100000000,
--		       --VCell
--				 ITindex => "0011",--100ms x"000F4240")--10 ms		-- x"000186A0")-- 1ms x"001E8480")--20 ms     -- "01312D00") -- 200 ms x"00000064")--1 us x"000003E8")--10us x"00002710")--100us  -- x"0007A120")--5 ms  -- 
--				 VCellID => x"01",
--				 -- CMCell
--	 			 InitCenterMass => x"503B", -- 68,80 (third way from left
--				 RadixThreshold => "011", -- for increase the cluster area
--				 InitRadix => x"10")
	PORT MAP(
		CLK => clk,
		RST => reset,
		TRACKCELLID => x"01", --ID1,
 	   Addi => aer_in_dataint,
		REQi => saer_in_req_l,
		ACKi => taer_in_ack_l,
		Addo => Addr0,
		REQo => REQr0,
		ACKo => ACKr0,
		Addpo => datapo0,
		REQpo => reqpo0,
		ACKpo => ackpo0,
		Velocity => V0,
		ReqVel => NewVelReq0,
		AckVel => NewVelReq0,
		CMVel => CMT0,
		CenterMasspt => CM0,
		REQNDpt => CM0req,
		ACKNDpt => CM0ack,
		Active => tOT_active(0),
  	   spiWR => spiWR,
		spiADDRESS => spiADDRESS,
		spiDATA => spiDATA

	);
	CM0ack <= ACKND0;
	
	ACKND0 <= acki(0);
	diri(0) <= CM0(15 downto 8) & CM0(7 downto 0) & '0'; --CMint0;--(others => '1');  --
	datai(0) <= V0;--x"ff";--
	reqi(0)<= CM0req;--cmnd0;--
	
--	ID2 <= x"02";	

TrackCell1: TrackCell 
	Generic map( BASEADDRESS => BASEADDRESS
			  )

--	GENERIC MAP(--PRCell
--	          --Mask =>  (others => '1'),-- 
--				 Mask =>   "0001100000011000000110000001100000011000000110000001100000011000",--(others => '0'),-- vertical line
--				 --Mask => "0000000000000000000000001111111111111111000000000000000000000000",--(others => '0'),-- Horizontal line
--				 --Mask => "1100000011100000011100000011100000011100000011100000011100000011",--(others => '0'),-- diagonal \
--				 --Mask => "0000001100000111000011100001110000111000011100001110000011000000",--(others => '0'),-- diagonal /
--				 FiringThreshold => (others => x"01"),--(x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"),
--				 MaxTime => 100000000,
--		       --VCell
--				 ITindex => "0011",--100ms x"000F4240")--10 ms		-- x"000186A0")-- 1ms x"001E8480")--20 ms     -- "01312D00") -- 200 ms x"00000064")--1 us x"000003E8")--10us x"00002710")--100us  -- x"0007A120")--5 ms  -- 
--				 VCellID => x"02",
--				 -- CMCell
--	 			 InitCenterMass => x"504F", --48,80 for cars going up.
--				 RadixThreshold => "011", -- for increase the cluster area
--				 InitRadix => x"10")
	PORT MAP(
		CLK => clk,
		RST => reset,
		TRACKCELLID => x"02", --ID2,
		Addi => Addr0,
		REQi => REQr0,
		ACKi => ACKr0,
		Addo => Addr1,
		REQo => REQr1,
		ACKo => ACKr1,
		Addpo => datapo1,
		REQpo => reqpo1,
		ACKpo => ackpo1,
		Velocity => V1,
		ReqVel => NewVelReq1,
		AckVel => NewVelReq1,
		CMVel => CMT1,
		CenterMasspt => CM1,
		REQNDpt => CM1req,
		ACKNDpt => CM1ack,
		Active => tOT_active(1),
		spiWR => spiWR,
		spiADDRESS => spiADDRESS,
		spiDATA => spiDATA

	);
	CM1ack <= ACKND1;
	
	
	ACKND1 <= acki(1);
	diri(1) <= CM1(15 downto 8) & CM1(7 downto 0) &'0';--CMint0;--(others => '1');  --
	datai(1) <= V1;--x"ff";--
	reqi(1)<= CM1req;--cmnd0;--	
--	
--	
--	ID3 <= x"03";	

TrackCell2: TrackCell 
	Generic map( BASEADDRESS => BASEADDRESS
			  )

--	GENERIC MAP(--PRCell
--	          --Mask =>  (others => '1'),-- 
--				 --Mask =>   "0001100000011000000110000001100000011000000110000001100000011000",--(others => '0'),-- vertical line
--				 --Mask => "0000000000000000000000001111111111111111000000000000000000000000",--(others => '0'),-- Horizontal line
--				 Mask => "1100000011100000011100000011100000011100000011100000011100000011",--(others => '0'),-- diagonal \
--				 --Mask => "0000001100000111000011100001110000111000011100001110000011000000",--(others => '0'),-- diagonal /
----	          Mask => "1111111110000001100000011000000110000001100000011000000111111111",--(others => '0'),--
--				 FiringThreshold => (others => x"01"),--(x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"),
--				 MaxTime => 100000000,
--		       --VCell
--				 ITindex => "0011",--100ms x"000F4240")--10 ms		-- x"000186A0")-- 1ms x"001E8480")--20 ms     -- "01312D00") -- 200 ms x"00000064")--1 us x"000003E8")--10us x"00002710")--100us  -- x"0007A120")--5 ms  -- 
--				 VCellID => x"03",
--				 -- CMCell
--	 			 InitCenterMass => x"5066", -- 25,80 Fixed for Car tracking on highway pasadena jaer data
--				 RadixThreshold => "011", -- for increase the cluster area
--				 InitRadix => x"10")
	PORT MAP(
		CLK => clk,
		RST => reset,
		TRACKCELLID => x"03", --ID3,
		Addi => Addr1,
		REQi => REQr1,
		ACKi => ACKr1,
		Addo => Addr2,
		REQo => REQr2,
		ACKo => ACKr2,
		Addpo => datapo2,
		REQpo => reqpo2,
		ACKpo => ackpo2,
		Velocity => V2,
		ReqVel => NewVelReq2,
		AckVel => NewVelReq2,
		CMVel => CMT2,
		CenterMasspt => CM2,
		REQNDpt => CM2req,
		ACKNDpt => CM2ack,
		Active => tOT_active(2),
  	   spiWR => spiWR,
		spiADDRESS => spiADDRESS,
		spiDATA => spiDATA

	);
	CM2ack <= ACKND2;
	
	
	ACKND2 <= acki(2);
	diri(2) <= CM2(15 downto 8) & CM2(7 downto 0) &'0'; --CMint0;--(others => '1');  --
	datai(2) <= V2;--x"ff";--
	reqi(2)<= CM2req;--cmnd0;--		
--	
--	
--	
--	ID4 <= x"04";	

TrackCell3: TrackCell 
	Generic map( BASEADDRESS => BASEADDRESS
			  )

--	GENERIC MAP(--PRCell
--	          --Mask =>  (others => '1'),-- 
--				 --Mask =>   "0001100000011000000110000001100000011000000110000001100000011000",--(others => '0'),-- vertical line
--				 --Mask => "0000000000000000000000001111111111111111000000000000000000000000",--(others => '0'),-- Horizontal line
--				 Mask => "1100000011100000011100000011100000011100000011100000011100000011",--(others => '0'),-- diagonal \
--				 --Mask => "0000001100000111000011100001110000111000011100001110000011000000",--(others => '0'),-- diagonal /
----	          Mask => "1111111110000001100000011000000110000001100000011000000111111111",--(others => '0'),--
--				 FiringThreshold => (others => x"01"),--(x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"),
--				 MaxTime => 100000000,
--		       --VCell
--				 ITindex => "0011",--100ms x"000F4240")--10 ms		-- x"000186A0")-- 1ms x"001E8480")--20 ms     -- "01312D00") -- 200 ms x"00000064")--1 us x"000003E8")--10us x"00002710")--100us  -- x"0007A120")--5 ms  -- 
--				 VCellID => x"04",
--				 -- CMCell
--	 			 InitCenterMass => x"5005", -- 122,80 for cars going up.
--				 RadixThreshold => "011", -- for increase the cluster area
--				 InitRadix => x"05")
	PORT MAP(
		CLK => clk,
		RST => reset,
		TRACKCELLID => x"04", --ID4,
		Addi => Addr2,
		REQi => REQr2,
		ACKi => ACKr2,
		Addo => Addr3,
		REQo => REQr3,
		ACKo => ACKr3,
		Addpo => datapo3,
		REQpo => reqpo3,
		ACKpo => ackpo3,
		Velocity => V3,
		ReqVel => NewVelReq3,
		AckVel => NewVelReq3,
		CMVel => CMT3,
		CenterMasspt => CM3,
		REQNDpt => CM3req,
		ACKNDpt => CM3ack,
		Active => tOT_active(3),
  	   spiWR => spiWR,
		spiADDRESS => spiADDRESS,
		spiDATA => spiDATA

	);
	CM3ack <= ACKND3;
	
	
	ACKND3 <= acki(3);
	diri(3) <= CM3(15 downto 8) & CM3(7 downto 0) &'0'; --CMint0;--(others => '1');  --
	datai(3) <= V3;--x"ff";--
	reqi(3)<= CM3req;--cmnd0;--	
	
	Reqi(4) <= reqpo0;
	Reqi(5) <= reqpo1;
	Reqi(6) <= reqpo2;
	ackpo0  <= acki(4);
	ackpo1  <= acki(5);
	ackpo2  <= acki(6);
	diri(4)<= datapo0(15 downto 0) & '1';
	diri(5)<= datapo1(15 downto 0) & '1';
	diri(6)<= datapo2(15 downto 0) & '1';
	diri(7)<= datapo3(15 downto 0) & '1';
	Reqi(7) <= reqpo3;
	ackpo3  <= acki(7);

	
	-- Following lines allows to see BGAF output if all trackers are disabled, which is the initial state
	aer_out_data <=diro;
	aer_out_req_l <= Reqo;
	acko <= saer_out_ack_l;
	aer_in_ack_l <= taer_in_ack_l;
	
--	aer_out_data <= aer_in_data when (OT_active="0000") else diro;
--	aer_out_req_l <= aer_in_req_l when (OT_active="0000") else Reqo;
--	process (OT_active, saer_out_ack_l)
--	begin 
--	   if (OT_active="0000") then
--			aer_in_ack_l <= saer_out_ack_l;
--		else 	
--			acko <= saer_out_ack_l;
--		   aer_in_ack_l <= taer_in_ack_l;
--		end if;
--	end process;
--   acko <= saer_out_ack_l;	
	
	
	led (2) <= REQr1 and REQr0;
	led (1) <= REQr3 and REQr2;
	led (0) <= '1' when tOT_active="0000" else '0';
	
	OT_active <= tOT_active;
	
	Inst_AERArbriter: AERArbriter 
	GENERIC MAP (N => 8)
	PORT MAP(
		clk => clk,
		rst => reset,
		Reqi => Reqi,
		Acki => Acki,
		datai => datai,
		diri => diri,
		Reqo => Reqo,
		Acko => acko,
		datao => datao,
		diro => diro
	);
	
	
--dir <= (64-diro(13 downto 8))&(64-diro(5 downto 0));--CMint0(13 downto 8)&CMint0(5 downto 0);-----datai(0)(13 downto 8)&datai(0)(5 downto 0);--
--enable_in_buffers_l <= '0';
--enable_out_buffers_l <= '0';

syncronizer: process(RST_L, CLK)
begin
if (RST_L = '0') then
	--iaer_in_req_l <= '1'; 
	--saer_in_req_l <= '1';
	--iaer_out_ack_l <= '1';
	--saer_out_ack_l<='1';
	ID1<=x"00";
	ID2<=x"00";
	ID3<=x"00";
	ID4<=x"00";	
elsif(CLK'event and CLK = '1') then
	--iaer_in_req_l <= aer_in_req_l; 
	--saer_in_req_l <= iaer_in_req_l;
	--iaer_out_ack_l <= aer_out_ack_l; 
	--saer_out_ack_l <= iaer_out_ack_l;
	ID1<=x"01";
	ID2<=x"02";
	ID3<=x"03";
	ID4<=x"04";	
end if;
end process;
	iaer_in_req_l <= aer_in_req_l; 
	saer_in_req_l <= iaer_in_req_l;
	iaer_out_ack_l <= aer_out_ack_l; 
	saer_out_ack_l <= iaer_out_ack_l;


Vx <=datao(7 downto 0);
Vy <=datao(15 downto 8);
scale <=datao(23 downto 16);
cellid <= datao(31 downto 24);
--Vdir <= "00"&(63-diro(14 downto 9))&(63-diro(6 downto 1));
--Vdir <= '0'&(63-diro(14 downto 9))&'0'&(63-diro(6 downto 1));

Vdir <= (127-diro(14 downto 8)) & (127-diro(6 downto 0));

Inst_ExtRAMController: ExtRAMController PORT MAP(
		clk => clk50,
		rst => reset,
		req => reqo,
		Vdir => Vdir,
		Vx => Vx ,
		Vy => Vy,
		Scale => scale,
		CellID => cellid,
		ack => open,---
		data => data,
		dir => dir,
		ReadReq => ReadReq,
		ReadACK => ReadAck
	);

end Behavioral;

