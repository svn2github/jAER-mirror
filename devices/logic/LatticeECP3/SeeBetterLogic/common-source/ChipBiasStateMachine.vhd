library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ChipBiasConfigRecords.all;
use work.DAVIS240ChipBiasConfigRecords.all;

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
	signal DAVIS240BiasConfig_D : tDAVIS240BiasConfig;
	signal DAVIS240ChipConfig_D : tDAVIS240ChipConfig;
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
end architecture Structural;
