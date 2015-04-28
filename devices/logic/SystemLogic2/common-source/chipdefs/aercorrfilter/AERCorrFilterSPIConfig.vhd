library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ChipBiasConfigRecords.all;
use work.AERCorrFilterChipBiasConfigRecords.all;

entity AERCorrFilterSPIConfig is
	port(
		Clock_CI                 : in  std_logic;
		Reset_RI                 : in  std_logic;
		BiasConfig_DO            : out tAERCorrFilterBiasConfig;
		ChipConfig_DO            : out tAERCorrFilterChipConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI   : in  unsigned(6 downto 0);
		ConfigParamAddress_DI    : in  unsigned(7 downto 0);
		ConfigParamInput_DI      : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI      : in  std_logic;
		BiasConfigParamOutput_DO : out std_logic_vector(31 downto 0);
		ChipConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity AERCorrFilterSPIConfig;

architecture Behavioral of AERCorrFilterSPIConfig is
	signal LatchBiasReg_S                     : std_logic;
	signal BiasInput_DP, BiasInput_DN         : std_logic_vector(31 downto 0);
	signal BiasOutput_DP, BiasOutput_DN       : std_logic_vector(31 downto 0);
	signal BiasConfigReg_DP, BiasConfigReg_DN : tAERCorrFilterBiasConfig;

	signal LatchChipReg_S                     : std_logic;
	signal ChipInput_DP, ChipInput_DN         : std_logic_vector(31 downto 0);
	signal ChipOutput_DP, ChipOutput_DN       : std_logic_vector(31 downto 0);
	signal ChipConfigReg_DP, ChipConfigReg_DN : tAERCorrFilterChipConfig;
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
			when AERCorrFilter_BIASCONFIG_PARAM_ADDRESSES.Vth_D =>
				BiasConfigReg_DN.Vth_D                                            <= BiasInput_DP(tAERCorrFilterBiasConfig.Vth_D'length - 1 downto 0);
				BiasOutput_DN(tAERCorrFilterBiasConfig.Vth_D'length - 1 downto 0) <= BiasConfigReg_DP.Vth_D;

			when AERCorrFilter_BIASCONFIG_PARAM_ADDRESSES.Vrs_D =>
				BiasConfigReg_DN.Vrs_D                                            <= BiasInput_DP(tAERCorrFilterBiasConfig.Vrs_D'length - 1 downto 0);
				BiasOutput_DN(tAERCorrFilterBiasConfig.Vrs_D'length - 1 downto 0) <= BiasConfigReg_DP.Vrs_D;

			when AERCorrFilter_BIASCONFIG_PARAM_ADDRESSES.LocalBufBn_D =>
				BiasConfigReg_DN.LocalBufBn_D                                            <= BiasInput_DP(tAERCorrFilterBiasConfig.LocalBufBn_D'length - 1 downto 0);
				BiasOutput_DN(tAERCorrFilterBiasConfig.LocalBufBn_D'length - 1 downto 0) <= BiasConfigReg_DP.LocalBufBn_D;

			when AERCorrFilter_BIASCONFIG_PARAM_ADDRESSES.PadFollBn_D =>
				BiasConfigReg_DN.PadFollBn_D                                            <= BiasInput_DP(tAERCorrFilterBiasConfig.PadFollBn_D'length - 1 downto 0);
				BiasOutput_DN(tAERCorrFilterBiasConfig.PadFollBn_D'length - 1 downto 0) <= BiasConfigReg_DP.PadFollBn_D;

			when AERCorrFilter_BIASCONFIG_PARAM_ADDRESSES.BiasComp_D =>
				BiasConfigReg_DN.BiasComp_D                                            <= BiasInput_DP(tAERCorrFilterBiasConfig.BiasComp_D'length - 1 downto 0);
				BiasOutput_DN(tAERCorrFilterBiasConfig.BiasComp_D'length - 1 downto 0) <= BiasConfigReg_DP.BiasComp_D;

			when AERCorrFilter_BIASCONFIG_PARAM_ADDRESSES.ILeak_D =>
				BiasConfigReg_DN.ILeak_D                                            <= BiasInput_DP(tAERCorrFilterBiasConfig.ILeak_D'length - 1 downto 0);
				BiasOutput_DN(tAERCorrFilterBiasConfig.ILeak_D'length - 1 downto 0) <= BiasConfigReg_DP.ILeak_D;

			when AERCorrFilter_BIASCONFIG_PARAM_ADDRESSES.IFRefrBn_D =>
				BiasConfigReg_DN.IFRefrBn_D                                            <= BiasInput_DP(tAERCorrFilterBiasConfig.IFRefrBn_D'length - 1 downto 0);
				BiasOutput_DN(tAERCorrFilterBiasConfig.IFRefrBn_D'length - 1 downto 0) <= BiasConfigReg_DP.IFRefrBn_D;

			when AERCorrFilter_BIASCONFIG_PARAM_ADDRESSES.IFThrBn_D =>
				BiasConfigReg_DN.IFThrBn_D                                            <= BiasInput_DP(tAERCorrFilterBiasConfig.IFThrBn_D'length - 1 downto 0);
				BiasOutput_DN(tAERCorrFilterBiasConfig.IFThrBn_D'length - 1 downto 0) <= BiasConfigReg_DP.IFThrBn_D;

			when AERCorrFilter_BIASCONFIG_PARAM_ADDRESSES.BiasBuffer_D =>
				BiasConfigReg_DN.BiasBuffer_D                                            <= BiasInput_DP(tAERCorrFilterBiasConfig.BiasBuffer_D'length - 1 downto 0);
				BiasOutput_DN(tAERCorrFilterBiasConfig.BiasBuffer_D'length - 1 downto 0) <= BiasConfigReg_DP.BiasBuffer_D;

			when AERCorrFilter_BIASCONFIG_PARAM_ADDRESSES.SSP_D =>
				BiasConfigReg_DN.SSP_D                                            <= BiasInput_DP(tAERCorrFilterBiasConfig.SSP_D'length - 1 downto 0);
				BiasOutput_DN(tAERCorrFilterBiasConfig.SSP_D'length - 1 downto 0) <= BiasConfigReg_DP.SSP_D;

			when AERCorrFilter_BIASCONFIG_PARAM_ADDRESSES.SSN_D =>
				BiasConfigReg_DN.SSN_D                                            <= BiasInput_DP(tAERCorrFilterBiasConfig.SSN_D'length - 1 downto 0);
				BiasOutput_DN(tAERCorrFilterBiasConfig.SSN_D'length - 1 downto 0) <= BiasConfigReg_DP.SSN_D;

			when others => null;
		end case;
	end process biasIO;

	biasUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			BiasInput_DP  <= (others => '0');
			BiasOutput_DP <= (others => '0');

			BiasConfigReg_DP <= tAERCorrFilterBiasConfigDefault;
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
			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.DigitalMux0_D =>
				ChipConfigReg_DN.DigitalMux0_D                                            <= unsigned(ChipInput_DP(tAERCorrFilterChipConfig.DigitalMux0_D'length - 1 downto 0));
				ChipOutput_DN(tAERCorrFilterChipConfig.DigitalMux0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.DigitalMux0_D);

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.DigitalMux1_D =>
				ChipConfigReg_DN.DigitalMux1_D                                            <= unsigned(ChipInput_DP(tAERCorrFilterChipConfig.DigitalMux1_D'length - 1 downto 0));
				ChipOutput_DN(tAERCorrFilterChipConfig.DigitalMux1_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.DigitalMux1_D);

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.DigitalMux2_D =>
				ChipConfigReg_DN.DigitalMux2_D                                            <= unsigned(ChipInput_DP(tAERCorrFilterChipConfig.DigitalMux2_D'length - 1 downto 0));
				ChipOutput_DN(tAERCorrFilterChipConfig.DigitalMux2_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.DigitalMux2_D);

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.DigitalMux3_D =>
				ChipConfigReg_DN.DigitalMux3_D                                            <= unsigned(ChipInput_DP(tAERCorrFilterChipConfig.DigitalMux3_D'length - 1 downto 0));
				ChipOutput_DN(tAERCorrFilterChipConfig.DigitalMux3_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.DigitalMux3_D);

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.AnalogMux0_D =>
				ChipConfigReg_DN.AnalogMux0_D                                            <= unsigned(ChipInput_DP(tAERCorrFilterChipConfig.AnalogMux0_D'length - 1 downto 0));
				ChipOutput_DN(tAERCorrFilterChipConfig.AnalogMux0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.AnalogMux0_D);

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.AnalogMux1_D =>
				ChipConfigReg_DN.AnalogMux1_D                                            <= unsigned(ChipInput_DP(tAERCorrFilterChipConfig.AnalogMux1_D'length - 1 downto 0));
				ChipOutput_DN(tAERCorrFilterChipConfig.AnalogMux1_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.AnalogMux1_D);

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.AnalogMux2_D =>
				ChipConfigReg_DN.AnalogMux2_D                                            <= unsigned(ChipInput_DP(tAERCorrFilterChipConfig.AnalogMux2_D'length - 1 downto 0));
				ChipOutput_DN(tAERCorrFilterChipConfig.AnalogMux2_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.AnalogMux2_D);

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.AnalogMux3_D =>
				ChipConfigReg_DN.AnalogMux3_D                                            <= unsigned(ChipInput_DP(tAERCorrFilterChipConfig.AnalogMux3_D'length - 1 downto 0));
				ChipOutput_DN(tAERCorrFilterChipConfig.AnalogMux3_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.AnalogMux3_D);

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.BiasMux0_D =>
				ChipConfigReg_DN.BiasMux0_D                                            <= unsigned(ChipInput_DP(tAERCorrFilterChipConfig.BiasMux0_D'length - 1 downto 0));
				ChipOutput_DN(tAERCorrFilterChipConfig.BiasMux0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.BiasMux0_D);

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.ResetCalibNeuron_S =>
				ChipConfigReg_DN.ResetCalibNeuron_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                    <= ChipConfigReg_DP.ResetCalibNeuron_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.TypeNCalibNeuron_S =>
				ChipConfigReg_DN.TypeNCalibNeuron_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                    <= ChipConfigReg_DP.TypeNCalibNeuron_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.UseAOut_S =>
				ChipConfigReg_DN.UseAOut_S <= ChipInput_DP(0);
				ChipOutput_DN(0)           <= ChipConfigReg_DP.UseAOut_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.ChipIDX0_S =>
				ChipConfigReg_DN.ChipIDX0_S <= ChipInput_DP(0);
				ChipOutput_DN(0)            <= ChipConfigReg_DP.ChipIDX0_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.ChipIDX1_S =>
				ChipConfigReg_DN.ChipIDX1_S <= ChipInput_DP(0);
				ChipOutput_DN(0)            <= ChipConfigReg_DP.ChipIDX1_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.AMCX0_S =>
				ChipConfigReg_DN.AMCX0_S <= ChipInput_DP(0);
				ChipOutput_DN(0)         <= ChipConfigReg_DP.AMCX0_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.AMCX1_S =>
				ChipConfigReg_DN.AMCX1_S <= ChipInput_DP(0);
				ChipOutput_DN(0)         <= ChipConfigReg_DP.AMCX1_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.AMDX0_S =>
				ChipConfigReg_DN.AMDX0_S <= ChipInput_DP(0);
				ChipOutput_DN(0)         <= ChipConfigReg_DP.AMDX0_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.AMDX1_S =>
				ChipConfigReg_DN.AMDX1_S <= ChipInput_DP(0);
				ChipOutput_DN(0)         <= ChipConfigReg_DP.AMDX1_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.ChipIDY0_S =>
				ChipConfigReg_DN.ChipIDY0_S <= ChipInput_DP(0);
				ChipOutput_DN(0)            <= ChipConfigReg_DP.ChipIDY0_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.ChipIDY1_S =>
				ChipConfigReg_DN.ChipIDY1_S <= ChipInput_DP(0);
				ChipOutput_DN(0)            <= ChipConfigReg_DP.ChipIDY1_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.AMCY0_S =>
				ChipConfigReg_DN.AMCY0_S <= ChipInput_DP(0);
				ChipOutput_DN(0)         <= ChipConfigReg_DP.AMCY0_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.AMCY1_S =>
				ChipConfigReg_DN.AMCY1_S <= ChipInput_DP(0);
				ChipOutput_DN(0)         <= ChipConfigReg_DP.AMCY1_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.AMDY0_S =>
				ChipConfigReg_DN.AMDY0_S <= ChipInput_DP(0);
				ChipOutput_DN(0)         <= ChipConfigReg_DP.AMDY0_S;

			when AERCorrFilter_CHIPCONFIG_PARAM_ADDRESSES.AMDY1_S =>
				ChipConfigReg_DN.AMDY1_S <= ChipInput_DP(0);
				ChipOutput_DN(0)         <= ChipConfigReg_DP.AMDY1_S;

			when others => null;
		end case;
	end process chipIO;

	chipUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			ChipInput_DP  <= (others => '0');
			ChipOutput_DP <= (others => '0');

			ChipConfigReg_DP <= tAERCorrFilterChipConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			ChipInput_DP  <= ChipInput_DN;
			ChipOutput_DP <= ChipOutput_DN;

			if LatchChipReg_S = '1' and ConfigLatchInput_SI = '1' then
				ChipConfigReg_DP <= ChipConfigReg_DN;
			end if;
		end if;
	end process chipUpdate;
end architecture Behavioral;
