library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use work.Settings.CHIP_SIZE_COLUMNS;
use work.Settings.CHIP_SIZE_ROWS;

package APSADCConfigRecords is
	constant APSADCCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(2, 7);

	type tAPSADCConfigParamAddresses is record
		Run_S                 : unsigned(7 downto 0);
		Mode_D                : unsigned(7 downto 0);
		GlobalShutter_S       : unsigned(7 downto 0);
		StartColumn_D         : unsigned(7 downto 0);
		StartRow_D            : unsigned(7 downto 0);
		EndColumn_D           : unsigned(7 downto 0);
		EndRow_D              : unsigned(7 downto 0);
		Exposure_D            : unsigned(7 downto 0);
		FrameDelay_D          : unsigned(7 downto 0);
		ResetSettle_D         : unsigned(7 downto 0);
		ColumnSettle_D        : unsigned(7 downto 0);
		RowSettle_D           : unsigned(7 downto 0);
		GSTXGateOpenReset_S   : unsigned(7 downto 0);
		ResetRead_S           : unsigned(7 downto 0);
		WaitOnTransferStall_S : unsigned(7 downto 0);
	end record tAPSADCConfigParamAddresses;

	constant APSADCCONFIG_PARAM_ADDRESSES : tAPSADCConfigParamAddresses := (
		Run_S                 => to_unsigned(0, 8),
		Mode_D                => to_unsigned(1, 8),
		GlobalShutter_S       => to_unsigned(2, 8),
		StartColumn_D         => to_unsigned(3, 8),
		StartRow_D            => to_unsigned(4, 8),
		EndColumn_D           => to_unsigned(5, 8),
		EndRow_D              => to_unsigned(6, 8),
		Exposure_D            => to_unsigned(7, 8),
		FrameDelay_D          => to_unsigned(8, 8),
		ResetSettle_D         => to_unsigned(9, 8),
		ColumnSettle_D        => to_unsigned(10, 8),
		RowSettle_D           => to_unsigned(11, 8),
		GSTXGateOpenReset_S   => to_unsigned(12, 8),
		ResetRead_S           => to_unsigned(13, 8),
		WaitOnTransferStall_S => to_unsigned(14, 8));

	constant CHIP_SIZE_COLUMNS_WIDTH : integer := integer(ceil(log2(real(CHIP_SIZE_COLUMNS + 1))));
	constant CHIP_SIZE_ROWS_WIDTH    : integer := integer(ceil(log2(real(CHIP_SIZE_ROWS + 1))));

	constant EXPOSUREDELAY_SIZE : integer := 26;
	constant RESETTIME_SIZE     : integer := 8;
	constant SETTLETIMES_SIZE   : integer := 6;

	constant APSADC_MODE_VIDEO             : std_logic_vector(1 downto 0) := "00";
	constant APSADC_MODE_CAMERA_POWERSAVE  : std_logic_vector(1 downto 0) := "01";
	constant APSADC_MODE_CAMERA_LOWLATENCY : std_logic_vector(1 downto 0) := "10";

	type tAPSADCConfig is record
		Run_S                 : std_logic;
		Mode_D                : std_logic_vector(1 downto 0); -- switch between video and camera modes
		GlobalShutter_S       : std_logic; -- enable global shutter instead of rolling shutter
		StartColumn_D         : unsigned(CHIP_SIZE_COLUMNS_WIDTH - 1 downto 0);
		StartRow_D            : unsigned(CHIP_SIZE_ROWS_WIDTH - 1 downto 0);
		EndColumn_D           : unsigned(CHIP_SIZE_COLUMNS_WIDTH - 1 downto 0);
		EndRow_D              : unsigned(CHIP_SIZE_ROWS_WIDTH - 1 downto 0);
		Exposure_D            : unsigned(EXPOSUREDELAY_SIZE - 1 downto 0); -- in microseconds, up to 1 second
		FrameDelay_D          : unsigned(EXPOSUREDELAY_SIZE - 1 downto 0); -- in microseconds, up to 1 second
		ResetSettle_D         : unsigned(RESETTIME_SIZE - 1 downto 0); -- in cycles at 30MHz, up to 255 cycles
		ColumnSettle_D        : unsigned(SETTLETIMES_SIZE - 1 downto 0); -- in cycles at 30MHz, up to 63 cycles
		RowSettle_D           : unsigned(SETTLETIMES_SIZE - 1 downto 0); -- in cycles at 30MHz, up to 63 cycles
		GSTXGateOpenReset_S   : std_logic; -- GS: is the TXGate open during reset too?
		ResetRead_S           : std_logic; -- Wether to do the reset read or not.
		WaitOnTransferStall_S : std_logic; -- Wether to wait when the FIFOs are full or not.
	end record tAPSADCConfig;

	constant tAPSADCConfigDefault : tAPSADCConfig := (
		Run_S                 => '0',
		Mode_D                => APSADC_MODE_VIDEO,
		GlobalShutter_S       => '0',
		StartColumn_D         => to_unsigned(0, CHIP_SIZE_COLUMNS_WIDTH),
		StartRow_D            => to_unsigned(0, CHIP_SIZE_ROWS_WIDTH),
		EndColumn_D           => to_unsigned(CHIP_SIZE_COLUMNS - 1, CHIP_SIZE_COLUMNS_WIDTH),
		EndRow_D              => to_unsigned(CHIP_SIZE_ROWS - 1, CHIP_SIZE_ROWS_WIDTH),
		Exposure_D            => to_unsigned(60000, EXPOSUREDELAY_SIZE),
		FrameDelay_D          => to_unsigned(6000, EXPOSUREDELAY_SIZE),
		ResetSettle_D         => to_unsigned(10, RESETTIME_SIZE),
		ColumnSettle_D        => to_unsigned(10, SETTLETIMES_SIZE),
		RowSettle_D           => to_unsigned(10, SETTLETIMES_SIZE),
		GSTXGateOpenReset_S   => '1',
		ResetRead_S           => '1',
		WaitOnTransferStall_S => '0');
end package APSADCConfigRecords;
