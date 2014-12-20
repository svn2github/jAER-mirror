library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.CHIP_DVS_SIZE_COLUMNS;
use work.Settings.CHIP_DVS_SIZE_ROWS;

package DVSAERConfigRecords is
	constant DVSAERCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(1, 7);

	type tDVSAERConfigParamAddresses is record
		Run_S                               : unsigned(7 downto 0);
		AckDelayRow_D                       : unsigned(7 downto 0);
		AckDelayColumn_D                    : unsigned(7 downto 0);
		AckExtensionRow_D                   : unsigned(7 downto 0);
		AckExtensionColumn_D                : unsigned(7 downto 0);
		WaitOnTransferStall_S               : unsigned(7 downto 0);
		FilterRowOnlyEvents_S               : unsigned(7 downto 0);
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
		FilterBackgroundActivity_S          : unsigned(7 downto 0);
		FilterBackgroundActivityDeltaTime_D : unsigned(7 downto 0);
	end record tDVSAERConfigParamAddresses;

	constant DVSAERCONFIG_PARAM_ADDRESSES : tDVSAERConfigParamAddresses := (
		Run_S                               => to_unsigned(0, 8),
		AckDelayRow_D                       => to_unsigned(1, 8),
		AckDelayColumn_D                    => to_unsigned(2, 8),
		AckExtensionRow_D                   => to_unsigned(3, 8),
		AckExtensionColumn_D                => to_unsigned(4, 8),
		WaitOnTransferStall_S               => to_unsigned(5, 8),
		FilterRowOnlyEvents_S               => to_unsigned(6, 8),
		FilterPixel0Row_D                   => to_unsigned(7, 8),
		FilterPixel0Column_D                => to_unsigned(8, 8),
		FilterPixel1Row_D                   => to_unsigned(9, 8),
		FilterPixel1Column_D                => to_unsigned(10, 8),
		FilterPixel2Row_D                   => to_unsigned(11, 8),
		FilterPixel2Column_D                => to_unsigned(12, 8),
		FilterPixel3Row_D                   => to_unsigned(13, 8),
		FilterPixel3Column_D                => to_unsigned(14, 8),
		FilterPixel4Row_D                   => to_unsigned(15, 8),
		FilterPixel4Column_D                => to_unsigned(16, 8),
		FilterPixel5Row_D                   => to_unsigned(17, 8),
		FilterPixel5Column_D                => to_unsigned(18, 8),
		FilterPixel6Row_D                   => to_unsigned(19, 8),
		FilterPixel6Column_D                => to_unsigned(20, 8),
		FilterPixel7Row_D                   => to_unsigned(21, 8),
		FilterPixel7Column_D                => to_unsigned(22, 8),
		FilterBackgroundActivity_S          => to_unsigned(23, 8),
		FilterBackgroundActivityDeltaTime_D => to_unsigned(24, 8));

	constant DVS_AER_ACK_COUNTER_WIDTH  : integer := 5;
	constant DVS_FILTER_BA_DELTAT_WIDTH : integer := 20;

	type tDVSAERConfig is record
		Run_S                               : std_logic;
		AckDelayRow_D                       : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);
		AckDelayColumn_D                    : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);
		AckExtensionRow_D                   : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);
		AckExtensionColumn_D                : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);
		WaitOnTransferStall_S               : std_logic;
		FilterRowOnlyEvents_S               : std_logic;
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
		FilterBackgroundActivity_S          : std_logic;
		FilterBackgroundActivityDeltaTime_D : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
	end record tDVSAERConfig;

	constant tDVSAERConfigDefault : tDVSAERConfig := (
		Run_S                               => '0',
		AckDelayRow_D                       => to_unsigned(4, tDVSAERConfig.AckDelayRow_D'length),
		AckDelayColumn_D                    => to_unsigned(0, tDVSAERConfig.AckDelayColumn_D'length),
		AckExtensionRow_D                   => to_unsigned(1, tDVSAERConfig.AckExtensionRow_D'length),
		AckExtensionColumn_D                => to_unsigned(0, tDVSAERConfig.AckExtensionColumn_D'length),
		WaitOnTransferStall_S               => '0',
		FilterRowOnlyEvents_S               => '1',
		FilterPixel0Row_D                   => (others => '1'),
		FilterPixel0Column_D                => (others => '1'),
		FilterPixel1Row_D                   => (others => '1'),
		FilterPixel1Column_D                => (others => '1'),
		FilterPixel2Row_D                   => (others => '1'),
		FilterPixel2Column_D                => (others => '1'),
		FilterPixel3Row_D                   => (others => '1'),
		FilterPixel3Column_D                => (others => '1'),
		FilterPixel4Row_D                   => (others => '1'),
		FilterPixel4Column_D                => (others => '1'),
		FilterPixel5Row_D                   => (others => '1'),
		FilterPixel5Column_D                => (others => '1'),
		FilterPixel6Row_D                   => (others => '1'),
		FilterPixel6Column_D                => (others => '1'),
		FilterPixel7Row_D                   => (others => '1'),
		FilterPixel7Column_D                => (others => '1'),
		FilterBackgroundActivity_S          => '0',
		FilterBackgroundActivityDeltaTime_D => to_unsigned(20000, tDVSAERConfig.FilterBackgroundActivityDeltaTime_D'length));
end package DVSAERConfigRecords;
