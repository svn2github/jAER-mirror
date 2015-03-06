library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ExtTriggerConfigRecords is
	constant EXTTRIGGERCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(4, 7);

	-- Pulse lengths are in 100 ns time-slices. Since we want to support up to 1Hz signals,
	-- we need this value to go up to 10 million => 24 bits are needed (16 million).
	constant MAX_TRIGGER_TIME_SIZE : integer := 24;

	type tExtTriggerConfigParamAddresses is record
		RunDetector_S             : unsigned(7 downto 0);
		DetectRisingEdges_S       : unsigned(7 downto 0);
		DetectFallingEdges_S      : unsigned(7 downto 0);
		DetectPulses_S            : unsigned(7 downto 0);
		DetectPulsePolarity_S     : unsigned(7 downto 0);
		DetectPulseLength_D       : unsigned(7 downto 0);
		RunGenerator_S            : unsigned(7 downto 0);
		GenerateUseCustomSignal_S : unsigned(7 downto 0);
		GeneratePulsePolarity_S   : unsigned(7 downto 0);
		GeneratePulseInterval_D   : unsigned(7 downto 0);
		GeneratePulseLength_D     : unsigned(7 downto 0);
	end record tExtTriggerConfigParamAddresses;

	constant EXTTRIGGERCONFIG_PARAM_ADDRESSES : tExtTriggerConfigParamAddresses := (
		RunDetector_S             => to_unsigned(0, 8),
		DetectRisingEdges_S       => to_unsigned(1, 8),
		DetectFallingEdges_S      => to_unsigned(2, 8),
		DetectPulses_S            => to_unsigned(3, 8),
		DetectPulsePolarity_S     => to_unsigned(4, 8),
		DetectPulseLength_D       => to_unsigned(5, 8),
		RunGenerator_S            => to_unsigned(6, 8),
		GenerateUseCustomSignal_S => to_unsigned(7, 8),
		GeneratePulsePolarity_S   => to_unsigned(8, 8),
		GeneratePulseInterval_D   => to_unsigned(9, 8),
		GeneratePulseLength_D     => to_unsigned(10, 8));

	type tExtTriggerConfig is record
		RunDetector_S             : std_logic;
		DetectRisingEdges_S       : std_logic;
		DetectFallingEdges_S      : std_logic;
		DetectPulses_S            : std_logic;
		DetectPulsePolarity_S     : std_logic;
		DetectPulseLength_D       : unsigned(MAX_TRIGGER_TIME_SIZE - 1 downto 0);
		RunGenerator_S            : std_logic;
		GenerateUseCustomSignal_S : std_logic;
		GeneratePulsePolarity_S   : std_logic;
		GeneratePulseInterval_D   : unsigned(MAX_TRIGGER_TIME_SIZE - 1 downto 0);
		GeneratePulseLength_D     : unsigned(MAX_TRIGGER_TIME_SIZE - 1 downto 0);
	end record tExtTriggerConfig;

	constant tExtTriggerConfigDefault : tExtTriggerConfig := (
		RunDetector_S             => '0',
		DetectRisingEdges_S       => '0',
		DetectFallingEdges_S      => '0',
		DetectPulses_S            => '1',
		DetectPulsePolarity_S     => '1',
		DetectPulseLength_D       => to_unsigned(10, tExtTriggerConfig.DetectPulseLength_D'length),
		RunGenerator_S            => '0',
		GenerateUseCustomSignal_S => '0',
		GeneratePulsePolarity_S   => '1',
		GeneratePulseInterval_D   => to_unsigned(10, tExtTriggerConfig.GeneratePulseInterval_D'length),
		GeneratePulseLength_D     => to_unsigned(5, tExtTriggerConfig.GeneratePulseLength_D'length));
end package ExtTriggerConfigRecords;