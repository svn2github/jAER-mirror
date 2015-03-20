library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.CHIP_APS_SIZE_COLUMNS;
use work.Settings.CHIP_APS_SIZE_ROWS;
use work.Settings.CHIP_HAS_GLOBAL_SHUTTER;
use work.Settings.CHIP_HAS_INTEGRATED_ADC;
use work.Settings.ADC_CLOCK_FREQ;

package D4AAPSADCConfigRecords is
	constant D4AAPSADCCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(2, 7);

	type tD4AAPSADCConfigParamAddresses is record
		Run_S                 : unsigned(7 downto 0);
		GlobalShutter_S       : unsigned(7 downto 0);
		StartColumn0_D        : unsigned(7 downto 0);
		StartRow0_D           : unsigned(7 downto 0);
		EndColumn0_D          : unsigned(7 downto 0);
		EndRow0_D             : unsigned(7 downto 0);
		Exposure_D            : unsigned(7 downto 0);
		FrameDelay_D          : unsigned(7 downto 0);
		RowSettle_D           : unsigned(7 downto 0);
		ResetRead_S           : unsigned(7 downto 0);
		WaitOnTransferStall_S : unsigned(7 downto 0);
		StartColumn1_D        : unsigned(7 downto 0);
		StartRow1_D           : unsigned(7 downto 0);
		EndColumn1_D          : unsigned(7 downto 0);
		EndRow1_D             : unsigned(7 downto 0);
		StartColumn2_D        : unsigned(7 downto 0);
		StartRow2_D           : unsigned(7 downto 0);
		EndColumn2_D          : unsigned(7 downto 0);
		EndRow2_D             : unsigned(7 downto 0);
		StartColumn3_D        : unsigned(7 downto 0);
		StartRow3_D           : unsigned(7 downto 0);
		EndColumn3_D          : unsigned(7 downto 0);
		EndRow3_D             : unsigned(7 downto 0);
		HasQuadROI_S          : unsigned(7 downto 0);
		UseInternalADC_S      : unsigned(7 downto 0);
		SampleEnable_S        : unsigned(7 downto 0);
		SampleSettle_D        : unsigned(7 downto 0);
		RampReset_D           : unsigned(7 downto 0);
		Transfer_D            : unsigned(7 downto 0);
		RSFDSettle_D          : unsigned(7 downto 0);
		RSCpReset_D           : unsigned(7 downto 0);
		RSCpSettle_D          : unsigned(7 downto 0);
		GSPDReset_D           : unsigned(7 downto 0);
		GSResetFall_D         : unsigned(7 downto 0);
		GSTXFall_D            : unsigned(7 downto 0);
		GSFDReset_D           : unsigned(7 downto 0);
		GSCpResetFD_D         : unsigned(7 downto 0);
		GSCpResetSettle_D     : unsigned(7 downto 0);
	end record tD4AAPSADCConfigParamAddresses;

	constant D4AAPSADCCONFIG_PARAM_ADDRESSES : tD4AAPSADCConfigParamAddresses := (
		Run_S                 => to_unsigned(0, 8),
		GlobalShutter_S       => to_unsigned(2, 8),
		StartColumn0_D        => to_unsigned(3, 8),
		StartRow0_D           => to_unsigned(4, 8),
		EndColumn0_D          => to_unsigned(5, 8),
		EndRow0_D             => to_unsigned(6, 8),
		Exposure_D            => to_unsigned(7, 8),
		FrameDelay_D          => to_unsigned(8, 8),
		RowSettle_D           => to_unsigned(11, 8),
		ResetRead_S           => to_unsigned(13, 8),
		WaitOnTransferStall_S => to_unsigned(14, 8),
		StartColumn1_D        => to_unsigned(15, 8),
		StartRow1_D           => to_unsigned(16, 8),
		EndColumn1_D          => to_unsigned(17, 8),
		EndRow1_D             => to_unsigned(18, 8),
		StartColumn2_D        => to_unsigned(19, 8),
		StartRow2_D           => to_unsigned(20, 8),
		EndColumn2_D          => to_unsigned(21, 8),
		EndRow2_D             => to_unsigned(22, 8),
		StartColumn3_D        => to_unsigned(23, 8),
		StartRow3_D           => to_unsigned(24, 8),
		EndColumn3_D          => to_unsigned(25, 8),
		EndRow3_D             => to_unsigned(26, 8),
		HasQuadROI_S          => to_unsigned(27, 8),
		UseInternalADC_S      => to_unsigned(28, 8),
		SampleEnable_S        => to_unsigned(29, 8),
		SampleSettle_D        => to_unsigned(30, 8),
		RampReset_D           => to_unsigned(31, 8),
		Transfer_D            => to_unsigned(32, 8),
		RSFDSettle_D          => to_unsigned(33, 8),
		RSCpReset_D           => to_unsigned(34, 8),
		RSCpSettle_D          => to_unsigned(35, 8),
		GSPDReset_D           => to_unsigned(36, 8),
		GSResetFall_D         => to_unsigned(37, 8),
		GSTXFall_D            => to_unsigned(38, 8),
		GSFDReset_D           => to_unsigned(39, 8),
		GSCpResetFD_D         => to_unsigned(40, 8),
		GSCpResetSettle_D     => to_unsigned(41, 8));

	constant APS_EXPOSURE_SIZE      : integer := 25; -- Up to about one second.
	constant APS_FRAMEDELAY_SIZE    : integer := 25; -- Up to about one second.
	constant APS_ROWSETTLETIME_SIZE : integer := 6; -- Up to about two microseconds.

	-- On-chip ADC specific timings.
	constant APS_SAMPLESETTLETIME_SIZE : integer := 8; -- Up to about eight microseconds.
	constant APS_RAMPRESETTIME_SIZE    : integer := 8; -- Up to about eight microseconds.

	-- DAVIS RGB specific timings.
	constant APS_TRANSFERTIME_SIZE        : integer := 8; -- Up to about eight microseconds.
	constant APS_RSFDSETTLETIME_SIZE      : integer := 8; -- Up to about eight microseconds.
	constant APS_RSCPRESETTIME_SIZE       : integer := 8; -- Up to about eight microseconds.
	constant APS_RSCPSETTLETIME_SIZE      : integer := 8; -- Up to about eight microseconds.
	constant APS_GSPDRESETTIME_SIZE       : integer := 8; -- Up to about eight microseconds.
	constant APS_GSRESETFALLTIME_SIZE     : integer := 8; -- Up to about eight microseconds.
	constant APS_GSTXFALLTIME_SIZE        : integer := 8; -- Up to about eight microseconds.
	constant APS_GSFDRESETTIME_SIZE       : integer := 8; -- Up to about eight microseconds.
	constant APS_GSCPRESETFDTIME_SIZE     : integer := 8; -- Up to about eight microseconds.
	constant APS_GSCPRESETSETTLETIME_SIZE : integer := 8; -- Up to about eight microseconds.

	type tD4AAPSADCConfig is record
		Run_S                 : std_logic;
		GlobalShutter_S       : std_logic; -- Enable global shutter instead of rolling shutter.
		StartColumn0_D        : unsigned(CHIP_APS_SIZE_COLUMNS'range);
		StartRow0_D           : unsigned(CHIP_APS_SIZE_ROWS'range);
		EndColumn0_D          : unsigned(CHIP_APS_SIZE_COLUMNS'range);
		EndRow0_D             : unsigned(CHIP_APS_SIZE_ROWS'range);
		Exposure_D            : unsigned(APS_EXPOSURE_SIZE - 1 downto 0); -- in cycles at 30MHz
		FrameDelay_D          : unsigned(APS_FRAMEDELAY_SIZE - 1 downto 0); -- in cycles at 30MHz
		RowSettle_D           : unsigned(APS_ROWSETTLETIME_SIZE - 1 downto 0); -- in cycles at 30MHz
		ResetRead_S           : std_logic; -- Wether to do the reset read or not.
		WaitOnTransferStall_S : std_logic; -- Wether to wait when the FIFO is full or not.
		StartColumn1_D        : unsigned(CHIP_APS_SIZE_COLUMNS'range);
		StartRow1_D           : unsigned(CHIP_APS_SIZE_ROWS'range);
		EndColumn1_D          : unsigned(CHIP_APS_SIZE_COLUMNS'range);
		EndRow1_D             : unsigned(CHIP_APS_SIZE_ROWS'range);
		StartColumn2_D        : unsigned(CHIP_APS_SIZE_COLUMNS'range);
		StartRow2_D           : unsigned(CHIP_APS_SIZE_ROWS'range);
		EndColumn2_D          : unsigned(CHIP_APS_SIZE_COLUMNS'range);
		EndRow2_D             : unsigned(CHIP_APS_SIZE_ROWS'range);
		StartColumn3_D        : unsigned(CHIP_APS_SIZE_COLUMNS'range);
		StartRow3_D           : unsigned(CHIP_APS_SIZE_ROWS'range);
		EndColumn3_D          : unsigned(CHIP_APS_SIZE_COLUMNS'range);
		EndRow3_D             : unsigned(CHIP_APS_SIZE_ROWS'range);
		HasQuadROI_S          : std_logic;
		UseInternalADC_S      : std_logic;
		SampleEnable_S        : std_logic;
		SampleSettle_D        : unsigned(APS_SAMPLESETTLETIME_SIZE - 1 downto 0); -- in cycles at 30MHz
		RampReset_D           : unsigned(APS_RAMPRESETTIME_SIZE - 1 downto 0); -- in cycles at 30MHz
		Transfer_D            : unsigned(APS_TRANSFERTIME_SIZE - 1 downto 0); -- in cycles at 30MHz
		RSFDSettle_D          : unsigned(APS_RSFDSETTLETIME_SIZE - 1 downto 0); -- in cycles at 30MHz
		RSCpReset_D           : unsigned(APS_RSCPRESETTIME_SIZE - 1 downto 0); -- in cycles at 30MHz
		RSCpSettle_D          : unsigned(APS_RSCPSETTLETIME_SIZE - 1 downto 0); -- in cycles at 30MHz
		GSPDReset_D           : unsigned(APS_GSPDRESETTIME_SIZE - 1 downto 0); -- in cycles at 30MHz
		GSResetFall_D         : unsigned(APS_GSRESETFALLTIME_SIZE - 1 downto 0); -- in cycles at 30MHz
		GSTXFall_D            : unsigned(APS_GSTXFALLTIME_SIZE - 1 downto 0); -- in cycles at 30MHz
		GSFDReset_D           : unsigned(APS_GSFDRESETTIME_SIZE - 1 downto 0); -- in cycles at 30MHz
		GSCpResetFD_D         : unsigned(APS_GSCPRESETFDTIME_SIZE - 1 downto 0); -- in cycles at 30MHz
		GSCpResetSettle_D     : unsigned(APS_GSCPRESETSETTLETIME_SIZE - 1 downto 0); -- in cycles at 30MHz
	end record tD4AAPSADCConfig;

	constant tD4AAPSADCConfigDefault : tD4AAPSADCConfig := (
		Run_S                 => '0',
		GlobalShutter_S       => CHIP_HAS_GLOBAL_SHUTTER,
		StartColumn0_D        => to_unsigned(0, CHIP_APS_SIZE_COLUMNS'length),
		StartRow0_D           => to_unsigned(0, CHIP_APS_SIZE_ROWS'length),
		EndColumn0_D          => CHIP_APS_SIZE_COLUMNS - 1,
		EndRow0_D             => CHIP_APS_SIZE_ROWS - 1,
		Exposure_D            => to_unsigned(2000 * ADC_CLOCK_FREQ, APS_EXPOSURE_SIZE),
		FrameDelay_D          => to_unsigned(200 * ADC_CLOCK_FREQ, APS_FRAMEDELAY_SIZE),
		RowSettle_D           => to_unsigned(10, APS_ROWSETTLETIME_SIZE),
		ResetRead_S           => '1',
		WaitOnTransferStall_S => '0',
		StartColumn1_D        => CHIP_APS_SIZE_COLUMNS,
		StartRow1_D           => CHIP_APS_SIZE_ROWS,
		EndColumn1_D          => CHIP_APS_SIZE_COLUMNS,
		EndRow1_D             => CHIP_APS_SIZE_ROWS,
		StartColumn2_D        => CHIP_APS_SIZE_COLUMNS,
		StartRow2_D           => CHIP_APS_SIZE_ROWS,
		EndColumn2_D          => CHIP_APS_SIZE_COLUMNS,
		EndRow2_D             => CHIP_APS_SIZE_ROWS,
		StartColumn3_D        => CHIP_APS_SIZE_COLUMNS,
		StartRow3_D           => CHIP_APS_SIZE_ROWS,
		EndColumn3_D          => CHIP_APS_SIZE_COLUMNS,
		EndRow3_D             => CHIP_APS_SIZE_ROWS,
		HasQuadROI_S          => '0',
		UseInternalADC_S      => CHIP_HAS_INTEGRATED_ADC,
		SampleEnable_S        => '1',
		SampleSettle_D        => to_unsigned(60, APS_SAMPLESETTLETIME_SIZE),
		RampReset_D           => to_unsigned(10, APS_RAMPRESETTIME_SIZE),
		Transfer_D            => to_unsigned(60, APS_TRANSFERTIME_SIZE),
		RSFDSettle_D          => to_unsigned(60, APS_RSFDSETTLETIME_SIZE),
		RSCpReset_D           => to_unsigned(60, APS_RSCPRESETTIME_SIZE),
		RSCpSettle_D          => to_unsigned(60, APS_RSCPSETTLETIME_SIZE),
		GSPDReset_D           => to_unsigned(60, APS_GSPDRESETTIME_SIZE),
		GSResetFall_D         => to_unsigned(60, APS_GSRESETFALLTIME_SIZE),
		GSTXFall_D            => to_unsigned(60, APS_GSTXFALLTIME_SIZE),
		GSFDReset_D           => to_unsigned(60, APS_GSFDRESETTIME_SIZE),
		GSCpResetFD_D         => to_unsigned(60, APS_GSCPRESETFDTIME_SIZE),
		GSCpResetSettle_D     => to_unsigned(60, APS_GSCPRESETSETTLETIME_SIZE));
end package D4AAPSADCConfigRecords;
