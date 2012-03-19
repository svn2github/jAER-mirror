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
type states is (IDLE,WAIT_EVENT, PROCESA_EVENT, SEND_EVENT, RECEIVED_ACK );
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
	when IDLE => NS <= WAIT_EVENT;
					 RAM_ADDRESS <= (others =>'Z');
					 RAM_OE <= 'Z';
					 RAM_WE <= "ZZZZ";
					 AER_OUT_REQ_L <= '1';
					 AER_OUT_DATA <= (others =>'Z');
					 AER_IN_ACK_L <= '1';

	when WAIT_EVENT => 
					if (AER_IN_REQ_L = '0') then
						NS <= PROCESA_EVENT;
					else
						NS <= WAIT_EVENT;
					end if;
					RAM_ADDRESS <= "000" & AER_IN_DATA;
					RAM_OE <= '0';
					RAM_WE <= "1111";
					AER_OUT_REQ_L <= '1';
					AER_OUT_DATA <= (others =>'Z');
					AER_IN_ACK_L <= '1';

	when PROCESA_EVENT =>								  -- Estos dos estados creo que se pueden mezclar
					NS <= SEND_EVENT;
					RAM_ADDRESS <= "000" & AER_IN_DATA;
					RAM_OE <= '0';
					RAM_WE <= "1111";
					AER_OUT_REQ_L <= '1';
					AER_OUT_DATA <= RAM_DATA(15 downto 0);
					AER_IN_ACK_L <= '1';	

	when SEND_EVENT =>
					if (AER_OUT_ACK_L = '0') then
						NS <= RECEIVED_ACK;
					else
						NS <= SEND_EVENT;
					end if;
					RAM_ADDRESS <= "000" & AER_IN_DATA;
					RAM_OE <= '0';
					RAM_WE <= "1111";
					AER_OUT_REQ_L <= '0';
					AER_OUT_DATA <= RAM_DATA(15 downto 0);
					AER_IN_ACK_L <= '1';	

	when RECEIVED_ACK =>
					if (AER_IN_REQ_L = '0') then
						NS <= RECEIVED_ACK;
					else
						NS <= WAIT_EVENT;
					end if;
					RAM_ADDRESS <= "000" & AER_IN_DATA;
					RAM_OE <= '0';
					RAM_WE <= "1111";
					AER_OUT_REQ_L <= '1';
					AER_OUT_DATA <= (others =>'Z');
					AER_IN_ACK_L <= '0';	
	end case;
end process;

LED (2)<= '0';
LED (1) <= AER_IN_REQ_L;
LED(0) <= AER_OUT_ACK_L;

end Behavioral;
