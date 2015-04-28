library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.AER_BUS_WIDTH_COL;
use work.Settings.AER_BUS_WIDTH_ROW;

package DVSAERCorrFilterConfigRecords is
	constant DVSAERCORRFILTERCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(1, 7);

	type tDVSAERCorrFilterConfigParamAddresses is record
		SizeColumns_D         : unsigned(7 downto 0);
		SizeRows_D            : unsigned(7 downto 0);
		Run_S                 : unsigned(7 downto 0);
		AckDelayRow_D         : unsigned(7 downto 0);
		AckDelayColumn_D      : unsigned(7 downto 0);
		AckExtensionRow_D     : unsigned(7 downto 0);
		AckExtensionColumn_D  : unsigned(7 downto 0);
		WaitOnTransferStall_S : unsigned(7 downto 0);
		FilterRowOnlyEvents_S : unsigned(7 downto 0);
		PassDelayTime_D       : unsigned(7 downto 0);
	end record tDVSAERCorrFilterConfigParamAddresses;

	constant DVSAERCORRFILTERCONFIG_PARAM_ADDRESSES : tDVSAERCorrFilterConfigParamAddresses := (
		SizeColumns_D         => to_unsigned(0, 8),
		SizeRows_D            => to_unsigned(1, 8),
		Run_S                 => to_unsigned(2, 8),
		AckDelayRow_D         => to_unsigned(3, 8),
		AckDelayColumn_D      => to_unsigned(4, 8),
		AckExtensionRow_D     => to_unsigned(5, 8),
		AckExtensionColumn_D  => to_unsigned(6, 8),
		WaitOnTransferStall_S => to_unsigned(7, 8),
		FilterRowOnlyEvents_S => to_unsigned(8, 8),
		PassDelayTime_D       => to_unsigned(9, 8));

	constant DVS_AER_ACK_COUNTER_WIDTH : integer := 6;

	type tDVSAERCorrFilterConfig is record
		SizeColumns_D         : unsigned(AER_BUS_WIDTH_COL - 1 downto 0);
		SizeRows_D            : unsigned(AER_BUS_WIDTH_ROW - 1 downto 0);
		Run_S                 : std_logic;
		AckDelayRow_D         : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);
		AckDelayColumn_D      : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);
		AckExtensionRow_D     : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);
		AckExtensionColumn_D  : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);
		WaitOnTransferStall_S : std_logic;
		FilterRowOnlyEvents_S : std_logic;
		PassDelayTime_D       : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);
	end record tDVSAERCorrFilterConfig;

	constant tDVSAERCorrFilterConfigDefault : tDVSAERCorrFilterConfig := (
		SizeColumns_D         => (others => '1'),
		SizeRows_D            => (others => '1'),
		Run_S                 => '0',
		AckDelayRow_D         => to_unsigned(4, tDVSAERCorrFilterConfig.AckDelayRow_D'length),
		AckDelayColumn_D      => to_unsigned(0, tDVSAERCorrFilterConfig.AckDelayColumn_D'length),
		AckExtensionRow_D     => to_unsigned(1, tDVSAERCorrFilterConfig.AckExtensionRow_D'length),
		AckExtensionColumn_D  => to_unsigned(0, tDVSAERCorrFilterConfig.AckExtensionColumn_D'length),
		WaitOnTransferStall_S => '0',
		FilterRowOnlyEvents_S => '1',
		PassDelayTime_D       => to_unsigned(2, tDVSAERCorrFilterConfig.PassDelayTime_D'length));
end package DVSAERCorrFilterConfigRecords;
