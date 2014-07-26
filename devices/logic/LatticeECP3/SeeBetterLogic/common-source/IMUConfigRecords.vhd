library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package IMUConfigRecords is
	constant IMUCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(3, 7);
end package IMUConfigRecords;
