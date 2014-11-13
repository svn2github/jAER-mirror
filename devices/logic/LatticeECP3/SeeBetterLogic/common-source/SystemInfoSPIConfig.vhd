library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SystemInfoConfigRecords.all;
use work.Settings.all;

entity SystemInfoSPIConfig is
	port(
		Clock_CI                       : in  std_logic;
		Reset_RI                       : in  std_logic;

		-- SPI configuration inputs and outputs. Read-only here.
		ConfigParamAddress_DI          : in  unsigned(7 downto 0);
		SystemInfoConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity SystemInfoSPIConfig;

architecture Behavioral of SystemInfoSPIConfig is
	signal SystemInfoOutput_DP, SystemInfoOutput_DN : std_logic_vector(31 downto 0);
begin
	SystemInfoConfigParamOutput_DO <= SystemInfoOutput_DP;

	systemInfoIO : process(ConfigParamAddress_DI)
	begin
		SystemInfoOutput_DN <= (others => '0');

		case ConfigParamAddress_DI is
			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.LogicVersion_D =>
				SystemInfoOutput_DN(LOGIC_VERSION'range) <= std_logic_vector(LOGIC_VERSION);

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipIdentifier_D =>
				SystemInfoOutput_DN(CHIP_IDENTIFIER'range) <= std_logic_vector(CHIP_IDENTIFIER);

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipSizeColumns_D =>
				SystemInfoOutput_DN(CHIP_SIZE_COLUMNS'range) <= std_logic_vector(CHIP_SIZE_COLUMNS);

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipSizeRows_D =>
				SystemInfoOutput_DN(CHIP_SIZE_ROWS'range) <= std_logic_vector(CHIP_SIZE_ROWS);

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipHasGlobalShutter_S =>
				SystemInfoOutput_DN(0) <= CHIP_HAS_GLOBAL_SHUTTER;

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipHasIntegratedADC_S =>
				SystemInfoOutput_DN(0) <= CHIP_HAS_INTEGRATED_ADC;

			when others => null;
		end case;
	end process systemInfoIO;

	systemInfoUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			SystemInfoOutput_DP <= (others => '0');
		elsif rising_edge(Clock_CI) then -- rising clock edge
			SystemInfoOutput_DP <= SystemInfoOutput_DN;
		end if;
	end process systemInfoUpdate;
end architecture Behavioral;
