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
	signal LatchExtTriggerReg_SP, LatchExtTriggerReg_SN   : std_logic;
	signal ExtTriggerInput_DP, ExtTriggerInput_DN         : std_logic_vector(31 downto 0);
	signal ExtTriggerOutput_DP, ExtTriggerOutput_DN       : std_logic_vector(31 downto 0);
	signal ExtTriggerConfigReg_DP, ExtTriggerConfigReg_DN : tExtTriggerConfig;
begin
	ExtTriggerConfig_DO            <= ExtTriggerConfigReg_DP;
	ExtTriggerConfigParamOutput_DO <= ExtTriggerOutput_DP;

	extTriggerISelect : process(ConfigModuleAddress_DI)
	begin
		-- Input side select.
		LatchExtTriggerReg_SN <= '0';

		if ConfigModuleAddress_DI = ExtTriggerCONFIG_MODULE_ADDRESS then
			LatchExtTriggerReg_SN <= '1';
		end if;
	end process extTriggerISelect;

	extTriggerIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, ExtTriggerInput_DP, ExtTriggerConfigReg_DP)
	begin
		ExtTriggerConfigReg_DN <= ExtTriggerConfigReg_DP;
		ExtTriggerInput_DN     <= ConfigParamInput_DI;
		ExtTriggerOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when ExtTriggerCONFIG_PARAM_ADDRESSES.Run_S =>
				ExtTriggerConfigReg_DN.Run_S <= ExtTriggerInput_DP(0);
				ExtTriggerOutput_DN(0)       <= ExtTriggerConfigReg_DP.Run_S;

			when others => null;
		end case;
	end process extTriggerIO;

	extTriggerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			LatchExtTriggerReg_SP <= '0';
			ExtTriggerInput_DP    <= (others => '0');
			ExtTriggerOutput_DP   <= (others => '0');

			ExtTriggerConfigReg_DP <= tExtTriggerConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			LatchExtTriggerReg_SP <= LatchExtTriggerReg_SN;
			ExtTriggerInput_DP    <= ExtTriggerInput_DN;
			ExtTriggerOutput_DP   <= ExtTriggerOutput_DN;

			if LatchExtTriggerReg_SP = '1' and ConfigLatchInput_SI = '1' then
				ExtTriggerConfigReg_DP <= ExtTriggerConfigReg_DN;
			end if;
		end if;
	end process extTriggerUpdate;
end architecture Behavioral;
