library ieee;
use ieee.std_logic_1164.all;

entity SimpleRegister is
	generic(
		RESET_VALUE : std_logic := '0');

	port(
		Clock_CI  : in  std_logic;
		Reset_RI  : in  std_logic;
		Enable_SI : in  std_logic;
		Input_SI  : in  std_logic;
		Output_SO : out std_logic);
end entity SimpleRegister;

architecture Behavioral of SimpleRegister is
begin
	registerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			Output_SO <= RESET_VALUE;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			if Enable_SI = '1' then
				Output_SO <= Input_SI;
			end if;
		end if;
	end process registerUpdate;
end architecture Behavioral;
