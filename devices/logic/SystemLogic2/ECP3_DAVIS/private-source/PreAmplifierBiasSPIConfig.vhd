--------------------------------------------------------------------------------
-- Company: INI, iniLabs
-- Engineer: Diederik Paul Moeys, Luca Longinotti
--
-- Create Date:  23.04.2015
-- Design Name:  DAVIS208
-- Module Name:  PreAmplifierBiasSPIConfig
-- Project Name: VISUALISE
-- Description:	 SPIConfig of PreAmplifierBias State Machine
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Libraries -------------------------------------------------------------------
-------------------------------------------------------------------------------- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.PreAmplifierBiasConfigRecords.all;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Entity Declaration ----------------------------------------------------------
--------------------------------------------------------------------------------
entity PreAmplifierBiasSPIConfig is
	port(
		-- Clock and reset inputs
		Clock_CI                             : in  std_logic;
		Reset_RI                             : in  std_logic;

		-- Output containing parameters
		PreAmplifierBiasConfig_DO            : out tPreAmplifierBiasConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI               : in  unsigned(6 downto 0);
		ConfigParamAddress_DI                : in  unsigned(7 downto 0);
		ConfigParamInput_DI                  : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI                  : in  std_logic;
		PreAmplifierBiasConfigParamOutput_DO : out std_logic_vector(31 downto 0)); -- Check parameters
end PreAmplifierBiasSPIConfig;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------  

--------------------------------------------------------------------------------
-- Architecture Declaration ----------------------------------------------------
--------------------------------------------------------------------------------
architecture Behavioral of PreAmplifierBiasSPIConfig is
	signal LatchPreAmplifierBiasReg_S                                 : std_logic;
	signal PreAmplifierBiasInput_DP, PreAmplifierBiasInput_DN         : std_logic_vector(31 downto 0);
	signal PreAmplifierBiasOutput_DP, PreAmplifierBiasOutput_DN       : std_logic_vector(31 downto 0);
	signal PreAmplifierBiasConfigReg_DP, PreAmplifierBiasConfigReg_DN : tPreAmplifierBiasConfig;
begin
	PreAmplifierBiasConfig_DO            <= PreAmplifierBiasConfigReg_DP;
	PreAmplifierBiasConfigParamOutput_DO <= PreAmplifierBiasOutput_DP;

	LatchPreAmplifierBiasReg_S <= '1' when ConfigModuleAddress_DI = PREAMPLIFIERBIASCONFIG_MODULE_ADDRESS else '0';

	-------------------------------------------------------------------------------- 
	-- Combinational process
	PreAmplifierBiasIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, PreAmplifierBiasInput_DP, PreAmplifierBiasConfigReg_DP)
	begin
		PreAmplifierBiasConfigReg_DN <= PreAmplifierBiasConfigReg_DP;
		PreAmplifierBiasInput_DN     <= ConfigParamInput_DI;
		PreAmplifierBiasOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when PREAMPLIFIERBIASCONFIG_PARAM_ADDRESSES.Run_S =>
				PreAmplifierBiasConfigReg_DN.Run_S <= PreAmplifierBiasInput_DP(0);
				PreAmplifierBiasOutput_DN(0)       <= PreAmplifierBiasConfigReg_DP.Run_S;

			when PREAMPLIFIERBIASCONFIG_PARAM_ADDRESSES.HighThreshold_S =>
				PreAmplifierBiasConfigReg_DN.HighThreshold_S                             <= unsigned(PreAmplifierBiasInput_DP(tPreAmplifierBiasConfig.HighThreshold_S'range));
				PreAmplifierBiasOutput_DN(tPreAmplifierBiasConfig.HighThreshold_S'range) <= std_logic_vector(PreAmplifierBiasConfigReg_DP.HighThreshold_S);

			when PREAMPLIFIERBIASCONFIG_PARAM_ADDRESSES.LowThreshold_S =>
				PreAmplifierBiasConfigReg_DN.LowThreshold_S                             <= unsigned(PreAmplifierBiasInput_DP(tPreAmplifierBiasConfig.LowThreshold_S'range));
				PreAmplifierBiasOutput_DN(tPreAmplifierBiasConfig.LowThreshold_S'range) <= std_logic_vector(PreAmplifierBiasConfigReg_DP.LowThreshold_S);

			when PREAMPLIFIERBIASCONFIG_PARAM_ADDRESSES.ADCSamplingTime_S =>
				PreAmplifierBiasConfigReg_DN.ADCSamplingTime_S                             <= unsigned(PreAmplifierBiasInput_DP(tPreAmplifierBiasConfig.ADCSamplingTime_S'range));
				PreAmplifierBiasOutput_DN(tPreAmplifierBiasConfig.ADCSamplingTime_S'range) <= std_logic_vector(PreAmplifierBiasConfigReg_DP.ADCSamplingTime_S);

			when others => null;
		end case;
	end process PreAmplifierBiasIO;

	--------------------------------------------------------------------------------
	-- Sequential process
	PreAmplifierBiasUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			PreAmplifierBiasInput_DP  <= (others => '0');
			PreAmplifierBiasOutput_DP <= (others => '0');

			PreAmplifierBiasConfigReg_DP <= tPreAmplifierBiasConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			PreAmplifierBiasInput_DP  <= PreAmplifierBiasInput_DN;
			PreAmplifierBiasOutput_DP <= PreAmplifierBiasOutput_DN;

			if LatchPreAmplifierBiasReg_S = '1' and ConfigLatchInput_SI = '1' then
				PreAmplifierBiasConfigReg_DP <= PreAmplifierBiasConfigReg_DN;
			end if;
		end if;
	end process PreAmplifierBiasUpdate;
--------------------------------------------------------------------------------
end Behavioral;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------