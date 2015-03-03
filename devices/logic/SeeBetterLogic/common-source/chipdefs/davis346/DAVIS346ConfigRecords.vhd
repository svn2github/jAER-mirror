library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.CHIP_HAS_GLOBAL_SHUTTER;
use work.ChipBiasConfigRecords.all;

package DAVIS346ChipBiasConfigRecords is
	type tDAVIS346ChipConfigParamAddresses is record
		DigitalMux0_D       : unsigned(7 downto 0);
		DigitalMux1_D       : unsigned(7 downto 0);
		DigitalMux2_D       : unsigned(7 downto 0);
		DigitalMux3_D       : unsigned(7 downto 0);
		AnalogMux0_D        : unsigned(7 downto 0);
		AnalogMux1_D        : unsigned(7 downto 0);
		AnalogMux2_D        : unsigned(7 downto 0);
		BiasOutMux_D        : unsigned(7 downto 0);
		ResetCalibNeuron_S  : unsigned(7 downto 0);
		TypeNCalibNeuron_S  : unsigned(7 downto 0);
		ResetTestPixel_S    : unsigned(7 downto 0);
		AERnArow_S          : unsigned(7 downto 0);
		UseAOut_S           : unsigned(7 downto 0);
		GlobalShutter_S     : unsigned(7 downto 0);
		SelectGrayCounter_S : unsigned(7 downto 0);
		TestADC_S           : unsigned(7 downto 0);
	end record tDAVIS346ChipConfigParamAddresses;

	-- Start with addresses 128 here, so that the MSB (bit 7) is always high. This heavily simplifies
	-- the SPI configuration module, and clearly separates biases from chip diagnostic.
	constant DAVIS346_CHIPCONFIG_PARAM_ADDRESSES : tDAVIS346ChipConfigParamAddresses := (
		DigitalMux0_D       => to_unsigned(128, 8),
		DigitalMux1_D       => to_unsigned(129, 8),
		DigitalMux2_D       => to_unsigned(130, 8),
		DigitalMux3_D       => to_unsigned(131, 8),
		AnalogMux0_D        => to_unsigned(132, 8),
		AnalogMux1_D        => to_unsigned(133, 8),
		AnalogMux2_D        => to_unsigned(134, 8),
		BiasOutMux_D        => to_unsigned(135, 8),
		ResetCalibNeuron_S  => to_unsigned(136, 8),
		TypeNCalibNeuron_S  => to_unsigned(137, 8),
		ResetTestPixel_S    => to_unsigned(138, 8),
		AERnArow_S          => to_unsigned(140, 8),
		UseAOut_S           => to_unsigned(141, 8),
		GlobalShutter_S     => to_unsigned(142, 8),
		SelectGrayCounter_S => to_unsigned(143, 8),
		TestADC_S           => to_unsigned(144, 8));

	type tDAVIS346ChipConfig is record
		DigitalMux0_D       : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		DigitalMux1_D       : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		DigitalMux2_D       : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		DigitalMux3_D       : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		AnalogMux0_D        : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		AnalogMux1_D        : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		AnalogMux2_D        : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		BiasOutMux_D        : unsigned(CHIP_MUX_LENGTH - 1 downto 0);
		ResetCalibNeuron_S  : std_logic;
		TypeNCalibNeuron_S  : std_logic;
		ResetTestPixel_S    : std_logic;
		AERnArow_S          : std_logic;
		UseAOut_S           : std_logic;
		GlobalShutter_S     : std_logic;
		SelectGrayCounter_S : std_logic;
		TestADC_S           : std_logic;
	end record tDAVIS346ChipConfig;

	-- Effectively used bits in chip register.
	constant CHIP_REG_USED_SIZE : integer := (8 * CHIP_MUX_LENGTH) + 8;

	constant tDAVIS346ChipConfigDefault : tDAVIS346ChipConfig := (
		DigitalMux0_D       => (others => '0'),
		DigitalMux1_D       => (others => '0'),
		DigitalMux2_D       => (others => '0'),
		DigitalMux3_D       => (others => '0'),
		AnalogMux0_D        => (others => '0'),
		AnalogMux1_D        => (others => '0'),
		AnalogMux2_D        => (others => '0'),
		BiasOutMux_D        => (others => '0'),
		ResetCalibNeuron_S  => '1',
		TypeNCalibNeuron_S  => '0',
		ResetTestPixel_S    => '1',
		AERnArow_S          => '0',
		UseAOut_S           => '1',
		GlobalShutter_S     => CHIP_HAS_GLOBAL_SHUTTER,
		SelectGrayCounter_S => '0',
		TestADC_S           => '0');
end package DAVIS346ChipBiasConfigRecords;
