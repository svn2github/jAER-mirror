library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package DACConfigRecords is
	constant DACCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(7, 7);

	type tDACConfigParamAddresses is record
		Run_S       : unsigned(7 downto 0);
		DAC_D       : unsigned(7 downto 0);
		Register_D  : unsigned(7 downto 0);
		Channel_D   : unsigned(7 downto 0);
		DataRead_D  : unsigned(7 downto 0);
		DataWrite_D : unsigned(7 downto 0);
		Set_S       : unsigned(7 downto 0);
	end record tDACConfigParamAddresses;

	constant DACCONFIG_PARAM_ADDRESSES : tDACConfigParamAddresses := (
		Run_S       => to_unsigned(0, 8),
		DAC_D       => to_unsigned(1, 8),
		Register_D  => to_unsigned(2, 8),
		Channel_D   => to_unsigned(3, 8),
		DataRead_D  => to_unsigned(4, 8),
		DataWrite_D => to_unsigned(5, 8),
		Set_S       => to_unsigned(6, 8));

	-- Support up to 4 DACs, with up to 4 registers, each with up to 16 channels each.
	constant DAC_CHAN_NUMBER : integer := 4 * 4 * 16;

	constant DAC_REGISTER_LENGTH : integer := 2;
	constant DAC_CHANNEL_LENGTH  : integer := 4;
	constant DAC_DATA_LENGTH     : integer := 12;

	type tDACConfig is record
		Run_S       : std_logic;
		DAC_D       : unsigned(1 downto 0); -- Address up to 4 DACs.
		Register_D  : unsigned(DAC_REGISTER_LENGTH - 1 downto 0);
		Channel_D   : unsigned(DAC_CHANNEL_LENGTH - 1 downto 0);
		DataWrite_D : std_logic_vector(DAC_DATA_LENGTH - 1 downto 0);
		Set_S       : std_logic;
	end record tDACConfig;

	constant tDACConfigDefault : tDACConfig := (
		Run_S       => '0',
		DAC_D       => (others => '0'),
		Register_D  => (others => '0'),
		Channel_D   => (others => '0'),
		DataWrite_D => (others => '0'),
		Set_S       => '0');
end package DACConfigRecords;
