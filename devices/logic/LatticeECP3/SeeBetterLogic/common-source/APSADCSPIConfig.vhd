library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.APSADCConfigRecords.all;

entity APSADCSPIConfig is
	port(
		Clock_CI                   : in  std_logic;
		Reset_RI                   : in  std_logic;
		APSADCConfig_DO            : out tAPSADCConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI     : in  unsigned(6 downto 0);
		ConfigParamAddress_DI      : in  unsigned(7 downto 0);
		ConfigParamInput_DI        : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI        : in  std_logic;
		APSADCConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity APSADCSPIConfig;

architecture Behavioral of APSADCSPIConfig is
	signal LatchAPSADCReg_S                       : std_logic;
	signal APSADCInput_DP, APSADCInput_DN         : std_logic_vector(31 downto 0);
	signal APSADCOutput_DP, APSADCOutput_DN       : std_logic_vector(31 downto 0);
	signal APSADCConfigReg_DP, APSADCConfigReg_DN : tAPSADCConfig;
begin
	APSADCConfig_DO            <= APSADCConfigReg_DP;
	APSADCConfigParamOutput_DO <= APSADCOutput_DP;

	LatchAPSADCReg_S <= '1' when ConfigModuleAddress_DI = APSADCCONFIG_MODULE_ADDRESS else '0';

	apsadcIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, APSADCInput_DP, APSADCConfigReg_DP)
	begin
		APSADCConfigReg_DN <= APSADCConfigReg_DP;
		APSADCInput_DN     <= ConfigParamInput_DI;
		APSADCOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when APSADCCONFIG_PARAM_ADDRESSES.Run_S =>
				APSADCConfigReg_DN.Run_S <= APSADCInput_DP(0);
				APSADCOutput_DN(0)       <= APSADCConfigReg_DP.Run_S;

			when others => null;
		end case;
	end process apsadcIO;

	apsadcUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			APSADCInput_DP  <= (others => '0');
			APSADCOutput_DP <= (others => '0');

			APSADCConfigReg_DP <= tAPSADCConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			APSADCInput_DP  <= APSADCInput_DN;
			APSADCOutput_DP <= APSADCOutput_DN;

			if LatchAPSADCReg_S = '1' and ConfigLatchInput_SI = '1' then
				APSADCConfigReg_DP <= APSADCConfigReg_DN;
			end if;
		end if;
	end process apsadcUpdate;
end architecture Behavioral;
