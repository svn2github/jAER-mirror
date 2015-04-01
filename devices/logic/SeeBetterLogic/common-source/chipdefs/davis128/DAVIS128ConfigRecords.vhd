library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.CHIP_HAS_GLOBAL_SHUTTER;
use work.ChipBiasConfigRecords.all;

package DAVIS128ChipBiasConfigRecords is
	type tDAVIS128BiasConfigParamAddresses is record
		ApsOverflowLevel_D : unsigned(7 downto 0);
		ApsCas_D           : unsigned(7 downto 0);
		AdcRefHigh_D       : unsigned(7 downto 0);
		AdcRefLow_D        : unsigned(7 downto 0);
		AdcTestVoltage_D   : unsigned(7 downto 0);
		LocalBufBn_D       : unsigned(7 downto 0);
		PadFollBn_D        : unsigned(7 downto 0);
		DiffBn_D           : unsigned(7 downto 0);
		OnBn_D             : unsigned(7 downto 0);
		OffBn_D            : unsigned(7 downto 0);
		PixInvBn_D         : unsigned(7 downto 0);
		PrBp_D             : unsigned(7 downto 0);
		PrSFBp_D           : unsigned(7 downto 0);
		RefrBp_D           : unsigned(7 downto 0);
		ReadoutBufBp_D     : unsigned(7 downto 0);
		ApsROSFBn_D        : unsigned(7 downto 0);
		AdcCompBp_D        : unsigned(7 downto 0);
		ColSelLowBn_D      : unsigned(7 downto 0);
		DACBufBp_D         : unsigned(7 downto 0);
		LcolTimeoutBn_D    : unsigned(7 downto 0);
		AEPdBn_D           : unsigned(7 downto 0);
		AEPuXBp_D          : unsigned(7 downto 0);
		AEPuYBp_D          : unsigned(7 downto 0);
		IFRefrBn_D         : unsigned(7 downto 0);
		IFThrBn_D          : unsigned(7 downto 0);
		BiasBuffer_D       : unsigned(7 downto 0);
		SSP_D              : unsigned(7 downto 0);
		SSN_D              : unsigned(7 downto 0);
	end record tDAVIS128BiasConfigParamAddresses;

	constant DAVIS128_BIASCONFIG_PARAM_ADDRESSES : tDAVIS128BiasConfigParamAddresses := (
		ApsOverflowLevel_D => to_unsigned(0, 8),
		ApsCas_D           => to_unsigned(1, 8),
		AdcRefHigh_D       => to_unsigned(2, 8),
		AdcRefLow_D        => to_unsigned(3, 8),
		AdcTestVoltage_D   => to_unsigned(4, 8),
		LocalBufBn_D       => to_unsigned(8, 8),
		PadFollBn_D        => to_unsigned(9, 8),
		DiffBn_D           => to_unsigned(10, 8),
		OnBn_D             => to_unsigned(11, 8),
		OffBn_D            => to_unsigned(12, 8),
		PixInvBn_D         => to_unsigned(13, 8),
		PrBp_D             => to_unsigned(14, 8),
		PrSFBp_D           => to_unsigned(15, 8),
		RefrBp_D           => to_unsigned(16, 8),
		ReadoutBufBp_D     => to_unsigned(17, 8),
		ApsROSFBn_D        => to_unsigned(18, 8),
		AdcCompBp_D        => to_unsigned(19, 8),
		ColSelLowBn_D      => to_unsigned(20, 8),
		DACBufBp_D         => to_unsigned(21, 8),
		LcolTimeoutBn_D    => to_unsigned(22, 8),
		AEPdBn_D           => to_unsigned(23, 8),
		AEPuXBp_D          => to_unsigned(24, 8),
		AEPuYBp_D          => to_unsigned(25, 8),
		IFRefrBn_D         => to_unsigned(26, 8),
		IFThrBn_D          => to_unsigned(27, 8),
		BiasBuffer_D       => to_unsigned(34, 8),
		SSP_D              => to_unsigned(35, 8),
		SSN_D              => to_unsigned(36, 8));

	type tDAVIS128BiasConfig is record
		ApsOverflowLevel_D : std_logic_vector(BIAS_VD_LENGTH - 1 downto 0);
		ApsCas_D           : std_logic_vector(BIAS_VD_LENGTH - 1 downto 0);
		AdcRefHigh_D       : std_logic_vector(BIAS_VD_LENGTH - 1 downto 0);
		AdcRefLow_D        : std_logic_vector(BIAS_VD_LENGTH - 1 downto 0);
		AdcTestVoltage_D   : std_logic_vector(BIAS_VD_LENGTH - 1 downto 0);
		LocalBufBn_D       : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		PadFollBn_D        : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		DiffBn_D           : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		OnBn_D             : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		OffBn_D            : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		PixInvBn_D         : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		PrBp_D             : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		PrSFBp_D           : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		RefrBp_D           : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		ReadoutBufBp_D     : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		ApsROSFBn_D        : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		AdcCompBp_D        : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		ColSelLowBn_D      : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		DACBufBp_D         : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		LcolTimeoutBn_D    : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		AEPdBn_D           : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		AEPuXBp_D          : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		AEPuYBp_D          : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		IFRefrBn_D         : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		IFThrBn_D          : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		BiasBuffer_D       : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		SSP_D              : std_logic_vector(BIAS_SS_LENGTH - 1 downto 0);
		SSN_D              : std_logic_vector(BIAS_SS_LENGTH - 1 downto 0);
	end record tDAVIS128BiasConfig;

	constant tDAVIS128BiasConfigDefault : tDAVIS128BiasConfig := (
		ApsOverflowLevel_D => (others => '0'),
		ApsCas_D           => (others => '0'),
		AdcRefHigh_D       => (others => '0'),
		AdcRefLow_D        => (others => '0'),
		AdcTestVoltage_D   => (others => '0'),
		LocalBufBn_D       => (others => '0'),
		PadFollBn_D        => (others => '0'),
		DiffBn_D           => (others => '0'),
		OnBn_D             => (others => '0'),
		OffBn_D            => (others => '0'),
		PixInvBn_D         => (others => '0'),
		PrBp_D             => (others => '0'),
		PrSFBp_D           => (others => '0'),
		RefrBp_D           => (others => '0'),
		ReadoutBufBp_D     => (others => '0'),
		ApsROSFBn_D        => (others => '0'),
		AdcCompBp_D        => (others => '0'),
		ColSelLowBn_D      => (others => '0'),
		DACBufBp_D         => (others => '0'),
		LcolTimeoutBn_D    => (others => '0'),
		AEPdBn_D           => (others => '0'),
		AEPuXBp_D          => (others => '0'),
		AEPuYBp_D          => (others => '0'),
		IFRefrBn_D         => (others => '0'),
		IFThrBn_D          => (others => '0'),
		BiasBuffer_D       => (others => '0'),
		SSP_D              => (others => '0'),
		SSN_D              => (others => '0'));

	type tDAVIS128ChipConfigParamAddresses is record
		DigitalMux0_D         : unsigned(7 downto 0);
		DigitalMux1_D         : unsigned(7 downto 0);
		DigitalMux2_D         : unsigned(7 downto 0);
		DigitalMux3_D         : unsigned(7 downto 0);
		AnalogMux0_D          : unsigned(7 downto 0);
		AnalogMux1_D          : unsigned(7 downto 0);
		AnalogMux2_D          : unsigned(7 downto 0);
		BiasMux0_D            : unsigned(7 downto 0);
		ResetCalibNeuron_S    : unsigned(7 downto 0);
		TypeNCalibNeuron_S    : unsigned(7 downto 0);
		ResetTestPixel_S      : unsigned(7 downto 0);
		AERnArow_S            : unsigned(7 downto 0);
		UseAOut_S             : unsigned(7 downto 0);
		GlobalShutter_S       : unsigned(7 downto 0);
		SelectGrayCounter_S   : unsigned(7 downto 0);
	end record tDAVIS128ChipConfigParamAddresses;

	-- Start with addresses 128 here, so that the MSB (bit 7) is always high. This heavily simplifies
	-- the SPI configuration module, and clearly separates biases from chip diagnostic.
	constant DAVIS128_CHIPCONFIG_PARAM_ADDRESSES : tDAVIS128ChipConfigParamAddresses := (
		DigitalMux0_D         => to_unsigned(128, 8),
		DigitalMux1_D         => to_unsigned(129, 8),
		DigitalMux2_D         => to_unsigned(130, 8),
		DigitalMux3_D         => to_unsigned(131, 8),
		AnalogMux0_D          => to_unsigned(132, 8),
		AnalogMux1_D          => to_unsigned(133, 8),
		AnalogMux2_D          => to_unsigned(134, 8),
		BiasMux0_D            => to_unsigned(135, 8),
		ResetCalibNeuron_S    => to_unsigned(136, 8),
		TypeNCalibNeuron_S    => to_unsigned(137, 8),
		ResetTestPixel_S      => to_unsigned(138, 8),
		AERnArow_S            => to_unsigned(140, 8),
		UseAOut_S             => to_unsigned(141, 8),
		GlobalShutter_S       => to_unsigned(142, 8),
		SelectGrayCounter_S   => to_unsigned(143, 8));

	type tDAVIS128ChipConfig is record
		DigitalMux0_D         : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		DigitalMux1_D         : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		DigitalMux2_D         : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		DigitalMux3_D         : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		AnalogMux0_D          : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		AnalogMux1_D          : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		AnalogMux2_D          : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		BiasMux0_D            : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		ResetCalibNeuron_S    : std_logic;
		TypeNCalibNeuron_S    : std_logic;
		ResetTestPixel_S      : std_logic;
		AERnArow_S            : std_logic;
		UseAOut_S             : std_logic;
		GlobalShutter_S       : std_logic;
		SelectGrayCounter_S   : std_logic;
	end record tDAVIS128ChipConfig;

	-- Effectively used bits in chip register.
	constant CHIP_REG_USED_SIZE : integer := (8 * CHIP_MUX_LENGTH) + 7;

	constant tDAVIS128ChipConfigDefault : tDAVIS128ChipConfig := (
		DigitalMux0_D         => (others => '0'),
		DigitalMux1_D         => (others => '0'),
		DigitalMux2_D         => (others => '0'),
		DigitalMux3_D         => (others => '0'),
		AnalogMux0_D          => (others => '0'),
		AnalogMux1_D          => (others => '0'),
		AnalogMux2_D          => (others => '0'),
		BiasMux0_D            => (others => '0'),
		ResetCalibNeuron_S    => '1',
		TypeNCalibNeuron_S    => '0',
		ResetTestPixel_S      => '1',
		AERnArow_S            => '0',
		UseAOut_S             => '0',
		GlobalShutter_S       => CHIP_HAS_GLOBAL_SHUTTER,
		SelectGrayCounter_S   => '0');
end package DAVIS128ChipBiasConfigRecords;
