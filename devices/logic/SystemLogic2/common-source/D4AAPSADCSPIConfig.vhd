library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.D4AAPSADCConfigRecords.all;
use work.Settings.CHIP_APS_SIZE_COLUMNS;
use work.Settings.CHIP_APS_SIZE_ROWS;
use work.Settings.CHIP_APS_STREAM_START;
use work.Settings.CHIP_APS_AXES_INVERT;
use work.Settings.CHIP_APS_HAS_GLOBAL_SHUTTER;
use work.Settings.CHIP_APS_HAS_INTEGRATED_ADC;
use work.Settings.BOARD_APS_HAS_EXTERNAL_ADC;

entity D4AAPSADCSPIConfig is
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
			when D4AAPSADCCONFIG_PARAM_ADDRESSES.SizeColumns_D =>
				D4AAPSADCConfigReg_DN.SizeColumns_D                      <= CHIP_APS_SIZE_ROWS; -- Invert Col/Row for DAVIS RGB.
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.SizeColumns_D'range) <= std_logic_vector(CHIP_APS_SIZE_ROWS); -- The SM is row-based, but decoding expects column-based sizes.

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.SizeRows_D =>
				D4AAPSADCConfigReg_DN.SizeRows_D                      <= CHIP_APS_SIZE_COLUMNS; -- Invert Col/Row for DAVIS RGB.
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.SizeRows_D'range) <= std_logic_vector(CHIP_APS_SIZE_COLUMNS); -- The SM is row-based, but decoding expects column-based sizes.

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.OrientationInfo_D =>
				D4AAPSADCConfigReg_DN.OrientationInfo_D                      <= CHIP_APS_AXES_INVERT & CHIP_APS_STREAM_START;
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.OrientationInfo_D'range) <= CHIP_APS_AXES_INVERT & CHIP_APS_STREAM_START;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.ColorFilter_D =>
				D4AAPSADCConfigReg_DN.ColorFilter_D                      <= D4AAPSADCInput_DP(tD4AAPSADCConfig.ColorFilter_D'range);
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.ColorFilter_D'range) <= D4AAPSADCConfigReg_DP.ColorFilter_D;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.Run_S =>
				D4AAPSADCConfigReg_DN.Run_S <= D4AAPSADCInput_DP(0);
				D4AAPSADCOutput_DN(0)       <= D4AAPSADCConfigReg_DP.Run_S;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.ResetRead_S =>
				D4AAPSADCConfigReg_DN.ResetRead_S <= D4AAPSADCInput_DP(0);
				D4AAPSADCOutput_DN(0)             <= D4AAPSADCConfigReg_DP.ResetRead_S;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.WaitOnTransferStall_S =>
				D4AAPSADCConfigReg_DN.WaitOnTransferStall_S <= D4AAPSADCInput_DP(0);
				D4AAPSADCOutput_DN(0)                       <= D4AAPSADCConfigReg_DP.WaitOnTransferStall_S;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.HasGlobalShutter_S =>
				D4AAPSADCConfigReg_DN.HasGlobalShutter_S <= CHIP_APS_HAS_GLOBAL_SHUTTER;
				D4AAPSADCOutput_DN(0)                    <= CHIP_APS_HAS_GLOBAL_SHUTTER;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.GlobalShutter_S =>
				-- Allow read/write of parameter only on chips which support it.
				if CHIP_APS_HAS_GLOBAL_SHUTTER = '1' then
					D4AAPSADCConfigReg_DN.GlobalShutter_S <= D4AAPSADCInput_DP(0);
					D4AAPSADCOutput_DN(0)                 <= D4AAPSADCConfigReg_DP.GlobalShutter_S;
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.Exposure_D =>
				D4AAPSADCConfigReg_DN.Exposure_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.Exposure_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.Exposure_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.Exposure_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.FrameDelay_D =>
				D4AAPSADCConfigReg_DN.FrameDelay_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.FrameDelay_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.FrameDelay_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.FrameDelay_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.RowSettle_D =>
				D4AAPSADCConfigReg_DN.RowSettle_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.RowSettle_D'range));
				D4AAPSADCOutput_DN(tD4AAPSADCConfig.RowSettle_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.RowSettle_D);

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.HasExternalADC_S =>
				D4AAPSADCConfigReg_DN.HasExternalADC_S <= D4AAPSADCInput_DP(0);
				D4AAPSADCOutput_DN(0)                  <= D4AAPSADCConfigReg_DP.HasExternalADC_S;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.HasInternalADC_S =>
				D4AAPSADCConfigReg_DN.HasInternalADC_S <= CHIP_APS_HAS_INTEGRATED_ADC;
				D4AAPSADCOutput_DN(0)                  <= CHIP_APS_HAS_INTEGRATED_ADC;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.UseInternalADC_S =>
				-- Allow read/write of parameter only on chips which support it.
				if CHIP_APS_HAS_INTEGRATED_ADC = '1' then
					D4AAPSADCConfigReg_DN.UseInternalADC_S <= D4AAPSADCInput_DP(0);
					D4AAPSADCOutput_DN(0)                  <= D4AAPSADCConfigReg_DP.UseInternalADC_S;
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.SampleEnable_S =>
				-- Allow read/write of parameter only on chips which support it.
				if CHIP_APS_HAS_INTEGRATED_ADC = '1' then
					D4AAPSADCConfigReg_DN.SampleEnable_S <= D4AAPSADCInput_DP(0);
					D4AAPSADCOutput_DN(0)                <= D4AAPSADCConfigReg_DP.SampleEnable_S;
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.SampleSettle_D =>
				-- Allow read/write of parameter only on chips which support it.
				if CHIP_APS_HAS_INTEGRATED_ADC = '1' then
					D4AAPSADCConfigReg_DN.SampleSettle_D                      <= unsigned(D4AAPSADCInput_DP(tD4AAPSADCConfig.SampleSettle_D'range));
					D4AAPSADCOutput_DN(tD4AAPSADCConfig.SampleSettle_D'range) <= std_logic_vector(D4AAPSADCConfigReg_DP.SampleSettle_D);
				end if;

			when D4AAPSADCCONFIG_PARAM_ADDRESSES.RampReset_D =>
				-- Allow read/write of parameter only on chips which support it.
				if CHIP_APS_HAS_INTEGRATED_ADC = '1' then
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
