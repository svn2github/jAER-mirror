library ieee;
use ieee.std_logic_1164.all;

package ChipGeometry is
	constant ORIENTATION_STRAIGHT : std_logic_vector(1 downto 0) := "00";
	constant ORIENTATION_ROT90    : std_logic_vector(1 downto 0) := "01";
	constant ORIENTATION_ROT180   : std_logic_vector(1 downto 0) := "10";
	constant ORIENTATION_ROT270   : std_logic_vector(1 downto 0) := "11";

	constant APS_STREAM_START_UPPER_RIGHT : std_logic_vector(1 downto 0) := "11";
	constant APS_STREAM_START_UPPER_LEFT  : std_logic_vector(1 downto 0) := "01";
	constant APS_STREAM_START_LOWER_RIGHT : std_logic_vector(1 downto 0) := "10";
	constant APS_STREAM_START_LOWER_LEFT  : std_logic_vector(1 downto 0) := "00";

	constant DVS_ORIGIN_UPPER_RIGHT : std_logic_vector(1 downto 0) := "11";
	constant DVS_ORIGIN_UPPER_LEFT  : std_logic_vector(1 downto 0) := "01";
	constant DVS_ORIGIN_LOWER_RIGHT : std_logic_vector(1 downto 0) := "10";
	constant DVS_ORIGIN_LOWER_LEFT  : std_logic_vector(1 downto 0) := "00";
end package ChipGeometry;
