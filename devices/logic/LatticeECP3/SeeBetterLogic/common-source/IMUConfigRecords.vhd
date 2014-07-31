library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package IMUConfigRecords is
	constant IMUCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(3, 7);

	type tIMUConfigParamAddresses is record
		Run_S                  : unsigned(7 downto 0);
		TempStandby_S          : unsigned(7 downto 0);
		AccelStandby_S         : unsigned(7 downto 0);
		GyroStandby_S          : unsigned(7 downto 0);
		LPCycle_S              : unsigned(7 downto 0);
		LPWakeup_D             : unsigned(7 downto 0);
		SampleRateDivider_D    : unsigned(7 downto 0);
		DigitalLowPassFilter_D : unsigned(7 downto 0);
		AccelFullScale_D       : unsigned(7 downto 0);
		GyroFullScale_D        : unsigned(7 downto 0);
	end record tIMUConfigParamAddresses;

	constant IMUCONFIG_PARAM_ADDRESSES : tIMUConfigParamAddresses := (
		Run_S                  => to_unsigned(0, 8),
		TempStandby_S          => to_unsigned(1, 8),
		AccelStandby_S         => to_unsigned(2, 8),
		GyroStandby_S          => to_unsigned(3, 8),
		LPCycle_S              => to_unsigned(4, 8),
		LPWakeup_D             => to_unsigned(5, 8),
		SampleRateDivider_D    => to_unsigned(6, 8),
		DigitalLowPassFilter_D => to_unsigned(7, 8),
		AccelFullScale_D       => to_unsigned(8, 8),
		GyroFullScale_D        => to_unsigned(9, 8));

	type tIMUConfig is record
		Run_S                  : std_logic;
		TempStandby_S          : std_logic;
		AccelStandby_S         : std_logic_vector(2 downto 0);
		GyroStandby_S          : std_logic_vector(2 downto 0);
		LPCycle_S              : std_logic;
		LPWakeup_D             : unsigned(1 downto 0);
		SampleRateDivider_D    : unsigned(7 downto 0);
		DigitalLowPassFilter_D : unsigned(2 downto 0);
		AccelFullScale_D       : unsigned(1 downto 0);
		GyroFullScale_D        : unsigned(1 downto 0);
	end record tIMUConfig;

	constant tIMUConfigDefault : tIMUConfig := (
		Run_S                  => '0',
		TempStandby_S          => '0',
		AccelStandby_S         => "000",
		GyroStandby_S          => "000",
		LPCycle_S              => '0',
		LPWakeup_D             => to_unsigned(1, tIMUConfig.LPWakeup_D'length),
		SampleRateDivider_D    => to_unsigned(0, tIMUConfig.SampleRateDivider_D'length),
		DigitalLowPassFilter_D => to_unsigned(1, tIMUConfig.DigitalLowPassFilter_D'length),
		AccelFullScale_D       => to_unsigned(1, tIMUConfig.AccelFullScale_D'length),
		GyroFullScale_D        => to_unsigned(1, tIMUConfig.GyroFullScale_D'length));
end package IMUConfigRecords;
