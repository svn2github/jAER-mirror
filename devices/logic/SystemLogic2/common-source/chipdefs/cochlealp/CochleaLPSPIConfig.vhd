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
				-- TODO: fix numbers.
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig1_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig2_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig3_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig4_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig5_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig6_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig7_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig8_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig9_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig10_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig11_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig12_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig13_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig14_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig15_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig16_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig17_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig18_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig19_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig20_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig21_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig22_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig23_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig24_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig25_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig26_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig27_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig28_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig29_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig30_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig31_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig32_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig33_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig34_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig35_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig36_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig37_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig38_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig39_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig40_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig41_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig42_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig43_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig44_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig45_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig46_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig47_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig48_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig49_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig50_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig51_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig52_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig53_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig54_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig55_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig56_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig57_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig58_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig59_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig60_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig61_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig62_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

			when CochleaLP_CHIPCONFIG_PARAM_ADDRESSES.ChannelConfig63_D =>
				ChipConfigReg_DN.ChannelConfig0_D                                        <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0));
				ChipOutput_DN(tCochleaLPChipConfig.ChannelConfig0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.ChannelConfig0_D);

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
