----------------------------------------------------------------------------------
-- Company: University of Seville & INI
-- Engineer: Alejandro Linares & Paco Gomez
-- 
-- Create Date:    11:31:39 03/10/2010 
-- Design Name: 
-- Module Name:    ExtRAMController - Behavioral 
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

entity ExtRAMController is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           --VCell inteface
			  req : in  STD_LOGIC;
           Vdir : in  STD_LOGIC_VECTOR (13 downto 0);
           Vx : in  STD_LOGIC_VECTOR (7 downto 0);
           Vy : in  STD_LOGIC_VECTOR (7 downto 0);
           Scale : in  STD_LOGIC_VECTOR (7 downto 0);
           CellID : in  STD_LOGIC_VECTOR (7 downto 0);
           ack : out  STD_LOGIC;
			  -- USB State Machine interface
           data : out  STD_LOGIC_VECTOR (31 downto 0);
           dir : in  STD_LOGIC_VECTOR (13 downto 0);
           ReadReq : in  STD_LOGIC;
           ReadACK : out  STD_LOGIC);
			  -- SRAM interface
		     --sram_oe_l : out std_logic;
		     --sram_we_l : out std_logic_vector(3 downto 0);
		     --sram_address : out std_logic_vector(13 downto 0 );
		     --sram_data : inout std_logic_vector( 31 downto 0 ));
end ExtRAMController;

architecture Behavioral of ExtRAMController is

type ExtRAMConStates is (idle, WriteRAM, ReadRAM_A, ReadRAM_B,EraseRAM);
signal CState , NState : ExtRAMConStates;
signal dataaux :std_logic_vector(31 downto 0);

  constant ADDR_WIDTH : integer :=14;
  constant DATA_WIDTH : integer := 32; 

  type tram_ot is array (2**(ADDR_WIDTH-1)-1 downto 0) of std_logic_vector (DATA_WIDTH-1 downto 0);
  signal ram_ot: tram_ot;
  signal sram_data : std_logic_vector(31 downto 0 );
begin

sec: process (clk ,rst)
begin
	if rst='1' then
		CState<= idle;
	elsif rising_edge(clk) then
		CState <= NState;
	end if;
end process;





Comb: process (Vx, Vy, Scale, CellID, Vdir, dir,CState, Req, ReadReq)
begin
	case Cstate is
	when idle =>
		if Req='0' then
			NState <= WriteRAM;
		elsif ReadReq = '0' then
			Nstate <= ReadRAM_A;
		else
			Nstate <= idle;
		end if;
		
		ack <= '1';
		ReadAck <= '1';
		--sram_oe_l <= '1';
	   --sram_data <= Vx&Vy&Scale&CellID;--x"0a"&x"0b"&x"0c"&x"0d";--
	   --sram_address <= vdir;
		--sram_we_l <= (others =>'1');
		
--		dataaux <= (others =>'1');
	when WriteRAM =>
		if Req = '1' then 
			NState <= idle;
		else 
			NState <= WriteRAM;
		end if;
		
		ack <= '0';
		ReadAck <= '1';
		--sram_oe_l <= '1';
	   --sram_data <= Vx&Vy&Scale&CellID;--x"0a"&x"0b"&x"0c"&x"0d";--
	   --sram_address <= Vdir;
		--sram_we_l <= (others =>'0');
--		dataaux <= dataaux;
	when ReadRAM_A =>
		
			NState <= ReadRAM_b;
		
		
		ack <= '1';
		ReadAck <= '1';
--		sram_oe_l <= '0';
--	   sram_data <= (others =>'Z');
--	   sram_address <= dir;
--		sram_we_l <= (others =>'1');
		
--		dataaux <= x"0a"&x"0b"&x"0c"&x"0d";--sram_data;--
		
		when ReadRAM_B =>
		
			NState <= EraseRAM;
			
		ack <= '1';
		ReadAck <= '0';
--		sram_oe_l <= '0';
--	   sram_data <= (others =>'Z');
--	   sram_address <= dir;
--		sram_we_l <= (others =>'1');
		
--		dataaux <= x"0a"&x"0b"&x"0c"&x"0d";--dataaux;--sram_data;--
	
	when EraseRAM =>
		if ReadReq = '1' then
			NState <= idle; 
		else 
			NState <= EraseRAM;
		end if;
				
		ack <= '1';
--		sram_oe_l <= '1';
--	   sram_data <= (others =>'0');
--	   sram_address <= dir;
--		sram_we_l <= (others =>'0');
		ReadAck <= '0';
	--	dataaux<=dataaux;
				
	end case;
end process;

sal: process (clk, rst)
begin
	if (rst='1') then
	   dataaux <= (others => '0');
	elsif rising_edge(clk) then
		if CState=ReadRAM_B then
			--sram_data <= ram_ot(conv_integer("00"&dir));

			dataaux <= ram_ot(conv_integer("00"&dir)); --sram_data;--x"0a"&x"0b"&x"0c"&x"0d";--dataaux;--
		else
			dataaux <= dataaux;
		end if;
		if CState=WriteRAM then
				ram_ot(conv_integer("00"&Vdir)) <= Vx&Vy&Scale&CellID;
		elsif CState=EraseRAM then
				ram_ot (conv_integer("00"&dir))<=(others=>'0');
		end if;
	end if;
end process;
			
data <= dataaux;
		
end Behavioral;

