library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package APSADCConfigRecords is
	constant APSADCCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(2, 7);
end package APSADCConfigRecords;
