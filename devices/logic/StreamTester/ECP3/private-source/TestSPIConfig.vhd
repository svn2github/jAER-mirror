library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.TestConfigRecords.all;

entity TestSPIConfig is
	port(
		Clock_CI                 : in  std_logic;
		Reset_RI                 : in  std_logic;
		TestConfig_DO            : out tTestConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI   : in  unsigned(6 downto 0);
		ConfigParamAddress_DI    : in  unsigned(7 downto 0);
		ConfigParamInput_DI      : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI      : in  std_logic;
		TestConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity TestSPIConfig;

architecture Behavioral of TestSPIConfig is
	signal LatchTestReg_S                     : std_logic;
	signal TestInput_DP, TestInput_DN         : std_logic_vector(31 downto 0);
	signal TestOutput_DP, TestOutput_DN       : std_logic_vector(31 downto 0);
	signal TestConfigReg_DP, TestConfigReg_DN : tTestConfig;
begin
	TestConfig_DO            <= TestConfigReg_DP;
	TestConfigParamOutput_DO <= TestOutput_DP;

	LatchTestReg_S <= '1' when ConfigModuleAddress_DI = TESTCONFIG_MODULE_ADDRESS else '0';

	testIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, TestInput_DP, TestConfigReg_DP)
	begin
		TestConfigReg_DN <= TestConfigReg_DP;
		TestInput_DN     <= ConfigParamInput_DI;
		TestOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when TESTCONFIG_PARAM_ADDRESSES.TestUSBFifo_S =>
				TestConfigReg_DN.TestUSBFifo_S <= TestInput_DP(0);
				TestOutput_DN(0)               <= TestConfigReg_DP.TestUSBFifo_S;

			when TESTCONFIG_PARAM_ADDRESSES.TestUSBOutputsHigh_S =>
				TestConfigReg_DN.TestUSBOutputsHigh_S <= TestInput_DP(0);
				TestOutput_DN(0)                      <= TestConfigReg_DP.TestUSBOutputsHigh_S;

			when TESTCONFIG_PARAM_ADDRESSES.TestBank0_S =>
				TestConfigReg_DN.TestBank0_S <= TestInput_DP(0);
				TestOutput_DN(0)             <= TestConfigReg_DP.TestBank0_S;

			when TESTCONFIG_PARAM_ADDRESSES.TestBank1_S =>
				TestConfigReg_DN.TestBank1_S <= TestInput_DP(0);
				TestOutput_DN(0)             <= TestConfigReg_DP.TestBank1_S;

			when TESTCONFIG_PARAM_ADDRESSES.TestBank2_S =>
				TestConfigReg_DN.TestBank2_S <= TestInput_DP(0);
				TestOutput_DN(0)             <= TestConfigReg_DP.TestBank2_S;

			when TESTCONFIG_PARAM_ADDRESSES.TestBank7_S =>
				TestConfigReg_DN.TestBank7_S <= TestInput_DP(0);
				TestOutput_DN(0)             <= TestConfigReg_DP.TestBank7_S;

			when others => null;
		end case;
	end process testIO;

	testUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			TestInput_DP  <= (others => '0');
			TestOutput_DP <= (others => '0');

			TestConfigReg_DP <= tTestConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			TestInput_DP  <= TestInput_DN;
			TestOutput_DP <= TestOutput_DN;

			if LatchTestReg_S = '1' and ConfigLatchInput_SI = '1' then
				TestConfigReg_DP <= TestConfigReg_DN;
			end if;
		end if;
	end process testUpdate;
end architecture Behavioral;
