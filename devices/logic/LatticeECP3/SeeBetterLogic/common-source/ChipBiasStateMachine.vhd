library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.CHIP_IDENTIFIER;
use work.ChipBiasConfigRecords.all;
use work.DAVIS128ChipBiasConfigRecords.all;
use work.DAVIS240ChipBiasConfigRecords.all;
use work.DAVIS346ChipBiasConfigRecords.all;
use work.DAVISrgbChipBiasConfigRecords.all;

entity ChipBiasStateMachine is
	port(
		Clock_CI                 : in  std_logic;
		Reset_RI                 : in  std_logic;

		-- Bias configuration outputs (to chip)
		ChipBiasDiagSelect_SO    : out std_logic;
		ChipBiasAddrSelect_SBO   : out std_logic;
		ChipBiasClock_CBO        : out std_logic;
		ChipBiasBitIn_DO         : out std_logic;
		ChipBiasLatch_SBO        : out std_logic;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI   : in  unsigned(6 downto 0);
		ConfigParamAddress_DI    : in  unsigned(7 downto 0);
		ConfigParamInput_DI      : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI      : in  std_logic;
		BiasConfigParamOutput_DO : out std_logic_vector(31 downto 0);
		ChipConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity ChipBiasStateMachine;

architecture Structural of ChipBiasStateMachine is
	signal DAVIS128BiasConfig_D : tDAVIS128BiasConfig;
	signal DAVIS128ChipConfig_D : tDAVIS128ChipConfig;
	signal DAVIS240BiasConfig_D : tDAVIS240BiasConfig;
	signal DAVIS240ChipConfig_D : tDAVIS240ChipConfig;
	signal DAVIS346ChipConfig_D : tDAVIS346ChipConfig;
	signal DAVISrgbBiasConfig_D : tDAVISrgbBiasConfig;
	signal DAVISrgbChipConfig_D : tDAVISrgbChipConfig;
begin
	davis128ChipBias : if CHIP_IDENTIFIER = 3 generate
		davis128ChipBiasSM : entity work.DAVIS128StateMachine
			port map(
				Clock_CI               => Clock_CI,
				Reset_RI               => Reset_RI,
				ChipBiasDiagSelect_SO  => ChipBiasDiagSelect_SO,
				ChipBiasAddrSelect_SBO => ChipBiasAddrSelect_SBO,
				ChipBiasClock_CBO      => ChipBiasClock_CBO,
				ChipBiasBitIn_DO       => ChipBiasBitIn_DO,
				ChipBiasLatch_SBO      => ChipBiasLatch_SBO,
				BiasConfig_DI          => DAVIS128BiasConfig_D,
				ChipConfig_DI          => DAVIS128ChipConfig_D);

		davis128ChipBiasSPIConfig : entity work.DAVIS128SPIConfig
			port map(
				Clock_CI                 => Clock_CI,
				Reset_RI                 => Reset_RI,
				BiasConfig_DO            => DAVIS128BiasConfig_D,
				ChipConfig_DO            => DAVIS128ChipConfig_D,
				ConfigModuleAddress_DI   => ConfigModuleAddress_DI,
				ConfigParamAddress_DI    => ConfigParamAddress_DI,
				ConfigParamInput_DI      => ConfigParamInput_DI,
				ConfigLatchInput_SI      => ConfigLatchInput_SI,
				BiasConfigParamOutput_DO => BiasConfigParamOutput_DO,
				ChipConfigParamOutput_DO => ChipConfigParamOutput_DO);
	end generate davis128ChipBias;

	davis240ChipBias : if CHIP_IDENTIFIER = 0 or CHIP_IDENTIFIER = 1 or CHIP_IDENTIFIER = 2 generate
		davis240ChipBiasSM : entity work.DAVIS240StateMachine
			port map(
				Clock_CI               => Clock_CI,
				Reset_RI               => Reset_RI,
				ChipBiasDiagSelect_SO  => ChipBiasDiagSelect_SO,
				ChipBiasAddrSelect_SBO => ChipBiasAddrSelect_SBO,
				ChipBiasClock_CBO      => ChipBiasClock_CBO,
				ChipBiasBitIn_DO       => ChipBiasBitIn_DO,
				ChipBiasLatch_SBO      => ChipBiasLatch_SBO,
				BiasConfig_DI          => DAVIS240BiasConfig_D,
				ChipConfig_DI          => DAVIS240ChipConfig_D);

		davis240ChipBiasSPIConfig : entity work.DAVIS240SPIConfig
			port map(
				Clock_CI                 => Clock_CI,
				Reset_RI                 => Reset_RI,
				BiasConfig_DO            => DAVIS240BiasConfig_D,
				ChipConfig_DO            => DAVIS240ChipConfig_D,
				ConfigModuleAddress_DI   => ConfigModuleAddress_DI,
				ConfigParamAddress_DI    => ConfigParamAddress_DI,
				ConfigParamInput_DI      => ConfigParamInput_DI,
				ConfigLatchInput_SI      => ConfigLatchInput_SI,
				BiasConfigParamOutput_DO => BiasConfigParamOutput_DO,
				ChipConfigParamOutput_DO => ChipConfigParamOutput_DO);
	end generate davis240ChipBias;

	-- DAVIS640 uses this too, since it has the same biases and chip config chain as DAVIS346.
	davis346ChipBias : if CHIP_IDENTIFIER = 4 or CHIP_IDENTIFIER = 5 or CHIP_IDENTIFIER = 6 generate
		davis346ChipBiasSM : entity work.DAVIS346StateMachine
			port map(
				Clock_CI               => Clock_CI,
				Reset_RI               => Reset_RI,
				ChipBiasDiagSelect_SO  => ChipBiasDiagSelect_SO,
				ChipBiasAddrSelect_SBO => ChipBiasAddrSelect_SBO,
				ChipBiasClock_CBO      => ChipBiasClock_CBO,
				ChipBiasBitIn_DO       => ChipBiasBitIn_DO,
				ChipBiasLatch_SBO      => ChipBiasLatch_SBO,
				BiasConfig_DI          => DAVIS128BiasConfig_D,
				ChipConfig_DI          => DAVIS346ChipConfig_D);

		davis346ChipBiasSPIConfig : entity work.DAVIS346SPIConfig
			port map(
				Clock_CI                 => Clock_CI,
				Reset_RI                 => Reset_RI,
				BiasConfig_DO            => DAVIS128BiasConfig_D,
				ChipConfig_DO            => DAVIS346ChipConfig_D,
				ConfigModuleAddress_DI   => ConfigModuleAddress_DI,
				ConfigParamAddress_DI    => ConfigParamAddress_DI,
				ConfigParamInput_DI      => ConfigParamInput_DI,
				ConfigLatchInput_SI      => ConfigLatchInput_SI,
				BiasConfigParamOutput_DO => BiasConfigParamOutput_DO,
				ChipConfigParamOutput_DO => ChipConfigParamOutput_DO);
	end generate davis346ChipBias;

	davisRGBChipBias : if CHIP_IDENTIFIER = 7 generate
		davisRGBChipBiasSM : entity work.DAVISrgbStateMachine
			port map(
				Clock_CI               => Clock_CI,
				Reset_RI               => Reset_RI,
				ChipBiasDiagSelect_SO  => ChipBiasDiagSelect_SO,
				ChipBiasAddrSelect_SBO => ChipBiasAddrSelect_SBO,
				ChipBiasClock_CBO      => ChipBiasClock_CBO,
				ChipBiasBitIn_DO       => ChipBiasBitIn_DO,
				ChipBiasLatch_SBO      => ChipBiasLatch_SBO,
				BiasConfig_DI          => DAVISrgbBiasConfig_D,
				ChipConfig_DI          => DAVISrgbChipConfig_D);

		davisRGBChipBiasSPIConfig : entity work.DAVISrgbSPIConfig
			port map(
				Clock_CI                 => Clock_CI,
				Reset_RI                 => Reset_RI,
				BiasConfig_DO            => DAVISrgbBiasConfig_D,
				ChipConfig_DO            => DAVISrgbChipConfig_D,
				ConfigModuleAddress_DI   => ConfigModuleAddress_DI,
				ConfigParamAddress_DI    => ConfigParamAddress_DI,
				ConfigParamInput_DI      => ConfigParamInput_DI,
				ConfigLatchInput_SI      => ConfigLatchInput_SI,
				BiasConfigParamOutput_DO => BiasConfigParamOutput_DO,
				ChipConfigParamOutput_DO => ChipConfigParamOutput_DO);
	end generate davisRGBChipBias;
end architecture Structural;
