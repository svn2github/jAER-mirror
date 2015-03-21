library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SystemInfoConfigRecords.all;
use work.Settings.all;

entity SystemInfoSPIConfig is
	port(
		Clock_CI                       : in  std_logic;
		Reset_RI                       : in  std_logic;

		-- Master/Slave information from TS Synchronizer.
		DeviceIsMaster_SI              : in  std_logic;

		-- SPI configuration inputs and outputs. Read-only here.
		ConfigParamAddress_DI          : in  unsigned(7 downto 0);
		SystemInfoConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity SystemInfoSPIConfig;

architecture Behavioral of SystemInfoSPIConfig is
	signal SystemInfoOutput_DP, SystemInfoOutput_DN : std_logic_vector(31 downto 0);
	signal DeviceIsMasterBuffer_S                   : std_logic;
begin
	SystemInfoConfigParamOutput_DO <= SystemInfoOutput_DP;

	systemInfoIO : process(ConfigParamAddress_DI, DeviceIsMasterBuffer_S)
	begin
		SystemInfoOutput_DN <= (others => '0');

		case ConfigParamAddress_DI is
			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.LogicVersion_D =>
				SystemInfoOutput_DN(LOGIC_VERSION'range) <= std_logic_vector(LOGIC_VERSION);

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipIdentifier_D =>
				SystemInfoOutput_DN(CHIP_IDENTIFIER'range) <= std_logic_vector(CHIP_IDENTIFIER);

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipOrientation_D =>
				SystemInfoOutput_DN(CHIP_ORIENTATION'range) <= CHIP_ORIENTATION;

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipAPSStreamStart_D =>
				SystemInfoOutput_DN(CHIP_APS_STREAM_START'range) <= CHIP_APS_STREAM_START;

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipAPSSizeColumns_D =>
				SystemInfoOutput_DN(CHIP_APS_SIZE_COLUMNS'range) <= std_logic_vector(CHIP_APS_SIZE_COLUMNS);

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipAPSSizeRows_D =>
				SystemInfoOutput_DN(CHIP_APS_SIZE_ROWS'range) <= std_logic_vector(CHIP_APS_SIZE_ROWS);

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipDVSSizeColumns_D =>
				SystemInfoOutput_DN(CHIP_DVS_SIZE_COLUMNS'range) <= std_logic_vector(CHIP_DVS_SIZE_COLUMNS);

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipDVSSizeRows_D =>
				SystemInfoOutput_DN(CHIP_DVS_SIZE_ROWS'range) <= std_logic_vector(CHIP_DVS_SIZE_ROWS);

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipHasGlobalShutter_S =>
				SystemInfoOutput_DN(0) <= CHIP_HAS_GLOBAL_SHUTTER;

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.ChipHasIntegratedADC_S =>
				SystemInfoOutput_DN(0) <= CHIP_HAS_INTEGRATED_ADC;

			when SYSTEMINFOCONFIG_PARAM_ADDRESSES.DeviceIsMaster_S =>
				SystemInfoOutput_DN(0) <= DeviceIsMasterBuffer_S;

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

	deviceIsMasterBuffer : entity work.SimpleRegister
		generic map(
			SIZE => 1)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Enable_SI    => '1',
			Input_SI(0)  => DeviceIsMaster_SI,
			Output_SO(0) => DeviceIsMasterBuffer_S);
end architecture Behavioral;
