library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ChipBiasConfigRecords is
	constant CHIPBIASCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(5, 7);

	constant BIASADDR_REG_LENGTH : integer := 8;
	constant BIAS_REG_LENGTH     : integer := 16;

	constant BIAS_VD_LENGTH : integer := 6;
	constant BIAS_CF_LENGTH : integer := 15;
	constant BIAS_SS_LENGTH : integer := 16;

	constant CHIP_REG_LENGTH : integer := 56;
	constant CHIP_MUX_LENGTH : integer := 4;
end package ChipBiasConfigRecords;
