library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package CochleaLP is
	constant CHIP_IDENTIFIER : unsigned(3 downto 0) := to_unsigned(11, 4);

	constant AER_BUS_WIDTH : integer := 8;
end package CochleaLP;
