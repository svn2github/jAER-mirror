library ieee;
use ieee.std_logic_1164.all;

package Settings is
	constant DEVICE_FAMILY : string := "ECP3";

	constant USB_CLOCK_FREQ         : integer := 80; -- 80 or 100 are viable settings, depending on FX3 and routing.
	constant USB_FIFO_WIDTH         : integer := 16;
	constant USB_BURST_WRITE_LENGTH : integer := 8;

	constant LOGIC_CLOCK_FREQ : integer := 120; -- PLL can generate between 5 and 500 MHz here.

	constant USBLOGIC_FIFO_SIZE              : integer := 512;
	constant USBLOGIC_FIFO_ALMOST_EMPTY_SIZE : integer := USB_BURST_WRITE_LENGTH;
	constant USBLOGIC_FIFO_ALMOST_FULL_SIZE  : integer := 2;
end Settings;
