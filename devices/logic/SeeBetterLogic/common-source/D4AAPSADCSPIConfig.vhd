library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.D4AAPSADCConfigRecords.all;
use work.Settings.CHIP_HAS_GLOBAL_SHUTTER;
use work.Settings.CHIP_HAS_INTEGRATED_ADC;

entity D4AAPSADCSPIConfig is
	generic(
		ENABLE_QUAD_ROI : boolean := false);
	port(
		Clock_CI                      : in  std_logic;
		Reset_RI                      : in  std_logic;
		D4AAPSADCConfig_DO            : out tD4AAPSADCConfig;

		-- SPI configuration inputs and outputs.
		ConfigModuleAddress_DI        : in  unsigned(6 downto 0);
		ConfigParamAddress_DI         : in  unsigned(7 downto 0);
		ConfigParamInput_DI           : in  std_logic_vector(31 downto 0);
		ConfigLatchInput_SI           : in  std_logic;
		D4AAPSADCConfigParamOutput_DO : out std_logic_vector(31 downto 0));
end entity D4AAPSADCSPIConfig;

architecture Behavioral of D4AAPSADCSPIConfig is
	signal LatchD4AAPSADCReg_S                          : std_logic;
	signal D4AAPSADCInput_DP, D4AAPSADCInput_DN         : std_logic_vector(31 downto 0);
	signal D4AAPSADCOutput_DP, D4AAPSADCOutput_DN       : std_logic_vector(31 downto 0);
	signal D4AAPSADCConfigReg_DP, D4AAPSADCConfigReg_DN : tD4AAPSADCConfig;
begin
	D4AAPSADCConfig_DO            <= D4AAPSADCConfigReg_DP;
	D4AAPSADCConfigParamOutput_DO <= D4AAPSADCOutput_DP;

	LatchD4AAPSADCReg_S <= '1' when ConfigModuleAddress_DI = D4AAPSADCCONFIG_MODULE_ADDRESS else '0';

	apsadcIO : process(ConfigParamAddress_DI, ConfigParamInput_DI, D4AAPSADCInput_DP, D4AAPSADCConfigReg_DP)
	begin
		D4AAPSADCConfigReg_DN <= D4AAPSADCConfigReg_DP;
		D4AAPSADCInput_DN     <= ConfigParamInput_DI;
		D4AAPSADCOutput_DN    <= (others => '0');

		case ConfigParamAddress_DI is
			when D4AAPSADCCONFIG_PARAM_ADDRESSES.Run_S =>
				D4AAPSADCConfigReg_DN.Run_S <= D4AAPSADCInput_DP(0);
				D4AAPSADCOutput_DN(0)       <= D4AAPSADCConfigReg_DP.Run_S;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.GlobalShutter_S =>
				-- Allow read/write of parameter only on chips which support it.
				if CHIP_HAS_GLOBAL_SHUTTER = '1' then
					D4AAPSADCConfigReg_DN.GlobalShutter_S <= D4AAPSADCInput_DP(0);
					D4AAPSADCOutput_DN(0)                 <= D4AAPSADCConfigReg_DP.GlobalShutter_S;
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.StartColumn0_D =>
				D4AAPSADCConfigReg_DN.StartColumn0_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.StartColumn0_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.StartColumn0_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.StartColumn0_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.StartRow0_D =>
				D4AAPSADCConfigReg_DN.StartRow0_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.StartRow0_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.StartRow0_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.StartRow0_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.EndColumn0_D =>
				D4AAPSADCConfigReg_DN.EndColumn0_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.EndColumn0_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.EndColumn0_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.EndColumn0_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.EndRow0_D =>
				D4AAPSADCConfigReg_DN.EndRow0_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.EndRow0_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.EndRow0_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.EndRow0_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.Exposure_D =>
				D4AAPSADCConfigReg_DN.Exposure_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.Exposure_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.Exposure_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.Exposure_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.FrameDelay_D =>
				D4AAPSADCConfigReg_DN.FrameDelay_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.FrameDelay_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.FrameDelay_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.FrameDelay_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.RowSettle_D =>
				D4AAPSADCConfigReg_DN.RowSettle_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.RowSettle_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.RowSettle_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.RowSettle_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.ResetRead_S =>
				D4AAPSADCConfigReg_DN.ResetRead_S <= D4AAPSADCInput_DP(0);
				D4AAPSADCOutput_DN(0)             <= D4AAPSADCConfigReg_DP.ResetRead_S;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.WaitOnTransferStall_S =>
				D4AAPSADCConfigReg_DN.WaitOnTransferStall_S <= D4AAPSADCInput_DP(0);
				D4AAPSADCOutput_DN(0)                       <= D4AAPSADCConfigReg_DP.WaitOnTransferStall_S;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.StartColumn1_D =>
				if ENABLE_QUAD_ROI = true then
					D4AAPSADCConfigReg_DN.StartColumn1_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.StartColumn1_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.StartColumn1_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.StartColumn1_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.StartRow1_D =>
				if ENABLE_QUAD_ROI = true then
					D4AAPSADCConfigReg_DN.StartRow1_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.StartRow1_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.StartRow1_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.StartRow1_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.EndColumn1_D =>
				if ENABLE_QUAD_ROI = true then
					D4AAPSADCConfigReg_DN.EndColumn1_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.EndColumn1_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.EndColumn1_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.EndColumn1_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.EndRow1_D =>
				if ENABLE_QUAD_ROI = true then
					D4AAPSADCConfigReg_DN.EndRow1_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.EndRow1_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.EndRow1_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.EndRow1_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.StartColumn2_D =>
				if ENABLE_QUAD_ROI = true then
					D4AAPSADCConfigReg_DN.StartColumn2_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.StartColumn2_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.StartColumn2_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.StartColumn2_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.StartRow2_D =>
				if ENABLE_QUAD_ROI = true then
					D4AAPSADCConfigReg_DN.StartRow2_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.StartRow2_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.StartRow2_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.StartRow2_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.EndColumn2_D =>
				if ENABLE_QUAD_ROI = true then
					D4AAPSADCConfigReg_DN.EndColumn2_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.EndColumn2_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.EndColumn2_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.EndColumn2_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.EndRow2_D =>
				if ENABLE_QUAD_ROI = true then
					D4AAPSADCConfigReg_DN.EndRow2_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.EndRow2_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.EndRow2_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.EndRow2_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.StartColumn3_D =>
				if ENABLE_QUAD_ROI = true then
					D4AAPSADCConfigReg_DN.StartColumn3_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.StartColumn3_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.StartColumn3_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.StartColumn3_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.StartRow3_D =>
				if ENABLE_QUAD_ROI = true then
					D4AAPSADCConfigReg_DN.StartRow3_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.StartRow3_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.StartRow3_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.StartRow3_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.EndColumn3_D =>
				if ENABLE_QUAD_ROI = true then
					D4AAPSADCConfigReg_DN.EndColumn3_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.EndColumn3_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.EndColumn3_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.EndColumn3_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.EndRow3_D =>
				if ENABLE_QUAD_ROI = true then
					D4AAPSADCConfigReg_DN.EndRow3_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.EndRow3_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.EndRow3_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.EndRow3_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.UseInternalADC_S =>
				-- Allow read/write of parameter only on chips which support it.
				if CHIP_HAS_INTEGRATED_ADC = '1' then
					D4AAPSADCConfigReg_DN.UseInternalADC_S <= D4AAPSADCInput_DP(0);
					D4AAPSADCOutput_DN(0)                  <= D4AAPSADCConfigReg_DP.UseInternalADC_S;
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.SampleEnable_S =>
				-- Allow read/write of parameter only on chips which support it.
				if CHIP_HAS_INTEGRATED_ADC = '1' then
					D4AAPSADCConfigReg_DN.SampleEnable_S <= D4AAPSADCInput_DP(0);
					D4AAPSADCOutput_DN(0)                <= D4AAPSADCConfigReg_DP.SampleEnable_S;
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.SampleSettle_D =>
				-- Allow read/write of parameter only on chips which support it.
				if CHIP_HAS_INTEGRATED_ADC = '1' then
					D4AAPSADCConfigReg_DN.SampleSettle_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.SampleSettle_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.SampleSettle_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.SampleSettle_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.RampReset_D =>
				-- Allow read/write of parameter only on chips which support it.
				if CHIP_HAS_INTEGRATED_ADC = '1' then
					D4AAPSADCConfigReg_DN.RampReset_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.RampReset_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.RampReset_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.RampReset_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.Transfer_D =>
				D4AAPSADCConfigReg_DN.Transfer_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.Transfer_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.Transfer_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.Transfer_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.RSFDSettle_D =>
				D4AAPSADCConfigReg_DN.RSFDSettle_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.RSFDSettle_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.RSFDSettle_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.RSFDSettle_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.RSCpReset_D =>
				D4AAPSADCConfigReg_DN.RSCpReset_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.RSCpReset_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.RSCpReset_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.RSCpReset_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.RSCpSettle_D =>
				D4AAPSADCConfigReg_DN.RSCpSettle_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.RSCpSettle_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.RSCpSettle_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.RSCpSettle_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.GSPDReset_D =>
				D4AAPSADCConfigReg_DN.GSPDReset_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.GSPDReset_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.GSPDReset_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.GSPDReset_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.GSResetFall_D =>
				D4AAPSADCConfigReg_DN.GSResetFall_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.GSResetFall_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.GSResetFall_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.GSResetFall_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.GSTXFall_D =>
				D4AAPSADCConfigReg_DN.GSTXFall_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.GSTXFall_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.GSTXFall_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.GSTXFall_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.GSFDReset_D =>
				D4AAPSADCConfigReg_DN.GSFDReset_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.GSFDReset_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.GSFDReset_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.GSFDReset_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.GSCpResetFD_D =>
				D4AAPSADCConfigReg_DN.GSCpResetFD_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.GSCpResetFD_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.GSCpResetFD_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.GSCpResetFD_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.GSCpResetSettle_D =>
				D4AAPSADCConfigReg_DN.GSCpResetSettle_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.GSCpResetSettle_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.GSCpResetSettle_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.GSCpResetSettle_D);

			when others => null;
		end case;
	end process apsadcIO;

	apsadcUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			D4AAPSADCInput_DP  <= (others => '0');
			D4AAPSADCOutput_DP <= (others => '0');

			D4AAPSADCConfigReg_DP <= tD4AAPSADCConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			D4AAPSADCInput_DP  <= D4AAPSADCInput_DN;
			D4AAPSADCOutput_DP <= D4AAPSADCOutput_DN;

			if LatchD4AAPSADCReg_S = '1' and ConfigLatchInput_SI = '1' then
				D4AAPSADCConfigReg_DP <= D4AAPSADCConfigReg_DN;
			end if;
		end if;
	end process apsadcUpdate;
end architecture Behavioral;
