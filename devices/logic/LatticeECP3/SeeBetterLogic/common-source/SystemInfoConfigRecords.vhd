library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package SystemInfoConfigRecords is
	constant SYSTEMINFOCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(6, 7);

	type tSystemInfoConfigParamAddresses is record
		LogicVersion_D         : unsigned(7 downto 0);
		ChipIdentifier_D       : unsigned(7 downto 0);
		ChipAPSSizeColumns_D   : unsigned(7 downto 0);
		ChipAPSSizeRows_D      : unsigned(7 downto 0);
		ChipDVSSizeColumns_D   : unsigned(7 downto 0);
		ChipDVSSizeRows_D      : unsigned(7 downto 0);
		ChipHasGlobalShutter_S : unsigned(7 downto 0);
		ChipHasIntegratedADC_S : unsigned(7 downto 0);
		DeviceIsMaster_S       : unsigned(7 downto 0);
	end record tSystemInfoConfigParamAddresses;

	constant SYSTEMINFOCONFIG_PARAM_ADDRESSES : tSystemInfoConfigParamAddresses := (
		LogicVersion_D         => to_unsigned(0, 8),
		ChipIdentifier_D       => to_unsigned(1, 8),
		ChipAPSSizeColumns_D   => to_unsigned(2, 8),
		ChipAPSSizeRows_D      => to_unsigned(3, 8),
		ChipDVSSizeColumns_D   => to_unsigned(4, 8),
		ChipDVSSizeRows_D      => to_unsigned(5, 8),
		ChipHasGlobalShutter_S => to_unsigned(6, 8),
		ChipHasIntegratedADC_S => to_unsigned(7, 8),
		DeviceIsMaster_S       => to_unsigned(8, 8));
end package SystemInfoConfigRecords;
