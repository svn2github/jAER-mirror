library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ChipBiasConfigRecords.all;
use work.DAVIS240ChipBiasConfigRecords.all;
use work.Settings.CHIP_HAS_GLOBAL_SHUTTER;

entity DAVIS240SPIConfig is
	port(
		Clock_CI                 : in  std_logic;
		Reset_RI                 : in  std_logic;
		BiasConfig_DO            : out tDAVIS240BiasConfig;
		ChipConfig_DO            : out tDAVIS240ChipConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI   : in  unsigned(6 downto 0);
		ConfigParamAddress_DI    : in  unsigned(7 downto 0);
		ConfigParamInput_DI      : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI      : in  std_logic;
		BiasConfigParamOutput_DO : out std_logic_vector(31 downto 0);
		ChipConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity DAVIS240SPIConfig;

architecture Behavioral of DAVIS240SPIConfig is
	signal LatchBiasReg_S                     : std_logic;
	signal BiasInput_DP, BiasInput_DN         : std_logic_vector(31 downto 0);
	signal BiasOutput_DP, BiasOutput_DN       : std_logic_vector(31 downto 0);
	signal BiasConfigReg_DP, BiasConfigReg_DN : tDAVIS240BiasConfig;

	signal LatchChipReg_S                     : std_logic;
	signal ChipInput_DP, ChipInput_DN         : std_logic_vector(31 downto 0);
	signal ChipOutput_DP, ChipOutput_DN       : std_logic_vector(31 downto 0);
	signal ChipConfigReg_DP, ChipConfigReg_DN : tDAVIS240ChipConfig;
begin
	BiasConfig_DO            <= BiasConfigReg_DP;
	BiasConfigParamOutput_DO <= BiasOutput_DP;

	ChipConfig_DO            <= ChipConfigReg_DP;
	ChipConfigParamOutput_DO <= ChipOutput_DP;

	LatchBiasReg_S <= '1' when (ConfigModuleAddress_DI = CHIPBIASCONFIG_MODULE_ADDRESS and ConfigParamAddress_DI(7) = '0') else '0';
	LatchChipReg_S <= '1' when (ConfigModuleAddress_DI = CHIPBIASCONFIG_MODULE_ADDRESS and ConfigParamAddress_DI(7) = '1') else '0';

	biasIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, BiasInput_DP, BiasConfigReg_DP)
	begin
		BiasConfigReg_DN <= BiasConfigReg_DP;
		BiasInput_DN     <= ConfigParamInput_DI;
		BiasOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.DiffBn_D =>
				BiasConfigReg_DN.DiffBn_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.DiffBn_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.DiffBn_D'length - 1 downto 0) <= BiasConfigReg_DP.DiffBn_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.OnBn_D =>
				BiasConfigReg_DN.OnBn_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.OnBn_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.OnBn_D'length - 1 downto 0) <= BiasConfigReg_DP.OnBn_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.OffBn_D =>
				BiasConfigReg_DN.OffBn_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.OffBn_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.OffBn_D'length - 1 downto 0) <= BiasConfigReg_DP.OffBn_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.ApsCasEpc_D =>
				BiasConfigReg_DN.ApsCasEpc_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.ApsCasEpc_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.ApsCasEpc_D'length - 1 downto 0) <= BiasConfigReg_DP.ApsCasEpc_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.DiffCasBnc_D =>
				BiasConfigReg_DN.DiffCasBnc_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.DiffCasBnc_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.DiffCasBnc_D'length - 1 downto 0) <= BiasConfigReg_DP.DiffCasBnc_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.ApsROSFBn_D =>
				BiasConfigReg_DN.ApsROSFBn_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.ApsROSFBn_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.ApsROSFBn_D'length - 1 downto 0) <= BiasConfigReg_DP.ApsROSFBn_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.LocalBufBn_D =>
				BiasConfigReg_DN.LocalBufBn_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.LocalBufBn_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.LocalBufBn_D'length - 1 downto 0) <= BiasConfigReg_DP.LocalBufBn_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.PixInvBn_D =>
				BiasConfigReg_DN.PixInvBn_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.PixInvBn_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.PixInvBn_D'length - 1 downto 0) <= BiasConfigReg_DP.PixInvBn_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.PrBp_D =>
				BiasConfigReg_DN.PrBp_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.PrBp_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.PrBp_D'length - 1 downto 0) <= BiasConfigReg_DP.PrBp_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.PrSFBp_D =>
				BiasConfigReg_DN.PrSFBp_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.PrSFBp_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.PrSFBp_D'length - 1 downto 0) <= BiasConfigReg_DP.PrSFBp_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.RefrBp_D =>
				BiasConfigReg_DN.RefrBp_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.RefrBp_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.RefrBp_D'length - 1 downto 0) <= BiasConfigReg_DP.RefrBp_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.AEPdBn_D =>
				BiasConfigReg_DN.AEPdBn_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.AEPdBn_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.AEPdBn_D'length - 1 downto 0) <= BiasConfigReg_DP.AEPdBn_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.LcolTimeoutBn_D =>
				BiasConfigReg_DN.LcolTimeoutBn_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.LcolTimeoutBn_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.LcolTimeoutBn_D'length - 1 downto 0) <= BiasConfigReg_DP.LcolTimeoutBn_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.AEPuXBp_D =>
				BiasConfigReg_DN.AEPuXBp_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.AEPuXBp_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.AEPuXBp_D'length - 1 downto 0) <= BiasConfigReg_DP.AEPuXBp_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.AEPuYBp_D =>
				BiasConfigReg_DN.AEPuYBp_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.AEPuYBp_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.AEPuYBp_D'length - 1 downto 0) <= BiasConfigReg_DP.AEPuYBp_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.IFThrBn_D =>
				BiasConfigReg_DN.IFThrBn_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.IFThrBn_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.IFThrBn_D'length - 1 downto 0) <= BiasConfigReg_DP.IFThrBn_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.IFRefrBn_D =>
				BiasConfigReg_DN.IFRefrBn_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.IFRefrBn_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.IFRefrBn_D'length - 1 downto 0) <= BiasConfigReg_DP.IFRefrBn_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.PadFollBn_D =>
				BiasConfigReg_DN.PadFollBn_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.PadFollBn_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.PadFollBn_D'length - 1 downto 0) <= BiasConfigReg_DP.PadFollBn_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.ApsOverflowLevel_D =>
				BiasConfigReg_DN.ApsOverflowLevel_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.ApsOverflowLevel_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.ApsOverflowLevel_D'length - 1 downto 0) <= BiasConfigReg_DP.ApsOverflowLevel_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.BiasBuffer_D =>
				BiasConfigReg_DN.BiasBuffer_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.BiasBuffer_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.BiasBuffer_D'length - 1 downto 0) <= BiasConfigReg_DP.BiasBuffer_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.SSP_D =>
				BiasConfigReg_DN.SSP_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.SSP_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.SSP_D'length - 1 downto 0) <= BiasConfigReg_DP.SSP_D;

			when DAVIS240_BIASCONFIG_PARAM_ADDRESSES.SSN_D =>
				BiasConfigReg_DN.SSN_D                                       <= BiasInput_DP(tDAVIS240BiasConfig.SSN_D'length - 1 downto 0);
				BiasOutput_DN(tDAVIS240BiasConfig.SSN_D'length - 1 downto 0) <= BiasConfigReg_DP.SSN_D;

			when others => null;
		end case;
	end process biasIO;

	biasUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			BiasInput_DP  <= (others => '0');
			BiasOutput_DP <= (others => '0');

			BiasConfigReg_DP <= tDAVIS240BiasConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			BiasInput_DP  <= BiasInput_DN;
			BiasOutput_DP <= BiasOutput_DN;

			if LatchBiasReg_S = '1' and ConfigLatchInput_SI = '1' then
				BiasConfigReg_DP <= BiasConfigReg_DN;
			end if;
		end if;
	end process biasUpdate;

	chipIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, ChipInput_DP, ChipConfigReg_DP)
	begin
		ChipConfigReg_DN <= ChipConfigReg_DP;
		ChipInput_DN     <= ConfigParamInput_DI;
		ChipOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.DigitalMux0_D =>
				ChipConfigReg_DN.DigitalMux0_D                                       <= unsigned(ChipInput_DP(tDAVIS240ChipConfig.DigitalMux0_D'length - 1 downto 0));
				ChipOutput_DN(tDAVIS240ChipConfig.DigitalMux0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.DigitalMux0_D);

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.DigitalMux1_D =>
				ChipConfigReg_DN.DigitalMux1_D                                       <= unsigned(ChipInput_DP(tDAVIS240ChipConfig.DigitalMux1_D'length - 1 downto 0));
				ChipOutput_DN(tDAVIS240ChipConfig.DigitalMux1_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.DigitalMux1_D);

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.DigitalMux2_D =>
				ChipConfigReg_DN.DigitalMux2_D                                       <= unsigned(ChipInput_DP(tDAVIS240ChipConfig.DigitalMux2_D'length - 1 downto 0));
				ChipOutput_DN(tDAVIS240ChipConfig.DigitalMux2_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.DigitalMux2_D);

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.DigitalMux3_D =>
				ChipConfigReg_DN.DigitalMux3_D                                       <= unsigned(ChipInput_DP(tDAVIS240ChipConfig.DigitalMux3_D'length - 1 downto 0));
				ChipOutput_DN(tDAVIS240ChipConfig.DigitalMux3_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.DigitalMux3_D);

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.AnalogMux0_D =>
				ChipConfigReg_DN.AnalogMux0_D                                       <= unsigned(ChipInput_DP(tDAVIS240ChipConfig.AnalogMux0_D'length - 1 downto 0));
				ChipOutput_DN(tDAVIS240ChipConfig.AnalogMux0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.AnalogMux0_D);

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.AnalogMux1_D =>
				ChipConfigReg_DN.AnalogMux1_D                                       <= unsigned(ChipInput_DP(tDAVIS240ChipConfig.AnalogMux1_D'length - 1 downto 0));
				ChipOutput_DN(tDAVIS240ChipConfig.AnalogMux1_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.AnalogMux1_D);

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.AnalogMux2_D =>
				ChipConfigReg_DN.AnalogMux2_D                                       <= unsigned(ChipInput_DP(tDAVIS240ChipConfig.AnalogMux2_D'length - 1 downto 0));
				ChipOutput_DN(tDAVIS240ChipConfig.AnalogMux2_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.AnalogMux2_D);

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.BiasMux0_D =>
				ChipConfigReg_DN.BiasMux0_D                                       <= unsigned(ChipInput_DP(tDAVIS240ChipConfig.BiasMux0_D'length - 1 downto 0));
				ChipOutput_DN(tDAVIS240ChipConfig.BiasMux0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.BiasMux0_D);

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.ResetCalibNeuron_S =>
				ChipConfigReg_DN.ResetCalibNeuron_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                    <= ChipConfigReg_DP.ResetCalibNeuron_S;

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.TypeNCalibNeuron_S =>
				ChipConfigReg_DN.TypeNCalibNeuron_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                    <= ChipConfigReg_DP.TypeNCalibNeuron_S;

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.ResetTestPixel_S =>
				ChipConfigReg_DN.ResetTestPixel_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                  <= ChipConfigReg_DP.ResetTestPixel_S;

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.HotPixelSuppression_S =>
				ChipConfigReg_DN.HotPixelSuppression_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                       <= ChipConfigReg_DP.HotPixelSuppression_S;

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.AERnArow_S =>
				ChipConfigReg_DN.AERnArow_S <= ChipInput_DP(0);
				ChipOutput_DN(0)            <= ChipConfigReg_DP.AERnArow_S;

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.UseAOut_S =>
				ChipConfigReg_DN.UseAOut_S <= ChipInput_DP(0);
				ChipOutput_DN(0)           <= ChipConfigReg_DP.UseAOut_S;

			when DAVIS240_CHIPCONFIG_PARAM_ADDRESSES.GlobalShutter_S =>
				-- Allow changing global shutter parameter only on chips which support it.
				if CHIP_HAS_GLOBAL_SHUTTER = '1' then
					ChipConfigReg_DN.GlobalShutter_S <= ChipInput_DP(0);
				end if;
				ChipOutput_DN(0) <= ChipConfigReg_DP.GlobalShutter_S;

			when others => null;
		end case;
	end process chipIO;

	chipUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			ChipInput_DP  <= (others => '0');
			ChipOutput_DP <= (others => '0');

			ChipConfigReg_DP <= tDAVIS240ChipConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			ChipInput_DP  <= ChipInput_DN;
			ChipOutput_DP <= ChipOutput_DN;

			if LatchChipReg_S = '1' and ConfigLatchInput_SI = '1' then
				ChipConfigReg_DP <= ChipConfigReg_DN;
			end if;
		end if;
	end process chipUpdate;
end architecture Behavioral;
