library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package TestConfigRecords is
	constant TESTCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(0, 7);

	type tTestConfigParamAddresses is record
		TestUSBFifo_S        : unsigned(7 downto 0);
		TestUSBOutputsHigh_S : unsigned(7 downto 0);
		TestBank0_S          : unsigned(7 downto 0);
		TestBank1_S          : unsigned(7 downto 0);
		TestBank2_S          : unsigned(7 downto 0);
		TestBank7_S          : unsigned(7 downto 0);
		TestAuxClock_S       : unsigned(7 downto 0);
		TestSERDESClock_S    : unsigned(7 downto 0);
		TestSyncConnectors_S : unsigned(7 downto 0);
		TestSRAM1_S          : unsigned(7 downto 0);
		TestSRAM2_S          : unsigned(7 downto 0);
		TestSRAM3_S          : unsigned(7 downto 0);
		TestSRAM4_S          : unsigned(7 downto 0);
	end record tTestConfigParamAddresses;

	constant TESTCONFIG_PARAM_ADDRESSES : tTestConfigParamAddresses := (
		TestUSBFifo_S        => to_unsigned(0, 8),
		TestUSBOutputsHigh_S => to_unsigned(1, 8),
		TestBank0_S          => to_unsigned(2, 8),
		TestBank1_S          => to_unsigned(3, 8),
		TestBank2_S          => to_unsigned(4, 8),
		TestBank7_S          => to_unsigned(5, 8),
		TestAuxClock_S       => to_unsigned(6, 8),
		TestSERDESClock_S    => to_unsigned(7, 8),
		TestSyncConnectors_S => to_unsigned(8, 8),
		TestSRAM1_S          => to_unsigned(9, 8),
		TestSRAM2_S          => to_unsigned(10, 8),
		TestSRAM3_S          => to_unsigned(11, 8),
		TestSRAM4_S          => to_unsigned(12, 8));

	type tTestConfig is record
		TestUSBFifo_S        : std_logic;
		TestUSBOutputsHigh_S : std_logic;
		TestBank0_S          : std_logic;
		TestBank1_S          : std_logic;
		TestBank2_S          : std_logic;
		TestBank7_S          : std_logic;
		TestAuxClock_S       : std_logic;
		TestSERDESClock_S    : std_logic;
		TestSyncConnectors_S : std_logic;
		TestSRAM1_S          : std_logic;
		TestSRAM2_S          : std_logic;
		TestSRAM3_S          : std_logic;
		TestSRAM4_S          : std_logic;
	end record tTestConfig;

	constant tTestConfigDefault : tTestConfig := (
		TestUSBFifo_S        => '0',
		TestUSBOutputsHigh_S => '0',
		TestBank0_S          => '0',
		TestBank1_S          => '0',
		TestBank2_S          => '0',
		TestBank7_S          => '0',
		TestAuxClock_S       => '0',
		TestSERDESClock_S    => '0',
		TestSyncConnectors_S => '0',
		TestSRAM1_S          => '0',
		TestSRAM2_S          => '0',
		TestSRAM3_S          => '0',
		TestSRAM4_S          => '0');
end package TestConfigRecords;
