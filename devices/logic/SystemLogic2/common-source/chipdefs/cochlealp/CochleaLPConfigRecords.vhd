library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ChipBiasConfigRecords.all;

package CochleaLPChipBiasConfigRecords is
	type tCochleaLPBiasConfigParamAddresses is record
		VBNIBias_D   : unsigned(7 downto 0);
		VBNTest_D    : unsigned(7 downto 0);
		VBPScan_D    : unsigned(7 downto 0);
		AEPdBn_D     : unsigned(7 downto 0);
		AEPuYBp_D    : unsigned(7 downto 0);
		BiasBuffer_D : unsigned(7 downto 0);
		SSP_D        : unsigned(7 downto 0);
		SSN_D        : unsigned(7 downto 0);
	end record tCochleaLPBiasConfigParamAddresses;

	constant COCHLEALP_BIASCONFIG_PARAM_ADDRESSES : tCochleaLPBiasConfigParamAddresses := (
		VBNIBias_D   => to_unsigned(0, 8),
		VBNTest_D    => to_unsigned(1, 8),
		VBPScan_D    => to_unsigned(8, 8),
		AEPdBn_D     => to_unsigned(11, 8),
		AEPuYBp_D    => to_unsigned(14, 8),
		BiasBuffer_D => to_unsigned(19, 8),
		SSP_D        => to_unsigned(20, 8),
		SSN_D        => to_unsigned(21, 8));

	type tCochleaLPBiasConfig is record
		VBNIBias_D   : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		VBNTest_D    : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		VBPScan_D    : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		AEPdBn_D     : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		AEPuYBp_D    : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		BiasBuffer_D : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		SSP_D        : std_logic_vector(BIAS_SS_LENGTH - 1 downto 0);
		SSN_D        : std_logic_vector(BIAS_SS_LENGTH - 1 downto 0);
	end record tCochleaLPBiasConfig;

	constant tCochleaLPBiasConfigDefault : tCochleaLPBiasConfig := (
		VBNIBias_D   => (others => '0'),
		VBNTest_D    => (others => '0'),
		VBPScan_D    => (others => '0'),
		AEPdBn_D     => (others => '0'),
		AEPuYBp_D    => (others => '0'),
		BiasBuffer_D => (others => '0'),
		SSP_D        => (others => '0'),
		SSN_D        => (others => '0'));

	type tCochleaLPChipConfigParamAddresses is record
		ResetCapConfigADM_D    : unsigned(7 downto 0);
		DelayCapConfigADM_D    : unsigned(7 downto 0);
		ComparatorSelfOsc_S    : unsigned(7 downto 0);
		LNAGainConfig_D        : unsigned(7 downto 0);
		LNADoubleInputSelect_S : unsigned(7 downto 0);
		TestScannerBias_S      : unsigned(7 downto 0);
	end record tCochleaLPChipConfigParamAddresses;

	-- Start with addresses 128 here, so that the MSB (bit 7) is always high. This heavily simplifies
	-- the SPI configuration module, and clearly separates biases from chip diagnostic.
	constant COCHLEALP_CHIPCONFIG_PARAM_ADDRESSES : tCochleaLPChipConfigParamAddresses := (
		ResetCapConfigADM_D    => to_unsigned(128, 8),
		DelayCapConfigADM_D    => to_unsigned(129, 8),
		ComparatorSelfOsc_S    => to_unsigned(130, 8),
		LNAGainConfig_D        => to_unsigned(131, 8),
		LNADoubleInputSelect_S => to_unsigned(132, 8),
		TestScannerBias_S      => to_unsigned(133, 8));

	-- Total length of actual register to send out.
	constant CHIP_REG_LENGTH : integer := 24;

	-- Effectively used bits in chip register.
	constant CHIP_REG_USED_SIZE : integer := 11;

	type tCochleaLPChipConfig is record
		ResetCapConfigADM_D    : unsigned(1 downto 0);
		DelayCapConfigADM_D    : unsigned(2 downto 0);
		ComparatorSelfOsc_S    : std_logic;
		LNAGainConfig_D        : unsigned(2 downto 0);
		LNADoubleInputSelect_S : std_logic;
		TestScannerBias_S      : std_logic;
	end record tCochleaLPChipConfig;

	constant tCochleaLPChipConfigDefault : tCochleaLPChipConfig := (
		ResetCapConfigADM_D    => (others => '0'),
		DelayCapConfigADM_D    => (others => '0'),
		ComparatorSelfOsc_S    => '0',
		LNAGainConfig_D        => (others => '0'),
		LNADoubleInputSelect_S => '0',
		TestScannerBias_S      => '0');

	-- There are 64 channels here.
	constant CHIP_CHAN_NUMBER : integer := 64;

	--  Total length of actual register to send out.
	constant CHIP_CHANADDR_REG_LENGTH : integer := 16;

	-- Effectively used bits in channel address config registers.
	constant CHIP_CHANADDR_REG_USED_SIZE : integer := 6;

	-- Total length of actual register to send out.
	constant CHIP_CHAN_REG_LENGTH : integer := 24;

	-- Effectively used bits in channel config registers.
	constant CHIP_CHAN_REG_USED_SIZE : integer := 20;

	type tCochleaLPChannelConfigParamAddresses is record
		ChannelAddress_D   : unsigned(7 downto 0);
		ChannelDataRead_D  : unsigned(7 downto 0);
		ChannelDataWrite_D : unsigned(7 downto 0);
		ChannelSet_S       : unsigned(7 downto 0);
	end record tCochleaLPChannelConfigParamAddresses;

	-- Start with addresses 160 here, so that the MSB (bit 7) is always high, plus 32 to
	-- distance from the above standard chip configuration.
	constant COCHLEALP_CHANNELCONFIG_PARAM_ADDRESSES : tCochleaLPChannelConfigParamAddresses := (
		ChannelAddress_D   => to_unsigned(160, 8),
		ChannelDataRead_D  => to_unsigned(161, 8),
		ChannelDataWrite_D => to_unsigned(162, 8),
		ChannelSet_S       => to_unsigned(163, 8));

	type tCochleaLPChannelConfig is record
		ChannelAddress_D   : unsigned(CHIP_CHANADDR_REG_USED_SIZE - 1 downto 0);
		ChannelDataWrite_D : std_logic_vector(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelSet_S       : std_logic;
	end record tCochleaLPChannelConfig;

	constant tCochleaLPChannelConfigDefault : tCochleaLPChannelConfig := (
		ChannelAddress_D   => (others => '0'),
		ChannelDataWrite_D => (others => '0'),
		ChannelSet_S       => '0');
end package CochleaLPChipBiasConfigRecords;
