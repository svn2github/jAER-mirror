library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DACConfigRecords.all;

entity DACSPIConfig is
	port(
		Clock_CI                : in  std_logic;
		Reset_RI                : in  std_logic;
		DACConfig_DO            : out tDACConfig;
		DACDataRead_DI          : in  unsigned(DAC_DATA_LENGTH - 1 downto 0);

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI  : in  unsigned(6 downto 0);
		ConfigParamAddress_DI   : in  unsigned(7 downto 0);
		ConfigParamInput_DI     : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI     : in  std_logic;
		DACConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity DACSPIConfig;

architecture Behavioral of DACSPIConfig is
	signal LatchDACReg_S                    : std_logic;
	signal DACInput_DP, DACInput_DN         : std_logic_vector(31 downto 0);
	signal DACOutput_DP, DACOutput_DN       : std_logic_vector(31 downto 0);
	signal DACConfigReg_DP, DACConfigReg_DN : tDACConfig;
begin
	DACConfig_DO            <= DACConfigReg_DP;
	DACConfigParamOutput_DO <= DACOutput_DP;

	LatchDACReg_S <= '1' when ConfigModuleAddress_DI = DACCONFIG_MODULE_ADDRESS else '0';

	dacIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, DACInput_DP, DACConfigReg_DP, DACDataRead_DI)
	begin
		DACConfigReg_DN <= DACConfigReg_DP;
		DACInput_DN     <= ConfigParamInput_DI;
		DACOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when DACCONFIG_PARAM_ADDRESSES.Run_S =>
				DACConfigReg_DN.Run_S <= DACInput_DP(0);
				DACOutput_DN(0)       <= DACConfigReg_DP.Run_S;

			when DACCONFIG_PARAM_ADDRESSES.ReadWrite_S =>
				DACConfigReg_DN.ReadWrite_S <= DACInput_DP(0);
				DACOutput_DN(0)             <= DACConfigReg_DP.ReadWrite_S;

			when DACCONFIG_PARAM_ADDRESSES.Register_D =>
				DACConfigReg_DN.Register_D                <= unsigned(DACInput_DP(tDACConfig.Register_D'range));
				DACOutput_DN(tDACConfig.Register_D'range) <= std_logic_vector(DACConfigReg_DP.Register_D);

			when DACCONFIG_PARAM_ADDRESSES.Channel_D =>
				DACConfigReg_DN.Channel_D                <= unsigned(DACInput_DP(tDACConfig.Channel_D'range));
				DACOutput_DN(tDACConfig.Channel_D'range) <= std_logic_vector(DACConfigReg_DP.Channel_D);

			when DACCONFIG_PARAM_ADDRESSES.DataRead_D =>
				-- DataRead_D is never read directly and only used as SPI output.
				-- The SPI output parameter is updated with the data coming out from the DAC.
				DACOutput_DN(DACDataRead_DI'range) <= std_logic_vector(DACDataRead_DI);

			when DACCONFIG_PARAM_ADDRESSES.DataWrite_D =>
				DACConfigReg_DN.DataWrite_D                <= unsigned(DACInput_DP(tDACConfig.DataWrite_D'range));
				DACOutput_DN(tDACConfig.DataWrite_D'range) <= std_logic_vector(DACConfigReg_DP.DataWrite_D);

			when DACCONFIG_PARAM_ADDRESSES.Execute_S =>
				DACConfigReg_DN.Execute_S <= DACInput_DP(0);
				DACOutput_DN(0)           <= DACConfigReg_DP.Execute_S;

			when others => null;
		end case;
	end process dacIO;

	dacUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			DACInput_DP  <= (others => '0');
			DACOutput_DP <= (others => '0');

			DACConfigReg_DP <= tDACConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			DACInput_DP  <= DACInput_DN;
			DACOutput_DP <= DACOutput_DN;

			if LatchDACReg_S = '1' and ConfigLatchInput_SI = '1' then
				DACConfigReg_DP <= DACConfigReg_DN;
			end if;
		end if;
	end process dacUpdate;
end architecture Behavioral;
