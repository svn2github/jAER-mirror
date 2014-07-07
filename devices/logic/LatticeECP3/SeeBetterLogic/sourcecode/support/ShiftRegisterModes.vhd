library ieee;
use ieee.std_logic_1164.all;

package ShiftRegisterModes is
	constant SHIFTREGISTER_MODE_SIZE : integer := 2;

	constant SHIFTREGISTER_MODE_DO_NOTHING	  : std_logic_vector(SHIFTREGISTER_MODE_SIZE-1 downto 0) := "00";
	constant SHIFTREGISTER_MODE_PARALLEL_LOAD : std_logic_vector(SHIFTREGISTER_MODE_SIZE-1 downto 0) := "01";
	constant SHIFTREGISTER_MODE_SHIFT_RIGHT	  : std_logic_vector(SHIFTREGISTER_MODE_SIZE-1 downto 0) := "10";
	constant SHIFTREGISTER_MODE_SHIFT_LEFT	  : std_logic_vector(SHIFTREGISTER_MODE_SIZE-1 downto 0) := "11";
end package ShiftRegisterModes;
