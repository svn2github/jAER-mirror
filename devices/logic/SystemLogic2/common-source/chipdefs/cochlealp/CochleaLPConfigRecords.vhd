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

	-- Channels are 64, so 0-63 (6 bits).
	-- Ears are 2, '0' is left, '1' is right.
	type tCochleaLPChipConfigParamAddresses is record
		ResetCapConfigADM_D    : unsigned(7 downto 0);
		DelayCapConfigADM_D    : unsigned(7 downto 0);
		ComparatorSelfOsc_S    : unsigned(7 downto 0);
		LNAGainConfig_D        : unsigned(7 downto 0);
		LNADoubleInputSelect_S : unsigned(7 downto 0);
		TestScannerBias_S      : unsigned(7 downto 0);
		ScannerEnabled_S       : unsigned(7 downto 0);
		ScannerEar_S           : unsigned(7 downto 0);
		ScannerChannel_S       : unsigned(7 downto 0);
		ChannelConfig0_D       : unsigned(7 downto 0);
		ChannelConfig1_D       : unsigned(7 downto 0);
		ChannelConfig2_D       : unsigned(7 downto 0);
		ChannelConfig3_D       : unsigned(7 downto 0);
		ChannelConfig4_D       : unsigned(7 downto 0);
		ChannelConfig5_D       : unsigned(7 downto 0);
		ChannelConfig6_D       : unsigned(7 downto 0);
		ChannelConfig7_D       : unsigned(7 downto 0);
		ChannelConfig8_D       : unsigned(7 downto 0);
		ChannelConfig9_D       : unsigned(7 downto 0);
		ChannelConfig10_D      : unsigned(7 downto 0);
		ChannelConfig11_D      : unsigned(7 downto 0);
		ChannelConfig12_D      : unsigned(7 downto 0);
		ChannelConfig13_D      : unsigned(7 downto 0);
		ChannelConfig14_D      : unsigned(7 downto 0);
		ChannelConfig15_D      : unsigned(7 downto 0);
		ChannelConfig16_D      : unsigned(7 downto 0);
		ChannelConfig17_D      : unsigned(7 downto 0);
		ChannelConfig18_D      : unsigned(7 downto 0);
		ChannelConfig19_D      : unsigned(7 downto 0);
		ChannelConfig20_D      : unsigned(7 downto 0);
		ChannelConfig21_D      : unsigned(7 downto 0);
		ChannelConfig22_D      : unsigned(7 downto 0);
		ChannelConfig23_D      : unsigned(7 downto 0);
		ChannelConfig24_D      : unsigned(7 downto 0);
		ChannelConfig25_D      : unsigned(7 downto 0);
		ChannelConfig26_D      : unsigned(7 downto 0);
		ChannelConfig27_D      : unsigned(7 downto 0);
		ChannelConfig28_D      : unsigned(7 downto 0);
		ChannelConfig29_D      : unsigned(7 downto 0);
		ChannelConfig30_D      : unsigned(7 downto 0);
		ChannelConfig31_D      : unsigned(7 downto 0);
		ChannelConfig32_D      : unsigned(7 downto 0);
		ChannelConfig33_D      : unsigned(7 downto 0);
		ChannelConfig34_D      : unsigned(7 downto 0);
		ChannelConfig35_D      : unsigned(7 downto 0);
		ChannelConfig36_D      : unsigned(7 downto 0);
		ChannelConfig37_D      : unsigned(7 downto 0);
		ChannelConfig38_D      : unsigned(7 downto 0);
		ChannelConfig39_D      : unsigned(7 downto 0);
		ChannelConfig40_D      : unsigned(7 downto 0);
		ChannelConfig41_D      : unsigned(7 downto 0);
		ChannelConfig42_D      : unsigned(7 downto 0);
		ChannelConfig43_D      : unsigned(7 downto 0);
		ChannelConfig44_D      : unsigned(7 downto 0);
		ChannelConfig45_D      : unsigned(7 downto 0);
		ChannelConfig46_D      : unsigned(7 downto 0);
		ChannelConfig47_D      : unsigned(7 downto 0);
		ChannelConfig48_D      : unsigned(7 downto 0);
		ChannelConfig49_D      : unsigned(7 downto 0);
		ChannelConfig50_D      : unsigned(7 downto 0);
		ChannelConfig51_D      : unsigned(7 downto 0);
		ChannelConfig52_D      : unsigned(7 downto 0);
		ChannelConfig53_D      : unsigned(7 downto 0);
		ChannelConfig54_D      : unsigned(7 downto 0);
		ChannelConfig55_D      : unsigned(7 downto 0);
		ChannelConfig56_D      : unsigned(7 downto 0);
		ChannelConfig57_D      : unsigned(7 downto 0);
		ChannelConfig58_D      : unsigned(7 downto 0);
		ChannelConfig59_D      : unsigned(7 downto 0);
		ChannelConfig60_D      : unsigned(7 downto 0);
		ChannelConfig61_D      : unsigned(7 downto 0);
		ChannelConfig62_D      : unsigned(7 downto 0);
		ChannelConfig63_D      : unsigned(7 downto 0);
	end record tCochleaLPChipConfigParamAddresses;

	-- Start with addresses 128 here, so that the MSB (bit 7) is always high. This heavily simplifies
	-- the SPI configuration module, and clearly separates biases from chip diagnostic.
	constant COCHLEALP_CHIPCONFIG_PARAM_ADDRESSES : tCochleaLPChipConfigParamAddresses := (
		ResetCapConfigADM_D    => to_unsigned(128, 8),
		DelayCapConfigADM_D    => to_unsigned(129, 8),
		ComparatorSelfOsc_S    => to_unsigned(130, 8),
		LNAGainConfig_D        => to_unsigned(131, 8),
		LNADoubleInputSelect_S => to_unsigned(132, 8),
		TestScannerBias_S      => to_unsigned(133, 8),
		ScannerEnabled_S       => to_unsigned(134, 8),
		ScannerEar_S           => to_unsigned(135, 8),
		ScannerChannel_S       => to_unsigned(136, 8),
		ChannelConfig0_D       => to_unsigned(137, 8),
		ChannelConfig1_D       => to_unsigned(138, 8),
		ChannelConfig2_D       => to_unsigned(139, 8),
		ChannelConfig3_D       => to_unsigned(140, 8),
		ChannelConfig4_D       => to_unsigned(141, 8),
		ChannelConfig5_D       => to_unsigned(142, 8),
		ChannelConfig6_D       => to_unsigned(143, 8),
		ChannelConfig7_D       => to_unsigned(144, 8),
		ChannelConfig8_D       => to_unsigned(145, 8),
		ChannelConfig9_D       => to_unsigned(146, 8),
		ChannelConfig10_D      => to_unsigned(147, 8),
		ChannelConfig11_D      => to_unsigned(148, 8),
		ChannelConfig12_D      => to_unsigned(149, 8),
		ChannelConfig13_D      => to_unsigned(150, 8),
		ChannelConfig14_D      => to_unsigned(151, 8),
		ChannelConfig15_D      => to_unsigned(152, 8),
		ChannelConfig16_D      => to_unsigned(153, 8),
		ChannelConfig17_D      => to_unsigned(154, 8),
		ChannelConfig18_D      => to_unsigned(155, 8),
		ChannelConfig19_D      => to_unsigned(156, 8),
		ChannelConfig20_D      => to_unsigned(157, 8),
		ChannelConfig21_D      => to_unsigned(158, 8),
		ChannelConfig22_D      => to_unsigned(159, 8),
		ChannelConfig23_D      => to_unsigned(160, 8),
		ChannelConfig24_D      => to_unsigned(161, 8),
		ChannelConfig25_D      => to_unsigned(162, 8),
		ChannelConfig26_D      => to_unsigned(163, 8),
		ChannelConfig27_D      => to_unsigned(164, 8),
		ChannelConfig28_D      => to_unsigned(165, 8),
		ChannelConfig29_D      => to_unsigned(166, 8),
		ChannelConfig30_D      => to_unsigned(167, 8),
		ChannelConfig31_D      => to_unsigned(168, 8),
		ChannelConfig32_D      => to_unsigned(169, 8),
		ChannelConfig33_D      => to_unsigned(170, 8),
		ChannelConfig34_D      => to_unsigned(171, 8),
		ChannelConfig35_D      => to_unsigned(172, 8),
		ChannelConfig36_D      => to_unsigned(173, 8),
		ChannelConfig37_D      => to_unsigned(174, 8),
		ChannelConfig38_D      => to_unsigned(175, 8),
		ChannelConfig39_D      => to_unsigned(176, 8),
		ChannelConfig40_D      => to_unsigned(177, 8),
		ChannelConfig41_D      => to_unsigned(178, 8),
		ChannelConfig42_D      => to_unsigned(179, 8),
		ChannelConfig43_D      => to_unsigned(180, 8),
		ChannelConfig44_D      => to_unsigned(181, 8),
		ChannelConfig45_D      => to_unsigned(182, 8),
		ChannelConfig46_D      => to_unsigned(183, 8),
		ChannelConfig47_D      => to_unsigned(184, 8),
		ChannelConfig48_D      => to_unsigned(185, 8),
		ChannelConfig49_D      => to_unsigned(186, 8),
		ChannelConfig50_D      => to_unsigned(187, 8),
		ChannelConfig51_D      => to_unsigned(188, 8),
		ChannelConfig52_D      => to_unsigned(189, 8),
		ChannelConfig53_D      => to_unsigned(190, 8),
		ChannelConfig54_D      => to_unsigned(191, 8),
		ChannelConfig55_D      => to_unsigned(192, 8),
		ChannelConfig56_D      => to_unsigned(193, 8),
		ChannelConfig57_D      => to_unsigned(194, 8),
		ChannelConfig58_D      => to_unsigned(195, 8),
		ChannelConfig59_D      => to_unsigned(196, 8),
		ChannelConfig60_D      => to_unsigned(197, 8),
		ChannelConfig61_D      => to_unsigned(198, 8),
		ChannelConfig62_D      => to_unsigned(199, 8),
		ChannelConfig63_D      => to_unsigned(200, 8));

	-- Effectively used bits in channel config registers.
	constant CHIP_CHAN_REG_USED_SIZE : integer := 20;

	type tCochleaLPChipConfig is record
		ResetCapConfigADM_D    : unsigned(1 downto 0);
		DelayCapConfigADM_D    : unsigned(2 downto 0);
		ComparatorSelfOsc_S    : std_logic;
		LNAGainConfig_D        : unsigned(2 downto 0);
		LNADoubleInputSelect_S : std_logic;
		TestScannerBias_S      : std_logic;
		ScannerEnabled_S       : std_logic;
		ScannerEar_S           : std_logic;
		ScannerChannel_S       : unsigned(5 downto 0);
		ChannelConfig0_D       : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig1_D       : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig2_D       : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig3_D       : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig4_D       : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig5_D       : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig6_D       : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig7_D       : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig8_D       : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig9_D       : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig10_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig11_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig12_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig13_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig14_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig15_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig16_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig17_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig18_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig19_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig20_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig21_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig22_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig23_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig24_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig25_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig26_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig27_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig28_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig29_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig30_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig31_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig32_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig33_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig34_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig35_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig36_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig37_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig38_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig39_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig40_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig41_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig42_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig43_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig44_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig45_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig46_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig47_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig48_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig49_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig50_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig51_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig52_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig53_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig54_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig55_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig56_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig57_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig58_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig59_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig60_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig61_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig62_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
		ChannelConfig63_D      : unsigned(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);
	end record tCochleaLPChipConfig;

	-- Total length of actual register to send out.
	constant CHIP_REG_LENGTH : integer := 24;

	-- Effectively used bits in chip register.
	constant CHIP_REG_USED_SIZE : integer := 11;

	constant tCochleaLPChipConfigDefault : tCochleaLPChipConfig := (
		ResetCapConfigADM_D    => (others => '0'),
		DelayCapConfigADM_D    => (others => '0'),
		ComparatorSelfOsc_S    => '0',
		LNAGainConfig_D        => (others => '0'),
		LNADoubleInputSelect_S => '0',
		TestScannerBias_S      => '0',
		ScannerEnabled_S       => '0',
		ScannerEar_S           => '0',
		ScannerChannel_S       => (others => '0'),
		ChannelConfig0_D       => (others => '0'),
		ChannelConfig1_D       => (others => '0'),
		ChannelConfig2_D       => (others => '0'),
		ChannelConfig3_D       => (others => '0'),
		ChannelConfig4_D       => (others => '0'),
		ChannelConfig5_D       => (others => '0'),
		ChannelConfig6_D       => (others => '0'),
		ChannelConfig7_D       => (others => '0'),
		ChannelConfig8_D       => (others => '0'),
		ChannelConfig9_D       => (others => '0'),
		ChannelConfig10_D      => (others => '0'),
		ChannelConfig11_D      => (others => '0'),
		ChannelConfig12_D      => (others => '0'),
		ChannelConfig13_D      => (others => '0'),
		ChannelConfig14_D      => (others => '0'),
		ChannelConfig15_D      => (others => '0'),
		ChannelConfig16_D      => (others => '0'),
		ChannelConfig17_D      => (others => '0'),
		ChannelConfig18_D      => (others => '0'),
		ChannelConfig19_D      => (others => '0'),
		ChannelConfig20_D      => (others => '0'),
		ChannelConfig21_D      => (others => '0'),
		ChannelConfig22_D      => (others => '0'),
		ChannelConfig23_D      => (others => '0'),
		ChannelConfig24_D      => (others => '0'),
		ChannelConfig25_D      => (others => '0'),
		ChannelConfig26_D      => (others => '0'),
		ChannelConfig27_D      => (others => '0'),
		ChannelConfig28_D      => (others => '0'),
		ChannelConfig29_D      => (others => '0'),
		ChannelConfig30_D      => (others => '0'),
		ChannelConfig31_D      => (others => '0'),
		ChannelConfig32_D      => (others => '0'),
		ChannelConfig33_D      => (others => '0'),
		ChannelConfig34_D      => (others => '0'),
		ChannelConfig35_D      => (others => '0'),
		ChannelConfig36_D      => (others => '0'),
		ChannelConfig37_D      => (others => '0'),
		ChannelConfig38_D      => (others => '0'),
		ChannelConfig39_D      => (others => '0'),
		ChannelConfig40_D      => (others => '0'),
		ChannelConfig41_D      => (others => '0'),
		ChannelConfig42_D      => (others => '0'),
		ChannelConfig43_D      => (others => '0'),
		ChannelConfig44_D      => (others => '0'),
		ChannelConfig45_D      => (others => '0'),
		ChannelConfig46_D      => (others => '0'),
		ChannelConfig47_D      => (others => '0'),
		ChannelConfig48_D      => (others => '0'),
		ChannelConfig49_D      => (others => '0'),
		ChannelConfig50_D      => (others => '0'),
		ChannelConfig51_D      => (others => '0'),
		ChannelConfig52_D      => (others => '0'),
		ChannelConfig53_D      => (others => '0'),
		ChannelConfig54_D      => (others => '0'),
		ChannelConfig55_D      => (others => '0'),
		ChannelConfig56_D      => (others => '0'),
		ChannelConfig57_D      => (others => '0'),
		ChannelConfig58_D      => (others => '0'),
		ChannelConfig59_D      => (others => '0'),
		ChannelConfig60_D      => (others => '0'),
		ChannelConfig61_D      => (others => '0'),
		ChannelConfig62_D      => (others => '0'),
		ChannelConfig63_D      => (others => '0'));
end package CochleaLPChipBiasConfigRecords;
