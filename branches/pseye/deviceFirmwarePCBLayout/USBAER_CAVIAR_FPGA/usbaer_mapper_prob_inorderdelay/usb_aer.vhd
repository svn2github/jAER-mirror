--Test Mapper
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
 library UNISIM;
use UNISIM.vcomponents.all;

entity usb_aer is
	Port ( 
		clk : in std_logic;
		rst_l : in std_logic;
		led : out std_logic_vector( 2 downto 0 );

		-- AER input
		aer_in_data : in std_logic_vector( 15 downto 0 );
		aer_in_req_l : in std_logic;
		aer_in_ack_l : out std_logic;

		-- AER output
		aer_out_req_l : out std_logic;
		aer_out_ack_l : in std_logic;
		aer_out_data : out std_logic_vector( 15 downto 0 );

		-- SRAM interface
		sram_oe_l : out std_logic;
		sram_we_l : out std_logic_vector(3 downto 0);
		address : out std_logic_vector( 18 downto 0 );
		sram_data : inout std_logic_vector( 31 downto 0 );
		
		-- Micro interface
		micro_vdata : in std_logic;
		micro_prog : in std_logic;
		micro_control: in std_logic;	-- Aux0 en sch
	 	micro_rw: in std_logic;
		micro_busy:out std_logic;
		micro_data:	inout std_logic_vector( 7 downto 0 );

		-- Other control lines
		enable_out_buffers_l : out std_logic;
		enable_in_buffers_l: out std_logic
	);
end usb_aer;

architecture Behavioral of usb_aer is



component CLKDLL
 port (
   CLK0 : out std_logic;
   CLK90 : out std_logic;
   CLK180 : out std_logic;
   CLK270 : out std_logic;
   CLK2X : out std_logic;
   CLKDV : out std_logic;
   LOCKED : out std_logic;
   CLKIN : in std_logic;
   CLKFB : in std_logic;
   RST : in std_logic
 );
end component;

component BUFG
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;

component IBUFG
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;



COMPONENT program_ram
    PORT ( RST_N : in std_logic;
           CLK : in std_logic;
           ENABLE_N : in std_logic;
           DATA_VALID : in std_logic;
           DATA : inout std_logic_vector(7 downto 0);
           BUSY : out std_logic;
			  CONTROL: in std_logic;
			  READWRITE: in std_logic;
           RAM_ADDRESS : out std_logic_vector(18 downto 0);
           RAM_DATA : inout std_logic_vector(31 downto 0);
           RAM_OE : out std_logic;
           RAM_WE : out std_logic_vector(3 downto 0);
			  DELAY_TIME: out std_logic_vector (15 downto 0); -- In x10 microseconds
			  RNG: out std_logic_vector (15 downto 0); -- In x10 microseconds
           LED : out std_logic_vector(2 downto 0));
end component;

COMPONENT Mapper_function
    PORT ( CLK : in std_logic;
           RST_N : in std_logic;
           ENABLE_N : in std_logic;
			  BUSY : out std_logic;
           AER_IN_DATA : in std_logic_vector(15 downto 0);
           AER_IN_REQ_L : in std_logic;
           AER_IN_ACK_L : out std_logic;
           AER_OUT_DATA : out std_logic_vector(15 downto 0);
           AER_OUT_REQ_L : out std_logic;
           AER_OUT_ACK_L : in std_logic;
           RAM_ADDRESS : out std_logic_vector(18 downto 0);
           RAM_DATA : inout std_logic_vector(31 downto 0);
           RAM_OE : out std_logic;
           RAM_WE : out std_logic_vector(3 downto 0);
			  DELAY_TIME: in std_logic_vector (15 downto 0); -- In x10 microseconds
			  RNG: in std_logic_vector (15 downto 0); -- In x10 microseconds
           LED : out std_logic_vector(2 downto 0)
			);
end component;


signal mled: std_logic_vector(2 downto 0);
signal pled: std_logic_vector(2 downto 0);
signal not_micro_prog: std_logic;
signal direccion: std_logic_vector(18 downto 0);


signal imicro_prog, smicro_prog: std_logic;
signal imicro_vdata, smicro_vdata: std_logic;
signal imicro_control, smicro_control: std_logic;
signal imicro_rw, smicro_rw: std_logic;
signal iaer_in_req_l,  saer_in_req_l: std_logic;
signal iaer_out_ack_l, saer_out_ack_l: std_logic;

signal miCLK: std_logic;
signal Clk50int ,Clk100,Clk100int, clk0b: std_logic;

signal counter: std_logic_vector(23 downto 0);

signal mapper_busy, enable_n_progam: std_logic;

signal delay_time,rng: std_logic_vector (15 downto 0);


attribute box_type : string; 
attribute box_type of IBUFG : component is "black_box"; 

--attribute box_type : string; 
attribute box_type of BUFG : component is "black_box"; 

--attribute box_type : string; 
attribute box_type of CLKDLL : component is "black_box"; 

begin


--bufg1 : BUFG port map (O => CLK100, I => CLK100int);

clk50buf : IBUFG port map (I => clk, O => clk50int);
--clk50int <= clk;

--DLL1 : CLKDLL port map (CLKIN => Clk50int, CLKFB => Clk100int, RST => RST_L, CLK0 => OPEN,			   --Reset alto o bajo?
--	       		CLK90 => OPEN, CLK180 => OPEN, CLK270 => OPEN, CLK2X => Clk0B, 
--			CLKDV => OPEN, LOCKED => OPEN);

--bufg0 : BUFG port map (O => Clk100int, I => Clk0B);

miCLK <= CLK50int;--100;


 
ControlRAM: program_ram PORT MAP (
 				RST_N 	=> RST_L,
       		CLK 		=> miCLK,
				ENABLE_N => enable_n_progam,
				DATA_VALID => smicro_vdata,
				DATA 		=> micro_data,
				BUSY 		=> micro_busy,
				CONTROL  => smicro_control,
				READWRITE =>smicro_rw,
				RAM_ADDRESS => address,
				RAM_DATA => sram_data,
				RAM_OE 	=> sram_oe_l,
				RAM_WE 	=> sram_we_l,
				DELAY_TIME => delay_time,
				RNG => rng,
				LED 		=> pled
				);

Mapper: mapper_function PORT MAP(
				CLK 		=> miCLK,
				RST_N 	=> RST_L,
				ENABLE_N => smicro_prog,
				BUSY => mapper_busy,
				AER_IN_DATA => AER_IN_DATA,
				AER_IN_REQ_L => sAER_IN_REQ_L,
				AER_IN_ACK_L => AER_IN_ACK_L,
				AER_OUT_DATA => AER_OUT_DATA,
				AER_OUT_REQ_L => AER_OUT_REQ_L,
				AER_OUT_ACK_L => sAER_OUT_ACK_L,
				RAM_ADDRESS => address,
				RAM_DATA => sram_data,
				RAM_OE 	=> sram_oe_l,
				RAM_WE	=> sram_we_l,
				DELAY_TIME => delay_time,
				RNG => rng,
				LED => mled
				);

syncronizer: process(RST_L, miCLK)
begin
if (RST_L = '0') then
	imicro_vdata <= '0';
	smicro_vdata <= '0';
	imicro_rw <= '0';
	smicro_rw <= '0';
	imicro_prog <= '0';
	smicro_prog <= '0';
	imicro_control <= '0';
	smicro_control <= '0';
	iaer_in_req_l <= '0'; 
	saer_in_req_l <= '0';
	iaer_out_ack_l <= '0';
	saer_out_ack_l	<= '0';
	counter <= (others =>'0');
elsif(miCLK'event and miCLK = '1') then
 	imicro_vdata <= micro_vdata;
	smicro_vdata <= imicro_vdata;
	imicro_rw <= micro_rw;
	smicro_rw <= imicro_rw;
	imicro_control <= micro_control;
	smicro_control <= imicro_control;
 	imicro_prog <= micro_prog;
	smicro_prog <= imicro_prog;
	iaer_in_req_l <= aer_in_req_l; 
	saer_in_req_l <= iaer_in_req_l;
	iaer_out_ack_l <= aer_out_ack_l;
	saer_out_ack_l	<= iaer_out_ack_l;
	counter <= counter + 1;
end if;
end process;

divisor: process(RST_L, miCLK)
begin
if (RST_L ='0') then
	counter <= (others =>'0');
elsif(miCLK'event and miCLK='1') then
	counter <= counter +1;
end if;
end process;




led(2) <= pled(2) when smicro_prog='1' else mled(2);
led(1 downto 0) <= pled(1 downto 0) when smicro_prog ='1' else mled(1 downto 0);


enable_out_buffers_l <= '0';
enable_in_buffers_l <= '0';
not_micro_prog <= not smicro_prog;
enable_n_progam <= not_micro_prog;-- or mapper_busy;

end Behavioral;
