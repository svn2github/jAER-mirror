library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ChipBiasConfigRecords.all;
use work.CochleaLPChipBiasConfigRecords.all;

entity CochleaLPSPIConfig is
	port(
		Clock_CI                 : in  std_logic;
		Reset_RI                 : in  std_logic;
		BiasConfig_DO            : out tCochleaLPBiasConfig;
		ChipConfig_DO            : out tCochleaLPChipConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI   : in  unsigned(6 downto 0);
		ConfigParamAddress_DI    : in  unsigned(7 downto 0);
		ConfigParamInput_DI      : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI      : in  std_logic;
		BiasConfigParamOutput_DO : out std_logic_vector(31 downto 0);
		ChipConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity CochleaLPSPIConfig;

architecture Behavioral of CochleaLPSPIConfig is
	signal LatchBiasReg_S                     : std_logic;
	signal BiasInput_DP, BiasInput_DN         : std_logic_vector(31 downto 0);
	signal BiasOutput_DP, BiasOutput_DN       : std_logic_vector(31 downto 0);
	signal BiasConfigReg_DP, BiasConfigReg_DN : tCochleaLPBiasConfig;

	signal LatchChipReg_S                     : std_logic;
	signal ChipInput_DP, ChipInput_DN         : std_logic_vector(31 downto 0);
	signal ChipOutput_DP, ChipOutput_DN       : std_logic_vector(31 downto 0);
	signal ChipConfigReg_DP, ChipConfigReg_DN : tCochleaLPChipConfig;
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
			when CochleaLP_BIASCONFIG_PARAM_ADDRESSES.VBNIBias_D =>
				BiasConfigReg_DN.VBNIBias_D                                        <= BiasInput_DP(tCochleaLPBiasConfig.VBNIBias_D'length - 1 downto 0);
				BiasOutput_DN(tCochleaLPBiasConfig.VBNIBias_D'length - 1 downto 0) <= BiasConfigReg_DP.VBNIBias_D;

			when CochleaLP_BIASCONFIG_PARAM_ADDRESSES.VBNTest_D =>
				BiasConfigReg_DN.VBNTest_D                                        <= BiasInput_DP(tCochleaLPBiasConfig.VBNTest_D'length - 1 downto 0);
				BiasOutput_DN(tCochleaLPBiasConfig.VBNTest_D'length - 1 downto 0) <= BiasConfigReg_DP.VBNTest_D;

			when CochleaLP_BIASCONFIG_PARAM_ADDRESSES.VBPScan_D =>
				BiasConfigReg_DN.VBPScan_D                                        <= BiasInput_DP(tCochleaLPBiasConfig.VBPScan_D'length - 1 downto 0);
				BiasOutput_DN(tCochleaLPBiasConfig.VBPScan_D'length - 1 downto 0) <= BiasConfigReg_DP.VBPScan_D;

			when CochleaLP_BIASCONFIG_PARAM_ADDRESSES.AEPdBn_D =>
				BiasConfigReg_DN.AEPdBn_D                                        <= BiasInput_DP(tCochleaLPBiasConfig.AEPdBn_D'length - 1 downto 0);
				BiasOutput_DN(tCochleaLPBiasConfig.AEPdBn_D'length - 1 downto 0) <= BiasConfigReg_DP.AEPdBn_D;

			when CochleaLP_BIASCONFIG_PARAM_ADDRESSES.AEPuYBp_D =>
				BiasConfigReg_DN.AEPuYBp_D                                        <= BiasInput_DP(tCochleaLPBiasConfig.AEPuYBp_D'length - 1 downto 0);
				BiasOutput_DN(tCochleaLPBiasConfig.AEPuYBp_D'length - 1 downto 0) <= BiasConfigReg_DP.AEPuYBp_D;

			when CochleaLP_BIASCONFIG_PARAM_ADDRESSES.BiasBuffer_D =>
				BiasConfigReg_DN.BiasBuffer_D                                        <= BiasInput_DP(tCochleaLPBiasConfig.BiasBuffer_D'length - 1 downto 0);
				BiasOutput_DN(tCochleaLPBiasConfig.BiasBuffer_D'length - 1 downto 0) <= BiasConfigReg_DP.BiasBuffer_D;

			when CochleaLP_BIASCONFIG_PARAM_ADDRESSES.SSP_D =>
				BiasConfigReg_DN.SSP_D                                        <= BiasInput_DP(tCochleaLPBiasConfig.SSP_D'length - 1 downto 0);
				BiasOutput_DN(tCochleaLPBiasConfig.SSP_D'length - 1 downto 0) <= BiasConfigReg_DP.SSP_D;

			when CochleaLP_BIASCONFIG_PARAM_ADDRESSES.SSN_D =>
				BiasConfigReg_DN.SSN_D                                        <= BiasInput_DP(tCochleaLPBiasConfig.SSN_D'length - 1 downto 0);
				BiasOutput_DN(tCochleaLPBiasConfig.SSN_D'length - 1 downto 0) <= BiasConfigReg_DP.SSN_D;

			when others => null;
		end case;
	end process biasIO;

	biasUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			BiasInput_DP  <= (others => '0');
			BiasOutput_DP <= (others => '0');

			BiasConfigReg_DP <= tCochleaLPBiasConfigDefault;
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
			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ResetCapConfigADM_D =>
				ChipConfigReg_DN.ResetCapConfigADM_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ResetCapConfigADM_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ResetCapConfigADM_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ResetCapConfigADM_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.DelayCapConfigADM_D =>
				ChipConfigReg_DN.DelayCapConfigADM_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.DelayCapConfigADM_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.DelayCapConfigADM_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.DelayCapConfigADM_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ComparatorSelfOsc_S =>
				ChipConfigReg_DN.ComparatorSelfOsc_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                     <= ChipConfigReg_DP.ComparatorSelfOsc_S;

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.LNAGainConfig_D =>
				ChipConfigReg_DN.LNAGainConfig_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.LNAGainConfig_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.LNAGainConfig_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.LNAGainConfig_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.LNADoubleInputSelect_S =>
				ChipConfigReg_DN.LNADoubleInputSelect_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                        <= ChipConfigReg_DP.LNADoubleInputSelect_S;

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.TestScannerBias_S =>
				ChipConfigReg_DN.TestScannerBias_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                   <= ChipConfigReg_DP.TestScannerBias_S;

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ScannerEnabled_S =>
				ChipConfigReg_DN.ScannerEnabled_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                  <= ChipConfigReg_DP.ScannerEnabled_S;

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ScannerEar_S =>
				ChipConfigReg_DN.ScannerEar_S <= ChipInput_DP(0);
				ChipOutput_DN(0)              <= ChipConfigReg_DP.ScannerEar_S;

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ScannerChannel_S =>
				ChipConfigReg_DN.ScannerChannel_S                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ScannerChannel_S'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ScannerChannel_S'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ScannerChannel_S);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig0_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig1_D =>
				ChipConfigReg_DN.ChannelConfig1_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig1_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig1_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig1_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig2_D =>
				ChipConfigReg_DN.ChannelConfig2_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig2_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig2_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig2_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig3_D =>
				ChipConfigReg_DN.ChannelConfig3_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig3_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig3_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig3_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig4_D =>
				ChipConfigReg_DN.ChannelConfig4_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig4_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig4_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig4_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig5_D =>
				ChipConfigReg_DN.ChannelConfig5_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig5_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig5_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig5_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig6_D =>
				ChipConfigReg_DN.ChannelConfig6_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig6_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig6_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig6_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig7_D =>
				ChipConfigReg_DN.ChannelConfig7_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig7_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig7_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig7_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig8_D =>
				ChipConfigReg_DN.ChannelConfig8_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig8_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig8_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig8_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig9_D =>
				ChipConfigReg_DN.ChannelConfig9_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig9_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig9_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig9_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig10_D =>
				ChipConfigReg_DN.ChannelConfig10_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig10_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig10_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig10_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig11_D =>
				ChipConfigReg_DN.ChannelConfig11_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig11_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig11_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig11_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig12_D =>
				ChipConfigReg_DN.ChannelConfig12_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig12_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig12_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig12_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig13_D =>
				ChipConfigReg_DN.ChannelConfig13_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig13_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig13_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig13_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig14_D =>
				ChipConfigReg_DN.ChannelConfig14_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig14_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig14_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig14_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig15_D =>
				ChipConfigReg_DN.ChannelConfig15_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig15_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig15_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig15_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig16_D =>
				ChipConfigReg_DN.ChannelConfig16_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig16_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig16_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig16_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig17_D =>
				ChipConfigReg_DN.ChannelConfig17_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig17_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig17_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig17_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig18_D =>
				ChipConfigReg_DN.ChannelConfig18_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig18_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig18_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig18_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig19_D =>
				ChipConfigReg_DN.ChannelConfig19_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig19_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig19_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig19_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig20_D =>
				ChipConfigReg_DN.ChannelConfig20_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig20_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig20_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig20_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig21_D =>
				ChipConfigReg_DN.ChannelConfig21_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig21_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig21_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig21_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig22_D =>
				ChipConfigReg_DN.ChannelConfig22_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig22_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig22_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig22_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig23_D =>
				ChipConfigReg_DN.ChannelConfig23_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig23_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig23_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig23_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig24_D =>
				ChipConfigReg_DN.ChannelConfig24_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig24_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig24_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig24_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig25_D =>
				ChipConfigReg_DN.ChannelConfig25_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig25_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig25_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig25_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig26_D =>
				ChipConfigReg_DN.ChannelConfig26_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig26_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig26_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig26_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig27_D =>
				ChipConfigReg_DN.ChannelConfig27_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig27_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig27_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig27_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig28_D =>
				ChipConfigReg_DN.ChannelConfig28_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig28_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig28_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig28_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig29_D =>
				ChipConfigReg_DN.ChannelConfig29_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig29_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig29_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig29_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig30_D =>
				ChipConfigReg_DN.ChannelConfig30_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig30_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig30_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig30_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig31_D =>
				ChipConfigReg_DN.ChannelConfig31_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig31_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig31_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig31_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig32_D =>
				ChipConfigReg_DN.ChannelConfig32_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig32_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig32_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig32_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig33_D =>
				ChipConfigReg_DN.ChannelConfig33_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig33_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig33_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig33_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig34_D =>
				ChipConfigReg_DN.ChannelConfig34_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig34_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig34_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig34_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig35_D =>
				ChipConfigReg_DN.ChannelConfig35_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig35_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig35_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig35_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig36_D =>
				ChipConfigReg_DN.ChannelConfig36_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig36_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig36_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig36_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig37_D =>
				ChipConfigReg_DN.ChannelConfig37_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig37_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig37_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig37_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig38_D =>
				ChipConfigReg_DN.ChannelConfig38_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig38_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig38_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig38_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig39_D =>
				ChipConfigReg_DN.ChannelConfig39_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig39_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig39_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig39_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig40_D =>
				ChipConfigReg_DN.ChannelConfig40_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig40_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig40_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig40_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig41_D =>
				ChipConfigReg_DN.ChannelConfig41_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig41_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig41_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig41_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig42_D =>
				ChipConfigReg_DN.ChannelConfig42_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig42_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig42_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig42_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig43_D =>
				ChipConfigReg_DN.ChannelConfig43_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig43_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig43_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig43_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig44_D =>
				ChipConfigReg_DN.ChannelConfig44_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig44_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig44_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig44_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig45_D =>
				ChipConfigReg_DN.ChannelConfig45_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig45_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig45_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig45_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig46_D =>
				ChipConfigReg_DN.ChannelConfig46_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig46_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig46_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig46_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig47_D =>
				ChipConfigReg_DN.ChannelConfig47_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig47_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig47_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig47_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig48_D =>
				ChipConfigReg_DN.ChannelConfig48_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig48_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig48_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig48_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig49_D =>
				ChipConfigReg_DN.ChannelConfig49_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig49_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig49_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig49_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig50_D =>
				ChipConfigReg_DN.ChannelConfig50_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig50_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig50_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig50_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig51_D =>
				ChipConfigReg_DN.ChannelConfig51_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig51_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig51_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig51_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig52_D =>
				ChipConfigReg_DN.ChannelConfig52_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig52_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig52_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig52_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig53_D =>
				ChipConfigReg_DN.ChannelConfig53_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig53_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig53_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig53_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig54_D =>
				ChipConfigReg_DN.ChannelConfig54_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig54_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig54_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig54_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig55_D =>
				ChipConfigReg_DN.ChannelConfig55_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig55_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig55_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig55_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig56_D =>
				ChipConfigReg_DN.ChannelConfig56_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig56_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig56_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig56_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig57_D =>
				ChipConfigReg_DN.ChannelConfig57_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig57_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig57_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig57_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig58_D =>
				ChipConfigReg_DN.ChannelConfig58_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig58_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig58_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig58_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig59_D =>
				ChipConfigReg_DN.ChannelConfig59_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig59_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig59_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig59_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig60_D =>
				ChipConfigReg_DN.ChannelConfig60_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig60_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig60_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig60_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig61_D =>
				ChipConfigReg_DN.ChannelConfig61_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig61_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig61_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig61_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig62_D =>
				ChipConfigReg_DN.ChannelConfig62_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig62_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig62_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig62_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig63_D =>
				ChipConfigReg_DN.ChannelConfig63_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig63_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig63_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig63_D);

			when others => null;
		end case;
	end process chipIO;

	chipUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			ChipInput_DP  <= (others => '0');
			ChipOutput_DP <= (others => '0');

			ChipConfigReg_DP <= tCochleaLPChipConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			ChipInput_DP  <= ChipInput_DN;
			ChipOutput_DP <= ChipOutput_DN;

			if LatchChipReg_S = '1' and ConfigLatchInput_SI = '1' then
				ChipConfigReg_DP <= ChipConfigReg_DN;
			end if;
		end if;
	end process chipUpdate;
end architecture Behavioral;
