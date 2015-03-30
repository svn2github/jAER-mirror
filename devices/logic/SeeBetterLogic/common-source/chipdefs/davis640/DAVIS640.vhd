library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ChipGeometry.all;

package DAVIS640 is
	constant CHIP_IDENTIFIER : unsigned(3 downto 0) := to_unsigned(6, 4);

	constant CHIP_HAS_GLOBAL_SHUTTER : std_logic := '1';
	constant CHIP_HAS_INTEGRATED_ADC : std_logic := '1';

	constant CHIP_ORIENTATION      : std_logic_vector(1 downto 0) := ORIENTATION_STRAIGHT;
	constant CHIP_APS_STREAM_START : std_logic_vector(1 downto 0) := APS_STREAM_START_UPPER_LEFT;
	constant CHIP_DVS_ORIGIN_POINT : std_logic_vector(1 downto 0) := DVS_ORIGIN_LOWER_LEFT;

	constant CHIP_APS_SIZE_COLUMNS : unsigned(8 downto 0) := to_unsigned(480, 9);
	constant CHIP_APS_SIZE_ROWS    : unsigned(9 downto 0) := to_unsigned(640, 10);

	constant CHIP_DVS_SIZE_COLUMNS : unsigned(8 downto 0) := to_unsigned(480, 9);
	constant CHIP_DVS_SIZE_ROWS    : unsigned(9 downto 0) := to_unsigned(640, 10);

	constant DVS_AER_BUS_WIDTH : integer := 11;
	constant APS_ADC_BUS_WIDTH : integer := 10;
end package DAVIS640;
