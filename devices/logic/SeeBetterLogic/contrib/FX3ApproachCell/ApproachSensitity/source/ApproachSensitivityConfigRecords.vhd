library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package APPROACHCELLConfigRecords is
	constant APPROACHCELLCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(1, 7);

	type tAPPROACHCELLConfigParamAddresses is record
		Run_S          : unsigned(7 downto 0);
	
	end record tAPPROACHCELLConfigParamAddresses;

	constant APPROACHCELLCONFIG_PARAM_ADDRESSES : tAPPROACHCELLConfigParamAddresses := (
		Run_S          => to_unsigned(0, 8),
		
	type tAPPROACHCELLConfig is record
		Run_S          : std_logic;
		
	end record tAPPROACHCELLConfig;

	constant tAPPROACHCELLConfigDefault : tAPPROACHCELLConfig := (
		Run_S          => '0',
	
end package APPROACHCELLConfigRecords;