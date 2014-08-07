library ieee;
use ieee.std_logic_1164.all;

entity SimpleRegister is
	generic(
		SIZE        : integer := 1;
		RESET_VALUE : boolean := false);
	port(
		Clock_CI  : in  std_logic;
		Reset_RI  : in  std_logic;
		Enable_SI : in  std_logic;
		Input_SI  : in  std_logic_vector(SIZE - 1 downto 0);
		Output_SO : out std_logic_vector(SIZE - 1 downto 0));
end entity SimpleRegister;

architecture Behavioral of SimpleRegister is
begin
	registerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			if RESET_VALUE then
				Output_SO <= (others => '1');
			else
				Output_SO <= (others => '0');
			end if;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			if Enable_SI = '1' then
				Output_SO <= Input_SI;
			end if;
		end if;
	end process registerUpdate;
end architecture Behavioral;
