library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ChipBiasConfigRecords is
	constant CHIPBIASCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(5, 7);

	constant BIAS_REG_LENGTH : integer := 16;
	constant BIAS_CF_LENGTH  : integer := 15;
	constant BIAS_SS_LENGTH  : integer := 16;

	type tBiasConfigParamAddresses is record
		DiffBn_D           : unsigned(7 downto 0);
		OnBn_D             : unsigned(7 downto 0);
		OffBn_D            : unsigned(7 downto 0);
		ApsCasEpc_D        : unsigned(7 downto 0);
		DiffCasBnc_D       : unsigned(7 downto 0);
		ApsROSFBn_D        : unsigned(7 downto 0);
		LocalBufBn_D       : unsigned(7 downto 0);
		PixInvBn_D         : unsigned(7 downto 0);
		PrBp_D             : unsigned(7 downto 0);
		PrSFBp_D           : unsigned(7 downto 0);
		RefrBp_D           : unsigned(7 downto 0);
		AEPdBn_D           : unsigned(7 downto 0);
		LcolTimeoutBn_D    : unsigned(7 downto 0);
		AEPuXBp_D          : unsigned(7 downto 0);
		AEPuYBp_D          : unsigned(7 downto 0);
		IFThrBn_D          : unsigned(7 downto 0);
		IFRefrBn_D         : unsigned(7 downto 0);
		PadFollBn_D        : unsigned(7 downto 0);
		ApsOverflowLevel_D : unsigned(7 downto 0);
		BiasBuffer_D       : unsigned(7 downto 0);
		SSP_D              : unsigned(7 downto 0);
		SSN_D              : unsigned(7 downto 0);
	end record tBiasConfigParamAddresses;

	constant BIASCONFIG_PARAM_ADDRESSES : tBiasConfigParamAddresses := (
		DiffBn_D           => to_unsigned(0, 8),
		OnBn_D             => to_unsigned(1, 8),
		OffBn_D            => to_unsigned(2, 8),
		ApsCasEpc_D        => to_unsigned(3, 8),
		DiffCasBnc_D       => to_unsigned(4, 8),
		ApsROSFBn_D        => to_unsigned(5, 8),
		LocalBufBn_D       => to_unsigned(6, 8),
		PixInvBn_D         => to_unsigned(7, 8),
		PrBp_D             => to_unsigned(8, 8),
		PrSFBp_D           => to_unsigned(9, 8),
		RefrBp_D           => to_unsigned(10, 8),
		AEPdBn_D           => to_unsigned(11, 8),
		LcolTimeoutBn_D    => to_unsigned(12, 8),
		AEPuXBp_D          => to_unsigned(13, 8),
		AEPuYBp_D          => to_unsigned(14, 8),
		IFThrBn_D          => to_unsigned(15, 8),
		IFRefrBn_D         => to_unsigned(16, 8),
		PadFollBn_D        => to_unsigned(17, 8),
		ApsOverflowLevel_D => to_unsigned(18, 8),
		BiasBuffer_D       => to_unsigned(19, 8),
		SSP_D              => to_unsigned(20, 8),
		SSN_D              => to_unsigned(21, 8));

	type tBiasConfig is record
		DiffBn_D           : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		OnBn_D             : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		OffBn_D            : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		ApsCasEpc_D        : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		DiffCasBnc_D       : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		ApsROSFBn_D        : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		LocalBufBn_D       : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		PixInvBn_D         : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		PrBp_D             : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		PrSFBp_D           : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		RefrBp_D           : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		AEPdBn_D           : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		LcolTimeoutBn_D    : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		AEPuXBp_D          : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		AEPuYBp_D          : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		IFThrBn_D          : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		IFRefrBn_D         : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		PadFollBn_D        : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		ApsOverflowLevel_D : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		BiasBuffer_D       : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		SSP_D              : std_logic_vector(BIAS_SS_LENGTH - 1 downto 0);
		SSN_D              : std_logic_vector(BIAS_SS_LENGTH - 1 downto 0);
	end record tBiasConfig;

	constant tBiasConfigDefault : tBiasConfig := (
		DiffBn_D           => (others => '0'),
		OnBn_D             => (others => '0'),
		OffBn_D            => (others => '0'),
		ApsCasEpc_D        => (others => '0'),
		DiffCasBnc_D       => (others => '0'),
		ApsROSFBn_D        => (others => '0'),
		LocalBufBn_D       => (others => '0'),
		PixInvBn_D         => (others => '0'),
		PrBp_D             => (others => '0'),
		PrSFBp_D           => (others => '0'),
		RefrBp_D           => (others => '0'),
		AEPdBn_D           => (others => '0'),
		LcolTimeoutBn_D    => (others => '0'),
		AEPuXBp_D          => (others => '0'),
		AEPuYBp_D          => (others => '0'),
		IFThrBn_D          => (others => '0'),
		IFRefrBn_D         => (others => '0'),
		PadFollBn_D        => (others => '0'),
		ApsOverflowLevel_D => (others => '0'),
		BiasBuffer_D       => (others => '0'),
		SSP_D              => (others => '0'),
		SSN_D              => (others => '0'));

	constant CHIP_REG_LENGTH : integer := 56;

	type tChipConfigParamAddresses is record
		DigitalMux0_D         : unsigned(7 downto 0);
		DigitalMux1_D         : unsigned(7 downto 0);
		DigitalMux2_D         : unsigned(7 downto 0);
		DigitalMux3_D         : unsigned(7 downto 0);
		AnalogMux0_D          : unsigned(7 downto 0);
		AnalogMux1_D          : unsigned(7 downto 0);
		AnalogMux2_D          : unsigned(7 downto 0);
		BiasOutMux_D          : unsigned(7 downto 0);
		ResetCalibNeuron_S    : unsigned(7 downto 0);
		TypeNCalibNeuron_S    : unsigned(7 downto 0);
		ResetTestPixel_S      : unsigned(7 downto 0);
		HotPixelSuppression_S : unsigned(7 downto 0);
		AERnArow_S            : unsigned(7 downto 0);
		UseAOut_S             : unsigned(7 downto 0);
		GlobalShutter_S       : unsigned(7 downto 0);
	end record tChipConfigParamAddresses;

	-- Start with addresses at 50 here, to accomodate up to 50 biases easily, as required by new biasgen.
	constant CHIPCONFIG_PARAM_ADDRESSES : tChipConfigParamAddresses := (
		DigitalMux0_D         => to_unsigned(50, 8),
		DigitalMux1_D         => to_unsigned(51, 8),
		DigitalMux2_D         => to_unsigned(52, 8),
		DigitalMux3_D         => to_unsigned(53, 8),
		AnalogMux0_D          => to_unsigned(54, 8),
		AnalogMux1_D          => to_unsigned(55, 8),
		AnalogMux2_D          => to_unsigned(56, 8),
		BiasOutMux_D          => to_unsigned(57, 8),
		ResetCalibNeuron_S    => to_unsigned(58, 8),
		TypeNCalibNeuron_S    => to_unsigned(59, 8),
		ResetTestPixel_S      => to_unsigned(60, 8),
		HotPixelSuppression_S => to_unsigned(61, 8),
		AERnArow_S            => to_unsigned(62, 8),
		UseAOut_S             => to_unsigned(63, 8),
		GlobalShutter_S       => to_unsigned(64, 8));

	type tChipConfig is record
		DigitalMux0_D         : unsigned(3 downto 0);
		DigitalMux1_D         : unsigned(3 downto 0);
		DigitalMux2_D         : unsigned(3 downto 0);
		DigitalMux3_D         : unsigned(3 downto 0);
		AnalogMux0_D          : unsigned(3 downto 0);
		AnalogMux1_D          : unsigned(3 downto 0);
		AnalogMux2_D          : unsigned(3 downto 0);
		BiasOutMux_D          : unsigned(3 downto 0);
		ResetCalibNeuron_S    : std_logic;
		TypeNCalibNeuron_S    : std_logic;
		ResetTestPixel_S      : std_logic;
		HotPixelSuppression_S : std_logic;
		AERnArow_S            : std_logic;
		UseAOut_S             : std_logic;
		GlobalShutter_S       : std_logic;
	end record tChipConfig;

	constant tChipConfigDefault : tChipConfig := (
		DigitalMux0_D         => (others => '0'),
		DigitalMux1_D         => (others => '0'),
		DigitalMux2_D         => (others => '0'),
		DigitalMux3_D         => (others => '0'),
		AnalogMux0_D          => (others => '0'),
		AnalogMux1_D          => (others => '0'),
		AnalogMux2_D          => (others => '0'),
		BiasOutMux_D          => (others => '0'),
		ResetCalibNeuron_S    => '1',
		TypeNCalibNeuron_S    => '0',
		ResetTestPixel_S      => '1',
		HotPixelSuppression_S => '0',
		AERnArow_S            => '0',
		UseAOut_S             => '1',
		GlobalShutter_S       => '0');
end package ChipBiasConfigRecords;
