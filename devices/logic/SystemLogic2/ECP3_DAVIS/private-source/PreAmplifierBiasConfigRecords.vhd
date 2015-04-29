--------------------------------------------------------------------------------
-- Company: INI
-- Engineer: Diederik Paul Moeys
--
-- Create Date:    23.04.2015
-- Design Name:    DAVIS208
-- Module Name:    PreAmplifierBiasConfigRecords
-- Project Name:   VISUALISE
-- Target Device:  Latticed LFE3-17EA-7ftn256i
-- Tool versions:  Diamond x64 3.0.0.97x
-- Description:	   Config Records of PreAmplifierBias State Machine
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Libraries -------------------------------------------------------------------
-------------------------------------------------------------------------------- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

package PreAmplifierBiasConfigRecords is
	constant PREAMPLIFIERBIASCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(4, 7);

	type tPreAmplifierBiasConfigParamAddresses is record
		Run_S             : unsigned(7 downto 0);
		HighThreshold_S   : unsigned(7 downto 0);
		LowThreshold_S    : unsigned(7 downto 0);
		ADCSamplingTime_S : unsigned(7 downto 0);
	end record tPreAmplifierBiasConfigParamAddresses;

	constant PREAMPLIFIERBIASCONFIG_PARAM_ADDRESSES : tPreAmplifierBiasConfigParamAddresses := (
		Run_S             => to_unsigned(0, 8),
		HighThreshold_S   => to_unsigned(1, 8),
		LowThreshold_S    => to_unsigned(2, 8),
		ADCSamplingTime_S => to_unsigned(3, 8));

	constant THRESHOLD_SIZE       : integer := 10;
	constant ADC_SAMPLE_TIME_SIZE : integer := 28;

	type tPreAmplifierBiasConfig is record
		Run_S             : std_logic;
		HighThreshold_S   : unsigned(THRESHOLD_SIZE - 1 downto 0); -- High threshold parameter
		LowThreshold_S    : unsigned(THRESHOLD_SIZE - 1 downto 0); -- Low threshold parameter
		ADCSamplingTime_S : unsigned(ADC_SAMPLE_TIME_SIZE - 1 downto 0); -- Set counter limit, i.e. when to sample the next pre-amplifier output value
	end record tPreAmplifierBiasConfig;

	constant tPreAmplifierBiasConfigDefault : tPreAmplifierBiasConfig := (
		Run_S             => '0',
		HighThreshold_S   => to_unsigned(0, THRESHOLD_SIZE),
		LowThreshold_S    => to_unsigned(0, THRESHOLD_SIZE),
		ADCSamplingTime_S => to_unsigned(0, ADC_SAMPLE_TIME_SIZE));
end package PreAmplifierBiasConfigRecords;
