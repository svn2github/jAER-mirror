library ieee;
use ieee.std_logic_1164.all;

package Settings is
	constant DEVICE_FAMILY : string := "XO";

	constant USB_CLOCK_FREQ         : integer := 30; -- 30 or 48 are valid here.
	constant USB_FIFO_WIDTH         : integer := 16;
	constant USB_EARLY_PACKET_MS    : integer := 1; -- send a packet each X milliseconds
	constant USB_BURST_WRITE_LENGTH : integer := 4;

	constant LOGIC_CLOCK_FREQ : integer := 90; -- PLL can generate between 5 and 500 MHz here.

	constant USBLOGIC_FIFO_SIZE                 : integer := 32;
	constant USBLOGIC_FIFO_ALMOST_EMPTY_SIZE    : integer := USB_BURST_WRITE_LENGTH;
	constant USBLOGIC_FIFO_ALMOST_FULL_SIZE     : integer := 2;
end Settings;
