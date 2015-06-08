library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GenericAERConfigRecords.all;

entity GenericAERSPIConfig is
	port(
		Clock_CI                       : in  std_logic;
		Reset_RI                       : in  std_logic;
		GenericAERConfig_DO            : out tGenericAERConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI         : in  unsigned(6 downto 0);
		ConfigParamAddress_DI          : in  unsigned(7 downto 0);
		ConfigParamInput_DI            : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI            : in  std_logic;
		GenericAERConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity GenericAERSPIConfig;

architecture Behavioral of GenericAERSPIConfig is
	signal LatchGenericAERReg_S                           : std_logic;
	signal GenericAERInput_DP, GenericAERInput_DN         : std_logic_vector(31 downto 0);
	signal GenericAEROutput_DP, GenericAEROutput_DN       : std_logic_vector(31 downto 0);
	signal GenericAERConfigReg_DP, GenericAERConfigReg_DN : tGenericAERConfig;
begin
	GenericAERConfig_DO            <= GenericAERConfigReg_DP;
	GenericAERConfigParamOutput_DO <= GenericAEROutput_DP;

	LatchGenericAERReg_S <= '1' when ConfigModuleAddress_DI = GENERICAERCONFIG_MODULE_ADDRESS else '0';

	dvsaerIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, GenericAERInput_DP, GenericAERConfigReg_DP)
	begin
		GenericAERConfigReg_DN <= GenericAERConfigReg_DP;
		GenericAERInput_DN     <= ConfigParamInput_DI;
		GenericAEROutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when GENERICAERCONFIG_PARAM_ADDRESSES.Run_S =>
				GenericAERConfigReg_DN.Run_S <= GenericAERInput_DP(0);
				GenericAEROutput_DN(0)       <= GenericAERConfigReg_DP.Run_S;

			when GENERICAERCONFIG_PARAM_ADDRESSES.AckDelay_D =>
				GenericAERConfigReg_DN.AckDelay_D                       <= unsigned(GenericAERInput_DP(tGenericAERConfig.AckDelay_D'range));
				GenericAEROutput_DN(tGenericAERConfig.AckDelay_D'range) <= std_logic_vector(GenericAERConfigReg_DP.AckDelay_D);

			when GENERICAERCONFIG_PARAM_ADDRESSES.AckExtension_D =>
				GenericAERConfigReg_DN.AckExtension_D                       <= unsigned(GenericAERInput_DP(tGenericAERConfig.AckExtension_D'range));
				GenericAEROutput_DN(tGenericAERConfig.AckExtension_D'range) <= std_logic_vector(GenericAERConfigReg_DP.AckExtension_D);

			when GENERICAERCONFIG_PARAM_ADDRESSES.WaitOnTransferStall_S =>
				GenericAERConfigReg_DN.WaitOnTransferStall_S <= GenericAERInput_DP(0);
				GenericAEROutput_DN(0)                       <= GenericAERConfigReg_DP.WaitOnTransferStall_S;

			when GENERICAERCONFIG_PARAM_ADDRESSES.ExternalAERControl_S =>
				GenericAERConfigReg_DN.ExternalAERControl_S <= GenericAERInput_DP(0);
				GenericAEROutput_DN(0)                      <= GenericAERConfigReg_DP.ExternalAERControl_S;

			when others => null;
		end case;
	end process dvsaerIO;

	dvsaerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			GenericAERInput_DP  <= (others => '0');
			GenericAEROutput_DP <= (others => '0');

			GenericAERConfigReg_DP <= tGenericAERConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			GenericAERInput_DP  <= GenericAERInput_DN;
			GenericAEROutput_DP <= GenericAEROutput_DN;

			if LatchGenericAERReg_S = '1' and ConfigLatchInput_SI = '1' then
				GenericAERConfigReg_DP <= GenericAERConfigReg_DN;
			end if;
		end if;
	end process dvsaerUpdate;
end architecture Behavioral;
