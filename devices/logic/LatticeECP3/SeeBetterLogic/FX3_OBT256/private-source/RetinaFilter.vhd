library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity RetinaFilter is
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
end RetinaFilter;

architecture Behavioral of RetinaFilter is

  type estados is (IDLE, WAIT_COMMAND,WAIT_NO_COMMAND, WAIT_ACKH, WAIT_VALID, WAIT_NOVALID, ERASE, SEND_EVENT, SUBE_ACK,FILTER_st,READ_t0,READ_t0b,WRITE,WRITE_b);
  signal CS, NS: estados;

  constant ADDR_WIDTH : integer := 14;
  constant DATA_WIDTH : integer := 32;
  constant MAX : integer := integer'HIGH;

  type tram_rf is array (2**(ADDR_WIDTH-1)-1 downto 0) of unsigned (DATA_WIDTH-1 downto 0);
  signal ram_rf: tram_rf;

  signal LATCHED_EVENT: std_logic_vector(16 downto 0);
  signal dir,dir2: unsigned(15 downto 0);


  --signal contador: std_logic_vector(11 downto 0);

 signal iaer_in_req_l, saer_in_req_l, saer_out_ack_l, iaer_out_ack_l: std_logic;
 signal req, ack: std_logic;
 signal imicro_data: std_logic_vector(7 downto 0);

 signal timestamp,t2,t0,t1: unsigned (31 downto 0);-- timestamps
 signal r,dt1,dt2: unsigned (31 downto 0); -- factor
 signal nwrites: integer range 0 to 9;


 signal clk,clk50int,clk0B,clk100int,reset,clk200int,clk0B2,not_lockdll1,lockdll1:std_logic;

 --timer
 signal count_timer,icount_timer:unsigned (31 downto 0);

 signal end_timer: std_logic;
 signal ncommand: integer range 0 to 15;
 signal BGAFen: std_logic;

begin

clk <=clk50;

SYNC_AER: process(RST_L, CLK)
begin
if(RST_L = '0') then
	CS <= IDLE;
	LATCHED_EVENT <=(others =>'0');
	t0 <=(others =>'0');
	t1 <=(others =>'0');
	--contador <= (others =>'0');
	ncommand<=0;
	nwrites <=0;
	r<=x"0000000a";
	icount_timer <= x"00001388";
	BGAFen <= '0';
	WS2CAVIAR_en <= '0';
	DAVIS_en <= '1';
elsif(CLK'event and CLK ='1') then
	CS <= NS;
	if (CS = IDLE and saer_in_req_l = '0') then -- and aer_in_data(8)='0') then -- cuando recibo un evento req=0
		LATCHED_EVENT <= aer_in_data;
		t1 <= timestamp;
	--elsif (CS = IDLE and saer_in_req_l = '0' and aer_in_data(8)='1') then
	--    t1 <= (others => '1');
	end if;
	if cs=idle then
		nwrites <= 0;
		dir2 <= dir;
	elsif cs=WAIT_ACKH and ns= read_t0 then
		dir2 <= dir;
	elsif (NS=WRITE and CS=read_t0b)or(NS=WRITE and CS=write_b) then
		nwrites <=nwrites +1;
		case nwrites is
				when 1 => if (dir > 127) then dir2 <= dir-127; else dir2 <= dir; end if;
				when 2 => if (dir > 128) then dir2 <= dir-128; else dir2 <= dir; end if;--256;
				when 3 => if (dir > 129) then dir2 <= dir-129; else dir2 <= dir; end if;--257;
				when 4 => if (dir > 1)   then dir2 <= dir-1;   else dir2 <= dir; end if;
				when 5 => if (dir + 1 >  dir)  then dir2 <= dir+1;   else dir2 <= dir; end if;
				when 6 => if (dir + 127 > dir) then dir2 <= dir+127; else dir2 <= dir; end if; --255;
				when 7 => if (dir + 128 > dir) then dir2 <= dir+128; else dir2 <= dir; end if;--256;
				when 8 => if (dir + 129 > dir) then dir2 <= dir+129; else dir2 <= dir; end if;--257;
				when others =>	 null;
 			end case;
	end if;

	if cs=READ_t0b then
		t0<= ram_rf(to_integer(dir2));
	end if;

	if cs=SEND_EVENT then
		req<='0';
	else
		req<='1';
	end if;

	if cs=WRITE then
				ram_rf(to_integer(dir2)) <= t1;
	end if;

if (cs=idle and saer_in_req_l = '0' ) then
		r<=icount_timer;
	end if;




	if (CS = IDLE) then
		--contador <= (others =>'0');
		ncommand<=0;
	elsif(CS = ERASE) then
		--contador <= contador + 1;
	end if;
	if spiwr='1' then  
		case SPIADDRESS is
				when x"80" => icount_timer(7 downto 0) <= unsigned(spiDATA); 
				when x"81" => icount_timer(15 downto 8) <= unsigned(spiDATA); 
				when x"82" => icount_timer(23 downto 16) <= unsigned(spiDATA); 
				when x"83" => icount_timer(31 downto 24) <= unsigned(spiDATA); 
				when x"84" => if (spiDATA=x"00") then BGAFen<='0'; elsif (spiDATA=x"FF") then BGAFen<='1'; end if;
				when x"85" => if (spiDATA=x"00") then WS2CAVIAR_en<='0'; elsif (spiDATA=x"FF") then WS2CAVIAR_en<='1'; end if;
				when x"86" => if (spiDATA=x"00") then DAVIS_en<='0'; elsif (spiDATA=x"FF") then DAVIS_en<='1'; end if;
				when others => null;
			end case;
	end if;
end if;
end process;
--alex <= dir2(13 downto 0);
dir <= "00" & unsigned(LATCHED_EVENT(16 downto 10)) & unsigned(LATCHED_EVENT(8 downto 2));-- when (LATCHED_EVENT(8)='1' and LATCHED_EVENT(16)='0') else (others=>'0'); -- retina SeeBetter10
dt1<=r;

alex(0) <= '1' when (t0+dt1 >= t1) else '0';alex(1) <= '1' when (t0+dt1 < t1 and  t0 < t1)    else '0';
alex(2) <= '1' when (t0 + dt1 >= MAX and t0+dt1 > t1)else '0';

COMB_AER: process(saer_in_req_l, CS,  end_timer,ncommand, saer_out_ack_l,t0,t1,nwrites,dt1,spiWR)
begin
case CS is

	when IDLE =>
		   if (saer_in_req_l = '0' ) then --and aer_in_data(8)='0') then
				NS <= WAIT_ACKH;
			--elsif (saer_in_req_l = '0'and aer_in_data(8)='1') then
			--    NS <= FILTER_ST;
			else
				NS <= IDLE;
			end if;
			ack <= '1';
	when WAIT_ACKH =>
			if (saer_in_req_l = '1') then
				NS <= READ_t0;
			else
				NS <= WAIT_ACKH;
			end if;
			ack <= '0';
	when READ_t0 =>
			NS <= READ_t0b;
			ack <= '0';
	when READ_t0b =>
			NS <= WRITE;
			ack <= '0';
	when WRITE =>
			NS <=WRITE_b;
			ack <= '0';
	when WRITE_b =>
			if nwrites <= 0 then --8
				NS <=WRITE;
			else
				NS <= FILTER_st;
			end if;
			ack <= '0';
	when FILTER_st =>  -- Modified this simple previous condition to take into account signed std_logic_vector and overflows of timestamp timers. MAX is 2^n-1 as a constant value
	 --if ('0'&t0 + '0'&dt1 < MAX and ('0'&t0)+('0'&dt1) > ('0'&t1)) then
	 		--NS <= SEND_EVENT;
	 --elsif ('0'&t0 + '0'&dt1 >=MAX and ('0'&t0 < '0'& t1)) then
			--NS <= SEND_EVENT;
	 --elsif ('0'&t0 + '0'&dt1 >=MAX and ('0'&t0)+('0'&dt1) > ('0'&t1)) then
	 		--NS <= SEND_EVENT;
	 --else
		if (t0+dt1 >= t1) then
	 		NS <= SEND_EVENT;
		else
			NS<=SUBE_ACK;
		 end if;
		  	ack <= '0';
	 when 	SEND_EVENT =>
			if saer_out_ack_l='1' then
				NS<=SEND_EVENT;
			else
				NS<=SUBE_ACK;
			end if;
			ack <= '0';
	when SUBE_ACK =>
		if saer_out_ack_l='0' then
				NS<=SUBE_ACK;
			else
				NS<=IDLE;
			end if;
		  	ack <= '1';
		when WAIT_COMMAND =>
			if spiWR = '1' then
				NS<= WAIT_COMMAND;
			else
				NS <= IDLE;
			end if;
		   ack <= '1';
		when others => NS <= CS;
	end case;
end process;

    iaer_in_req_l <= aer_in_req_l;
	saer_in_req_l <= iaer_in_req_l;
	iaer_out_ack_l <= aer_out_ack_l;
	saer_out_ack_l <= iaer_out_ack_l;
	aer_out_req_l<=req;-- when (BGAFen='1') else saer_in_req_l;
	aer_in_ack_l<=ack;-- when (BGAFen='1') else saer_out_ack_l;
	aer_out_data <= LATCHED_EVENT;-- when (BGAFen='1') else -- and LATCHED_EVENT(8)='1' and LATCHED_EVENT(16)='0') else
					--(others=>'0') when (BGAFen='1') else
					--aer_in_data ;--  when (BGAFen='0');
 BGAF_en <= BGAFen;
timestampp: process (clk, rst_l)
begin
	if rst_l='0' then
		timestamp<= (others =>'0');
	elsif clk='1' and clk'event then
		timestamp<=timestamp+1;
	end if;
end process;

end Behavioral;
