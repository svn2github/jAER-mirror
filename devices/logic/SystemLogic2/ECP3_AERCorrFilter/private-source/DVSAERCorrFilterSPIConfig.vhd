library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DVSAERCorrFilterConfigRecords.all;

entity DVSAERCorrFilterSPIConfig is
	port(
		Clock_CI                             : in  std_logic;
		Reset_RI                             : in  std_logic;
		DVSAERCorrFilterConfig_DO            : out tDVSAERCorrFilterConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI               : in  unsigned(6 downto 0);
		ConfigParamAddress_DI                : in  unsigned(7 downto 0);
		ConfigParamInput_DI                  : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI                  : in  std_logic;
		DVSAERCorrFilterConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity DVSAERCorrFilterSPIConfig;

architecture Behavioral of DVSAERCorrFilterSPIConfig is
	signal LatchDVSAERCorrFilterReg_S                                 : std_logic;
	signal DVSAERCorrFilterInput_DP, DVSAERCorrFilterInput_DN         : std_logic_vector(31 downto 0);
	signal DVSAERCorrFilterOutput_DP, DVSAERCorrFilterOutput_DN       : std_logic_vector(31 downto 0);
	signal DVSAERCorrFilterConfigReg_DP, DVSAERCorrFilterConfigReg_DN : tDVSAERCorrFilterConfig;
begin
	DVSAERCorrFilterConfig_DO            <= DVSAERCorrFilterConfigReg_DP;
	DVSAERCorrFilterConfigParamOutput_DO <= DVSAERCorrFilterOutput_DP;

	LatchDVSAERCorrFilterReg_S <= '1' when ConfigModuleAddress_DI = DVSAERCORRFILTERCONFIG_MODULE_ADDRESS else '0';

	dvsaercfIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, DVSAERCorrFilterInput_DP, DVSAERCorrFilterConfigReg_DP)
	begin
		DVSAERCorrFilterConfigReg_DN <= DVSAERCorrFilterConfigReg_DP;
		DVSAERCorrFilterInput_DN     <= ConfigParamInput_DI;
		DVSAERCorrFilterOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.SizeColumns_D =>
				DVSAERCorrFilterConfigReg_DN.SizeColumns_D                             <= (others => '1');
				DVSAERCorrFilterOutput_DN(tDVSAERCorrFilterConfig.SizeColumns_D'range) <= (others => '1');

			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.SizeRows_D =>
				DVSAERCorrFilterConfigReg_DN.SizeRows_D                             <= (others => '1');
				DVSAERCorrFilterOutput_DN(tDVSAERCorrFilterConfig.SizeRows_D'range) <= (others => '1');

			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.OrientationInfo_D =>
				DVSAERCorrFilterConfigReg_DN.OrientationInfo_D                             <= "000";
				DVSAERCorrFilterOutput_DN(tDVSAERCorrFilterConfig.OrientationInfo_D'range) <= "000";

			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.Run_S =>
				DVSAERCorrFilterConfigReg_DN.Run_S <= DVSAERCorrFilterInput_DP(0);
				DVSAERCorrFilterOutput_DN(0)       <= DVSAERCorrFilterConfigReg_DP.Run_S;

			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.AckDelayRow_D =>
				DVSAERCorrFilterConfigReg_DN.AckDelayRow_D                             <= unsigned(DVSAERCorrFilterInput_DP(tDVSAERCorrFilterConfig.AckDelayRow_D'range));
				DVSAERCorrFilterOutput_DN(tDVSAERCorrFilterConfig.AckDelayRow_D'range) <= std_logic_vector(DVSAERCorrFilterConfigReg_DP.AckDelayRow_D);

			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.AckDelayColumn_D =>
				DVSAERCorrFilterConfigReg_DN.AckDelayColumn_D                             <= unsigned(DVSAERCorrFilterInput_DP(tDVSAERCorrFilterConfig.AckDelayColumn_D'range));
				DVSAERCorrFilterOutput_DN(tDVSAERCorrFilterConfig.AckDelayColumn_D'range) <= std_logic_vector(DVSAERCorrFilterConfigReg_DP.AckDelayColumn_D);

			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.AckExtensionRow_D =>
				DVSAERCorrFilterConfigReg_DN.AckExtensionRow_D                             <= unsigned(DVSAERCorrFilterInput_DP(tDVSAERCorrFilterConfig.AckExtensionRow_D'range));
				DVSAERCorrFilterOutput_DN(tDVSAERCorrFilterConfig.AckExtensionRow_D'range) <= std_logic_vector(DVSAERCorrFilterConfigReg_DP.AckExtensionRow_D);

			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.AckExtensionColumn_D =>
				DVSAERCorrFilterConfigReg_DN.AckExtensionColumn_D                             <= unsigned(DVSAERCorrFilterInput_DP(tDVSAERCorrFilterConfig.AckExtensionColumn_D'range));
				DVSAERCorrFilterOutput_DN(tDVSAERCorrFilterConfig.AckExtensionColumn_D'range) <= std_logic_vector(DVSAERCorrFilterConfigReg_DP.AckExtensionColumn_D);

			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.WaitOnTransferStall_S =>
				DVSAERCorrFilterConfigReg_DN.WaitOnTransferStall_S <= DVSAERCorrFilterInput_DP(0);
				DVSAERCorrFilterOutput_DN(0)                       <= DVSAERCorrFilterConfigReg_DP.WaitOnTransferStall_S;

			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.FilterRowOnlyEvents_S =>
				DVSAERCorrFilterConfigReg_DN.FilterRowOnlyEvents_S <= DVSAERCorrFilterInput_DP(0);
				DVSAERCorrFilterOutput_DN(0)                       <= DVSAERCorrFilterConfigReg_DP.FilterRowOnlyEvents_S;

			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.ExternalAERControl_S =>
				DVSAERCorrFilterConfigReg_DN.ExternalAERControl_S <= DVSAERCorrFilterInput_DP(0);
				DVSAERCorrFilterOutput_DN(0)                      <= DVSAERCorrFilterConfigReg_DP.ExternalAERControl_S;

			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.HasBackgroundActivityFilter_S =>
				DVSAERCorrFilterConfigReg_DN.HasBackgroundActivityFilter_S <= '1';
				DVSAERCorrFilterOutput_DN(0)                               <= '1';

			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.FilterBackgroundActivity_S =>
				DVSAERCorrFilterConfigReg_DN.FilterBackgroundActivity_S <= DVSAERCorrFilterInput_DP(0);
				DVSAERCorrFilterOutput_DN(0)                            <= DVSAERCorrFilterConfigReg_DP.FilterBackgroundActivity_S;

			when DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES.FilterBackgroundActivityPassDelayTime_D =>
				DVSAERCorrFilterConfigReg_DN.FilterBackgroundActivityPassDelayTime_D                             <= unsigned(DVSAERCorrFilterInput_DP(tDVSAERCorrFilterConfig.FilterBackgroundActivityPassDelayTime_D'range));
				DVSAERCorrFilterOutput_DN(tDVSAERCorrFilterConfig.FilterBackgroundActivityPassDelayTime_D'range) <= std_logic_vector(DVSAERCorrFilterConfigReg_DP.FilterBackgroundActivityPassDelayTime_D);

			when others => null;
		end case;
	end process dvsaercfIO;

	dvsaercfUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			DVSAERCorrFilterInput_DP  <= (others => '0');
			DVSAERCorrFilterOutput_DP <= (others => '0');

			DVSAERCorrFilterConfigReg_DP <= tDVSAERCorrFilterConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			DVSAERCorrFilterInput_DP  <= DVSAERCorrFilterInput_DN;
			DVSAERCorrFilterOutput_DP <= DVSAERCorrFilterOutput_DN;

			if LatchDVSAERCorrFilterReg_S = '1' and ConfigLatchInput_SI = '1' then
				DVSAERCorrFilterConfigReg_DP <= DVSAERCorrFilterConfigReg_DN;
			end if;
		end if;
	end process dvsaercfUpdate;
end architecture Behavioral;
