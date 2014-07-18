library ieee;
use ieee.std_logic_1164.all;

package ShiftRegisterModes is
	constant SHIFTREGISTER_MODE_SIZE : integer := 3;

	constant SHIFTREGISTER_MODE_DO_NOTHING       : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0) := "000";
	constant SHIFTREGISTER_MODE_PARALLEL_LOAD    : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0) := "001";
	constant SHIFTREGISTER_MODE_PARALLEL_CLEAR   : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0) := "010";
	constant SHIFTREGISTER_MODE_PARALLEL_SET     : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0) := "011";
	constant SHIFTREGISTER_MODE_SHIFT_RIGHT      : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0) := "100";
	constant SHIFTREGISTER_MODE_SHIFT_LEFT       : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0) := "101";
	constant SHIFTREGISTER_MODE_SHIFT_RIGHT_ZERO : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0) := "110";
	constant SHIFTREGISTER_MODE_SHIFT_LEFT_ZERO  : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0) := "111";
end package ShiftRegisterModes;
