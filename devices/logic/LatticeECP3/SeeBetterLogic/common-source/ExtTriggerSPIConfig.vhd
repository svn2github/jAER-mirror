library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ExtTriggerConfigRecords.all;

entity ExtTriggerSPIConfig is
	port(
		Clock_CI                       : in  std_logic;
		Reset_RI                       : in  std_logic;
		ExtTriggerConfig_DO            : out tExtTriggerConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI         : in  unsigned(6 downto 0);
		ConfigParamAddress_DI          : in  unsigned(7 downto 0);
		ConfigParamInput_DI            : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI            : in  std_logic;
		ExtTriggerConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity ExtTriggerSPIConfig;

architecture Behavioral of ExtTriggerSPIConfig is
	signal LatchExtTriggerReg_S                           : std_logic;
	signal ExtTriggerInput_DP, ExtTriggerInput_DN         : std_logic_vector(31 downto 0);
	signal ExtTriggerOutput_DP, ExtTriggerOutput_DN       : std_logic_vector(31 downto 0);
	signal ExtTriggerConfigReg_DP, ExtTriggerConfigReg_DN : tExtTriggerConfig;
begin
	ExtTriggerConfig_DO            <= ExtTriggerConfigReg_DP;
	ExtTriggerConfigParamOutput_DO <= ExtTriggerOutput_DP;

	LatchExtTriggerReg_S <= '1' when ConfigModuleAddress_DI = ExtTriggerCONFIG_MODULE_ADDRESS else '0';

	extTriggerIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, ExtTriggerInput_DP, ExtTriggerConfigReg_DP)
	begin
		ExtTriggerConfigReg_DN <= ExtTriggerConfigReg_DP;
		ExtTriggerInput_DN     <= ConfigParamInput_DI;
		ExtTriggerOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when ExtTriggerCONFIG_PARAM_ADDRESSES.RunDetector_S =>
				ExtTriggerConfigReg_DN.RunDetector_S <= ExtTriggerInput_DP(0);
				ExtTriggerOutput_DN(0)               <= ExtTriggerConfigReg_DP.RunDetector_S;

			when ExtTriggerCONFIG_PARAM_ADDRESSES.DetectRisingEdges_S =>
				ExtTriggerConfigReg_DN.DetectRisingEdges_S <= ExtTriggerInput_DP(0);
				ExtTriggerOutput_DN(0)                     <= ExtTriggerConfigReg_DP.DetectRisingEdges_S;

			when ExtTriggerCONFIG_PARAM_ADDRESSES.DetectFallingEdges_S =>
				ExtTriggerConfigReg_DN.DetectFallingEdges_S <= ExtTriggerInput_DP(0);
				ExtTriggerOutput_DN(0)                      <= ExtTriggerConfigReg_DP.DetectFallingEdges_S;

			when ExtTriggerCONFIG_PARAM_ADDRESSES.DetectPulses_S =>
				ExtTriggerConfigReg_DN.DetectPulses_S <= ExtTriggerInput_DP(0);
				ExtTriggerOutput_DN(0)                <= ExtTriggerConfigReg_DP.DetectPulses_S;

			when ExtTriggerCONFIG_PARAM_ADDRESSES.DetectPulsePolarity_S =>
				ExtTriggerConfigReg_DN.DetectPulsePolarity_S <= ExtTriggerInput_DP(0);
				ExtTriggerOutput_DN(0)                       <= ExtTriggerConfigReg_DP.DetectPulsePolarity_S;

			when ExtTriggerCONFIG_PARAM_ADDRESSES.DetectPulseLength_D =>
				ExtTriggerConfigReg_DN.DetectPulseLength_D                       <= unsigned(ExtTriggerInput_DP(tExtTriggerConfig.DetectPulseLength_D'range));
				ExtTriggerOutput_DN(tExtTriggerConfig.DetectPulseLength_D'range) <= std_logic_vector(ExtTriggerConfigReg_DP.DetectPulseLength_D);

			when ExtTriggerCONFIG_PARAM_ADDRESSES.RunGenerator_S =>
				ExtTriggerConfigReg_DN.RunGenerator_S <= ExtTriggerInput_DP(0);
				ExtTriggerOutput_DN(0)                <= ExtTriggerConfigReg_DP.RunGenerator_S;

			when ExtTriggerCONFIG_PARAM_ADDRESSES.GenerateUseCustomSignal_S =>
				ExtTriggerConfigReg_DN.GenerateUseCustomSignal_S <= ExtTriggerInput_DP(0);
				ExtTriggerOutput_DN(0)                           <= ExtTriggerConfigReg_DP.GenerateUseCustomSignal_S;

			when ExtTriggerCONFIG_PARAM_ADDRESSES.GeneratePulsePolarity_S =>
				ExtTriggerConfigReg_DN.GeneratePulsePolarity_S <= ExtTriggerInput_DP(0);
				ExtTriggerOutput_DN(0)                         <= ExtTriggerConfigReg_DP.GeneratePulsePolarity_S;

			when ExtTriggerCONFIG_PARAM_ADDRESSES.GeneratePulseInterval_D =>
				ExtTriggerConfigReg_DN.GeneratePulseInterval_D                       <= unsigned(ExtTriggerInput_DP(tExtTriggerConfig.GeneratePulseInterval_D'range));
				ExtTriggerOutput_DN(tExtTriggerConfig.GeneratePulseInterval_D'range) <= std_logic_vector(ExtTriggerConfigReg_DP.GeneratePulseInterval_D);

			when ExtTriggerCONFIG_PARAM_ADDRESSES.GeneratePulseLength_D =>
				ExtTriggerConfigReg_DN.GeneratePulseLength_D                       <= unsigned(ExtTriggerInput_DP(tExtTriggerConfig.GeneratePulseLength_D'range));
				ExtTriggerOutput_DN(tExtTriggerConfig.GeneratePulseLength_D'range) <= std_logic_vector(ExtTriggerConfigReg_DP.GeneratePulseLength_D);

			when others => null;
		end case;
	end process extTriggerIO;

	extTriggerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			ExtTriggerInput_DP  <= (others => '0');
			ExtTriggerOutput_DP <= (others => '0');

			ExtTriggerConfigReg_DP <= tExtTriggerConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			ExtTriggerInput_DP  <= ExtTriggerInput_DN;
			ExtTriggerOutput_DP <= ExtTriggerOutput_DN;

			if LatchExtTriggerReg_S = '1' and ConfigLatchInput_SI = '1' then
				ExtTriggerConfigReg_DP <= ExtTriggerConfigReg_DN;
			end if;
		end if;
	end process extTriggerUpdate;
end architecture Behavioral;
