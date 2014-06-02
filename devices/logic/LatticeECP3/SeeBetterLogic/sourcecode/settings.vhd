library IEEE;
use IEEE.MATH_REAL."ceil";
use IEEE.MATH_REAL."log2";

package settings is
	constant USB_CLOCK_FREQ : integer := 80;
	constant USB_FIFO_WIDTH : integer := 16;
	constant USB_FIFO_SIZE : integer := 64;
	constant USB_EARLY_PACKET_MS : integer := 1;
	constant USB_BURST_WRITE_LENGTH : integer := 8;
	constant LOGIC_CLOCK_FREQ : integer := 240; -- PLL can generate between 5 and 500 MHz here.
	constant AER_BUS_WIDTH : integer := 10;
	constant ADC_BUS_WIDTH : integer := 10;

	-- calculated constants
	constant USB_EARLY_PACKET_CYCLES : integer := USB_CLOCK_FREQ * 1000 * USB_EARLY_PACKET_MS;
	constant USB_EARLY_PACKET_WIDTH : integer := integer(ceil(log2(real(USB_EARLY_PACKET_CYCLES))));

	-- number of intermediate writes to perform (including zero, so a value of 5 means 6 write cycles)
	constant USB_BURST_WRITE_CYCLES : integer := USB_BURST_WRITE_LENGTH - 3;
	constant USB_BURST_WRITE_WIDTH : integer := integer(ceil(log2(real(USB_BURST_WRITE_CYCLES))));
end settings;
