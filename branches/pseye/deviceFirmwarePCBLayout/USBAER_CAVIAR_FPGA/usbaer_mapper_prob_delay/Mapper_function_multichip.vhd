library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Mapper_function is
    Port ( CLK : in std_logic;
           RST_N : in std_logic;
           ENABLE_N : in std_logic;
           AER_IN_DATA : in std_logic_vector(15 downto 0);
           AER_IN_REQ_L : in std_logic;
           AER_IN_ACK_L : out std_logic;
           AER_OUT_DATA : out std_logic_vector(15 downto 0);
           AER_OUT_REQ_L : out std_logic;
           AER_OUT_ACK_L : in std_logic;
           RAM_ADDRESS : out std_logic_vector(18 downto 0);
           RAM_DATA : in std_logic_vector(31 downto 0);
           RAM_OE : out std_logic;
           RAM_WE : out std_logic_vector(3 downto 0);
           LED : out std_logic_vector(2 downto 0)
			);
end Mapper_function;

architecture Behavioral of Mapper_function is
type states is (IDLE, WAIT_REQ_L, WAIT_REQ_H, READ_RAM, SEND_EVENT, SUBE_ACK );
signal CS,NS: states;

begin

SYNC: process(RST_N, enable_n, CLK)
begin
	if (RST_N = '0' or ENABLE_N = '1') then
		CS <= IDLE;
	elsif(CLK'event and CLK ='1') then
		CS <= NS;
	end if;
end process;


COMB: process(CS, AER_IN_DATA, AER_IN_REQ_L, AER_OUT_ACK_L, RAM_DATA)
begin
case CS is
	when IDLE => 
						NS <= WAIT_REQ_L;
						AER_IN_ACK_L <= '1';
						AER_OUT_REQ_L <= '1';
						AER_OUT_DATA <= (others =>'Z');
						RAM_ADDRESS <= (others =>'Z');
						RAM_OE <= 'Z';
						RAM_WE <= "ZZZZ";
						led <= "000";

	when WAIT_REQ_L => 
						if (AER_IN_REQ_L = '0') then
							NS <= WAIT_REQ_H;
						else
							NS <= WAIT_REQ_L;
						end if;
						AER_IN_ACK_L <= '1';
						AER_OUT_REQ_L <= '1';
						AER_OUT_DATA <= (others =>'0');
						RAM_ADDRESS <= "000" & AER_IN_DATA;
						RAM_OE <= '0';
						RAM_WE <= "1111";
						led <= "001";

	when WAIT_REQ_H =>
						if	(AER_IN_REQ_L = '0') then
							NS <= WAIT_REQ_H;
						else
							NS <= READ_RAM;
						end if;
						AER_IN_ACK_L <= '0';
						AER_OUT_REQ_L <= '1';
						AER_OUT_DATA <= (others =>'0');
						RAM_ADDRESS <= "000" & AER_IN_DATA;;
						RAM_OE <= '0';
						RAM_WE <= "1111";
						led <= "010";

	when READ_RAM =>
						if (AER_OUT_ACK_L = '0') then
							NS <= READ_RAM;
						else
							NS <= SEND_EVENT;
						end if;
						AER_IN_ACK_L <= '0';
						AER_OUT_REQ_L <= '1';	
						AER_OUT_DATA <= RAM_DATA(15 downto 0);
						RAM_ADDRESS <= "000" & AER_IN_DATA;
						RAM_OE <= '0';
						RAM_WE <= "1111";
						led <= "011";

	when SEND_EVENT =>
						if (AER_OUT_ACK_L = '1') then
							NS <= SEND_EVENT;
						else
							NS <= SUBE_ACK;
						end if;
						AER_IN_ACK_L <= '0';
						AER_OUT_REQ_L <= '0';
						AER_OUT_DATA <= RAM_DATA(15 downto 0);
						RAM_ADDRESS <= "000" & AER_IN_DATA;
						RAM_OE <= '0';
						RAM_WE <= "1111";
						led <= "100";

	when SUBE_ACK =>						-- Tambien se podria comprobar ACK_OUT aqui
						NS <= WAIT_REQ_L;
						AER_IN_ACK_L <= '1';
						AER_OUT_REQ_L <= '1';
						AER_OUT_DATA <= (others =>'0');
						RAM_ADDRESS <= "000" & AER_IN_DATA;
						RAM_OE <= '0';
						RAM_WE <= "1111";
						led <= "101";

	end case;
end process;


end Behavioral;
