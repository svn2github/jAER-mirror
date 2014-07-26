library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

package Settings is
	constant DEVICE_FAMILY : string := "ECP3";

	constant USB_CLOCK_FREQ         : integer := 100; -- 80 or 100 are viable settings, depending on FX3 and routing.
	constant USB_FIFO_WIDTH         : integer := 16;
	constant USB_EARLY_PACKET_MS    : integer := 1; -- send a packet each X milliseconds
	constant USB_BURST_WRITE_LENGTH : integer := 8;

	constant LOGIC_CLOCK_FREQ : integer := 200; -- PLL can generate between 5 and 500 MHz here.

	constant AER_BUS_WIDTH : integer := 10;
	constant ADC_BUS_WIDTH : integer := 10;

	constant TIMESTAMP_WIDTH      : integer := 15;
	constant EVENT_WIDTH          : integer := 15;
	constant EVENT_DATA_WIDTH_MAX : integer := 12;
	constant OVERFLOW_WIDTH       : integer := EVENT_DATA_WIDTH_MAX;

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

	-- event codes
	constant EVENT_CODE_TIMESTAMP               : std_logic                                           := '1';
	constant EVENT_CODE_EVENT                   : std_logic                                           := '0';
	constant EVENT_CODE_SPECIAL                 : std_logic_vector(2 downto 0)                        := "000";
	constant EVENT_CODE_SPECIAL_TIMESTAMP_RESET : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(1, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_EXT_TRIGGER     : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(2, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_SOE         : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(3, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_EOE         : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(4, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_SORR        : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(5, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_EORR        : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(6, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_SOSR        : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(7, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_EOSR        : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(8, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_SOCOL       : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(9, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_EOCOL       : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(10, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_SOROW       : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(11, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_EOROW       : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(12, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_IMU_ACCEL       : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(13, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_IMU_GYRO        : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(14, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_IMU_COMPASS     : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(15, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_IMU_TEMP        : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(16, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_Y_ADDR                  : std_logic_vector(2 downto 0)                        := "001";
	-- The fourth bit of an X address is the polarity. It usually gets encoded directly from the AER bus input.
	constant EVENT_CODE_X_ADDR                  : std_logic_vector(1 downto 0)                        := "01";
	constant EVENT_CODE_X_ADDR_POL_OFF          : std_logic_vector(2 downto 0)                        := "010";
	constant EVENT_CODE_X_ADDR_POL_ON           : std_logic_vector(2 downto 0)                        := "011";
	constant EVENT_CODE_ADC_SAMPLE              : std_logic_vector(2 downto 0)                        := "100";
	constant EVENT_CODE_PREFIX_DATA             : std_logic_vector(2 downto 0)                        := "101";
	--constant EVENT_CODE_UNUSED		   : std_logic_vector(2 downto 0) := "110";
	constant EVENT_CODE_TIMESTAMP_WRAP          : std_logic_vector(2 downto 0)                        := "111";

	-- calculated constants
	constant USB_EARLY_PACKET_CYCLES : integer := USB_CLOCK_FREQ * 1_000 * USB_EARLY_PACKET_MS;
	constant USB_EARLY_PACKET_WIDTH  : integer := integer(ceil(log2(real(USB_EARLY_PACKET_CYCLES + 1))));

	-- number of intermediate writes to perform (including zero, so a value of 5 means 6 write cycles)
	constant USB_BURST_WRITE_CYCLES : integer := USB_BURST_WRITE_LENGTH - 3;
	constant USB_BURST_WRITE_WIDTH  : integer := integer(ceil(log2(real(USB_BURST_WRITE_CYCLES + 1))));
end Settings;
