library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real."ceil";
use ieee.math_real."log2";

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
	constant EVENT_WIDTH	 : integer := 16;

	constant USBFPGA_FIFO_SIZE		  : integer := 64;
	constant USBFPGA_FIFO_ALMOST_SIZE : integer := USB_BURST_WRITE_LENGTH;
	constant DVSAER_FIFO_SIZE		  : integer := 16;
	constant DVSAER_FIFO_ALMOST_SIZE  : integer := 4;
	constant APSADC_FIFO_SIZE		  : integer := 128;
	constant APSADC_FIFO_ALMOST_SIZE  : integer := 8;
	constant IMU_FIFO_SIZE			  : integer := 14;	-- two samples (2x7)
	constant IMU_FIFO_ALMOST_SIZE	  : integer := 7;	-- one sample (1x7)

	-- event codes
	constant EVENT_CODE_TIMESTAMP				: std_logic						:= '1';
	constant EVENT_CODE_SPECIAL					: std_logic_vector(3 downto 0)	:= "0000";
	constant EVENT_CODE_SPECIAL_TIMESTAMP_RESET : std_logic_vector(11 downto 0) := "000000000001";
	constant EVENT_CODE_Y_ADDR					: std_logic_vector(3 downto 0)	:= "0001";
	-- The fourth bit of an X address is the polarity. It usually gets encoded directly from the AER bus input.
	constant EVENT_CODE_X_ADDR					: std_logic_vector(2 downto 0)	:= "001";
	constant EVENT_CODE_X_ADDR_POL_OFF			: std_logic_vector(3 downto 0)	:= "0010";
	constant EVENT_CODE_X_ADDR_POL_ON			: std_logic_vector(3 downto 0)	:= "0011";
	constant EVENT_CODE_ADC_SAMPLE				: std_logic_vector(3 downto 0)	:= "0100";
	--constant EVENT_CODE_UNUSED		   : std_logic_vector(3 downto 0) := "0101";
	--constant EVENT_CODE_UNUSED		   : std_logic_vector(3 downto 0) := "0110";
	constant EVENT_CODE_TIMESTAMP_WRAP			: std_logic_vector(3 downto 0)	:= "0111";

	constant OVERFLOW_WIDTH : integer := 12;

	-- calculated constants
	constant USB_EARLY_PACKET_CYCLES : integer := USB_CLOCK_FREQ * 1000 * USB_EARLY_PACKET_MS;
	constant USB_EARLY_PACKET_WIDTH	 : integer := integer(ceil(log2(real(USB_EARLY_PACKET_CYCLES+1))));

	-- number of intermediate writes to perform (including zero, so a value of 5 means 6 write cycles)
	constant USB_BURST_WRITE_CYCLES : integer := USB_BURST_WRITE_LENGTH - 3;
	constant USB_BURST_WRITE_WIDTH	: integer := integer(ceil(log2(real(USB_BURST_WRITE_CYCLES+1))));
end Settings;
