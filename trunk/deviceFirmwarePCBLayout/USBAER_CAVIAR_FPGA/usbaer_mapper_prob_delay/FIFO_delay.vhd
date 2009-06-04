library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity FIFO_delay is
port (clk: in std_logic;
		rst_l: in std_logic;
		FIFO_save: in std_logic;
		ev: in std_logic_vector (15 downto 0);
		ts: in std_logic_vector (7 downto 0);
		FIFO_erase: in std_logic;
		FIFO_ev: out std_logic_vector (15 downto 0);
		FIFO_ts: out std_logic_vector (7 downto 0);
		FIFO_busy: out std_logic;
		FIFO_empty: out std_logic;
		FIFO_full: out std_logic
);
end FIFO_delay;

architecture A of FIFO_delay is
   constant N: integer := 49;
   type tfifo is array (integer range <>) of std_logic_vector (20 downto 0);
	signal fifo: tfifo (0 to N);
	
	type fifo_states is (IDLE, SEARCH_POSITION, OPEN_FIFO, WRITE_FIFO, ERASE_FIRST1, ERASE_FIRST2);
	signal fifo_cs, fifo_ns: fifo_states;
	
	signal used: integer range 0 to N;
	signal position: integer range 0 to N;
	signal ififo_full, ififo_empty: std_logic;
	
	signal wait_erase: std_logic;
	
begin
   FIFO_SYNC: process (clk, rst_l)
	  variable j: integer range 0 to N;
	  variable got_first: boolean;
	begin
	   if (rst_l='0') then 
		   for i in 0 to N loop
			   fifo (i) <= (others => '1');
			end loop;
			iFIFO_full<='0';
			used <= 0;
			fifo_cs <= IDLE;
			iFIFO_empty <= '1';
			wait_erase <= '0';
		elsif clk'event and clk='1' then
		   fifo_cs <= fifo_ns;
			case fifo_cs is
				when SEARCH_POSITION =>
				   got_first:=FALSE;
					position <= used;
				   for j in N downto 0 loop
						   if j<=used and fifo(j)(20 downto 14) > ts and not got_first then
							   position <= j;
							elsif j<= used then got_first:=TRUE;
							end if;
					end loop;
				when OPEN_FIFO =>
				   if iFIFO_full='0' then
						for j in N downto 1 loop
						   if j > position then
							   fifo(j) <= fifo(j-1);
							end if;
						end loop;
						fifo (position) <= ts(6 downto 0) & ev(14 downto 8) & ev(6 downto 0);
						if used < N-2 then
							used <= used +1;
							iFIFO_empty <= '0';
							iFIFO_full <= '0';
						else 
							iFIFO_full <= '1'; 
							used <= N-1;
						end if;
					end if;
				when WRITE_FIFO => fifo(position) <= ts(6 downto 0) & ev(14 downto 8) & ev(6 downto 0);
				when ERASE_FIRST1 =>
						for i in 0 to N-1 loop
							fifo (i) <= fifo(i+1);
						end loop;
						fifo(used)<=(others => '1');
				when ERASE_FIRST2 =>
						if used >0 then
						   iFIFO_empty <= '0';
							used <= used -1;
						   if used=1 then iFIFO_empty <= '1';
							end if;
						end if;
						iFIFO_full <= '0';
				when others => null;
			end case;
		end if;
	end process;
	FIFO_ev <= '0' & fifo(0)(13 downto 7) & '0' & fifo(0)(6 downto 0);
	FIFO_ts <= '0' & fifo(0)(20 downto 14);
	
	FIFO_COMB: process (fifo_cs, FIFO_save, FIFO_erase, iFIFO_full, iFIFO_empty)
	begin
		case fifo_cs is
			when IDLE => 
				if FIFO_erase='1' and iFIFO_empty='0' then fifo_ns <= ERASE_FIRST1;
				elsif FIFO_save='1' and iFIFO_full='0' then fifo_ns <= SEARCH_POSITION;
				else fifo_ns <= IDLE;
				end if;
				FIFO_busy <= '0';
			when SEARCH_POSITION =>
				fifo_ns <= OPEN_FIFO;
				FIFO_busy <= '1';
			when OPEN_FIFO =>
				fifo_ns <= WRITE_FIFO;
				FIFO_busy <= '1';
			when WRITE_FIFO => 
				if FIFO_erase='1' then fifo_ns <= ERASE_FIRST1;
				else fifo_ns <= IDLE; 
				end if;
				FIFO_busy <= '1';
			when ERASE_FIRST1 =>
			   fifo_ns <= ERASE_FIRST2;
				FIFO_busy <= '1';
			when ERASE_FIRST2 =>
			   fifo_ns <= IDLE;
				FIFO_busy <= '1';
		end case;
	end process;
	
	FIFO_full <= ififo_full;
	FIFO_empty <= ififo_empty;
end A;