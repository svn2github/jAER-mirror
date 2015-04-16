library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ACConfigRecords is
	--constant ACCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(1, 7);

	--type tACConfigParamAddresses is record
		--Run_S          : unsigned(7 downto 0);
		--AckDelay_D     : unsigned(7 downto 0);
		--AckExtension_D : unsigned(7 downto 0);
	--end record tACConfigParamAddresses;

	--constant ACCONFIG_PARAM_ADDRESSES : tACConfigParamAddresses := (
		--Run_S          => to_unsigned(0, 8),
		--AckDelay_D     => to_unsigned(1, 8),
		--AckExtension_D => to_unsigned(2, 8));

	
	type tACConfig is record
		DecayCounter_Size : Integer;
		TimeCounter_Size : Integer ;
		UpdateUnit:  signed (7 downto 0);
		IFThreshold: signed(63 downto 0);
	end record tACConfig;

end package ACConfigRecords;


		 