library IEEE;
use IEEE.MATH_REAL."ceil";
use IEEE.MATH_REAL."log2";

package Settings is
	constant DEVICE_FAMILY : string := "ECP3";

	constant USB_CLOCK_FREQ			: integer := 80;  -- 80 or 100 are viable settings, depending on FX3 and routing.
	constant USB_FIFO_WIDTH			: integer := 16;
	constant USB_EARLY_PACKET_MS	: integer := 1;	 -- send a packet each X milliseconds
	constant USB_BURST_WRITE_LENGTH : integer := 8;

	constant LOGIC_CLOCK_FREQ : integer := 240;	 -- PLL can generate between 5 and 500 MHz here.

	constant AER_BUS_WIDTH : integer := 10;
	constant ADC_BUS_WIDTH : integer := 10;

	constant TIMESTAMP_WIDTH : integer := 15;
	constant EVENT_WIDTH	 : integer := 15;

	constant USBFPGA_FIFO_SIZE		  : integer := 64;
	constant USBFPGA_FIFO_ALMOST_SIZE : integer := USB_BURST_WRITE_LENGTH;
	constant DVSAER_FIFO_SIZE		  : integer := 16;
	constant DVSAER_FIFO_ALMOST_SIZE  : integer := 4;
	constant APSADC_FIFO_SIZE		  : integer := 128;
	constant APSADC_FIFO_ALMOST_SIZE  : integer := 8;
	constant IMU_FIFO_SIZE			  : integer := 14;	-- two samples (2x7)
	constant IMU_FIFO_ALMOST_SIZE	  : integer := 7;	-- one sample (1x7)

	-- calculated constants
	constant USB_EARLY_PACKET_CYCLES : integer := USB_CLOCK_FREQ * 1000 * USB_EARLY_PACKET_MS;
	constant USB_EARLY_PACKET_WIDTH	 : integer := integer(ceil(log2(real(USB_EARLY_PACKET_CYCLES+1))));

	-- number of intermediate writes to perform (including zero, so a value of 5 means 6 write cycles)
	constant USB_BURST_WRITE_CYCLES : integer := USB_BURST_WRITE_LENGTH - 3;
	constant USB_BURST_WRITE_WIDTH	: integer := integer(ceil(log2(real(USB_BURST_WRITE_CYCLES+1))));
end Settings;
