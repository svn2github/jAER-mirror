library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.CHIP_IDENTIFIER;
use work.ChipBiasConfigRecords.all;
use work.DAVIS128ChipBiasConfigRecords.all;
use work.DAVIS208ChipBiasConfigRecords.all;
use work.DAVIS240ChipBiasConfigRecords.all;
use work.DAVIS346ChipBiasConfigRecords.all;
use work.DAVISrgbChipBiasConfigRecords.all;

entity ChipBiasSelector is
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
end entity ChipBiasSelector;

architecture Structural of ChipBiasSelector is
begin
	davis128ChipBias : if CHIP_IDENTIFIER = 3 generate
		signal DAVIS128BiasConfig_D, DAVIS128BiasConfigReg_D : tDAVIS128BiasConfig;
		signal DAVIS128ChipConfig_D, DAVIS128ChipConfigReg_D : tDAVIS128ChipConfig;
	begin
		davis128ChipBiasSM : entity work.DAVIS128StateMachine
			port map(
				Clock_CI               => Clock_CI,
				Reset_RI               => Reset_RI,
				ChipBiasDiagSelect_SO  => ChipBiasDiagSelect_SO,
				ChipBiasAddrSelect_SBO => ChipBiasAddrSelect_SBO,
				ChipBiasClock_CBO      => ChipBiasClock_CBO,
				ChipBiasBitIn_DO       => ChipBiasBitIn_DO,
				ChipBiasLatch_SBO      => ChipBiasLatch_SBO,
				BiasConfig_DI          => DAVIS128BiasConfigReg_D,
				ChipConfig_DI          => DAVIS128ChipConfigReg_D);

		davis128ConfigRegisters : process(Clock_CI, Reset_RI) is
		begin
			if Reset_RI = '1' then
				DAVIS128BiasConfigReg_D <= tDAVIS128BiasConfigDefault;
				DAVIS128ChipConfigReg_D <= tDAVIS128ChipConfigDefault;
			elsif rising_edge(Clock_CI) then
				DAVIS128BiasConfigReg_D <= DAVIS128BiasConfig_D;
				DAVIS128ChipConfigReg_D <= DAVIS128ChipConfig_D;
			end if;
		end process davis128ConfigRegisters;

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

	davis208ChipBias : if CHIP_IDENTIFIER = 8 generate
		signal DAVIS208BiasConfig_D, DAVIS208BiasConfigReg_D : tDAVIS208BiasConfig;
		signal DAVIS208ChipConfig_D, DAVIS208ChipConfigReg_D : tDAVIS208ChipConfig;
	begin
		davis208ChipBiasSM : entity work.DAVIS208StateMachine
			port map(
				Clock_CI               => Clock_CI,
				Reset_RI               => Reset_RI,
				ChipBiasDiagSelect_SO  => ChipBiasDiagSelect_SO,
				ChipBiasAddrSelect_SBO => ChipBiasAddrSelect_SBO,
				ChipBiasClock_CBO      => ChipBiasClock_CBO,
				ChipBiasBitIn_DO       => ChipBiasBitIn_DO,
				ChipBiasLatch_SBO      => ChipBiasLatch_SBO,
				BiasConfig_DI          => DAVIS208BiasConfigReg_D,
				ChipConfig_DI          => DAVIS208ChipConfigReg_D);

		davis208ConfigRegisters : process(Clock_CI, Reset_RI) is
		begin
			if Reset_RI = '1' then
				DAVIS208BiasConfigReg_D <= tDAVIS208BiasConfigDefault;
				DAVIS208ChipConfigReg_D <= tDAVIS208ChipConfigDefault;
			elsif rising_edge(Clock_CI) then
				DAVIS208BiasConfigReg_D <= DAVIS208BiasConfig_D;
				DAVIS208ChipConfigReg_D <= DAVIS208ChipConfig_D;
			end if;
		end process davis208ConfigRegisters;

		davis208ChipBiasSPIConfig : entity work.DAVIS208SPIConfig
			port map(
				Clock_CI                 => Clock_CI,
				Reset_RI                 => Reset_RI,
				BiasConfig_DO            => DAVIS208BiasConfig_D,
				ChipConfig_DO            => DAVIS208ChipConfig_D,
				ConfigModuleAddress_DI   => ConfigModuleAddress_DI,
				ConfigParamAddress_DI    => ConfigParamAddress_DI,
				ConfigParamInput_DI      => ConfigParamInput_DI,
				ConfigLatchInput_SI      => ConfigLatchInput_SI,
				BiasConfigParamOutput_DO => BiasConfigParamOutput_DO,
				ChipConfigParamOutput_DO => ChipConfigParamOutput_DO);
	end generate davis208ChipBias;

	davis240ChipBias : if CHIP_IDENTIFIER = 0 or CHIP_IDENTIFIER = 1 or CHIP_IDENTIFIER = 2 generate
		signal DAVIS240BiasConfig_D, DAVIS240BiasConfigReg_D : tDAVIS240BiasConfig;
		signal DAVIS240ChipConfig_D, DAVIS240ChipConfigReg_D : tDAVIS240ChipConfig;
	begin
		davis240ChipBiasSM : entity work.DAVIS240StateMachine
			port map(
				Clock_CI               => Clock_CI,
				Reset_RI               => Reset_RI,
				ChipBiasDiagSelect_SO  => ChipBiasDiagSelect_SO,
				ChipBiasAddrSelect_SBO => ChipBiasAddrSelect_SBO,
				ChipBiasClock_CBO      => ChipBiasClock_CBO,
				ChipBiasBitIn_DO       => ChipBiasBitIn_DO,
				ChipBiasLatch_SBO      => ChipBiasLatch_SBO,
				BiasConfig_DI          => DAVIS240BiasConfigReg_D,
				ChipConfig_DI          => DAVIS240ChipConfigReg_D);

		davis240ConfigRegisters : process(Clock_CI, Reset_RI) is
		begin
			if Reset_RI = '1' then
				DAVIS240BiasConfigReg_D <= tDAVIS240BiasConfigDefault;
				DAVIS240ChipConfigReg_D <= tDAVIS240ChipConfigDefault;
			elsif rising_edge(Clock_CI) then
				DAVIS240BiasConfigReg_D <= DAVIS240BiasConfig_D;
				DAVIS240ChipConfigReg_D <= DAVIS240ChipConfig_D;
			end if;
		end process davis240ConfigRegisters;

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
		signal DAVIS128BiasConfig_D, DAVIS128BiasConfigReg_D : tDAVIS128BiasConfig;
		signal DAVIS346ChipConfig_D, DAVIS346ChipConfigReg_D : tDAVIS346ChipConfig;
	begin
		davis346ChipBiasSM : entity work.DAVIS346StateMachine
			port map(
				Clock_CI               => Clock_CI,
				Reset_RI               => Reset_RI,
				ChipBiasDiagSelect_SO  => ChipBiasDiagSelect_SO,
				ChipBiasAddrSelect_SBO => ChipBiasAddrSelect_SBO,
				ChipBiasClock_CBO      => ChipBiasClock_CBO,
				ChipBiasBitIn_DO       => ChipBiasBitIn_DO,
				ChipBiasLatch_SBO      => ChipBiasLatch_SBO,
				BiasConfig_DI          => DAVIS128BiasConfigReg_D,
				ChipConfig_DI          => DAVIS346ChipConfigReg_D);

		davis346ConfigRegisters : process(Clock_CI, Reset_RI) is
		begin
			if Reset_RI = '1' then
				DAVIS128BiasConfigReg_D <= tDAVIS128BiasConfigDefault;
				DAVIS346ChipConfigReg_D <= tDAVIS346ChipConfigDefault;
			elsif rising_edge(Clock_CI) then
				DAVIS128BiasConfigReg_D <= DAVIS128BiasConfig_D;
				DAVIS346ChipConfigReg_D <= DAVIS346ChipConfig_D;
			end if;
		end process davis346ConfigRegisters;

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
		signal DAVISrgbBiasConfig_D, DAVISrgbBiasConfigReg_D : tDAVISrgbBiasConfig;
		signal DAVISrgbChipConfig_D, DAVISrgbChipConfigReg_D : tDAVISrgbChipConfig;
	begin
		davisRGBChipBiasSM : entity work.DAVISrgbStateMachine
			port map(
				Clock_CI               => Clock_CI,
				Reset_RI               => Reset_RI,
				ChipBiasDiagSelect_SO  => ChipBiasDiagSelect_SO,
				ChipBiasAddrSelect_SBO => ChipBiasAddrSelect_SBO,
				ChipBiasClock_CBO      => ChipBiasClock_CBO,
				ChipBiasBitIn_DO       => ChipBiasBitIn_DO,
				ChipBiasLatch_SBO      => ChipBiasLatch_SBO,
				BiasConfig_DI          => DAVISrgbBiasConfigReg_D,
				ChipConfig_DI          => DAVISrgbChipConfigReg_D);

		davisRGBConfigRegisters : process(Clock_CI, Reset_RI) is
		begin
			if Reset_RI = '1' then
				DAVISrgbBiasConfigReg_D <= tDAVISrgbBiasConfigDefault;
				DAVISrgbChipConfigReg_D <= tDAVISrgbChipConfigDefault;
			elsif rising_edge(Clock_CI) then
				DAVISrgbBiasConfigReg_D <= DAVISrgbBiasConfig_D;
				DAVISrgbChipConfigReg_D <= DAVISrgbChipConfig_D;
			end if;
		end process davisRGBConfigRegisters;

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
