library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.APSADCConfigRecords.all;
use work.Settings.CHIP_HAS_GLOBAL_SHUTTER;

entity APSADCSPIConfig is
	generic(
		ENABLE_QUAD_ROI : boolean := false);
	port(
		Clock_CI                   : in  std_logic;
		Reset_RI                   : in  std_logic;
		APSADCConfig_DO            : out tAPSADCConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI     : in  unsigned(6 downto 0);
		ConfigParamAddress_DI      : in  unsigned(7 downto 0);
		ConfigParamInput_DI        : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI        : in  std_logic;
		APSADCConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity APSADCSPIConfig;

architecture Behavioral of APSADCSPIConfig is
	signal LatchAPSADCReg_S                       : std_logic;
	signal APSADCInput_DP, APSADCInput_DN         : std_logic_vector(31 downto 0);
	signal APSADCOutput_DP, APSADCOutput_DN       : std_logic_vector(31 downto 0);
	signal APSADCConfigReg_DP, APSADCConfigReg_DN : tAPSADCConfig;
begin
	APSADCConfig_DO            <= APSADCConfigReg_DP;
	APSADCConfigParamOutput_DO <= APSADCOutput_DP;

	LatchAPSADCReg_S <= '1' when ConfigModuleAddress_DI = APSADCCONFIG_MODULE_ADDRESS else '0';

	apsadcIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, APSADCInput_DP, APSADCConfigReg_DP)
	begin
		APSADCConfigReg_DN <= APSADCConfigReg_DP;
		APSADCInput_DN     <= ConfigParamInput_DI;
		APSADCOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when APSADCCONFIG_PARAM_ADDRESSES.Run_S =>
				APSADCConfigReg_DN.Run_S <= APSADCInput_DP(0);
				APSADCOutput_DN(0)       <= APSADCConfigReg_DP.Run_S;

			when APSADCCONFIG_PARAM_ADDRESSES.ForceADCRunning_S =>
				APSADCConfigReg_DN.ForceADCRunning_S <= APSADCInput_DP(0);
				APSADCOutput_DN(0)                   <= APSADCConfigReg_DP.ForceADCRunning_S;

			when APSADCCONFIG_PARAM_ADDRESSES.GlobalShutter_S =>
				-- Allow changing global shutter parameter only on chips which support it.
				if CHIP_HAS_GLOBAL_SHUTTER = '1' then
					APSADCConfigReg_DN.GlobalShutter_S <= APSADCInput_DP(0);
				end if;
				APSADCOutput_DN(0) <= APSADCConfigReg_DP.GlobalShutter_S;

			when APSADCCONFIG_PARAM_ADDRESSES.StartColumn0_D =>
				APSADCConfigReg_DN.StartColumn0_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.StartColumn0_D'range));
				APSADCOutput_DN(tAPSADCConfig.StartColumn0_D'range) <= std_logic_vector(APSADCConfigReg_DP.StartColumn0_D);

			when APSADCCONFIG_PARAM_ADDRESSES.StartRow0_D =>
				APSADCConfigReg_DN.StartRow0_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.StartRow0_D'range));
				APSADCOutput_DN(tAPSADCConfig.StartRow0_D'range) <= std_logic_vector(APSADCConfigReg_DP.StartRow0_D);

			when APSADCCONFIG_PARAM_ADDRESSES.EndColumn0_D =>
				APSADCConfigReg_DN.EndColumn0_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.EndColumn0_D'range));
				APSADCOutput_DN(tAPSADCConfig.EndColumn0_D'range) <= std_logic_vector(APSADCConfigReg_DP.EndColumn0_D);

			when APSADCCONFIG_PARAM_ADDRESSES.EndRow0_D =>
				APSADCConfigReg_DN.EndRow0_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.EndRow0_D'range));
				APSADCOutput_DN(tAPSADCConfig.EndRow0_D'range) <= std_logic_vector(APSADCConfigReg_DP.EndRow0_D);

			when APSADCCONFIG_PARAM_ADDRESSES.Exposure_D =>
				APSADCConfigReg_DN.Exposure_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.Exposure_D'range));
				APSADCOutput_DN(tAPSADCConfig.Exposure_D'range) <= std_logic_vector(APSADCConfigReg_DP.Exposure_D);

			when APSADCCONFIG_PARAM_ADDRESSES.FrameDelay_D =>
				APSADCConfigReg_DN.FrameDelay_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.FrameDelay_D'range));
				APSADCOutput_DN(tAPSADCConfig.FrameDelay_D'range) <= std_logic_vector(APSADCConfigReg_DP.FrameDelay_D);

			when APSADCCONFIG_PARAM_ADDRESSES.ResetSettle_D =>
				APSADCConfigReg_DN.ResetSettle_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.ResetSettle_D'range));
				APSADCOutput_DN(tAPSADCConfig.ResetSettle_D'range) <= std_logic_vector(APSADCConfigReg_DP.ResetSettle_D);

			when APSADCCONFIG_PARAM_ADDRESSES.ColumnSettle_D =>
				APSADCConfigReg_DN.ColumnSettle_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.ColumnSettle_D'range));
				APSADCOutput_DN(tAPSADCConfig.ColumnSettle_D'range) <= std_logic_vector(APSADCConfigReg_DP.ColumnSettle_D);

			when APSADCCONFIG_PARAM_ADDRESSES.RowSettle_D =>
				APSADCConfigReg_DN.RowSettle_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.RowSettle_D'range));
				APSADCOutput_DN(tAPSADCConfig.RowSettle_D'range) <= std_logic_vector(APSADCConfigReg_DP.RowSettle_D);

			when APSADCCONFIG_PARAM_ADDRESSES.GSTXGateOpenReset_S =>
				APSADCConfigReg_DN.GSTXGateOpenReset_S <= APSADCInput_DP(0);
				APSADCOutput_DN(0)                     <= APSADCConfigReg_DP.GSTXGateOpenReset_S;

			when APSADCCONFIG_PARAM_ADDRESSES.ResetRead_S =>
				APSADCConfigReg_DN.ResetRead_S <= APSADCInput_DP(0);
				APSADCOutput_DN(0)             <= APSADCConfigReg_DP.ResetRead_S;

			when APSADCCONFIG_PARAM_ADDRESSES.WaitOnTransferStall_S =>
				APSADCConfigReg_DN.WaitOnTransferStall_S <= APSADCInput_DP(0);
				APSADCOutput_DN(0)                       <= APSADCConfigReg_DP.WaitOnTransferStall_S;

			when APSADCCONFIG_PARAM_ADDRESSES.StartColumn1_D =>
				if ENABLE_QUAD_ROI = true then
					APSADCConfigReg_DN.StartColumn1_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.StartColumn1_D'range));
					APSADCOutput_DN(tAPSADCConfig.StartColumn1_D'range) <= std_logic_vector(APSADCConfigReg_DP.StartColumn1_D);
				end if;

			when APSADCCONFIG_PARAM_ADDRESSES.StartRow1_D =>
				if ENABLE_QUAD_ROI = true then
					APSADCConfigReg_DN.StartRow1_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.StartRow1_D'range));
					APSADCOutput_DN(tAPSADCConfig.StartRow1_D'range) <= std_logic_vector(APSADCConfigReg_DP.StartRow1_D);
				end if;

			when APSADCCONFIG_PARAM_ADDRESSES.EndColumn1_D =>
				if ENABLE_QUAD_ROI = true then
					APSADCConfigReg_DN.EndColumn1_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.EndColumn1_D'range));
					APSADCOutput_DN(tAPSADCConfig.EndColumn1_D'range) <= std_logic_vector(APSADCConfigReg_DP.EndColumn1_D);
				end if;

			when APSADCCONFIG_PARAM_ADDRESSES.EndRow1_D =>
				if ENABLE_QUAD_ROI = true then
					APSADCConfigReg_DN.EndRow1_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.EndRow1_D'range));
					APSADCOutput_DN(tAPSADCConfig.EndRow1_D'range) <= std_logic_vector(APSADCConfigReg_DP.EndRow1_D);
				end if;

			when APSADCCONFIG_PARAM_ADDRESSES.StartColumn2_D =>
				if ENABLE_QUAD_ROI = true then
					APSADCConfigReg_DN.StartColumn2_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.StartColumn2_D'range));
					APSADCOutput_DN(tAPSADCConfig.StartColumn2_D'range) <= std_logic_vector(APSADCConfigReg_DP.StartColumn2_D);
				end if;

			when APSADCCONFIG_PARAM_ADDRESSES.StartRow2_D =>
				if ENABLE_QUAD_ROI = true then
					APSADCConfigReg_DN.StartRow2_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.StartRow2_D'range));
					APSADCOutput_DN(tAPSADCConfig.StartRow2_D'range) <= std_logic_vector(APSADCConfigReg_DP.StartRow2_D);
				end if;

			when APSADCCONFIG_PARAM_ADDRESSES.EndColumn2_D =>
				if ENABLE_QUAD_ROI = true then
					APSADCConfigReg_DN.EndColumn2_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.EndColumn2_D'range));
					APSADCOutput_DN(tAPSADCConfig.EndColumn2_D'range) <= std_logic_vector(APSADCConfigReg_DP.EndColumn2_D);
				end if;

			when APSADCCONFIG_PARAM_ADDRESSES.EndRow2_D =>
				if ENABLE_QUAD_ROI = true then
					APSADCConfigReg_DN.EndRow2_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.EndRow2_D'range));
					APSADCOutput_DN(tAPSADCConfig.EndRow2_D'range) <= std_logic_vector(APSADCConfigReg_DP.EndRow2_D);
				end if;

			when APSADCCONFIG_PARAM_ADDRESSES.StartColumn3_D =>
				if ENABLE_QUAD_ROI = true then
					APSADCConfigReg_DN.StartColumn3_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.StartColumn3_D'range));
					APSADCOutput_DN(tAPSADCConfig.StartColumn3_D'range) <= std_logic_vector(APSADCConfigReg_DP.StartColumn3_D);
				end if;

			when APSADCCONFIG_PARAM_ADDRESSES.StartRow3_D =>
				if ENABLE_QUAD_ROI = true then
					APSADCConfigReg_DN.StartRow3_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.StartRow3_D'range));
					APSADCOutput_DN(tAPSADCConfig.StartRow3_D'range) <= std_logic_vector(APSADCConfigReg_DP.StartRow3_D);
				end if;

			when APSADCCONFIG_PARAM_ADDRESSES.EndColumn3_D =>
				if ENABLE_QUAD_ROI = true then
					APSADCConfigReg_DN.EndColumn3_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.EndColumn3_D'range));
					APSADCOutput_DN(tAPSADCConfig.EndColumn3_D'range) <= std_logic_vector(APSADCConfigReg_DP.EndColumn3_D);
				end if;

			when APSADCCONFIG_PARAM_ADDRESSES.EndRow3_D =>
				if ENABLE_QUAD_ROI = true then
					APSADCConfigReg_DN.EndRow3_D                   <= unsigned(APSADCInput_DP(tAPSADCConfig.EndRow3_D'range));
					APSADCOutput_DN(tAPSADCConfig.EndRow3_D'range) <= std_logic_vector(APSADCConfigReg_DP.EndRow3_D);
				end if;

			when others => null;
		end case;
	end process apsadcIO;

	apsadcUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			APSADCInput_DP  <= (others => '0');
			APSADCOutput_DP <= (others => '0');

			APSADCConfigReg_DP <= tAPSADCConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			APSADCInput_DP  <= APSADCInput_DN;
			APSADCOutput_DP <= APSADCOutput_DN;

			if LatchAPSADCReg_S = '1' and ConfigLatchInput_SI = '1' then
				APSADCConfigReg_DP <= APSADCConfigReg_DN;
			end if;
		end if;
	end process apsadcUpdate;
end architecture Behavioral;
