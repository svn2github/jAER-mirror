library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package DVSAERConfigRecords is
	constant DVSAERCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(1, 7);

	type tDVSAERConfigParamAddresses is record
		Run_S                 : unsigned(7 downto 0);
		AckDelay_D            : unsigned(7 downto 0);
		AckExtension_D        : unsigned(7 downto 0);
		WaitOnTransferStall_S : unsigned(7 downto 0);
		SendRowOnlyEvents_S   : unsigned(7 downto 0);
	end record tDVSAERConfigParamAddresses;

	constant DVSAERCONFIG_PARAM_ADDRESSES : tDVSAERConfigParamAddresses := (
		Run_S                 => to_unsigned(0, 8),
		AckDelay_D            => to_unsigned(1, 8),
		AckExtension_D        => to_unsigned(2, 8),
		WaitOnTransferStall_S => to_unsigned(3, 8),
		SendRowOnlyEvents_S   => to_unsigned(4, 8));

	type tDVSAERConfig is record
		Run_S                 : std_logic;
		AckDelay_D            : unsigned(4 downto 0);
		AckExtension_D        : unsigned(4 downto 0);
		WaitOnTransferStall_S : std_logic;
		SendRowOnlyEvents_S   : std_logic;
	end record tDVSAERConfig;

	constant tDVSAERConfigDefault : tDVSAERConfig := (
		Run_S                 => '0',
		AckDelay_D            => to_unsigned(2, tDVSAERConfig.AckDelay_D'length),
		AckExtension_D        => to_unsigned(1, tDVSAERConfig.AckExtension_D'length),
		WaitOnTransferStall_S => '0',
		SendRowOnlyEvents_S   => '0');
end package DVSAERConfigRecords;
