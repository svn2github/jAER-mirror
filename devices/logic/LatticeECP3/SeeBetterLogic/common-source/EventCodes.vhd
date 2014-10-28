library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package EventCodes is
	constant FULL_EVENT_WIDTH     : integer := 16;
	constant TIMESTAMP_WIDTH      : integer := 15;
	constant EVENT_WIDTH          : integer := 15;
	constant EVENT_DATA_WIDTH_MAX : integer := 12;
	constant OVERFLOW_WIDTH       : integer := EVENT_DATA_WIDTH_MAX;

	-- event codes
	constant EVENT_CODE_TIMESTAMP                   : std_logic                                           := '1';
	constant EVENT_CODE_EVENT                       : std_logic                                           := '0';
	constant EVENT_CODE_SPECIAL                     : std_logic_vector(2 downto 0)                        := "000";
	constant EVENT_CODE_SPECIAL_TIMESTAMP_RESET     : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(1, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_EXT_TRIGGER_FALLING : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(2, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_EXT_TRIGGER_RISING  : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(3, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_EXT_TRIGGER_PULSE   : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(4, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_IMU_START6          : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(5, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_IMU_START9          : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(6, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_IMU_END             : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(7, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_STARTEXPOSURE   : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(8, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_ENDEXPOSURE     : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(9, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_STARTRESETREAD  : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(10, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_ENDRESETREAD    : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(11, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_STARTSIGNALREAD : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(12, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_ENDSIGNALREAD   : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(13, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_STARTRESETCOL   : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(14, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_STARTSIGNALCOL  : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(15, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_ENDCOL          : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(16, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_STARTFRAME      : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(17, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_ENDFRAME        : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(18, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_SPECIAL_APS_ADCOVERFLOW     : std_logic_vector(EVENT_DATA_WIDTH_MAX - 1 downto 0) := std_logic_vector(to_unsigned(19, EVENT_DATA_WIDTH_MAX));
	constant EVENT_CODE_Y_ADDR                      : std_logic_vector(2 downto 0)                        := "001";
	-- The fourth bit of an X address is the polarity. It usually gets encoded directly from the AER bus input.
	constant EVENT_CODE_X_ADDR                      : std_logic_vector(1 downto 0)                        := "01";
	constant EVENT_CODE_X_ADDR_POL_OFF              : std_logic_vector(2 downto 0)                        := "010";
	constant EVENT_CODE_X_ADDR_POL_ON               : std_logic_vector(2 downto 0)                        := "011";
	constant EVENT_CODE_ADC_SAMPLE                  : std_logic_vector(2 downto 0)                        := "100";
	constant EVENT_CODE_MISC_DATA8                  : std_logic_vector(2 downto 0)                        := "101";
	constant EVENT_CODE_MISC_DATA8_IMU              : std_logic_vector(3 downto 0)                        := "0000";
	constant EVENT_CODE_MISC_DATA8_OMC              : std_logic_vector(3 downto 0)                        := "1000"; -- OMC event 8
	constant EVENT_CODE_MISC_DATA8_BGAF             : std_logic_vector(3 downto 0)                        := "0101";
	constant EVENT_CODE_MISC_DATA8_CM               : std_logic_vector(3 downto 0)                        := "0110";
	constant EVENT_CODE_MISC_DATA8_TRACKER          : std_logic_vector(3 downto 0)                        := "0111";
	constant EVENT_CODE_MISC_DATA10                 : std_logic_vector(2 downto 0)                        := "110";
	constant EVENT_CODE_TIMESTAMP_WRAP              : std_logic_vector(2 downto 0)                        := "111";
end package EventCodes;
