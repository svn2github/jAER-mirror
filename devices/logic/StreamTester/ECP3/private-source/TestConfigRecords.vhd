library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package TestConfigRecords is
	constant TESTCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(0, 7);

	type tTestConfigParamAddresses is record
		TestUSBFifo_S        : unsigned(7 downto 0);
		TestUSBOutputsHigh_S : unsigned(7 downto 0);
		TestBank1_S          : unsigned(7 downto 0);
	end record tTestConfigParamAddresses;

	constant TESTCONFIG_PARAM_ADDRESSES : tTestConfigParamAddresses := (
		TestUSBFifo_S        => to_unsigned(0, 8),
		TestUSBOutputsHigh_S => to_unsigned(1, 8),
		TestBank1_S          => to_unsigned(2, 8));

	type tTestConfig is record
		TestUSBFifo_S        : std_logic;
		TestUSBOutputsHigh_S : std_logic;
		TestBank1_S          : std_logic;
	end record tTestConfig;

	constant tTestConfigDefault : tTestConfig := (
		TestUSBFifo_S        => '0',
		TestUSBOutputsHigh_S => '0',
		TestBank1_S          => '0');
end package TestConfigRecords;
