library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ExtTriggerConfigRecords is
	constant EXTTRIGGERCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(4, 7);

	type tExtTriggerConfigParamAddresses is record
		Run_S : unsigned(7 downto 0);
	end record tExtTriggerConfigParamAddresses;

	constant EXTTRIGGERCONFIG_PARAM_ADDRESSES : tExtTriggerConfigParamAddresses := (
		Run_S => to_unsigned(0, 8));

	type tExtTriggerConfig is record
		Run_S : std_logic;
	end record tExtTriggerConfig;

	constant tExtTriggerConfigDefault : tExtTriggerConfig := (
		Run_S => '0');
end package ExtTriggerConfigRecords;
