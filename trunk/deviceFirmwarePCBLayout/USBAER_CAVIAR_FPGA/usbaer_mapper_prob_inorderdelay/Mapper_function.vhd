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
			  DELAY_TIME: in std_logic_vector (15 downto 0); -- In x10 microseconds
			  RNG: in std_logic_vector (15 downto 0);  -- In x10 microseconds is the time window to send the delayed event. Otherwise the delayed event could wait the whole cnt_delay range because a long wait in dispatching the delayed in fifo.
           LED : out std_logic_vector(2 downto 0)
			);
end Mapper_function;

architecture Behavioral of Mapper_function is

component FIFO_delay is
port (clk: in std_logic;
		rst_l: in std_logic;
		sram_busy: in std_logic;
		fifoRAM_ADDRESS: out std_logic_vector (18 downto 0);
		fifoRAM_DATA: in std_logic_vector (31 downto 0);
		fifoRAM_OE: out std_logic;
		fifoRAM_WE: out std_logic_vector (3 downto 0);
		FIFO_save: in std_logic;
		FIFO_saved: out std_logic;
		FIFO_erase: in std_logic;
		FIFO_erased: out std_logic;
		FIFO_ev: out std_logic_vector (15 downto 0);
		FIFO_ts: out std_logic_vector (15 downto 0);
		FIFO_busy: out std_logic;
		FIFO_wr: out std_logic;
		FIFO_empty: out std_logic;
		FIFO_full: out std_logic
);
end component;

type states is (IDLE, WAIT_REQ_L, WAIT_REQ_H, READ_RAM, READ_RAM1, READ_RAM2, SEND_EVENT_FIFO, SEND_EVENT_FIFO_nodelay, SUBE_ACK );
signal CS,NS: states;
signal latched_input: std_logic_vector(15 downto 0);
signal last_event: std_logic;
signal event_counter: std_logic_vector(2 downto 0);
signal inc_delay: std_logic;
signal repetition: std_logic_vector (3 downto 0);
signal last_rep: std_logic;
signal lfsr: std_logic_vector(31 downto 0);

signal cnt10us: integer range 0 to 500;
signal delay_cnt,fifo_delay_time, t1: std_logic_vector (15 downto 0);
signal t2,t3: std_logic;

signal smRAM_ADDRESS : std_logic_vector(18 downto 0);
signal smRAM_DATA : std_logic_vector(31 downto 0);
signal smRAM_OE : std_logic;
signal smRAM_WE : std_logic_vector(3 downto 0);
signal fifoRAM_ADDRESS : std_logic_vector(18 downto 0);
signal fifoRAM_DATA, fifo_data : std_logic_vector(31 downto 0);
signal fifoRAM_OE : std_logic;
signal fifoRAM_WE : std_logic_vector(3 downto 0);
signal sram_busy: std_logic;

signal FIFO_save, FIFO_saved, FIFO_erase, FIFO_erased, FIFO_busy, FIFO_wr, FIFO_full, FIFO_empty : std_logic;
signal Send_nodelay, Sent_nodelay: std_logic;
signal ev, FIFO_ev: std_logic_vector (15 downto 0);
signal ts, FIFO_ts: std_logic_vector (15 downto 0);
signal cmp_delay: std_logic;

type states_delay is (WAIT_EVENT,SEND_EVENT_NODELAY,WAIT_ACK_NODELAY,SEND_EVENT_DELAYED,WAIT_ACK_DELAYED);
signal dl_cs,dl_ns: states_delay;

constant MAX_DLY: integer := 65535; -- equivalent to 655,35 ms of delay.
--constant RNG: integer:= 1000; -- 1ms max time wait when the delay is passed.
begin
-- 1 us counter and the 16 bits delay counter
del: process (clk, rst_n)
begin
  if rst_n='0' then
     cnt10us <= 0;
	  delay_cnt <= (others =>'0');
  elsif clk'event and clk='1' then
     if cnt10us < 499 then
	     cnt10us <= cnt10us +1;
	  else
	     cnt10us <= 0;
		  delay_cnt <= delay_cnt +1;
	  end if;
  end if;
end process;


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



COMB: process(CS, AER_IN_REQ_L, RAM_DATA, latched_input,ENABLE_N, event_counter, FIFO_busy, FIFO_full, lfsr, last_event, Sent_nodelay, FIFO_save)
begin
case CS is
	when IDLE =>   inc_delay <= '0';
						if ENABLE_N = '1' then
							NS <= IDLE;
						else
							NS <= WAIT_REQ_L;
						end if;
						
						AER_IN_ACK_L <= '1';
						smRAM_ADDRESS <= (others =>'Z');
						smRAM_OE <= 'Z';
						smRAM_WE <= "ZZZZ";
						led(0) <= FIFO_full; --'0';
						sram_busy <='0';

	when WAIT_REQ_L => 
						inc_delay <= '0';
						if ENABLE_N = '1' then
							NS <= IDLE;
						elsif (AER_IN_REQ_L = '0') then
							NS <= WAIT_REQ_H;
						else
							NS <= WAIT_REQ_L;
						end if;
						AER_IN_ACK_L <= '1';
						smRAM_ADDRESS <=  latched_input & event_counter;
						smRAM_OE <= '0';
						smRAM_WE <= "1111";
						led(0) <= FIFO_full; --'0';
						sram_busy <='0';

	when WAIT_REQ_H =>
						inc_delay <= '0';
						if	(AER_IN_REQ_L = '0') then
							NS <= WAIT_REQ_H;
						else
							NS <= READ_RAM1;
						end if;
						AER_IN_ACK_L <= '0';
						smRAM_ADDRESS <= latched_input & event_counter; 
						smRAM_OE <= '0';
						smRAM_WE <= "1111";
						led(0) <= FIFO_full; --'1';
						sram_busy <='1';

	
	when READ_RAM =>
						inc_delay <= '1';
						if FIFO_busy='1' then ns <= READ_RAM; 	sram_busy <='0';
						else NS <= READ_RAM1; sram_busy <= '1';
						end if;
						AER_IN_ACK_L <= '0';
						smRAM_ADDRESS <= latched_input & event_counter; 
						smRAM_OE <= '0';
						smRAM_WE <= "1111";
						led(0) <= FIFO_full; --'1';
	when READ_RAM1 =>
						inc_delay <= '0';
						NS <= READ_RAM2;
						AER_IN_ACK_L <= '0';
						smRAM_ADDRESS <= latched_input & event_counter; 
						smRAM_OE <= '0';
						smRAM_WE <= "1111";
						led(0) <= FIFO_full; --'1';
						sram_busy <='1';

	when READ_RAM2 =>
						inc_delay <= '0';
						if (FIFO_busy = '1') then
							NS <= READ_RAM2;
						elsif RAM_DATA(31 downto 24) < lfsr(7 downto 0) and RAM_DATA(16)='1' then 
								NS <= SUBE_ACK;
						elsif RAM_DATA(31 downto 24) < lfsr(7 downto 0) then
								NS <= READ_RAM;
						elsif RAM_DATA(21) = '1' and FIFO_full='0' then 
						   NS <= SEND_EVENT_FIFO;
						else  -- If the delay is 0 (no delay) or the FIFO is already full, the mapped event is sent inmediatly
							NS <= SEND_EVENT_FIFO_nodelay;
						end if;
						AER_IN_ACK_L <= '0';
						smRAM_ADDRESS <= latched_input & event_counter;
						smRAM_OE <= '0';
						smRAM_WE <= "1111";
						led(0) <= FIFO_full; --'1';
						sram_busy <='1';

	when SEND_EVENT_FIFO =>
						inc_delay <= '0';
						if (FIFO_busy='1' or FIFO_save='1') then
							NS <= SEND_EVENT_FIFO;
						elsif FIFO_full='1' then
						   NS <= SEND_EVENT_FIFO_nodelay;   -- If fifo is full we shouldn't be in this state, so we move to the one where no delay is waited before sending the mapped event out.
						elsif (last_event = '0') then
							NS <= READ_RAM;
							--inc_delay<='1';
						else
							NS <= SUBE_ACK;
						end if;
						AER_IN_ACK_L <= '0';
						smRAM_ADDRESS <= latched_input & event_counter;
						smRAM_OE <= '0';
						smRAM_WE <= "1111";
						led(0) <= FIFO_full; --'1';
						sram_busy <='0';
	when SEND_EVENT_FIFO_nodelay =>
						inc_delay <= '0';
						if Sent_nodelay='0' then
						   NS <= SEND_EVENT_FIFO_nodelay;
						elsif (last_event = '0' and Sent_nodelay='1') then
						   NS <= READ_RAM;
							--inc_delay<='1';
						else NS <= SUBE_ACK;
						end if;
						AER_IN_ACK_L <= '0';
						smRAM_ADDRESS <= latched_input & event_counter;
						smRAM_OE <= '0';
						smRAM_WE <= "1111";
						led(0) <= FIFO_full; --'1';
						sram_busy <='0';
	when SUBE_ACK =>				
						inc_delay <= '0';
						NS <= WAIT_REQ_L;
						AER_IN_ACK_L <= '1';
						smRAM_ADDRESS <= latched_input & event_counter; 
						smRAM_OE <= '0';
						smRAM_WE <= "1111";
						led(0) <= FIFO_full; --'1';
						sram_busy <='0';
	end case;
end process;




SYCN: process(RST_N, CLK, CS, NS, AER_IN_DATA)
begin
if (RST_N = '0')  then
      event_counter <= (others =>'0');
		latched_input <= (others =>'0');
      FIFO_save <= '0';
		Send_nodelay <= '0';
elsif(CLK'event and CLK='1') then
	if (CS = WAIT_REQ_L and NS = WAIT_REQ_H)  then	 
			latched_input <= AER_IN_DATA;
			event_counter <= (others =>'0');
	elsif inc_delay='1' then --(CS = SEND_EVENT_fifo and NS = READ_RAM2) or (CS = READ_RAM2 and NS = READ_RAM) then	-- or (CS=SEND_EVENT_FIFO_nodelay and NS=READ_RAM2)
			event_counter <= event_counter + 1;
			if event_counter = 7 then
			  latched_input <= latched_input +1;
			end if;
   end if;
	if (ns=SEND_EVENT_fifo and FIFO_full='0') then
			FIFO_save <= '1';
	end if;
	if FIFO_save='1' and FIFO_saved='1' then
			FIFO_save <= '0';
	elsif FIFO_full='1' then FIFO_save <= '0';
	end if;
	if (CS = SEND_EVENT_fifo_nodelay) then
	      Send_nodelay <= '1';
	end if;
	if Send_nodelay='1' and Sent_nodelay='1' then
	   Send_nodelay <= '0';
	end if;
end if;
end process;

delay: process (RST_N,clk)
begin
	if rst_n='0' then
		repetition<=(others =>'0');
		ev <= (others => '0');
		last_event <= '1';
		fifo_data <= (others =>'0');
	elsif clk='1' and clk'event then
		if ns = READ_RAM2 then --and ns = SEND_EVENT_FIFO then
			repetition <= RAM_DATA (20 downto 17);
			last_event <= RAM_DATA(16) ;
		end if;
		if cs=READ_RAM2 then --and ns=SEND_EVENT_FIFO_nodelay then
			ev <= RAM_DATA(15 downto 0);
			fifo_data <= fifo_delay_time & RAM_DATA(15 downto 0);
		end if;
	end if;
end process;

led(2) <= cmp_delay; 
led(1) <= FIFO_empty; 
fifo_delay_time <= (delay_cnt + DELAY_TIME);
fifoRAM_DATA <= RAM_DATA when (FIFO_busy='1' and FIFO_wr='0') else (others => 'Z');
RAM_DATA <= fifo_data when (ENABLE_N='0' and FIFO_busy='1' and FIFO_wr='1') else (others => 'Z');
RAM_ADDRESS <= fifoRAM_ADDRESS when (ENABLE_N='0' and FIFO_busy='1') else smRAM_ADDRESS when (ENABLE_N='0') else (others => 'Z');
RAM_OE <= fifoRAM_OE when (ENABLE_N='0' and FIFO_busy='1') else smRAM_OE when (ENABLE_N='0') else 'Z';
RAM_WE <= fifoRAM_WE when (ENABLE_N='0' and FIFO_busy='1') else smRAM_WE when (ENABLE_N='0') else (others => 'Z');


BFIFO: FIFO_delay port map 
     (clk => clk,
		rst_l => rst_n,
		sram_busy => sram_busy,
		fifoRAM_ADDRESS => fifoRAM_ADDRESS,
		fifoRAM_DATA => fifoRAM_DATA,
		fifoRAM_OE => fifoRAM_OE,
		fifoRAM_WE => fifoRAM_WE,
		FIFO_save => FIFO_save,
		FIFO_saved => FIFO_saved,
		FIFO_erase => FIFO_erase,
		FIFO_erased => FIFO_erased,
		FIFO_ev => FIFO_ev,
		FIFO_ts => FIFO_ts,
		FIFO_busy => FIFO_busy,
		FIFO_wr => FIFO_wr,
		FIFO_empty => FIFO_empty,
		FIFO_full => FIFO_full
);
busy <= sram_busy;
SM_DL_SY: process (clk,rst_n)
begin
   if rst_n='0' then
	   dl_cs <= WAIT_EVENT;
		Sent_nodelay <= '0';
		FIFO_erase <= '0';
	elsif clk'event and clk='1' then
	   dl_cs <= dl_ns;
		if dl_cs = WAIT_ACK_DELAYED and dl_ns = WAIT_EVENT then
		   FIFO_erase <= '1';
		elsif FIFO_erase='1' and FIFO_erased='1' then FIFO_erase <= '0';
		elsif FIFO_empty='1' then FIFO_erase <= '0';
		end if;
		if dl_cs = WAIT_ACK_NODELAY and dl_ns=WAIT_EVENT then
		   Sent_nodelay <= '1';
		else Sent_nodelay <= '0';
		end if;
	end if;
end process;
t1 <= FIFO_ts + RNG;

Bcmp_delay: process (CLK, RST_N) 
begin
  if RST_N='0' then
     cmp_delay <= '0';
	  t2 <= '0';
	  t3 <= '0';
  elsif clk'event and clk='1' then
	  if delay_cnt >= FIFO_ts or delay_cnt < FIFO_ts-DELAY_TIME then
	     cmp_delay <= '1';
	  end if;
	  if cmp_delay='1' and FIFO_erase='1'  then
	     cmp_delay <= '0';
	  end if;
  end if;
end process;

SM_DL_CB: process (dl_cs,ts,delay_cnt,FIFO_ts,AER_OUT_ACK_L,ev,FIFO_ev,Send_nodelay,FIFO_empty, Sent_nodelay, FIFO_busy, FIFO_erase, sram_busy, cmp_delay, lfsr)
begin
   case dl_cs is
		when WAIT_EVENT =>
		   if FIFO_erase ='1' then dl_ns <= WAIT_EVENT; 
			elsif cmp_delay='1' and FIFO_empty='0' and FIFO_busy='0' then 
			   dl_ns <= SEND_EVENT_DELAYED;
			elsif Send_nodelay='1' and Sent_nodelay='0' then  -- and cmp_delay='0'
			   dl_ns <= SEND_EVENT_NODELAY;
--			elsif Send_nodelay='1' and Sent_nodelay='0' and lfsr(7 downto 0) < 128 then
--			   dl_ns <= SEND_EVENT_NODELAY;
			else dl_ns <= WAIT_EVENT;
			end if;
			AER_OUT_REQ_L <= '1';
			AER_OUT_DATA <= (others => 'Z');
			--led(2 downto 1) <= "11";
		when SEND_EVENT_NODELAY =>
			if AER_OUT_ACK_L ='1' then
			   dl_ns <= SEND_EVENT_NODELAY;
			else dl_ns <= WAIT_ACK_NODELAY;
			end if;
			AER_OUT_REQ_L <= '0';
			AER_OUT_DATA <= ev;
			--led(2 downto 1) <= "01";
		when WAIT_ACK_NODELAY =>
			if AER_OUT_ACK_L='0' then
			   dl_ns <= WAIT_ACK_NODELAY;
			else dl_ns <= WAIT_EVENT;
			end if;
			AER_OUT_REQ_L <= '1';
			AER_OUT_DATA <= ev;
			--led(2 downto 1) <= "01";
		when SEND_EVENT_DELAYED =>
			if AER_OUT_ACK_L='1' then
			   dl_ns <= SEND_EVENT_DELAYED;
			else dl_ns <= WAIT_ACK_DELAYED;
			end if;
			AER_OUT_REQ_L <= '0';
			AER_OUT_DATA <= FIFO_ev;  
			--led(2 downto 1) <= "10";
		when WAIT_ACK_DELAYED =>
			if AER_OUT_ACK_L='0' then
			   dl_ns <= WAIT_ACK_DELAYED;
			else dl_ns <= WAIT_EVENT;
			end if;
			AER_OUT_REQ_L <= '1';
			AER_OUT_DATA <= FIFO_ev; 
			--led(2 downto 1) <= "10";
	end case;
end process;

end Behavioral;
