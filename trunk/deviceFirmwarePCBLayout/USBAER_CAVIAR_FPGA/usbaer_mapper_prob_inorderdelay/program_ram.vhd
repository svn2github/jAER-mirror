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
end program_ram;

architecture Behavioral of program_ram is
type states is (IDLE,WAIT_VALID, WRITE_ADDR, WRITE, CHECK, READ, ESTABILIZA, ESTABILIZA2 );
signal CS,NS: states;

signal ADDR: std_logic_vector(18 downto 0);
signal LDATA: std_logic_vector(7 downto 0);
signal nibble: integer range 0 to 3;
signal nibble_address: integer range 0 to 7;

signal incrementa: std_logic;

begin
RAM_ADDRESS <= ADDR when CS /= IDLE else (others =>'Z');
SYNC: process(RST_N, enable_n, CLK)
	begin
	if (RST_N = '0' or ENABLE_N = '1') then
		CS <= IDLE;
		nibble<=0;
		nibble_address <=0;
		ADDR <= (others =>'0');
		LDATA <= (others =>'0');
	elsif RST_N='0' then
		DELAY_TIME <= x"03E8";
		RNG <= x"03E8";	
	elsif(CLK'event and CLK ='1') then

		
		CS <= NS;
		if (CS = WRITE_ADDR and DATA_VALID='1') then
			case nibble_address is 
				when 0 => ADDR(7 downto 0) <= DATA;
				when 1 => ADDR(15 downto 8) <= DATA;
				when 2 => ADDR(18 downto 16) <= DATA (2 downto 0);
				when 3 => DELAY_TIME(7 downto 0) <= DATA;
				when 4 => DELAY_TIME(15 downto 8) <= DATA;
				when 5 => RNG(7 downto 0) <= DATA;
				when 6 => RNG(15 downto 8) <= DATA;
				when others => NULL;
			end case;
		end if;
		if (CS = WAIT_VALID and DATA_VALID ='1') then
			LDATA <= DATA;
		end if;

		if (incrementa='1' and (CS = CHECK or CS=READ)) then
			if (nibble = 3) then
			  		nibble <= 0	;
				 	ADDR <= ADDR +1;
			else
			  nibble <= nibble + 1;	-- Incrementa hasta 3, pero no mas
			end if;
		end if;
		if (incrementa = '1' and CS = WRITE_ADDR and nibble_address <7) then
				nibble_address <= nibble_address+1;
		end if;
	end if;
end process;

COMB: process(cs,enable_n, DATA_VALID, ADDR, nibble, nibble_address, RAM_DATA, CONTROL, READWRITE)
variable rdata: std_logic_vector(7 downto 0);
begin
	case nibble is
		when 0 => rdata := ram_data(7	downto 0);
		when 1 => rdata := ram_data(15 downto 8);
		when 2 => rdata := ram_data(23 downto 16);
		when 3 => rdata := ram_data(31 downto 24);
	end case;
	case CS is
		when IDLE =>  
					NS <= WAIT_VALID;
					BUSY <= '1';			-- No acepta nada mientras este en reposo
					RAM_DATA <= (others =>'Z');
					RAM_OE <= 'Z';
					RAM_WE <= "ZZZZ";
					DATA <= (others =>'Z');
					incrementa <= '0';  
					LED(1 downto 0) <= "01";

	
		when WAIT_VALID =>
					if (DATA_VALID='0') then
						NS <= WAIT_VALID;
					elsif (CONTROL = '1') then
						NS <= WRITE_ADDR;
					elsif (READWRITE = '1') then
						NS <= READ;
					else
						NS <= WRITE;
					end if;
					BUSY <= '0';			
					RAM_DATA <= (others =>'Z');
					RAM_OE <= '1';
					RAM_WE <= "1111";
					DATA <= (others =>'Z');
					incrementa <= '0';
					LED(1 downto 0) <= "00";

		when WRITE =>
					if (DATA_VALID = '1') then
						NS <= WRITE;
					else
						NS <= ESTABILIZA;
					end if;
					BUSY <= '1';
					RAM_DATA <= DATA & DATA & DATA & DATA;	
					case nibble is
						when 0=> RAM_WE <= "1110";	
						when 1=> RAM_WE <= "1101";	
						when 2=> RAM_WE <= "1011";	
						when 3=> RAM_WE <= "0111";	
					end case;
					RAM_OE <= '1';
					DATA <= (others =>'Z');
					incrementa <= '0';
					LED(1 downto 0) <= "11";

		when ESTABILIZA =>
					--NS <= WAIT_VALID;
					NS <= ESTABILIZA2;
					incrementa <= '0';
					BUSY <= '1';			
					RAM_DATA <= DATA & DATA & DATA & DATA;	
					RAM_OE <= '1';
					RAM_WE <= "1111";
					DATA <= (others =>'Z');
					LED(1 downto 0) <= "11";

		when ESTABILIZA2 => 
					NS <= CHECK;
					--NS <= WAIT_VALID;
					incrementa <= '0';

					BUSY <= '1';			
					RAM_DATA <= (others =>'Z');	
					RAM_OE <= '0';
					RAM_WE <= "1111";
					DATA <= (others =>'Z');
					LED(1 downto 0) <= "11";					

		when CHECK =>
					--if (rdata = DATA) then
						NS <= WAIT_VALID;
						incrementa <= '1';
				--	else
				--		NS <= WRITE;
				--		incrementa <= '0';
				--	end if;
					BUSY <= '1';			
					RAM_DATA <= (others =>'Z');
					RAM_OE <= '0';
					RAM_WE <= "1111";
					DATA <= (others =>'Z');
					LED(1 downto 0) <= "11";

		when WRITE_ADDR =>
					if (DATA_VALID='0') then
						NS <= WAIT_VALID;
						incrementa <= '1';
					else
						NS <= WRITE_ADDR;
						incrementa <= '0';
					end if;
					BUSY <= '0';			
					RAM_DATA <= (others =>'Z');
					RAM_OE <= '1';
					RAM_WE <= "1111";
					DATA <= (others =>'Z');
					LED(1 downto 0) <= "01";

		when READ =>
					if (DATA_VALID='0') then
						NS <= WAIT_VALID;
						incrementa <= '1';
					else
						NS <= READ;
						incrementa <= '0';
					end if;
					BUSY <= '0';			
					RAM_DATA <= (others =>'Z');
					RAM_OE <= '0';
					RAM_WE <= "1111";
					DATA <= rdata;
					LED(1 downto 0) <= "10";

	end case;
end process;


LED(2) <= DATA_VALID;




end Behavioral;
