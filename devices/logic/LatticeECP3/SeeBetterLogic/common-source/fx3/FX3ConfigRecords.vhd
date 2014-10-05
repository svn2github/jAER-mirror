library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package FX3ConfigRecords is
	constant FX3CONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(9, 7);

	type tFX3ConfigParamAddresses is record
		Run_S              : unsigned(7 downto 0);
		EarlyPacketDelay_D : unsigned(7 downto 0);
	end record tFX3ConfigParamAddresses;

	constant FX3CONFIG_PARAM_ADDRESSES : tFX3ConfigParamAddresses := (
		Run_S              => to_unsigned(0, 8),
		EarlyPacketDelay_D => to_unsigned(1, 8));

	type tFX3Config is record
		Run_S              : std_logic;
		EarlyPacketDelay_D : unsigned(9 downto 0);
	end record tFX3Config;

	constant tFX3ConfigDefault : tFX3Config := (
		Run_S              => '1',
		EarlyPacketDelay_D => to_unsigned(1, 10));
end package FX3ConfigRecords;
