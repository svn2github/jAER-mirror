library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DACConfigRecords.all;

entity DACSPIConfig is
	port(
		Clock_CI                : in  std_logic;
		Reset_RI                : in  std_logic;
		DACConfig_DO            : out tDACConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI  : in  unsigned(6 downto 0);
		ConfigParamAddress_DI   : in  unsigned(7 downto 0);
		ConfigParamInput_DI     : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI     : in  std_logic;
		DACConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity DACSPIConfig;

architecture Behavioral of DACSPIConfig is
	type tDACConfigStore is array (DAC_CHAN_NUMBER - 1 downto 0) of unsigned(DAC_DATA_LENGTH - 1 downto 0);

	signal DACConfigStorage_DP, DACConfigStorage_DN : tDACConfigStore;

	signal LatchDACReg_S                    : std_logic;
	signal DACInput_DP, DACInput_DN         : std_logic_vector(31 downto 0);
	signal DACOutput_DP, DACOutput_DN       : std_logic_vector(31 downto 0);
	signal DACConfigReg_DP, DACConfigReg_DN : tDACConfig;
begin
	DACConfig_DO            <= DACConfigReg_DP;
	DACConfigParamOutput_DO <= DACOutput_DP;

	LatchDACReg_S <= '1' when ConfigModuleAddress_DI = DACCONFIG_MODULE_ADDRESS else '0';

	dacIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, DACInput_DP, DACConfigReg_DP, DACConfigStorage_DP)
	begin
		DACConfigReg_DN <= DACConfigReg_DP;
		DACInput_DN     <= ConfigParamInput_DI;
		DACOutput_DN    <= (others => '0');

		DACConfigStorage_DN <= DACConfigStorage_DP;

		case ConfigParamAddress_DI is
			when DACCONFIG_PARAM_ADDRESSES.Run_S =>
				DACConfigReg_DN.Run_S <= DACInput_DP(0);
				DACOutput_DN(0)       <= DACConfigReg_DP.Run_S;

			when DACCONFIG_PARAM_ADDRESSES.DAC_D =>
				DACConfigReg_DN.DAC_D                <= unsigned(DACInput_DP(tDACConfig.DAC_D'range));
				DACOutput_DN(tDACConfig.DAC_D'range) <= std_logic_vector(DACConfigReg_DP.DAC_D);

			when DACCONFIG_PARAM_ADDRESSES.Register_D =>
				DACConfigReg_DN.Register_D                <= unsigned(DACInput_DP(tDACConfig.Register_D'range));
				DACOutput_DN(tDACConfig.Register_D'range) <= std_logic_vector(DACConfigReg_DP.Register_D);

			when DACCONFIG_PARAM_ADDRESSES.Channel_D =>
				DACConfigReg_DN.Channel_D                <= unsigned(DACInput_DP(tDACConfig.Channel_D'range));
				DACOutput_DN(tDACConfig.Channel_D'range) <= std_logic_vector(DACConfigReg_DP.Channel_D);

			when DACCONFIG_PARAM_ADDRESSES.DataRead_D =>
				DACOutput_DN(DAC_DATA_LENGTH - 1 downto 0) <= std_logic_vector(DACConfigStorage_DP(to_integer(DACConfigReg_DP.DAC_D & DACConfigReg_DP.Register_D & DACConfigReg_DP.Channel_D)));

			when DACCONFIG_PARAM_ADDRESSES.DataWrite_D =>
				DACConfigReg_DN.DataWrite_D                <= unsigned(DACInput_DP(tDACConfig.DataWrite_D'range));
				DACOutput_DN(tDACConfig.DataWrite_D'range) <= std_logic_vector(DACConfigReg_DP.DataWrite_D);

			when DACCONFIG_PARAM_ADDRESSES.Set_S =>
				DACConfigReg_DN.Set_S <= DACInput_DP(0);
				DACOutput_DN(0)       <= DACConfigReg_DP.Set_S;

			when others => null;
		end case;
	end process dacIO;

	dacUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			DACInput_DP  <= (others => '0');
			DACOutput_DP <= (others => '0');

			DACConfigStorage_DP <= (others => (others => '0'));

			DACConfigReg_DP <= tDACConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			DACInput_DP  <= DACInput_DN;
			DACOutput_DP <= DACOutput_DN;

			DACConfigStorage_DP <= DACConfigStorage_DN;

			if LatchDACReg_S = '1' and ConfigLatchInput_SI = '1' then
				DACConfigReg_DP <= DACConfigReg_DN;

				-- Also store value in internal storage, so that it can be queried later on.
				if ConfigParamAddress_DI = DACCONFIG_PARAM_ADDRESSES.Set_S then
					DACConfigStorage_DP(to_integer(DACConfigReg_DP.DAC_D & DACConfigReg_DP.Register_D & DACConfigReg_DP.Channel_D)) <= DACConfigReg_DP.DataWrite_D;
				end if;
			end if;
		end if;
	end process dacUpdate;
end architecture Behavioral;
