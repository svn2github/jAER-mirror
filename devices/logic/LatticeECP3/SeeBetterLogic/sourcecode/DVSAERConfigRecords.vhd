library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package DVSAERConfigRecords is
	constant DVSAERCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(2, 7);

	type tDVSAERConfigParamAddresses is record
		ackDelay	 : unsigned(7 downto 0);
		ackExtension : unsigned(7 downto 0);
	end record tDVSAERConfigParamAddresses;

	constant DVSAERCONFIG_PARAM_ADDRESSES : tDVSAERConfigParamAddresses := (
		ackDelay	 => to_unsigned(1, 8),
		ackExtension => to_unsigned(2, 8));

	type tDVSAERConfig is record
		ackDelay	 : unsigned(4 downto 0);
		ackExtension : unsigned(4 downto 0);
	end record tDVSAERConfig;

	constant DVSAERCONFIG_MAX_PARAM_LENGTH : integer := 5;
	constant DVSAERCONFIG_TOTAL_LENGTH	   : integer := tDVSAERConfig.ackDelay'length + tDVSAERConfig.ackExtension'length;

	constant tDVSAERConfigDefault : tDVSAERConfig := (
		ackDelay	 => to_unsigned(2, tDVSAERConfig.ackDelay'length),
		ackExtension => to_unsigned(1, tDVSAERConfig.ackExtension'length));
end package DVSAERConfigRecords;
