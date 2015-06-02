library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.CHIP_DVS_SIZE_COLUMNS;
use work.Settings.CHIP_DVS_SIZE_ROWS;
use work.Settings.CHIP_DVS_ORIGIN_POINT;
use work.Settings.CHIP_DVS_AXES_INVERT;

package DVSAERConfigRecords is
	constant DVSAERCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(1, 7);

	type tDVSAERConfigParamAddresses is record
		SizeColumns_D                       : unsigned(7 downto 0);
		SizeRows_D                          : unsigned(7 downto 0);
		OrientationInfo_D                   : unsigned(7 downto 0);
		Run_S                               : unsigned(7 downto 0);
		AckDelayRow_D                       : unsigned(7 downto 0);
		AckDelayColumn_D                    : unsigned(7 downto 0);
		AckExtensionRow_D                   : unsigned(7 downto 0);
		AckExtensionColumn_D                : unsigned(7 downto 0);
		WaitOnTransferStall_S               : unsigned(7 downto 0);
		FilterRowOnlyEvents_S               : unsigned(7 downto 0);
		ExternalAERControl_S                : unsigned(7 downto 0);
		HasPixelFilter_S                    : unsigned(7 downto 0);
		FilterPixel0Row_D                   : unsigned(7 downto 0);
		FilterPixel0Column_D                : unsigned(7 downto 0);
		FilterPixel1Row_D                   : unsigned(7 downto 0);
		FilterPixel1Column_D                : unsigned(7 downto 0);
		FilterPixel2Row_D                   : unsigned(7 downto 0);
		FilterPixel2Column_D                : unsigned(7 downto 0);
		FilterPixel3Row_D                   : unsigned(7 downto 0);
		FilterPixel3Column_D                : unsigned(7 downto 0);
		FilterPixel4Row_D                   : unsigned(7 downto 0);
		FilterPixel4Column_D                : unsigned(7 downto 0);
		FilterPixel5Row_D                   : unsigned(7 downto 0);
		FilterPixel5Column_D                : unsigned(7 downto 0);
		FilterPixel6Row_D                   : unsigned(7 downto 0);
		FilterPixel6Column_D                : unsigned(7 downto 0);
		FilterPixel7Row_D                   : unsigned(7 downto 0);
		FilterPixel7Column_D                : unsigned(7 downto 0);
		HasBackgroundActivityFilter_S       : unsigned(7 downto 0);
		FilterBackgroundActivity_S          : unsigned(7 downto 0);
		FilterBackgroundActivityDeltaTime_D : unsigned(7 downto 0);
	end record tDVSAERConfigParamAddresses;

	constant DVSAERCONFIG_PARAM_ADDRESSES : tDVSAERConfigParamAddresses := (
		SizeColumns_D                       => to_unsigned(0, 8),
		SizeRows_D                          => to_unsigned(1, 8),
		OrientationInfo_D                   => to_unsigned(2, 8),
		Run_S                               => to_unsigned(3, 8),
		AckDelayRow_D                       => to_unsigned(4, 8),
		AckDelayColumn_D                    => to_unsigned(5, 8),
		AckExtensionRow_D                   => to_unsigned(6, 8),
		AckExtensionColumn_D                => to_unsigned(7, 8),
		WaitOnTransferStall_S               => to_unsigned(8, 8),
		FilterRowOnlyEvents_S               => to_unsigned(9, 8),
		ExternalAERControl_S                => to_unsigned(10, 8),
		HasPixelFilter_S                    => to_unsigned(11, 8),
		FilterPixel0Row_D                   => to_unsigned(12, 8),
		FilterPixel0Column_D                => to_unsigned(13, 8),
		FilterPixel1Row_D                   => to_unsigned(14, 8),
		FilterPixel1Column_D                => to_unsigned(15, 8),
		FilterPixel2Row_D                   => to_unsigned(16, 8),
		FilterPixel2Column_D                => to_unsigned(17, 8),
		FilterPixel3Row_D                   => to_unsigned(18, 8),
		FilterPixel3Column_D                => to_unsigned(19, 8),
		FilterPixel4Row_D                   => to_unsigned(20, 8),
		FilterPixel4Column_D                => to_unsigned(21, 8),
		FilterPixel5Row_D                   => to_unsigned(22, 8),
		FilterPixel5Column_D                => to_unsigned(23, 8),
		FilterPixel6Row_D                   => to_unsigned(24, 8),
		FilterPixel6Column_D                => to_unsigned(25, 8),
		FilterPixel7Row_D                   => to_unsigned(26, 8),
		FilterPixel7Column_D                => to_unsigned(27, 8),
		HasBackgroundActivityFilter_S       => to_unsigned(28, 8),
		FilterBackgroundActivity_S          => to_unsigned(29, 8),
		FilterBackgroundActivityDeltaTime_D => to_unsigned(30, 8));

	constant DVS_AER_ACK_COUNTER_WIDTH  : integer := 5;
	constant DVS_FILTER_BA_DELTAT_WIDTH : integer := 16;

	type tDVSAERConfig is record
		SizeColumns_D                       : unsigned(CHIP_DVS_SIZE_COLUMNS'range);
		SizeRows_D                          : unsigned(CHIP_DVS_SIZE_ROWS'range);
		OrientationInfo_D                   : std_logic_vector(2 downto 0);
		Run_S                               : std_logic;
		AckDelayRow_D                       : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);
		AckDelayColumn_D                    : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);
		AckExtensionRow_D                   : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);
		AckExtensionColumn_D                : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);
		WaitOnTransferStall_S               : std_logic;
		FilterRowOnlyEvents_S               : std_logic;
		ExternalAERControl_S                : std_logic;
		HasPixelFilter_S                    : std_logic;
		FilterPixel0Row_D                   : unsigned(CHIP_DVS_SIZE_ROWS'range);
		FilterPixel0Column_D                : unsigned(CHIP_DVS_SIZE_COLUMNS'range);
		FilterPixel1Row_D                   : unsigned(CHIP_DVS_SIZE_ROWS'range);
		FilterPixel1Column_D                : unsigned(CHIP_DVS_SIZE_COLUMNS'range);
		FilterPixel2Row_D                   : unsigned(CHIP_DVS_SIZE_ROWS'range);
		FilterPixel2Column_D                : unsigned(CHIP_DVS_SIZE_COLUMNS'range);
		FilterPixel3Row_D                   : unsigned(CHIP_DVS_SIZE_ROWS'range);
		FilterPixel3Column_D                : unsigned(CHIP_DVS_SIZE_COLUMNS'range);
		FilterPixel4Row_D                   : unsigned(CHIP_DVS_SIZE_ROWS'range);
		FilterPixel4Column_D                : unsigned(CHIP_DVS_SIZE_COLUMNS'range);
		FilterPixel5Row_D                   : unsigned(CHIP_DVS_SIZE_ROWS'range);
		FilterPixel5Column_D                : unsigned(CHIP_DVS_SIZE_COLUMNS'range);
		FilterPixel6Row_D                   : unsigned(CHIP_DVS_SIZE_ROWS'range);
		FilterPixel6Column_D                : unsigned(CHIP_DVS_SIZE_COLUMNS'range);
		FilterPixel7Row_D                   : unsigned(CHIP_DVS_SIZE_ROWS'range);
		FilterPixel7Column_D                : unsigned(CHIP_DVS_SIZE_COLUMNS'range);
		HasBackgroundActivityFilter_S       : std_logic;
		FilterBackgroundActivity_S          : std_logic;
		FilterBackgroundActivityDeltaTime_D : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
	end record tDVSAERConfig;

	constant tDVSAERConfigDefault : tDVSAERConfig := (
		SizeColumns_D                       => CHIP_DVS_SIZE_COLUMNS,
		SizeRows_D                          => CHIP_DVS_SIZE_ROWS,
		OrientationInfo_D                   => CHIP_DVS_AXES_INVERT & CHIP_DVS_ORIGIN_POINT,
		Run_S                               => '0',
		AckDelayRow_D                       => to_unsigned(4, tDVSAERConfig.AckDelayRow_D'length),
		AckDelayColumn_D                    => to_unsigned(0, tDVSAERConfig.AckDelayColumn_D'length),
		AckExtensionRow_D                   => to_unsigned(1, tDVSAERConfig.AckExtensionRow_D'length),
		AckExtensionColumn_D                => to_unsigned(0, tDVSAERConfig.AckExtensionColumn_D'length),
		WaitOnTransferStall_S               => '0',
		FilterRowOnlyEvents_S               => '1',
		ExternalAERControl_S                => '0',
		HasPixelFilter_S                    => '0',
		FilterPixel0Row_D                   => CHIP_DVS_SIZE_ROWS,
		FilterPixel0Column_D                => CHIP_DVS_SIZE_COLUMNS,
		FilterPixel1Row_D                   => CHIP_DVS_SIZE_ROWS,
		FilterPixel1Column_D                => CHIP_DVS_SIZE_COLUMNS,
		FilterPixel2Row_D                   => CHIP_DVS_SIZE_ROWS,
		FilterPixel2Column_D                => CHIP_DVS_SIZE_COLUMNS,
		FilterPixel3Row_D                   => CHIP_DVS_SIZE_ROWS,
		FilterPixel3Column_D                => CHIP_DVS_SIZE_COLUMNS,
		FilterPixel4Row_D                   => CHIP_DVS_SIZE_ROWS,
		FilterPixel4Column_D                => CHIP_DVS_SIZE_COLUMNS,
		FilterPixel5Row_D                   => CHIP_DVS_SIZE_ROWS,
		FilterPixel5Column_D                => CHIP_DVS_SIZE_COLUMNS,
		FilterPixel6Row_D                   => CHIP_DVS_SIZE_ROWS,
		FilterPixel6Column_D                => CHIP_DVS_SIZE_COLUMNS,
		FilterPixel7Row_D                   => CHIP_DVS_SIZE_ROWS,
		FilterPixel7Column_D                => CHIP_DVS_SIZE_COLUMNS,
		HasBackgroundActivityFilter_S       => '0',
		FilterBackgroundActivity_S          => '0',
		FilterBackgroundActivityDeltaTime_D => to_unsigned(30000, tDVSAERConfig.FilterBackgroundActivityDeltaTime_D'length));
end package DVSAERConfigRecords;
