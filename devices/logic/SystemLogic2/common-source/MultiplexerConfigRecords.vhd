library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MultiplexerConfigRecords is
	constant MULTIPLEXERCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(0, 7);

	type tMultiplexerConfigParamAddresses is record
		Run_S                       : unsigned(7 downto 0);
		TimestampRun_S              : unsigned(7 downto 0);
		TimestampReset_S            : unsigned(7 downto 0);
		ForceChipBiasEnable_S       : unsigned(7 downto 0);
		DropInput1OnTransferStall_S : unsigned(7 downto 0);
		DropInput2OnTransferStall_S : unsigned(7 downto 0);
		DropInput3OnTransferStall_S : unsigned(7 downto 0);
		DropInput4OnTransferStall_S : unsigned(7 downto 0);
	end record tMultiplexerConfigParamAddresses;

	constant MULTIPLEXERCONFIG_PARAM_ADDRESSES : tMultiplexerConfigParamAddresses := (
		Run_S                       => to_unsigned(0, 8),
		TimestampRun_S              => to_unsigned(1, 8),
		TimestampReset_S            => to_unsigned(2, 8),
		ForceChipBiasEnable_S       => to_unsigned(3, 8),
		DropInput1OnTransferStall_S => to_unsigned(4, 8),
		DropInput2OnTransferStall_S => to_unsigned(5, 8),
		DropInput3OnTransferStall_S => to_unsigned(6, 8),
		DropInput4OnTransferStall_S => to_unsigned(7, 8));

	type tMultiplexerConfig is record
		Run_S                       : std_logic;
		TimestampRun_S              : std_logic;
		TimestampReset_S            : std_logic;
		ForceChipBiasEnable_S       : std_logic;
		DropInput1OnTransferStall_S : std_logic;
		DropInput2OnTransferStall_S : std_logic;
		DropInput3OnTransferStall_S : std_logic;
		DropInput4OnTransferStall_S : std_logic;
	end record tMultiplexerConfig;

	constant tMultiplexerConfigDefault : tMultiplexerConfig := (
		Run_S                       => '0',
		TimestampRun_S              => '0',
		TimestampReset_S            => '0',
		ForceChipBiasEnable_S       => '0',
		DropInput1OnTransferStall_S => '1',
		DropInput2OnTransferStall_S => '1',
		DropInput3OnTransferStall_S => '1',
		DropInput4OnTransferStall_S => '1');
end package MultiplexerConfigRecords;
