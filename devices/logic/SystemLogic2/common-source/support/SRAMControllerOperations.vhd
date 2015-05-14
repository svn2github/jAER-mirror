library ieee;
use ieee.std_logic_1164.all;

package SRAMControllerOperations is
	constant SRAMCONTROLLER_OPERATIONS_SIZE : integer := 2;

	constant SRAMCONTROLLER_OPERATIONS_DO_NOTHING : std_logic_vector(SRAMCONTROLLER_OPERATIONS_SIZE - 1 downto 0) := "00";
	constant SRAMCONTROLLER_OPERATIONS_READ       : std_logic_vector(SRAMCONTROLLER_OPERATIONS_SIZE - 1 downto 0) := "01";
	constant SRAMCONTROLLER_OPERATIONS_WRITE      : std_logic_vector(SRAMCONTROLLER_OPERATIONS_SIZE - 1 downto 0) := "10";
	constant SRAMCONTROLLER_OPERATIONS_CLEAR      : std_logic_vector(SRAMCONTROLLER_OPERATIONS_SIZE - 1 downto 0) := "11";
end package SRAMControllerOperations;
