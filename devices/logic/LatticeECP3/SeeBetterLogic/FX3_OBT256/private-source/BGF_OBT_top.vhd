----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:29:55 02/26/2014 
-- Design Name: 
-- Module Name:    BGF_OBT_top - Behavioral 
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

--library UNISIM;
--use UNISIM.VComponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity BGF_OBT_top is
    Port (
	 	  	  aer_in_data : in std_logic_vector(16 downto 0);
           aer_in_req_l : in std_logic;
           aer_in_ack_l : out std_logic;
			  aer_out_data : out std_logic_vector(16 downto 0);
           aer_out_req_l : out std_logic;
           aer_out_ack_l : in std_logic;
           rst_l : in std_logic;
           clk50 : in std_logic;
			  CLK : in  STD_LOGIC;
			  DATA : in  STD_LOGIC;
			  LATCH : in  STD_LOGIC;
           spi_data : out std_logic_vector(7 downto 0);
           spi_address : out std_logic_vector(7 downto 0);
           spi_wr : out std_logic;
		   OT_active: out std_logic_vector (3 downto 0);
		   BGAF_en: out std_logic;
		   WS2CAVIAR_en: out std_logic;
		   DAVIS_en: out std_logic;
			  LED: out std_logic_vector (2 downto 0)
			  );
end BGF_OBT_top;

architecture Behavioral of BGF_OBT_top is
--component SPI_SLAVE
    --Port ( CLK : in  STD_LOGIC;
           --RST : in  STD_LOGIC;
           ----STR : out  STD_LOGIC;
           --NSS : in  STD_LOGIC;
           --SCLK : in  STD_LOGIC;
           --MOSI : in  STD_LOGIC;
           --MISO : out  STD_LOGIC;
		   --WR: out STD_LOGIC;
		   --ADDRESS: out STD_LOGIC_VECTOR(7 downto 0);
		   --DATA_OUT: out STD_LOGIC_VECTOR(7 downto 0));
--end component;

component RetinaFilter
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
		   BGAF_en: out std_logic;
		   WS2CAVIAR_en: out std_logic;
		   DAVIS_en: out std_logic;
		alex: out std_logic_vector (13 downto 0);
		   spiWR: in STD_LOGIC;
		   spiADDRESS: in STD_LOGIC_VECTOR(7 downto 0);
		   spiDATA: in STD_LOGIC_VECTOR(7 downto 0));
end component;
component ObjectTracker

	Generic ( BASEADDRESS : std_logic_vector (7 downto 0) := (others => '0')
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
end component;

component BUF
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;

signal spiWR: std_logic;
signal spiADDRESS: std_logic_vector (7 downto 0);
signal spiDATA: std_logic_vector (7 downto 0);

signal taer_out_req_l, req_bf2ot, ack_bf2ot, kk1, kk2, tack_bf2ot: std_logic;
signal aer_bf2ot, aer_in_datat: std_logic_vector (16 downto 0);
signal aer_bf2ot_i,aer_out_datat, taer_out_datat: std_logic_vector (16 downto 0);

signal rst_lb, rst: std_logic;
signal tOT_active: std_logic_vector (3 downto 0);

signal fx3_data: std_logic_vector (15 downto 0);
signal dclk, d1clk, d2clk: std_logic;
signal dlatch, d1latch, d2latch: std_logic;
signal ddata, d1data: std_logic;
signal dclk_pulse: std_logic;
signal BGAFen: std_logic;
signal alex: std_logic_vector (13 downto 0);
begin

rst <= not rst_l;
--B_SPI: SPI_SLAVE
--port map (
			  --CLK => clk50,
           --RST => rst_l,
           --NSS => NSS,
           --SCLK => SCLK,
           --MOSI => MOSI,
           --MISO => MISO,
			  --WR => spiWR,
			  --ADDRESS => spiADDRESS,
			  --DATA_OUT => spiDATA);
			  
BSPInew: process (clk50, rst_l)
begin
  if (rst_l = '1') then
     fx3_data <= (others=>'0');
	 dclk <= '0';
	 dlatch <= '0';
	 d1clk <= '0';
	 d1latch <= '0';
	 d2clk <= '0';
	 d2latch <= '0';
	 ddata <= '0';
	 d1data <= '0';
	 spiWR <= '0';
	 dclk_pulse <= '0';
--	 spiADDRESS <= (others => '0');
--	 spiDATA <= (others =>'0');
  elsif (clk50'event and clk50='1') then
     d2clk <= CLK;
	 d2latch <= LATCH;
     d1clk <= d2CLK;
	 d1latch <= d2LATCH;
     dclk <= d1CLK;
	 dlatch <= d1LATCH;
	 d1data <= DATA;
	 ddata <= d1data;
	 spiWR <= '0';
	 dclk_pulse <= '0';
	 if (d1CLK='1'and dclk='0') then
	    fx3_data  <= fx3_data(14 downto 0) & dDATA;
		dclk_pulse <= '1';
	 end if;
	 if (d1LATCH = '1' and dlatch='0') then
	    spiWR <= '1';
--		spiADDRESS <= fx3_data (15 downto 8);
--		spiDATA <= fx3_data (7 downto 0);
	 end if;
  end if;
end process;
		spiADDRESS <= fx3_data (15 downto 8);
		spiDATA <= fx3_data (7 downto 0);-- & dDATA & dclk_pulse;


aer_in_datat <= aer_in_data; -- (16 downto 9) & aer_in_data(7 downto 0) when (aer_in_data(8)='0') else (others=>'0');
B_RetinaFilter: RetinaFilter 
generic map (BASEADDRESS => x"80")
port map (
	 	   aer_in_data => aer_in_datat,
           aer_in_req_l => aer_in_req_l,
           aer_in_ack_l => aer_in_ack_l,
		   aer_out_data => aer_bf2ot,
           aer_out_req_l => req_bf2ot,
           aer_out_ack_l => ack_bf2ot,
           rst_l => rst,
           clk50 => clk50,
		   BGAF_en => BGAFen,
		   WS2CAVIAR_en => WS2CAVIAR_en,
		   DAVIS_en => DAVIS_en,
		   alex => alex,
		   spiWR => spiWR,
		   spiADDRESS => spiADDRESS,
		   spiDATA => spiDATA);
aer_bf2ot_i <= aer_bf2ot; --(16 downto 9) & aer_bf2ot(7 downto 0) when (aer_bf2ot(8)='1') else (others=>'0'); -- and aer_bf2ot(16)='0')
aer_out_datat <= aer_bf2ot_i when (tOT_active="0000") else taer_out_datat;  --
																			--it was ot_i
aer_out_req_l <= req_bf2ot when (tOT_active="0000") else taer_out_req_l;
ack_bf2ot <= aer_out_ack_l when (tOT_active="0000") else tack_bf2ot;

B_ObjectTracker: ObjectTracker
generic map (BASEADDRESS => x"00")
port map (
		   aer_in_data => aer_bf2ot_i,
           aer_in_req_l => req_bf2ot,
           aer_in_ack_l => tack_bf2ot,
		   aer_out_data => taer_out_datat,
           aer_out_req_l => taer_out_req_l,
           aer_out_ack_l => aer_out_ack_l,
           rst_l => rst,
           clk50 => clk50,
		   OT_active => tOT_active,
		   spiWR => spiWR,
		   spiADDRESS => spiADDRESS,
		   spiDATA => spiDATA,
		   LED => LED);
			  
aer_out_data <= aer_out_datat; -- when (BGAFen='1') else aer_in_data;  --(15 downto 8) & "1" & aer_out_datat(7 downto 0) 
BGAF_en <= BGAFen;
OT_active <= tOT_active;

spi_wr <= spiWR;
spi_address <= spiADDRESS;
spi_data <= spiDATA (7 downto 2) & dDATA & dclk_pulse;

end Behavioral;

