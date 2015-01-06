library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.CHIP_APS_SIZE_COLUMNS;
use work.Settings.CHIP_APS_SIZE_ROWS;
use work.Settings.CHIP_HAS_GLOBAL_SHUTTER;

package APSADCConfigRecords is
	constant APSADCCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(2, 7);

	type tAPSADCConfigParamAddresses is record
		Run_S                 : unsigned(7 downto 0);
		ForceADCRunning_S     : unsigned(7 downto 0);
		GlobalShutter_S       : unsigned(7 downto 0);
		StartColumn0_D        : unsigned(7 downto 0);
		StartRow0_D           : unsigned(7 downto 0);
		EndColumn0_D          : unsigned(7 downto 0);
		EndRow0_D             : unsigned(7 downto 0);
		Exposure_D            : unsigned(7 downto 0);
		FrameDelay_D          : unsigned(7 downto 0);
		ResetSettle_D         : unsigned(7 downto 0);
		ColumnSettle_D        : unsigned(7 downto 0);
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
	end record tAPSADCConfigParamAddresses;

	constant APSADCCONFIG_PARAM_ADDRESSES : tAPSADCConfigParamAddresses := (
		Run_S                 => to_unsigned(0, 8),
		ForceADCRunning_S     => to_unsigned(1, 8),
		GlobalShutter_S       => to_unsigned(2, 8),
		StartColumn0_D        => to_unsigned(3, 8),
		StartRow0_D           => to_unsigned(4, 8),
		EndColumn0_D          => to_unsigned(5, 8),
		EndRow0_D             => to_unsigned(6, 8),
		Exposure_D            => to_unsigned(7, 8),
		FrameDelay_D          => to_unsigned(8, 8),
		ResetSettle_D         => to_unsigned(9, 8),
		ColumnSettle_D        => to_unsigned(10, 8),
		RowSettle_D           => to_unsigned(11, 8),
		-- 12 is unused, left over from tests.
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
		EndRow3_D             => to_unsigned(26, 8));

	constant EXPOSUREDELAY_SIZE : integer := 26;
	constant RESETTIME_SIZE     : integer := 8;
	constant SETTLETIMES_SIZE   : integer := 6;

	type tAPSADCConfig is record
		Run_S                 : std_logic;
		ForceADCRunning_S     : std_logic; -- Force ADC to be always on, for quick resume.
		GlobalShutter_S       : std_logic; -- enable global shutter instead of rolling shutter
		StartColumn0_D         : unsigned(CHIP_APS_SIZE_COLUMNS'range);
		StartRow0_D            : unsigned(CHIP_APS_SIZE_ROWS'range);
		EndColumn0_D           : unsigned(CHIP_APS_SIZE_COLUMNS'range);
		EndRow0_D              : unsigned(CHIP_APS_SIZE_ROWS'range);
		Exposure_D            : unsigned(EXPOSUREDELAY_SIZE - 1 downto 0); -- in microseconds, up to 1 second
		FrameDelay_D          : unsigned(EXPOSUREDELAY_SIZE - 1 downto 0); -- in microseconds, up to 1 second
		ResetSettle_D         : unsigned(RESETTIME_SIZE - 1 downto 0); -- in cycles at 30MHz, up to 255 cycles
		ColumnSettle_D        : unsigned(SETTLETIMES_SIZE - 1 downto 0); -- in cycles at 30MHz, up to 63 cycles
		RowSettle_D           : unsigned(SETTLETIMES_SIZE - 1 downto 0); -- in cycles at 30MHz, up to 63 cycles
		ResetRead_S           : std_logic; -- Wether to do the reset read or not.
		WaitOnTransferStall_S : std_logic; -- Wether to wait when the FIFOs are full or not.
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
	end record tAPSADCConfig;

	constant tAPSADCConfigDefault : tAPSADCConfig := (
		Run_S                 => '0',
		ForceADCRunning_S     => '0',
		GlobalShutter_S       => CHIP_HAS_GLOBAL_SHUTTER,
		StartColumn0_D         => to_unsigned(0, CHIP_APS_SIZE_COLUMNS'length),
		StartRow0_D            => to_unsigned(0, CHIP_APS_SIZE_ROWS'length),
		EndColumn0_D           => CHIP_APS_SIZE_COLUMNS - 1,
		EndRow0_D              => CHIP_APS_SIZE_ROWS - 1,
		Exposure_D            => to_unsigned(60000, EXPOSUREDELAY_SIZE),
		FrameDelay_D          => to_unsigned(6000, EXPOSUREDELAY_SIZE),
		ResetSettle_D         => to_unsigned(10, RESETTIME_SIZE),
		ColumnSettle_D        => to_unsigned(10, SETTLETIMES_SIZE),
		RowSettle_D           => to_unsigned(10, SETTLETIMES_SIZE),
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
		EndRow3_D             => CHIP_APS_SIZE_ROWS);
end package APSADCConfigRecords;
