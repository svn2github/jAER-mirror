library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package DAVIS240c is
	constant CHIP_IDENTIFIER : unsigned(3 downto 0) := to_unsigned(2, 4);

	constant CHIP_HAS_GLOBAL_SHUTTER : std_logic := '1';
	constant CHIP_HAS_INTEGRATED_ADC : std_logic := '0';

	constant CHIP_APS_SIZE_COLUMNS : unsigned(7 downto 0) := to_unsigned(240, 8);
	constant CHIP_APS_SIZE_ROWS    : unsigned(7 downto 0) := to_unsigned(180, 8);

	constant CHIP_DVS_SIZE_COLUMNS : unsigned(7 downto 0) := to_unsigned(240, 8);
	constant CHIP_DVS_SIZE_ROWS    : unsigned(7 downto 0) := to_unsigned(180, 8);

	constant DVS_AER_BUS_WIDTH : integer := 10;
	constant APS_ADC_BUS_WIDTH : integer := 10;
end package DAVIS240c;
