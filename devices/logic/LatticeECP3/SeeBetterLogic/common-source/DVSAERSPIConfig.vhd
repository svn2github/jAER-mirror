library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DVSAERConfigRecords.all;

entity DVSAERSPIConfig is
	port(
		Clock_CI                   : in  std_logic;
		Reset_RI                   : in  std_logic;
		DVSAERConfig_DO            : out tDVSAERConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI     : in  unsigned(6 downto 0);
		ConfigParamAddress_DI      : in  unsigned(7 downto 0);
		ConfigParamInput_DI        : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI        : in  std_logic;
		DVSAERConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity DVSAERSPIConfig;

architecture RTL of DVSAERSPIConfig is
	signal LatchDVSAERReg_SP, LatchDVSAERReg_SN   : std_logic;
	signal DVSAERInput_DP, DVSAERInput_DN         : std_logic_vector(31 downto 0);
	signal DVSAEROutput_DP, DVSAEROutput_DN       : std_logic_vector(31 downto 0);
	signal DVSAERConfigReg_DP, DVSAERConfigReg_DN : tDVSAERConfig;
begin
	DVSAERConfig_DO            <= DVSAERConfigReg_DP;
	DVSAERConfigParamOutput_DO <= DVSAEROutput_DP;

	dvsaerISelect : process(ConfigModuleAddress_DI)
	begin
		-- Input side select.
		LatchDVSAERReg_SN <= '0';

		if ConfigModuleAddress_DI = DVSAERCONFIG_MODULE_ADDRESS then
			LatchDVSAERReg_SN <= '1';
		end if;
	end process dvsaerISelect;

	dvsaerIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, DVSAERInput_DP, DVSAERConfigReg_DP)
	begin
		DVSAERConfigReg_DN <= DVSAERConfigReg_DP;
		DVSAERInput_DN     <= ConfigParamInput_DI;
		DVSAEROutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when DVSAERCONFIG_PARAM_ADDRESSES.Run_S =>
				DVSAERConfigReg_DN.Run_S <= DVSAERInput_DP(0);
				DVSAEROutput_DN(0)       <= DVSAERConfigReg_DP.Run_S;

			when DVSAERCONFIG_PARAM_ADDRESSES.AckDelay_D =>
				DVSAERConfigReg_DN.AckDelay_D                                 <= unsigned(DVSAERInput_DP(tDVSAERConfig.AckDelay_D'length - 1 downto 0));
				DVSAEROutput_DN(tDVSAERConfig.AckDelay_D'length - 1 downto 0) <= std_logic_vector(DVSAERConfigReg_DP.AckDelay_D);

			when DVSAERCONFIG_PARAM_ADDRESSES.AckExtension_D =>
				DVSAERConfigReg_DN.AckExtension_D                                 <= unsigned(DVSAERInput_DP(tDVSAERConfig.AckExtension_D'length - 1 downto 0));
				DVSAEROutput_DN(tDVSAERConfig.AckExtension_D'length - 1 downto 0) <= std_logic_vector(DVSAERConfigReg_DP.AckExtension_D);

			when others => null;
		end case;
	end process dvsaerIO;

	dvsaerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			LatchDVSAERReg_SP <= '0';
			DVSAERInput_DP    <= (others => '0');
			DVSAEROutput_DP   <= (others => '0');

			DVSAERConfigReg_DP <= tDVSAERConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			LatchDVSAERReg_SP <= LatchDVSAERReg_SN;
			DVSAERInput_DP    <= DVSAERInput_DN;
			DVSAEROutput_DP   <= DVSAEROutput_DN;

			if LatchDVSAERReg_SP = '1' and ConfigLatchInput_SI = '1' then
				DVSAERConfigReg_DP <= DVSAERConfigReg_DN;
			end if;
		end if;
	end process dvsaerUpdate;
end architecture RTL;
