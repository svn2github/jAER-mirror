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
           LED : out std_logic_vector(2 downto 0)
			);
end Mapper_function;

architecture Behavioral of Mapper_function is
type states is (IDLE, WAIT_REQ_L, WAIT_REQ_H, READ_RAM, READ_RAM2, SEND_EVENT, SEND_EVENTrepe,SUBE_ACK );
signal CS,NS: states;
signal latched_input: std_logic_vector(15 downto 0);
signal last_event, no_event: std_logic;
signal event_counter: std_logic_vector(2 downto 0);
signal repeticiones: std_logic_vector (3 downto 0);
signal last_rep: std_logic;
signal lfsr: std_logic_vector(31 downto 0);


begin
-- generador de probabilidades, basado en lfsr

prob: process (clk,RST_N,lfsr)
variable i: natural;
begin
	if RST_N = '0' then
		lfsr <= x"80000000";
	elsif CLK'event and CLK='1' then
		for i in 31 downto 1 loop
      	 lfsr(i) <= lfsr(i-1);
   	end loop;
		lfsr(0)<= lfsr(31) xor lfsr(21) xor lfsr(1) xor lfsr (0);
	end if; 
end process;


SYNC: process(RST_N, enable_n, CLK)
begin
	if RST_N = '0' or ENABLE_N ='1' then
		CS <= IDLE;
	elsif(CLK'event and CLK ='1') then
		CS <= NS;
		
	end if;
end process;



COMB: process(CS, AER_IN_REQ_L, AER_OUT_ACK_L, RAM_DATA, latched_input,ENABLE_N,last_rep)
begin
case CS is
	when IDLE => 
						if ENABLE_N = '1' then
							NS <= IDLE;
						else
							NS <= WAIT_REQ_L;
						end if;
						
						--NS <= WAIT_REQ_L;
						AER_IN_ACK_L <= '1';
						AER_OUT_REQ_L <= '1';
						AER_OUT_DATA <= (others =>'Z');
						RAM_ADDRESS <= (others =>'Z');
						RAM_OE <= 'Z';
						RAM_WE <= "ZZZZ";
						led <= "000";
						busy <='0';

	when WAIT_REQ_L => 
						
						if ENABLE_N = '1' then
							NS <= IDLE;
						elsif (AER_IN_REQ_L = '0') then
							NS <= WAIT_REQ_H;
						else
							NS <= WAIT_REQ_L;
						end if;
						AER_IN_ACK_L <= '1';
						AER_OUT_REQ_L <= '1';
						AER_OUT_DATA <= RAM_DATA(15 downto 0);
						RAM_ADDRESS <=  latched_input & event_counter;
						RAM_OE <= '0';
						RAM_WE <= "1111";
						led <= "001";
						busy <='1';

	when WAIT_REQ_H =>
						if	(AER_IN_REQ_L = '0') then
							NS <= WAIT_REQ_H;
						else
							NS <= READ_RAM2;
						end if;
						AER_IN_ACK_L <= '0';
						AER_OUT_REQ_L <= '1';
						AER_OUT_DATA <= RAM_DATA(15 downto 0);
						RAM_ADDRESS <= latched_input & event_counter; 
						RAM_OE <= '0';
						RAM_WE <= "1111";
						led <= "011";
						busy <='1';

	
	when READ_RAM =>
						NS <= READ_RAM2;
						AER_IN_ACK_L <= '0';
						AER_OUT_REQ_L <= '1';	
						AER_OUT_DATA <= RAM_DATA(15 downto 0);
						RAM_ADDRESS <= latched_input & event_counter; 
						RAM_OE <= '0';
						RAM_WE <= "1111";
						led <= "100";
						busy <='1';

	when READ_RAM2 =>
						if (AER_OUT_ACK_L = '0') then
							NS <= READ_RAM2;
						elsif RAM_DATA (20 downto 17)="0000" then -- se come el evento, no debe poner el req a la salida
							NS <= WAIT_REQ_L;
						elsif RAM_DATA(31 downto 24) < lfsr(7 downto 0) then -- comprueba la probabilidad
							if last_event ='1' then 
								NS <= SUBE_ACK;
							else
								NS <= READ_RAM;
							end if;
						else
							NS <= SEND_EVENT;
						end if;
						AER_IN_ACK_L <= '0';
						AER_OUT_REQ_L <= '1';	
						AER_OUT_DATA <= RAM_DATA(15 downto 0);
						RAM_ADDRESS <= latched_input & event_counter;
						RAM_OE <= '0';
						RAM_WE <= "1111";
						led <= "100";
						busy <='1';

	when SEND_EVENT =>
						if (AER_OUT_ACK_L = '1') then
							NS <= SEND_EVENT;
						elsif last_rep= '0' then
							NS <= SEND_EVENTrepe;
						elsif (last_event = '0') then
							NS <= READ_RAM2;
						else
							--NS <= READ_RAM2;
							NS <= SUBE_ACK;
						end if;
						AER_IN_ACK_L <= '0';
						AER_OUT_REQ_L <= '0';
						AER_OUT_DATA <= RAM_DATA(15 downto 0);
						RAM_ADDRESS <= latched_input & event_counter;
						RAM_OE <= '0';
						RAM_WE <= "1111";
						led <= "101";
						busy <='1';
when SEND_EVENTrepe =>
					
						if (AER_OUT_ACK_L = '0') then
							NS <= SEND_EVENTrepe;
						else
							NS <= SEND_EVENT;
						end if;
						AER_IN_ACK_L <= '0';
						AER_OUT_REQ_L <= '1';
						AER_OUT_DATA <= RAM_DATA(15 downto 0);
						RAM_ADDRESS <= latched_input & event_counter;
						RAM_OE <= '0';
						RAM_WE <= "1111";
						led <= "101";
						busy <='1';

	when SUBE_ACK =>						-- Tambien se podria comprobar ACK_OUT aqui
						NS <= WAIT_REQ_L;
						AER_IN_ACK_L <= '1';
						AER_OUT_REQ_L <= '1';
						AER_OUT_DATA <= RAM_DATA(15 downto 0);
						RAM_ADDRESS <= latched_input & event_counter; 
						RAM_OE <= '0';
						RAM_WE <= "1111";
						led <= "111";
						busy <='1';

	end case;
end process;




SYCN: process( RST_N, CLK, CS, NS, AER_IN_DATA)
begin
if (RST_N = '0')  then
      event_counter <= (others =>'0');
		latched_input <= (others =>'0');
--		last_event <= '0';
--		no_event <= '0';

elsif(CLK'event and CLK='1') then
--	last_event <= RAM_DATA(16);
--	no_event <= RAM_DATA(17);

	if (CS = WAIT_REQ_L and NS = WAIT_REQ_H)  then	 
			--latched_input <= AER_IN_DATA(15 downto 8)&"0"&AER_IN_DATA(7 downto 1);
			latched_input <= AER_IN_DATA;
			event_counter <= (others =>'0');
	elsif (CS = SEND_EVENT and NS = READ_RAM2) or (CS = READ_RAM2 and NS = READ_RAM) then	
	
			event_counter <= event_counter + 1;

	end if;
end if;
end process;

repe: process (RST_N,clk, repeticiones, cs, ns)
begin
	if rst_n='0' then
		repeticiones<=(others =>'0');
	elsif clk='1' and clk'event then
		if cs = READ_RAM2 then
			repeticiones <= RAM_DATA (20 downto 17);
		elsif cs= SEND_EVENT and NS=SEND_EVENTrepe	then
			repeticiones <= repeticiones -1;
		else 
			repeticiones <= repeticiones;
		end if;						  	
	end if;
end process;


last_rep <= '1' when repeticiones = "0001" else '0';

last_event <= RAM_DATA(16) ;




--no_event <= RAM_DATA(16);
RAM_DATA <= (others =>'Z');	

end Behavioral;
