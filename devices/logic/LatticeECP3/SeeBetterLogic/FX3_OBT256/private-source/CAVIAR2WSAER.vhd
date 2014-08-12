--------------------------------------------------------------------------------
-- Company: ini
-- Engineer: Alejandro Linares
--
-- Create Date:    14:16:08 06/17/14
-- Design Name:    
-- Module Name:    WSAER2CAVIAR 
-- Project Name:   VISUALIZE
-- Target Device:  Latticed LFE3-17EA-7ftn256i
-- Tool versions:  Diamond x64 3.0.0.97
-- Description: Module to convert word-serial AER from DAViS to CAVIAR parallel AER
--
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CAVIAR2WSAER is
  port (
    CAVIAR_ack    : out  std_logic;  -- needs synchronization
    CAVIAR_req    : in std_logic;
    CAVIAR_data   : in  std_logic_vector(16 downto 0);

    -- clock and reset inputs
	CLK : in std_logic;
    RST : in std_logic;
	alex: out std_logic_vector (1 downto 0);
    WSAER_data : out std_logic_vector(9 downto 0); --bit 0 is polarity and bit 9 row / column.
	WSAER_req : out std_logic; --Supossed to be active low
	WSAER_ack : in std_logic);--Supossed to be active low

end CAVIAR2WSAER;

architecture Structural of CAVIAR2WSAER is
   type tsm is (idle, waitACK_col, waitACK_row, waitnACK_row);
   signal cs, ns: tsm;
   signal no_row, tWSAER_req: std_logic;
   signal old_row: std_logic_vector (7 downto 0);
begin
BSEQ:process (CLK,RST)
begin
   if (RST='1') then
      WSAER_data <= (others => '0');
	  no_row <='1';
	  old_row <= (others => '0');
	  cs <= idle;
	  tWSAER_req<='1';
	  WSAER_req<='1';
	  CAVIAR_ack<='1';
	  alex<="00";
   elsif (CLK'event and CLK='1') then
      cs <= ns;
	  tWSAER_req<='1';	
	  CAVIAR_ack<='1';
	  WSAER_req <= tWSAER_req;
	  case (cs) is
	     when idle =>
		 	  alex<="00";
	     when waitACK_col => 
			WSAER_data <= "1" & CAVIAR_data (8 downto 0);  
			tWSAER_req<='0'; 
			CAVIAR_ack <='0';
			alex<="01";
		 when waitACK_row => 
			no_row <= '0'; 
			WSAER_data <= "00" & CAVIAR_data (16 downto 9);
			tWSAER_req <='0'; 
			old_row <= CAVIAR_data(16 downto 9);
			alex<="10";
		 when waitnACK_row =>
		 	  alex<="11";
	  end case;
   end if;
 end process;
BCOM: process (cs, CAVIAR_data, CAVIAR_req, WSAER_ack, old_row, no_row)begin
  case cs is 
     when idle => 
		if (CAVIAR_req='0' and (CAVIAR_data(16 downto 9) /= old_row or no_row = '1')) then
		   ns <= waitACK_row;
	    elsif (CAVIAR_req='0' and CAVIAR_data(16 downto 9) = old_row) then
		   ns <= waitACK_col;
		else ns <= idle;
		end if;
	when waitACK_col =>
		if WSAER_ack='0' then ns <= idle;
		else ns <= waitACK_col;
		end if;
	when waitACK_row =>
		if WSAER_ack='0' then ns <= waitnACK_row;
		else ns <= waitACK_row;
		end if;
	when waitnACK_row =>
		if WSAER_ack='0' then ns <= waitnACK_row;
		else ns <= waitACK_col;
		end if;
	when others => ns <= idle;
  end case;
end process;
end Structural;
  