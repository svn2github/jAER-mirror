library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity FIFO_delay is
port (clk: in std_logic;
		rst_l: in std_logic;
		sram_busy: in std_logic;
		fifoRAM_ADDRESS: out std_logic_vector (18 downto 0);
		fifoRAM_DATA: in std_logic_vector (31 downto 0);
		fifoRAM_OE: out std_logic;
		fifoRAM_WE: out std_logic_vector (3 downto 0);
		FIFO_save: in std_logic;
		FIFO_saved: out std_logic;
--		ev: in std_logic_vector (15 downto 0);
--		ts: in std_logic_vector (15 downto 0);
		FIFO_erase: in std_logic;
		FIFO_erased: out std_logic;
		FIFO_ev: out std_logic_vector (15 downto 0);
		FIFO_ts: out std_logic_vector (15 downto 0);
		FIFO_busy: out std_logic;
		FIFO_wr: out std_logic;
		FIFO_empty: out std_logic;
		FIFO_full: out std_logic
);
end FIFO_delay;

architecture A of FIFO_delay is
   constant N: integer := 1024*16;
	constant LOGN: integer :=14;
--   type tfifo is array (integer range <>) of std_logic_vector (20 downto 0);
--	signal fifo: tfifo (0 to N);
	
	type fifo_states is (IDLE, SRAM_ADDRESS, WRITE_SRAM_FIFO, ERASE_FIRST_ADD, ERASE_FIRST_READ, EMPTY_ADDRESS, EMPTY_READ);
	signal fifo_cs, fifo_ns: fifo_states;
	
	signal fifoin, fifout, used: integer range 0 to N;
--	signal position: integer range 0 to N;
	signal ififo_full, ififo_empty: std_logic;
	
	signal wait_erase: std_logic;
	
begin
   FIFO_SYNC: process (clk, rst_l)
	  variable j: integer range 0 to N;
	begin
	   if (rst_l='0') then 
		   fifoin <= 0;
			fifout <= 0;
			iFIFO_full<='0';
			used <= 0;
			fifo_cs <= IDLE;
			iFIFO_empty <= '1';
			wait_erase <= '0';
			fifoRAM_ADDRESS <= "11111" & "00000000000000"; --FIFO is always at the last 1K word of the SRAM. No mapping table should be there.
			FIFO_ev <= (others =>'0');
			FIFO_ts <= (others =>'0');
		elsif clk'event and clk='1' then
		   fifo_cs <= fifo_ns;
			case fifo_cs is
				when SRAM_ADDRESS =>
					fifoRAM_ADDRESS <= "11111" & conv_std_logic_vector(fifoin,LOGN);
				when WRITE_SRAM_FIFO =>
				   if iFIFO_full='0' then
						if used < N-2 then
							used <= used +1;
							if fifoin <N then fifoin <= fifoin+1;
							else fifoin <= 0;
							end if;
							iFIFO_full <= '0';
						else 
							iFIFO_full <= '1'; 
							used <= N-1;
						end if;
					end if;
					iFIFO_empty <= '0';
				when ERASE_FIRST_ADD =>
					fifoRAM_ADDRESS <= "11111" & conv_std_logic_vector(fifout,LOGN);
				when ERASE_FIRST_READ =>
						if used >0 then
						   iFIFO_empty <= '0';
							used <= used -1;
						   if used=1 then iFIFO_empty <= '1';
							end if;
							if fifout < N then fifout <= fifout+1;
							else fifout <= 0;
							end if;
						else iFIFO_empty <= '1';
						end if;
						FIFO_ev <= fifoRAM_DATA (15 downto 0);
						FIFO_ts <= fifoRAM_DATA (31 downto 16);
						iFIFO_full <= '0';
				when EMPTY_ADDRESS =>
						fifoRAM_ADDRESS <= "11111" & conv_std_logic_vector(fifout,LOGN);
				when EMPTY_READ =>
						FIFO_ev <= fifoRAM_DATA (15 downto 0);
						FIFO_ts <= fifoRAM_DATA (31 downto 16);
						--iFIFO_full <= '0';
						--iFIFO_empty <= '0';
				when others => null;
			end case;
		end if;
	end process;
	
	FIFO_COMB: process (fifo_cs, FIFO_save, FIFO_erase, iFIFO_full, iFIFO_empty, sram_busy)
	begin
		case fifo_cs is
			when IDLE => 
				if FIFO_save='1' and iFIFO_full='0' then fifo_ns <= SRAM_ADDRESS;
				elsif FIFO_erase='1' and iFIFO_empty='0' then fifo_ns <= ERASE_FIRST_ADD;
				else fifo_ns <= IDLE;
				end if;
				FIFO_busy <= '0';
				FIFO_wr <= '0';
				fifoRAM_OE <= '1';
				fifoRAM_WE <= "1111";
				FIFO_saved <='0';
				FIFO_erased <='0';
			when SRAM_ADDRESS =>
			   if sram_busy ='1' then fifo_ns <= SRAM_ADDRESS;	FIFO_busy <= '0';
				else fifo_ns <= WRITE_SRAM_FIFO; FIFO_busy <= '1';
				end if;
				FIFO_wr <= '1';
				fifoRAM_OE <= '1';
				fifoRAM_WE <= "1111";
				FIFO_saved <='0';
				FIFO_erased <='0';
			when WRITE_SRAM_FIFO => 
				if FIFO_erase='1' then fifo_ns <= ERASE_FIRST_ADD; 
				elsif iFIFO_empty='1' then fifo_ns <= EMPTY_ADDRESS; 
				else fifo_ns <= IDLE;
				end if;
				FIFO_busy <= '1';
				FIFO_wr <= '1';
				fifoRAM_OE <= '1';
				fifoRAM_WE <= "0000";
				FIFO_saved <='1';
				FIFO_erased <='0';
			when ERASE_FIRST_ADD =>
			   if sram_busy='1' then fifo_ns <= ERASE_FIRST_ADD; FIFO_busy <= '0';
				else fifo_ns <= ERASE_FIRST_READ; FIFO_busy <= '1';
				end if;
				FIFO_wr <= '0';
				fifoRAM_OE <= '0';
				fifoRAM_WE <= "1111";
				FIFO_saved <='0';
				FIFO_erased <='0';
			when ERASE_FIRST_READ =>
			   fifo_ns <= IDLE;
				FIFO_busy <= '1';
				FIFO_wr <= '0';
				fifoRAM_OE <= '0';
				fifoRAM_WE <= "1111";
				FIFO_saved <='0';
				FIFO_erased <='1';
			when EMPTY_ADDRESS =>
			   if sram_busy='1' then fifo_ns <= EMPTY_ADDRESS; FIFO_busy <= '0';
				else fifo_ns <= EMPTY_READ; FIFO_busy <= '1';
				end if;
				FIFO_busy <= '1';
				FIFO_wr <= '0';
				fifoRAM_OE <= '0';
				fifoRAM_WE <= "1111";
				FIFO_saved <='0';
				FIFO_erased <='0';
			when EMPTY_READ =>
			   fifo_ns <= IDLE;
				FIFO_busy <= '1';
				FIFO_wr <= '0';
				fifoRAM_OE <= '0';
				fifoRAM_WE <= "1111";
				FIFO_saved <='0';
				FIFO_erased <='0';
		end case;
	end process;
	
	FIFO_full <= ififo_full;
	FIFO_empty <= ififo_empty;
end A;