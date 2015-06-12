library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ScannerConfigRecords.all;

entity ScannerSPIConfig is
	port(
		Clock_CI                    : in  std_logic;
		Reset_RI                    : in  std_logic;
		ScannerConfig_DO            : out tScannerConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI      : in  unsigned(6 downto 0);
		ConfigParamAddress_DI       : in  unsigned(7 downto 0);
		ConfigParamInput_DI         : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI         : in  std_logic;
		ScannerConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity ScannerSPIConfig;

architecture Behavioral of ScannerSPIConfig is
	signal LatchScannerReg_S                        : std_logic;
	signal ScannerInput_DP, ScannerInput_DN         : std_logic_vector(31 downto 0);
	signal ScannerOutput_DP, ScannerOutput_DN       : std_logic_vector(31 downto 0);
	signal ScannerConfigReg_DP, ScannerConfigReg_DN : tScannerConfig;
begin
	ScannerConfig_DO            <= ScannerConfigReg_DP;
	ScannerConfigParamOutput_DO <= ScannerOutput_DP;

	LatchScannerReg_S <= '1' when ConfigModuleAddress_DI = SCANNERCONFIG_MODULE_ADDRESS else '0';

	scannerIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, ScannerInput_DP, ScannerConfigReg_DP)
	begin
		ScannerConfigReg_DN <= ScannerConfigReg_DP;
		ScannerInput_DN     <= ConfigParamInput_DI;
		ScannerOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when SCANNERCONFIG_PARAM_ADDRESSES.ScannerEnabled_S =>
				ScannerConfigReg_DN.ScannerEnabled_S <= ScannerInput_DP(0);
				ScannerOutput_DN(0)                  <= ScannerConfigReg_DP.ScannerEnabled_S;

			when SCANNERCONFIG_PARAM_ADDRESSES.ScannerChannel_D =>
				ScannerConfigReg_DN.ScannerChannel_D                    <= unsigned(ScannerInput_DP(tScannerConfig.ScannerChannel_D'range));
				ScannerOutput_DN(tScannerConfig.ScannerChannel_D'range) <= std_logic_vector(ScannerConfigReg_DP.ScannerChannel_D);

			when SCANNERCONFIG_PARAM_ADDRESSES.TestAEREnable_S =>
				ScannerConfigReg_DN.TestAEREnable_S <= ScannerInput_DP(0);
				ScannerOutput_DN(0)                 <= ScannerConfigReg_DP.TestAEREnable_S;

			when others => null;
		end case;
	end process scannerIO;

	scannerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			ScannerInput_DP  <= (others => '0');
			ScannerOutput_DP <= (others => '0');

			ScannerConfigReg_DP <= tScannerConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			ScannerInput_DP  <= ScannerInput_DN;
			ScannerOutput_DP <= ScannerOutput_DN;

			if LatchScannerReg_S = '1' and ConfigLatchInput_SI = '1' then
				ScannerConfigReg_DP <= ScannerConfigReg_DN;
			end if;
		end if;
	end process scannerUpdate;
end architecture Behavioral;
