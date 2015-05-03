library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package SystemInfoConfigRecords is
	constant SYSTEMINFOCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(6, 7);

	type tSystemInfoConfigParamAddresses is record
		LogicVersion_D   : unsigned(7 downto 0);
		ChipIdentifier_D : unsigned(7 downto 0);
		DeviceIsMaster_S : unsigned(7 downto 0);
		LogicClock_D     : unsigned(7 downto 0);
		ADCClock_D       : unsigned(7 downto 0);
	end record tSystemInfoConfigParamAddresses;

	constant SYSTEMINFOCONFIG_PARAM_ADDRESSES : tSystemInfoConfigParamAddresses := (
		LogicVersion_D   => to_unsigned(0, 8),
		ChipIdentifier_D => to_unsigned(1, 8),
		DeviceIsMaster_S => to_unsigned(2, 8),
		LogicClock_D     => to_unsigned(3, 8),
		ADCClock_D       => to_unsigned(4, 8));
end package SystemInfoConfigRecords;
