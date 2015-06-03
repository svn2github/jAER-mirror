library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package DACConfigRecords is
	constant DACCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(7, 7);

	type tDACConfigParamAddresses is record
		Run_S       : unsigned(7 downto 0);
		ReadWrite_S : unsigned(7 downto 0);
		Register_D  : unsigned(7 downto 0);
		Channel_D   : unsigned(7 downto 0);
		DataRead_D  : unsigned(7 downto 0);
		DataWrite_D : unsigned(7 downto 0);
		Execute_S   : unsigned(7 downto 0);
	end record tDACConfigParamAddresses;

	constant DACCONFIG_PARAM_ADDRESSES : tDACConfigParamAddresses := (
		Run_S       => to_unsigned(0, 8),
		ReadWrite_S => to_unsigned(1, 8),
		Register_D  => to_unsigned(2, 8),
		Channel_D   => to_unsigned(3, 8),
		DataRead_D  => to_unsigned(4, 8),
		DataWrite_D => to_unsigned(5, 8),
		Execute_S   => to_unsigned(6, 8));

	constant DAC_REGISTER_LENGTH : integer := 2;
	constant DAC_CHANNEL_LENGTH  : integer := 4;
	constant DAC_DATA_LENGTH     : integer := 12;

	type tDACConfig is record
		Run_S       : std_logic;
		ReadWrite_S : std_logic;
		Register_D  : unsigned(DAC_REGISTER_LENGTH - 1 downto 0);
		Channel_D   : unsigned(DAC_CHANNEL_LENGTH - 1 downto 0);
		DataWrite_D : unsigned(DAC_DATA_LENGTH - 1 downto 0);
		Execute_S   : std_logic;
	end record tDACConfig;

	constant tDACConfigDefault : tDACConfig := (
		Run_S       => '0',
		ReadWrite_S => '0',
		Register_D  => (others => '0'),
		Channel_D   => (others => '0'),
		DataWrite_D => (others => '0'),
		Execute_S   => '0');
end package DACConfigRecords;
