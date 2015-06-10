library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use work.ChipBiasConfigRecords.all;
use work.CochleaLPChipBiasConfigRecords.all;

entity CochleaLPSPIConfig is
	port(
		Clock_CI                    : in  std_logic;
		Reset_RI                    : in  std_logic;
		BiasConfig_DO               : out tCochleaLPBiasConfig;
		ChipConfig_DO               : out tCochleaLPChipConfig;
		ChannelConfig_DO            : out tCochleaLPChannelConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI      : in  unsigned(6 downto 0);
		ConfigParamAddress_DI       : in  unsigned(7 downto 0);
		ConfigParamInput_DI         : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI         : in  std_logic;
		BiasConfigParamOutput_DO    : out std_logic_vector(31 downto 0);
		ChipConfigParamOutput_DO    : out std_logic_vector(31 downto 0);
		ChannelConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity CochleaLPSPIConfig;

architecture Behavioral of CochleaLPSPIConfig is
	signal ChannelConfigStorage_DP, ChannelConfigStorage_DN : std_logic_vector(CHIP_CHAN_REG_USED_SIZE - 1 downto 0);

	signal ChannelConfigStorageAddress_D     : unsigned(CHIP_CHANADDR_REG_USED_SIZE - 1 downto 0);
	signal ChannelConfigStorageWriteEnable_S : std_logic;

	signal LatchBiasReg_S                     : std_logic;
	signal BiasInput_DP, BiasInput_DN         : std_logic_vector(31 downto 0);
	signal BiasOutput_DP, BiasOutput_DN       : std_logic_vector(31 downto 0);
	signal BiasConfigReg_DP, BiasConfigReg_DN : tCochleaLPBiasConfig;

	signal LatchChipReg_S                     : std_logic;
	signal ChipInput_DP, ChipInput_DN         : std_logic_vector(31 downto 0);
	signal ChipOutput_DP, ChipOutput_DN       : std_logic_vector(31 downto 0);
	signal ChipConfigReg_DP, ChipConfigReg_DN : tCochleaLPChipConfig;

	signal LatchChannelReg_S                        : std_logic;
	signal ChannelInput_DP, ChannelInput_DN         : std_logic_vector(31 downto 0);
	signal ChannelOutput_DP, ChannelOutput_DN       : std_logic_vector(31 downto 0);
	signal ChannelConfigReg_DP, ChannelConfigReg_DN : tCochleaLPChannelConfig;
begin
	BiasConfig_DO            <= BiasConfigReg_DP;
	BiasConfigParamOutput_DO <= BiasOutput_DP;

	ChipConfig_DO            <= ChipConfigReg_DP;
	ChipConfigParamOutput_DO <= ChipOutput_DP;

	ChannelConfig_DO            <= ChannelConfigReg_DP;
	ChannelConfigParamOutput_DO <= ChannelOutput_DP;

	LatchBiasReg_S    <= '1' when (ConfigModuleAddress_DI = CHIPBIASCONFIG_MODULE_ADDRESS and ConfigParamAddress_DI(7) = '0') else '0';
	LatchChipReg_S    <= '1' when (ConfigModuleAddress_DI = CHIPBIASCONFIG_MODULE_ADDRESS and ConfigParamAddress_DI(7 downto 5) = "100") else '0';
	LatchChannelReg_S <= '1' when (ConfigModuleAddress_DI = CHIPBIASCONFIG_MODULE_ADDRESS and ConfigParamAddress_DI(7 downto 5) = "101") else '0';

	channelConfigStorage : entity work.BlockRAM
		generic map(
			ADDRESS_DEPTH => CHIP_CHAN_NUMBER,
			ADDRESS_WIDTH => CHIP_CHANADDR_REG_USED_SIZE,
			DATA_WIDTH    => CHIP_CHAN_REG_USED_SIZE)
		port map(
			Clock_CI       => Clock_CI,
			Reset_RI       => Reset_RI,
			Address_DI     => ChannelConfigStorageAddress_D,
			Enable_SI      => '1',
			WriteEnable_SI => ChannelConfigStorageWriteEnable_S,
			Data_DI        => ChannelConfigStorage_DN,
			Data_DO        => ChannelConfigStorage_DP);

	ChannelConfigStorageAddress_D     <= ChannelConfigReg_DP.ChannelAddress_D;
	ChannelConfigStorageWriteEnable_S <= '1' when (LatchChannelReg_S = '1' and ConfigLatchInput_SI = '1' and ConfigParamAddress_DI = COCHLEALP_CHANNELCONFIG_PARAM_ADDRESSES.ChannelSet_S) else '0';
	ChannelConfigStorage_DN           <= ChannelConfigReg_DP.ChannelDataWrite_D;

	biasIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, BiasInput_DP, BiasConfigReg_DP)
	begin
		BiasConfigReg_DN <= BiasConfigReg_DP;
		BiasInput_DN     <= ConfigParamInput_DI;
		BiasOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when COCHLEALP_BIASCONFIG_PARAM_ADDRESSES.VBNIBias_D =>
				BiasConfigReg_DN.VBNIBias_D                          <= BiasInput_DP(tCochleaLPBiasConfig.VBNIBias_D'range);
				BiasOutput_DN(tCochleaLPBiasConfig.VBNIBias_D'range) <= BiasConfigReg_DP.VBNIBias_D;

			when COCHLEALP_BIASCONFIG_PARAM_ADDRESSES.VBNTest_D =>
				BiasConfigReg_DN.VBNTest_D                          <= BiasInput_DP(tCochleaLPBiasConfig.VBNTest_D'range);
				BiasOutput_DN(tCochleaLPBiasConfig.VBNTest_D'range) <= BiasConfigReg_DP.VBNTest_D;

			when COCHLEALP_BIASCONFIG_PARAM_ADDRESSES.VBPScan_D =>
				BiasConfigReg_DN.VBPScan_D                          <= BiasInput_DP(tCochleaLPBiasConfig.VBPScan_D'range);
				BiasOutput_DN(tCochleaLPBiasConfig.VBPScan_D'range) <= BiasConfigReg_DP.VBPScan_D;

			when COCHLEALP_BIASCONFIG_PARAM_ADDRESSES.AEPdBn_D =>
				BiasConfigReg_DN.AEPdBn_D                          <= BiasInput_DP(tCochleaLPBiasConfig.AEPdBn_D'range);
				BiasOutput_DN(tCochleaLPBiasConfig.AEPdBn_D'range) <= BiasConfigReg_DP.AEPdBn_D;

			when COCHLEALP_BIASCONFIG_PARAM_ADDRESSES.AEPuYBp_D =>
				BiasConfigReg_DN.AEPuYBp_D                          <= BiasInput_DP(tCochleaLPBiasConfig.AEPuYBp_D'range);
				BiasOutput_DN(tCochleaLPBiasConfig.AEPuYBp_D'range) <= BiasConfigReg_DP.AEPuYBp_D;

			when COCHLEALP_BIASCONFIG_PARAM_ADDRESSES.BiasBuffer_D =>
				BiasConfigReg_DN.BiasBuffer_D                          <= BiasInput_DP(tCochleaLPBiasConfig.BiasBuffer_D'range);
				BiasOutput_DN(tCochleaLPBiasConfig.BiasBuffer_D'range) <= BiasConfigReg_DP.BiasBuffer_D;

			when COCHLEALP_BIASCONFIG_PARAM_ADDRESSES.SSP_D =>
				BiasConfigReg_DN.SSP_D                          <= BiasInput_DP(tCochleaLPBiasConfig.SSP_D'range);
				BiasOutput_DN(tCochleaLPBiasConfig.SSP_D'range) <= BiasConfigReg_DP.SSP_D;

			when COCHLEALP_BIASCONFIG_PARAM_ADDRESSES.SSN_D =>
				BiasConfigReg_DN.SSN_D                          <= BiasInput_DP(tCochleaLPBiasConfig.SSN_D'range);
				BiasOutput_DN(tCochleaLPBiasConfig.SSN_D'range) <= BiasConfigReg_DP.SSN_D;

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
			when COCHLEALP_CHIPCONFIG_PARAM_ADDRESSES.ResetCapConfigADM_D =>
				ChipConfigReg_DN.ResetCapConfigADM_D                          <= unsigned(ChipInput_DP(tCochleaLPChipConfig.ResetCapConfigADM_D'range));
				ChipOutput_DN(tCochleaLPChipConfig.ResetCapConfigADM_D'range) <= std_logic_vector(ChipConfigReg_DP.ResetCapConfigADM_D);

			when COCHLEALP_CHIPCONFIG_PARAM_ADDRESSES.DelayCapConfigADM_D =>
				ChipConfigReg_DN.DelayCapConfigADM_D                          <= unsigned(ChipInput_DP(tCochleaLPChipConfig.DelayCapConfigADM_D'range));
				ChipOutput_DN(tCochleaLPChipConfig.DelayCapConfigADM_D'range) <= std_logic_vector(ChipConfigReg_DP.DelayCapConfigADM_D);

			when COCHLEALP_CHIPCONFIG_PARAM_ADDRESSES.ComparatorSelfOsc_S =>
				ChipConfigReg_DN.ComparatorSelfOsc_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                     <= ChipConfigReg_DP.ComparatorSelfOsc_S;

			when COCHLEALP_CHIPCONFIG_PARAM_ADDRESSES.LNAGainConfig_D =>
				ChipConfigReg_DN.LNAGainConfig_D                          <= unsigned(ChipInput_DP(tCochleaLPChipConfig.LNAGainConfig_D'range));
				ChipOutput_DN(tCochleaLPChipConfig.LNAGainConfig_D'range) <= std_logic_vector(ChipConfigReg_DP.LNAGainConfig_D);

			when COCHLEALP_CHIPCONFIG_PARAM_ADDRESSES.LNADoubleInputSelect_S =>
				ChipConfigReg_DN.LNADoubleInputSelect_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                        <= ChipConfigReg_DP.LNADoubleInputSelect_S;

			when COCHLEALP_CHIPCONFIG_PARAM_ADDRESSES.TestScannerBias_S =>
				ChipConfigReg_DN.TestScannerBias_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                   <= ChipConfigReg_DP.TestScannerBias_S;

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

	channelIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, ChannelInput_DP, ChannelConfigReg_DP, ChannelConfigStorage_DP)
	begin
		ChannelConfigReg_DN <= ChannelConfigReg_DP;
		ChannelInput_DN     <= ConfigParamInput_DI;
		ChannelOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when COCHLEALP_CHANNELCONFIG_PARAM_ADDRESSES.ChannelAddress_D =>
				ChannelConfigReg_DN.ChannelAddress_D                             <= unsigned(ChannelInput_DP(tCochleaLPChannelConfig.ChannelAddress_D'range));
				ChannelOutput_DN(tCochleaLPChannelConfig.ChannelAddress_D'range) <= std_logic_vector(ChannelConfigReg_DP.ChannelAddress_D);

			when COCHLEALP_CHANNELCONFIG_PARAM_ADDRESSES.ChannelDataRead_D =>
				ChannelOutput_DN(CHIP_CHAN_REG_USED_SIZE - 1 downto 0) <= ChannelConfigStorage_DP;

			when COCHLEALP_CHANNELCONFIG_PARAM_ADDRESSES.ChannelDataWrite_D =>
				ChannelConfigReg_DN.ChannelDataWrite_D                             <= ChannelInput_DP(tCochleaLPChannelConfig.ChannelDataWrite_D'range);
				ChannelOutput_DN(tCochleaLPChannelConfig.ChannelDataWrite_D'range) <= ChannelConfigReg_DP.ChannelDataWrite_D;

			when COCHLEALP_CHANNELCONFIG_PARAM_ADDRESSES.ChannelSet_S =>
				ChannelConfigReg_DN.ChannelSet_S <= ChannelInput_DP(0);
				ChannelOutput_DN(0)              <= ChannelConfigReg_DP.ChannelSet_S;

			when others => null;
		end case;
	end process channelIO;

	channelUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			ChannelInput_DP  <= (others => '0');
			ChannelOutput_DP <= (others => '0');

			ChannelConfigReg_DP <= tCochleaLPChannelConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			ChannelInput_DP  <= ChannelInput_DN;
			ChannelOutput_DP <= ChannelOutput_DN;

			if LatchChannelReg_S = '1' and ConfigLatchInput_SI = '1' then
				ChannelConfigReg_DP <= ChannelConfigReg_DN;
			end if;
		end if;
	end process channelUpdate;
end architecture Behavioral;
