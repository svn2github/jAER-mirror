library ieee;
use ieee.std_logic_1164.all;

package ChipGeometry is
	constant AXES_KEEP   : std_logic := '0';
	constant AXES_INVERT : std_logic := '1';

	constant START_UPPER_RIGHT : std_logic_vector(1 downto 0) := "11";
	constant START_UPPER_LEFT  : std_logic_vector(1 downto 0) := "01";
	constant START_LOWER_RIGHT : std_logic_vector(1 downto 0) := "10";
	constant START_LOWER_LEFT  : std_logic_vector(1 downto 0) := "00";
end package ChipGeometry;
