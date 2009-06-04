library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity program_ram is
    Port ( RST_N : in std_logic;
           CLK : in std_logic;
           ENABLE_N : in std_logic;
           DATA_VALID : in std_logic;
           DATA : in std_logic_vector(7 downto 0);
           BUSY : out std_logic;
           RAM_ADDRESS : out std_logic_vector(18 downto 0);
           RAM_DATA : inout std_logic_vector(31 downto 0);
           RAM_OE : out std_logic;
           RAM_WE : out std_logic_vector(3 downto 0);
           LED : out std_logic_vector(2 downto 0));
end program_ram;

architecture Behavioral of program_ram is
type states is (IDLE,WAIT_VALID, WAIT_NOVALID, WRITE, CHECK );
signal CS,NS: states;

signal DATA32: std_logic_vector(31 downto 0);
signal ADDR: std_logic_vector(18 downto 0);
signal nibble: integer range 0 to 3;
signal incrementa: std_logic;

begin

SYNC: process(RST_N, enable_n, CLK)
	begin
	if (RST_N = '0' or ENABLE_N = '1') then
		CS <= IDLE;
		nibble<=0;
		ADDR <= (others =>'0');
		DATA32 <= (others =>'0');
	elsif(CLK'event and CLK ='1') then
		CS <= NS;
		if (CS = CHECK and incrementa = '0') then
			LED(2) <= '1';
		else
			LED(2) <= '0';
		end if;
		if (incrementa='1') then
			ADDR <= ADDR + 1;
		elsif (CS = WAIT_VALID and DATA_VALID = '1') then
			if (nibble = 3) then
				nibble <= 0;
			else
				nibble <= nibble + 1;
			end if;
			case nibble is
				when 0 => DATA32(7 downto 0) <= DATA;
				when 1 => DATA32(15 downto 8) <= DATA;
				when 2 => DATA32(23 downto 16) <= DATA;
				when 3 => DATA32(31 downto 24) <= DATA;
			end case;
		end if;
	end if;
end process;

COMB: process(cs,enable_n, DATA_VALID, ADDR, nibble, DATA32, RAM_DATA)
begin
	case CS is
		when IDLE =>  
					NS <= WAIT_VALID;
					BUSY <= '1';			-- No acepta nada mientras este en reposo
					RAM_DATA <= (others =>'Z');
					RAM_OE <= 'Z';
					RAM_WE <= "ZZZZ";
					incrementa <= '0';  
					LED(1 downto 0) <= "00";
	
		when WAIT_VALID =>
					if (DATA_VALID='0') then
						NS <= WAIT_VALID;
					elsif (nibble = 3) then
						NS <= WRITE;
					else
						NS <= WAIT_NOVALID;
					end if;
					BUSY <= '0';			
					RAM_DATA <= (others =>'Z');
					RAM_OE <= '1';
					RAM_WE <= "1111";
					incrementa <= '0';
					LED(1 downto 0) <= "00";

		when WAIT_NOVALID =>
					if (DATA_VALID = '1') then
						NS <= WAIT_NOVALID;
					else
						NS <= WAIT_VALID;
					end if;
					BUSY <= '0';			
					RAM_DATA <= (others =>'Z');
					RAM_OE <= '1';
					RAM_WE <= "1111";
					incrementa <= '0';
					LED(1 downto 0) <= "01";

		when WRITE =>
					NS <= CHECK;
					BUSY <= '1';			
					RAM_DATA <= DATA32;
					RAM_OE <= '1';
					RAM_WE <= "0000";
					incrementa <= '0';
					LED(1 downto 0) <= "10";

		when CHECK =>
					if (RAM_DATA = DATA32) then
						NS <= WAIT_NOVALID;
						incrementa <= '1';
					else
						NS <= WRITE;
						incrementa <= '0';
					end if;
					BUSY <= '1';			
					RAM_DATA <= (others =>'Z');
					RAM_OE <= '0';
					RAM_WE <= "1111";
					LED(1 downto 0) <= "11";

	end case;
end process;

RAM_ADDRESS <= ADDR when ENABLE_N = '0' else (others =>'Z');



end Behavioral;
