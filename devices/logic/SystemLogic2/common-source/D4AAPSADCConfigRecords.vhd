library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.CHIP_APS_SIZE_COLUMNS;
use work.Settings.CHIP_APS_SIZE_ROWS;
use work.Settings.CHIP_APS_STREAM_START;
use work.Settings.CHIP_APS_AXES_INVERT;
use work.Settings.CHIP_APS_HAS_GLOBAL_SHUTTER;
use work.Settings.CHIP_APS_HAS_INTEGRATED_ADC;
use work.Settings.BOARD_APS_HAS_EXTERNAL_ADC;
use work.Settings.ADC_CLOCK_FREQ;

package D4AAPSADCConfigRecords is
	constant D4AAPSADCCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(2, 7);

	type tD4AAPSADCConfigParamAddresses is record
		SizeColumns_D         : unsigned(7 downto 0);
		SizeRows_D            : unsigned(7 downto 0);
		OrientationInfo_D     : unsigned(7 downto 0);
		ColorFilter_D         : unsigned(7 downto 0);
		Run_S                 : unsigned(7 downto 0);
		ResetRead_S           : unsigned(7 downto 0);
		WaitOnTransferStall_S : unsigned(7 downto 0);
		HasGlobalShutter_S    : unsigned(7 downto 0);
		GlobalShutter_S       : unsigned(7 downto 0);
		Exposure_D            : unsigned(7 downto 0);
		FrameDelay_D          : unsigned(7 downto 0);
		RowSettle_D           : unsigned(7 downto 0);
		HasExternalADC_S      : unsigned(7 downto 0);
		HasInternalADC_S      : unsigned(7 downto 0);
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
		SizeColumns_D         => to_unsigned(0, 8),
		SizeRows_D            => to_unsigned(1, 8),
		OrientationInfo_D     => to_unsigned(2, 8),
		ColorFilter_D         => to_unsigned(3, 8),
		Run_S                 => to_unsigned(4, 8),
		ResetRead_S           => to_unsigned(5, 8),
		WaitOnTransferStall_S => to_unsigned(6, 8),
		HasGlobalShutter_S    => to_unsigned(7, 8),
		GlobalShutter_S       => to_unsigned(8, 8),
		Exposure_D            => to_unsigned(13, 8),
		FrameDelay_D          => to_unsigned(14, 8),
		RowSettle_D           => to_unsigned(17, 8),
		HasExternalADC_S      => to_unsigned(32, 8),
		HasInternalADC_S      => to_unsigned(33, 8),
		UseInternalADC_S      => to_unsigned(34, 8),
		SampleEnable_S        => to_unsigned(35, 8),
		SampleSettle_D        => to_unsigned(36, 8),
		RampReset_D           => to_unsigned(37, 8),
		Transfer_D            => to_unsigned(38, 8),
		RSFDSettle_D          => to_unsigned(39, 8),
		RSCpReset_D           => to_unsigned(40, 8),
		RSCpSettle_D          => to_unsigned(41, 8),
		GSPDReset_D           => to_unsigned(42, 8),
		GSResetFall_D         => to_unsigned(43, 8),
		GSTXFall_D            => to_unsigned(44, 8),
		GSFDReset_D           => to_unsigned(45, 8),
		GSCpResetFD_D         => to_unsigned(46, 8),
		GSCpResetSettle_D     => to_unsigned(47, 8));

	constant APS_EXPOSURE_SIZE      : integer := 25; -- Up to about one second.
	constant APS_FRAMEDELAY_SIZE    : integer := 25; -- Up to about one second.
	constant APS_ROWSETTLETIME_SIZE : integer := 12; -- Up to about 128 microseconds.

	-- On-chip ADC specific timings.
	constant APS_SAMPLESETTLETIME_SIZE : integer := 12; -- Up to about 128 microseconds.
	constant APS_RAMPRESETTIME_SIZE    : integer := 12; -- Up to about 128 microseconds.

	-- DAVIS RGB specific timings.
	constant APS_TRANSFERTIME_SIZE        : integer := 16; -- Up to about 2.16 miliseconds.
	constant APS_RSFDSETTLETIME_SIZE      : integer := 12; -- Up to about 128 microseconds.
	constant APS_RSCPRESETTIME_SIZE       : integer := 12; -- Up to about 128 microseconds.
	constant APS_RSCPSETTLETIME_SIZE      : integer := 12; -- Up to about 128 microseconds.
	constant APS_GSPDRESETTIME_SIZE       : integer := 12; -- Up to about 128 microseconds.
	constant APS_GSRESETFALLTIME_SIZE     : integer := 12; -- Up to about 128 microseconds.
	constant APS_GSTXFALLTIME_SIZE        : integer := 12; -- Up to about 128 microseconds.
	constant APS_GSFDRESETTIME_SIZE       : integer := 12; -- Up to about 128 microseconds.
	constant APS_GSCPRESETFDTIME_SIZE     : integer := 12; -- Up to about 128 microseconds.
	constant APS_GSCPRESETSETTLETIME_SIZE : integer := 12; -- Up to about 128 microseconds.

	type tD4AAPSADCConfig is record
		SizeColumns_D         : unsigned(CHIP_APS_SIZE_ROWS'range); -- Invert Col/Row for DAVIS RGB.
		SizeRows_D            : unsigned(CHIP_APS_SIZE_COLUMNS'range); -- The SM is row-based, but decoding expects column-based sizes.
		OrientationInfo_D     : std_logic_vector(2 downto 0);
		ColorFilter_D         : std_logic_vector(1 downto 0);
		Run_S                 : std_logic;
		ResetRead_S           : std_logic; -- Wether to do the reset read or not.
		WaitOnTransferStall_S : std_logic; -- Wether to wait when the FIFO is full or not.
		HasGlobalShutter_S    : std_logic;
		GlobalShutter_S       : std_logic; -- Enable global shutter instead of rolling shutter.
		Exposure_D            : unsigned(APS_EXPOSURE_SIZE - 1 downto 0); -- in cycles at 30MHz
		FrameDelay_D          : unsigned(APS_FRAMEDELAY_SIZE - 1 downto 0); -- in cycles at 30MHz
		RowSettle_D           : unsigned(APS_ROWSETTLETIME_SIZE - 1 downto 0); -- in cycles at 30MHz
		HasExternalADC_S      : std_logic;
		HasInternalADC_S      : std_logic;
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
		SizeColumns_D         => CHIP_APS_SIZE_ROWS, -- Invert Col/Row for DAVIS RGB.
		SizeRows_D            => CHIP_APS_SIZE_COLUMNS, -- The SM is row-based, but decoding expects column-based sizes.
		OrientationInfo_D     => CHIP_APS_AXES_INVERT & CHIP_APS_STREAM_START,
		ColorFilter_D         => "00",
		Run_S                 => '0',
		ResetRead_S           => '1',
		WaitOnTransferStall_S => '0',
		HasGlobalShutter_S    => CHIP_APS_HAS_GLOBAL_SHUTTER,
		GlobalShutter_S       => CHIP_APS_HAS_GLOBAL_SHUTTER,
		Exposure_D            => to_unsigned(2000 * ADC_CLOCK_FREQ, APS_EXPOSURE_SIZE),
		FrameDelay_D          => to_unsigned(200 * ADC_CLOCK_FREQ, APS_FRAMEDELAY_SIZE),
		RowSettle_D           => to_unsigned(10, APS_ROWSETTLETIME_SIZE),
		HasExternalADC_S      => BOARD_APS_HAS_EXTERNAL_ADC,
		HasInternalADC_S      => CHIP_APS_HAS_INTEGRATED_ADC,
		UseInternalADC_S      => CHIP_APS_HAS_INTEGRATED_ADC,
		SampleEnable_S        => '1',
		SampleSettle_D        => to_unsigned(60, APS_SAMPLESETTLETIME_SIZE),
		RampReset_D           => to_unsigned(10, APS_RAMPRESETTIME_SIZE),
		Transfer_D            => to_unsigned(150, APS_TRANSFERTIME_SIZE),
		RSFDSettle_D          => to_unsigned(150, APS_RSFDSETTLETIME_SIZE),
		RSCpReset_D           => to_unsigned(150, APS_RSCPRESETTIME_SIZE),
		RSCpSettle_D          => to_unsigned(150, APS_RSCPSETTLETIME_SIZE),
		GSPDReset_D           => to_unsigned(150, APS_GSPDRESETTIME_SIZE),
		GSResetFall_D         => to_unsigned(150, APS_GSRESETFALLTIME_SIZE),
		GSTXFall_D            => to_unsigned(150, APS_GSTXFALLTIME_SIZE),
		GSFDReset_D           => to_unsigned(150, APS_GSFDRESETTIME_SIZE),
		GSCpResetFD_D         => to_unsigned(150, APS_GSCPRESETFDTIME_SIZE),
		GSCpResetSettle_D     => to_unsigned(150, APS_GSCPRESETSETTLETIME_SIZE));
end package D4AAPSADCConfigRecords;
