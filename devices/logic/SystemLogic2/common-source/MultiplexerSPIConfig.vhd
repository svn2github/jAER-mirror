library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MultiplexerConfigRecords.all;

entity MultiplexerSPIConfig is
	port(
		Clock_CI                        : in  std_logic;
		Reset_RI                        : in  std_logic;
		MultiplexerConfig_DO            : out tMultiplexerConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI          : in  unsigned(6 downto 0);
		ConfigParamAddress_DI           : in  unsigned(7 downto 0);
		ConfigParamInput_DI             : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI             : in  std_logic;
		MultiplexerConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity MultiplexerSPIConfig;

architecture Behavioral of MultiplexerSPIConfig is
	signal LatchMultiplexerReg_S                            : std_logic;
	signal MultiplexerInput_DP, MultiplexerInput_DN         : std_logic_vector(31 downto 0);
	signal MultiplexerOutput_DP, MultiplexerOutput_DN       : std_logic_vector(31 downto 0);
	signal MultiplexerConfigReg_DP, MultiplexerConfigReg_DN : tMultiplexerConfig;
begin
	MultiplexerConfig_DO            <= MultiplexerConfigReg_DP;
	MultiplexerConfigParamOutput_DO <= MultiplexerOutput_DP;

	LatchMultiplexerReg_S <= '1' when ConfigModuleAddress_DI = MULTIPLEXERCONFIG_MODULE_ADDRESS else '0';

	multiplexerIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, MultiplexerInput_DP, MultiplexerConfigReg_DP)
	begin
		MultiplexerConfigReg_DN <= MultiplexerConfigReg_DP;
		MultiplexerInput_DN     <= ConfigParamInput_DI;
		MultiplexerOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when MULTIPLEXERCONFIG_PARAM_ADDRESSES.Run_S =>
				MultiplexerConfigReg_DN.Run_S <= MultiplexerInput_DP(0);
				MultiplexerOutput_DN(0)       <= MultiplexerConfigReg_DP.Run_S;

			when MULTIPLEXERCONFIG_PARAM_ADDRESSES.TimestampRun_S =>
				MultiplexerConfigReg_DN.TimestampRun_S <= MultiplexerInput_DP(0);
				MultiplexerOutput_DN(0)                <= MultiplexerConfigReg_DP.TimestampRun_S;

			when MULTIPLEXERCONFIG_PARAM_ADDRESSES.TimestampReset_S =>
				MultiplexerConfigReg_DN.TimestampReset_S <= MultiplexerInput_DP(0);
				MultiplexerOutput_DN(0)                  <= MultiplexerConfigReg_DP.TimestampReset_S;

			when MULTIPLEXERCONFIG_PARAM_ADDRESSES.ForceChipBiasEnable_S =>
				MultiplexerConfigReg_DN.ForceChipBiasEnable_S <= MultiplexerInput_DP(0);
				MultiplexerOutput_DN(0)                       <= MultiplexerConfigReg_DP.ForceChipBiasEnable_S;

			when MULTIPLEXERCONFIG_PARAM_ADDRESSES.DropInput1OnTransferStall_S =>
				MultiplexerConfigReg_DN.DropInput1OnTransferStall_S <= MultiplexerInput_DP(0);
				MultiplexerOutput_DN(0)                             <= MultiplexerConfigReg_DP.DropInput1OnTransferStall_S;

			when MULTIPLEXERCONFIG_PARAM_ADDRESSES.DropInput2OnTransferStall_S =>
				MultiplexerConfigReg_DN.DropInput2OnTransferStall_S <= MultiplexerInput_DP(0);
				MultiplexerOutput_DN(0)                             <= MultiplexerConfigReg_DP.DropInput2OnTransferStall_S;

			when MULTIPLEXERCONFIG_PARAM_ADDRESSES.DropInput3OnTransferStall_S =>
				MultiplexerConfigReg_DN.DropInput3OnTransferStall_S <= MultiplexerInput_DP(0);
				MultiplexerOutput_DN(0)                             <= MultiplexerConfigReg_DP.DropInput3OnTransferStall_S;

			when MULTIPLEXERCONFIG_PARAM_ADDRESSES.DropInput4OnTransferStall_S =>
				MultiplexerConfigReg_DN.DropInput4OnTransferStall_S <= MultiplexerInput_DP(0);
				MultiplexerOutput_DN(0)                             <= MultiplexerConfigReg_DP.DropInput4OnTransferStall_S;

			when others => null;
		end case;
	end process multiplexerIO;

	multiplexerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			MultiplexerInput_DP  <= (others => '0');
			MultiplexerOutput_DP <= (others => '0');

			MultiplexerConfigReg_DP <= tMultiplexerConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			MultiplexerInput_DP  <= MultiplexerInput_DN;
			MultiplexerOutput_DP <= MultiplexerOutput_DN;

			if LatchMultiplexerReg_S = '1' and ConfigLatchInput_SI = '1' then
				MultiplexerConfigReg_DP <= MultiplexerConfigReg_DN;
			end if;
		end if;
	end process multiplexerUpdate;
end architecture Behavioral;
