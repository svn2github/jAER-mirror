library ieee;
use ieee.std_logic_1164.all;

package Settings is
	constant DEVICE_FAMILY : string := "ECP3";

	constant USB_CLOCK_FREQ         : integer := 80; -- 80 or 100 are viable settings, depending on FX3 and routing.
	constant USB_FIFO_WIDTH         : integer := 16;
	constant USB_EARLY_PACKET_MS    : integer := 1; -- send a packet each X milliseconds
	constant USB_BURST_WRITE_LENGTH : integer := 8;

	constant LOGIC_CLOCK_FREQ       : integer := 60; -- PLL can generate between 5 and 500 MHz here.

	constant ADC_CLOCK_FREQ 		: integer := 30;
	
	constant AER_BUS_WIDTH          : integer := 10;
	constant ADC_BUS_WIDTH          : integer := 10;
	
	constant CHIP_SIZE_COLUMNS : integer := 240;
	constant CHIP_SIZE_ROWS    : integer := 180;
		
	constant MISC_OBT_AER_BUS_WIDTH : integer := 18;


	constant USBLOGIC_FIFO_SIZE                 : integer := 32;
	constant USBLOGIC_FIFO_ALMOST_EMPTY_SIZE    : integer := USB_BURST_WRITE_LENGTH;
	constant USBLOGIC_FIFO_ALMOST_FULL_SIZE     : integer := 2;
	constant DVSAER_FIFO_SIZE                   : integer := 16;
	constant DVSAER_FIFO_ALMOST_EMPTY_SIZE      : integer := 4;
	constant DVSAER_FIFO_ALMOST_FULL_SIZE       : integer := 2;
	constant APSADC_FIFO_SIZE                   : integer := 128;
	constant APSADC_FIFO_ALMOST_EMPTY_SIZE      : integer := 8;
	constant APSADC_FIFO_ALMOST_FULL_SIZE       : integer := 8;
	constant IMU_FIFO_SIZE                      : integer := 14; -- two samples (2x7)
	constant IMU_FIFO_ALMOST_EMPTY_SIZE         : integer := 7; -- one sample (1x7)
	constant IMU_FIFO_ALMOST_FULL_SIZE          : integer := 7; -- one sample (1x7)
	constant EXT_TRIGGER_FIFO_SIZE              : integer := 4;
	constant EXT_TRIGGER_FIFO_ALMOST_EMPTY_SIZE : integer := 1;
	constant EXT_TRIGGER_FIFO_ALMOST_FULL_SIZE  : integer := 1;
end Settings;
