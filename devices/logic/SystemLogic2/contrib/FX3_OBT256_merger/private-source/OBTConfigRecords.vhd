library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package OBTConfigRecords is
	constant OBTCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(11, 7);

	type tOBTConfigParamAddresses is record
		Run_S		   : unsigned(7 downto 0);
		AckDelay_D	   : unsigned(7 downto 0);
		AckExtension_D : unsigned(7 downto 0);
	end record tOBTConfigParamAddresses;

	constant OBTCONFIG_PARAM_ADDRESSES : tOBTConfigParamAddresses := (
		Run_S		   => to_unsigned(1, 8),
		AckDelay_D	   => to_unsigned(2, 8),
		AckExtension_D => to_unsigned(3, 8));

	type tOBTConfig is record
		Run_S		   : std_logic;
		AckDelay_D	   : unsigned(4 downto 0);
		AckExtension_D : unsigned(4 downto 0);
	end record tOBTConfig;

	constant tOBTConfigDefault : tOBTConfig := (
		Run_S		   => '0',
		AckDelay_D	   => to_unsigned(2, tOBTConfig.AckDelay_D'length),
		AckExtension_D => to_unsigned(1, tOBTConfig.AckExtension_D'length));
end package OBTConfigRecords;
