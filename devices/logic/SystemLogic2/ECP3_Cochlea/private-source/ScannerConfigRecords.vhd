library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ScannerConfigRecords is
	constant SCANNERCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(8, 7);

	type tScannerConfigParamAddresses is record
		ScannerEnabled_S : unsigned(7 downto 0);
		ScannerChannel_D : unsigned(7 downto 0);
	end record tScannerConfigParamAddresses;

	constant SCANNERCONFIG_PARAM_ADDRESSES : tScannerConfigParamAddresses := (
		ScannerEnabled_S => to_unsigned(0, 8),
		ScannerChannel_D => to_unsigned(1, 8));

	type tScannerConfig is record
		ScannerEnabled_S : std_logic;
		ScannerChannel_D : unsigned(6 downto 0); -- Up to 128 distinct channels.
	end record tScannerConfig;

	constant tScannerConfigDefault : tScannerConfig := (
		ScannerEnabled_S => '0',
		ScannerChannel_D => (others => '0'));
end package ScannerConfigRecords;
