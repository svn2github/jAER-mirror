library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ExtTriggerConfigRecords is
	constant EXTTRIGGERCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(4, 7);
end package ExtTriggerConfigRecords;
