library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.FX2ConfigRecords.all;

entity FX2SPIConfig is
	port(
		Clock_CI                : in  std_logic;
		Reset_RI                : in  std_logic;
		FX2Config_DO            : out tFX2Config;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI  : in  unsigned(6 downto 0);
		ConfigParamAddress_DI   : in  unsigned(7 downto 0);
		ConfigParamInput_DI     : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI     : in  std_logic;
		FX2ConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity FX2SPIConfig;

architecture Behavioral of FX2SPIConfig is
	signal LatchFX2Reg_S                    : std_logic;
	signal FX2Input_DP, FX2Input_DN         : std_logic_vector(31 downto 0);
	signal FX2Output_DP, FX2Output_DN       : std_logic_vector(31 downto 0);
	signal FX2ConfigReg_DP, FX2ConfigReg_DN : tFX2Config;
begin
	FX2Config_DO            <= FX2ConfigReg_DP;
	FX2ConfigParamOutput_DO <= FX2Output_DP;

	LatchFX2Reg_S <= '1' when ConfigModuleAddress_DI = FX2CONFIG_MODULE_ADDRESS else '0';

	fx2IO : process(ConfigParamAddress_DI, ConfigParamInput_DI, FX2Input_DP, FX2ConfigReg_DP)
	begin
		FX2ConfigReg_DN <= FX2ConfigReg_DP;
		FX2Input_DN     <= ConfigParamInput_DI;
		FX2Output_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when FX2CONFIG_PARAM_ADDRESSES.Run_S =>
				FX2ConfigReg_DN.Run_S <= FX2Input_DP(0);
				FX2Output_DN(0)       <= FX2ConfigReg_DP.Run_S;

			when FX2CONFIG_PARAM_ADDRESSES.EarlyPacketDelay_D =>
				FX2ConfigReg_DN.EarlyPacketDelay_D                              <= unsigned(FX2Input_DP(tFX2Config.EarlyPacketDelay_D'length - 1 downto 0));
				FX2Output_DN(tFX2Config.EarlyPacketDelay_D'length - 1 downto 0) <= std_logic_vector(FX2ConfigReg_DP.EarlyPacketDelay_D);

			when others => null;
		end case;
	end process fx2IO;

	fx2Update : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			FX2Input_DP  <= (others => '0');
			FX2Output_DP <= (others => '0');

			FX2ConfigReg_DP <= tFX2ConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			FX2Input_DP  <= FX2Input_DN;
			FX2Output_DP <= FX2Output_DN;

			if LatchFX2Reg_S = '1' and ConfigLatchInput_SI = '1' then
				FX2ConfigReg_DP <= FX2ConfigReg_DN;
			end if;
		end if;
	end process fx2Update;
end architecture Behavioral;
