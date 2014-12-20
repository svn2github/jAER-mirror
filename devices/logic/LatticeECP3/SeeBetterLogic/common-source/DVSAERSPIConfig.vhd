library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DVSAERConfigRecords.all;

entity DVSAERSPIConfig is
	generic(
		ENABLE_PIXEL_FILTERING               : boolean := false;
		ENABLE_BACKGROUND_ACTIVITY_FILTERING : boolean := false);
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

architecture Behavioral of DVSAERSPIConfig is
	signal LatchDVSAERReg_S                       : std_logic;
	signal DVSAERInput_DP, DVSAERInput_DN         : std_logic_vector(31 downto 0);
	signal DVSAEROutput_DP, DVSAEROutput_DN       : std_logic_vector(31 downto 0);
	signal DVSAERConfigReg_DP, DVSAERConfigReg_DN : tDVSAERConfig;
begin
	DVSAERConfig_DO            <= DVSAERConfigReg_DP;
	DVSAERConfigParamOutput_DO <= DVSAEROutput_DP;

	LatchDVSAERReg_S <= '1' when ConfigModuleAddress_DI = DVSAERCONFIG_MODULE_ADDRESS else '0';

	dvsaerIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, DVSAERInput_DP, DVSAERConfigReg_DP)
	begin
		DVSAERConfigReg_DN <= DVSAERConfigReg_DP;
		DVSAERInput_DN     <= ConfigParamInput_DI;
		DVSAEROutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when DVSAERCONFIG_PARAM_ADDRESSES.Run_S =>
				DVSAERConfigReg_DN.Run_S <= DVSAERInput_DP(0);
				DVSAEROutput_DN(0)       <= DVSAERConfigReg_DP.Run_S;

			when DVSAERCONFIG_PARAM_ADDRESSES.AckDelayRow_D =>
				DVSAERConfigReg_DN.AckDelayRow_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.AckDelayRow_D'range));
				DVSAEROutput_DN(tDVSAERConfig.AckDelayRow_D'range) <= std_logic_vector(DVSAERConfigReg_DP.AckDelayRow_D);

			when DVSAERCONFIG_PARAM_ADDRESSES.AckDelayColumn_D =>
				DVSAERConfigReg_DN.AckDelayColumn_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.AckDelayColumn_D'range));
				DVSAEROutput_DN(tDVSAERConfig.AckDelayColumn_D'range) <= std_logic_vector(DVSAERConfigReg_DP.AckDelayColumn_D);

			when DVSAERCONFIG_PARAM_ADDRESSES.AckExtensionRow_D =>
				DVSAERConfigReg_DN.AckExtensionRow_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.AckExtensionRow_D'range));
				DVSAEROutput_DN(tDVSAERConfig.AckExtensionRow_D'range) <= std_logic_vector(DVSAERConfigReg_DP.AckExtensionRow_D);

			when DVSAERCONFIG_PARAM_ADDRESSES.AckExtensionColumn_D =>
				DVSAERConfigReg_DN.AckExtensionColumn_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.AckExtensionColumn_D'range));
				DVSAEROutput_DN(tDVSAERConfig.AckExtensionColumn_D'range) <= std_logic_vector(DVSAERConfigReg_DP.AckExtensionColumn_D);

			when DVSAERCONFIG_PARAM_ADDRESSES.WaitOnTransferStall_S =>
				DVSAERConfigReg_DN.WaitOnTransferStall_S <= DVSAERInput_DP(0);
				DVSAEROutput_DN(0)                       <= DVSAERConfigReg_DP.WaitOnTransferStall_S;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterRowOnlyEvents_S =>
				DVSAERConfigReg_DN.FilterRowOnlyEvents_S <= DVSAERInput_DP(0);
				DVSAEROutput_DN(0)                       <= DVSAERConfigReg_DP.FilterRowOnlyEvents_S;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel0Row_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel0Row_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel0Row_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel0Row_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel0Row_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel0Column_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel0Column_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel0Column_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel0Column_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel0Column_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel1Row_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel1Row_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel1Row_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel1Row_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel1Row_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel1Column_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel1Column_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel1Column_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel1Column_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel1Column_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel2Row_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel2Row_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel2Row_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel2Row_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel2Row_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel2Column_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel2Column_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel2Column_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel2Column_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel2Column_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel3Row_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel3Row_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel3Row_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel3Row_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel3Row_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel3Column_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel3Column_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel3Column_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel3Column_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel3Column_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel4Row_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel4Row_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel4Row_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel4Row_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel4Row_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel4Column_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel4Column_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel4Column_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel4Column_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel4Column_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel5Row_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel5Row_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel5Row_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel5Row_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel5Row_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel5Column_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel5Column_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel5Column_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel5Column_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel5Column_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel6Row_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel6Row_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel6Row_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel6Row_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel6Row_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel6Column_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel6Column_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel6Column_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel6Column_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel6Column_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel7Row_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel7Row_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel7Row_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel7Row_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel7Row_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterPixel7Column_D =>
				if ENABLE_PIXEL_FILTERING = true then
					DVSAERConfigReg_DN.FilterPixel7Column_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterPixel7Column_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterPixel7Column_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterPixel7Column_D);
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterBackgroundActivity_S =>
				if ENABLE_BACKGROUND_ACTIVITY_FILTERING = true then
					DVSAERConfigReg_DN.FilterBackgroundActivity_S <= DVSAERInput_DP(0);
					DVSAEROutput_DN(0)                            <= DVSAERConfigReg_DP.FilterBackgroundActivity_S;
				end if;

			when DVSAERCONFIG_PARAM_ADDRESSES.FilterBackgroundActivityDeltaTime_D =>
				if ENABLE_BACKGROUND_ACTIVITY_FILTERING = true then
					DVSAERConfigReg_DN.FilterBackgroundActivityDeltaTime_D                   <= unsigned(DVSAERInput_DP(tDVSAERConfig.FilterBackgroundActivityDeltaTime_D'range));
					DVSAEROutput_DN(tDVSAERConfig.FilterBackgroundActivityDeltaTime_D'range) <= std_logic_vector(DVSAERConfigReg_DP.FilterBackgroundActivityDeltaTime_D);
				end if;

			when others => null;
		end case;
	end process dvsaerIO;

	dvsaerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			DVSAERInput_DP  <= (others => '0');
			DVSAEROutput_DP <= (others => '0');

			DVSAERConfigReg_DP <= tDVSAERConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			DVSAERInput_DP  <= DVSAERInput_DN;
			DVSAEROutput_DP <= DVSAEROutput_DN;

			if LatchDVSAERReg_S = '1' and ConfigLatchInput_SI = '1' then
				DVSAERConfigReg_DP <= DVSAERConfigReg_DN;
			end if;
		end if;
	end process dvsaerUpdate;
end architecture Behavioral;
