library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ChipBiasConfigRecords.all;

package AERCorrFilterChipBiasConfigRecords is
	type tAERCorrFilterBiasConfigParamAddresses is record
		Vth_D        : unsigned(7 downto 0);
		Vrs_D        : unsigned(7 downto 0);
		LocalBufBn_D : unsigned(7 downto 0);
		PadFollBn_D  : unsigned(7 downto 0);
		BiasComp_D   : unsigned(7 downto 0);
		ILeak_D      : unsigned(7 downto 0);
		IFRefrBn_D   : unsigned(7 downto 0);
		IFThrBn_D    : unsigned(7 downto 0);
		BiasBuffer_D : unsigned(7 downto 0);
		SSP_D        : unsigned(7 downto 0);
		SSN_D        : unsigned(7 downto 0);
	end record tAERCorrFilterBiasConfigParamAddresses;

	constant AERCorrFilter_BIASCONFIG_PARAM_ADDRESSES : tAERCorrFilterBiasConfigParamAddresses := (
		Vth_D        => to_unsigned(0, 8),
		Vrs_D        => to_unsigned(1, 8),
		LocalBufBn_D => to_unsigned(8, 8),
		PadFollBn_D  => to_unsigned(9, 8),
		BiasComp_D   => to_unsigned(14, 8),
		ILeak_D      => to_unsigned(20, 8),
		IFRefrBn_D   => to_unsigned(26, 8),
		IFThrBn_D    => to_unsigned(27, 8),
		BiasBuffer_D => to_unsigned(34, 8),
		SSP_D        => to_unsigned(35, 8),
		SSN_D        => to_unsigned(36, 8));

	type tAERCorrFilterBiasConfig is record
		Vth_D        : std_logic_vector(BIAS_VD_LENGTH - 1 downto 0);
		Vrs_D        : std_logic_vector(BIAS_VD_LENGTH - 1 downto 0);
		LocalBufBn_D : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		PadFollBn_D  : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		BiasComp_D   : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		ILeak_D      : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		IFRefrBn_D   : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		IFThrBn_D    : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		BiasBuffer_D : std_logic_vector(BIAS_CF_LENGTH - 1 downto 0);
		SSP_D        : std_logic_vector(BIAS_SS_LENGTH - 1 downto 0);
		SSN_D        : std_logic_vector(BIAS_SS_LENGTH - 1 downto 0);
	end record tAERCorrFilterBiasConfig;

	constant tAERCorrFilterBiasConfigDefault : tAERCorrFilterBiasConfig := (
		Vth_D        => (others => '0'),
		Vrs_D        => (others => '0'),
		LocalBufBn_D => (others => '0'),
		PadFollBn_D  => (others => '0'),
		BiasComp_D   => (others => '0'),
		ILeak_D      => (others => '0'),
		IFRefrBn_D   => (others => '0'),
		IFThrBn_D    => (others => '0'),
		BiasBuffer_D => (others => '0'),
		SSP_D        => (others => '0'),
		SSN_D        => (others => '0'));

	type tAERCorrFilterChipConfigParamAddresses is record
		DigitalMux0_D      : unsigned(7 downto 0);
		DigitalMux1_D      : unsigned(7 downto 0);
		DigitalMux2_D      : unsigned(7 downto 0);
		DigitalMux3_D      : unsigned(7 downto 0);
		AnalogMux0_D       : unsigned(7 downto 0);
		AnalogMux1_D       : unsigned(7 downto 0);
		AnalogMux2_D       : unsigned(7 downto 0);
		AnalogMux3_D       : unsigned(7 downto 0);
		BiasMux0_D         : unsigned(7 downto 0);
		ResetCalibNeuron_S : unsigned(7 downto 0);
		TypeNCalibNeuron_S : unsigned(7 downto 0);
		UseAOut_S          : unsigned(7 downto 0);
		ChipIDX0_S         : unsigned(7 downto 0);
		ChipIDX1_S         : unsigned(7 downto 0);
		AMCX0_S            : unsigned(7 downto 0);
		AMCX1_S            : unsigned(7 downto 0);
		AMDX0_S            : unsigned(7 downto 0);
		AMDX1_S            : unsigned(7 downto 0);
		ChipIDY0_S         : unsigned(7 downto 0);
		ChipIDY1_S         : unsigned(7 downto 0);
		AMCY0_S            : unsigned(7 downto 0);
		AMCY1_S            : unsigned(7 downto 0);
		AMDY0_S            : unsigned(7 downto 0);
		AMDY1_S            : unsigned(7 downto 0);
	end record tAERCorrFilterChipConfigParamAddresses;

	-- Start with addresses 128 here, so that the MSB (bit 7) is always high. This heavily simplifies
	-- the SPI configuration module, and clearly separates biases from chip diagnostic.
	constant AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES : tAERCorrFilterChipConfigParamAddresses := (
		DigitalMux0_D      => to_unsigned(128, 8),
		DigitalMux1_D      => to_unsigned(129, 8),
		DigitalMux2_D      => to_unsigned(130, 8),
		DigitalMux3_D      => to_unsigned(131, 8),
		AnalogMux0_D       => to_unsigned(132, 8),
		AnalogMux1_D       => to_unsigned(133, 8),
		AnalogMux2_D       => to_unsigned(134, 8),
		AnalogMux3_D       => to_unsigned(135, 8),
		BiasMux0_D         => to_unsigned(136, 8),
		ResetCalibNeuron_S => to_unsigned(137, 8),
		TypeNCalibNeuron_S => to_unsigned(138, 8),
		UseAOut_S          => to_unsigned(139, 8),
		ChipIDX0_S         => to_unsigned(140, 8),
		ChipIDX1_S         => to_unsigned(141, 8),
		AMCX0_S            => to_unsigned(142, 8),
		AMCX1_S            => to_unsigned(143, 8),
		AMDX0_S            => to_unsigned(144, 8),
		AMDX1_S            => to_unsigned(145, 8),
		ChipIDY0_S         => to_unsigned(146, 8),
		ChipIDY1_S         => to_unsigned(147, 8),
		AMCY0_S            => to_unsigned(148, 8),
		AMCY1_S            => to_unsigned(149, 8),
		AMDY0_S            => to_unsigned(150, 8),
		AMDY1_S            => to_unsigned(151, 8));

	type tAERCorrFilterChipConfig is record
		DigitalMux0_D      : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		DigitalMux1_D      : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		DigitalMux2_D      : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		DigitalMux3_D      : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		AnalogMux0_D       : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		AnalogMux1_D       : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		AnalogMux2_D       : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		AnalogMux3_D       : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		BiasMux0_D         : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		ResetCalibNeuron_S : std_logic;
		TypeNCalibNeuron_S : std_logic;
		UseAOut_S          : std_logic;
		ChipIDX0_S         : std_logic;
		ChipIDX1_S         : std_logic;
		AMCX0_S            : std_logic;
		AMCX1_S            : std_logic;
		AMDX0_S            : std_logic;
		AMDX1_S            : std_logic;
		ChipIDY0_S         : std_logic;
		ChipIDY1_S         : std_logic;
		AMCY0_S            : std_logic;
		AMCY1_S            : std_logic;
		AMDY0_S            : std_logic;
		AMDY1_S            : std_logic;
	end record tAERCorrFilterChipConfig;

	-- Total length of actual register to send out.
	constant CHIP_REG_LENGTH : integer := 60;

	-- Effectively used bits in chip register.
	constant CHIP_REG_USED_SIZE : integer := (9 * CHIP_MUX_LENGTH) + 15;

	constant tAERCorrFilterChipConfigDefault : tAERCorrFilterChipConfig := (
		DigitalMux0_D      => (others => '0'),
		DigitalMux1_D      => (others => '0'),
		DigitalMux2_D      => (others => '0'),
		DigitalMux3_D      => (others => '0'),
		AnalogMux0_D       => (others => '0'),
		AnalogMux1_D       => (others => '0'),
		AnalogMux2_D       => (others => '0'),
		AnalogMux3_D       => (others => '0'),
		BiasMux0_D         => (others => '0'),
		ResetCalibNeuron_S => '1',
		TypeNCalibNeuron_S => '0',
		UseAOut_S          => '0',
		ChipIDX0_S         => '0',
		ChipIDX1_S         => '0',
		AMCX0_S            => '0',
		AMCX1_S            => '0',
		AMDX0_S            => '0',
		AMDX1_S            => '0',
		ChipIDY0_S         => '0',
		ChipIDY1_S         => '0',
		AMCY0_S            => '0',
		AMCY1_S            => '0',
		AMDY0_S            => '0',
		AMDY1_S            => '0');
end package AERCorrFilterChipBiasConfigRecords;
