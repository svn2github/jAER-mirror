library ieee;
use ieee.std_logic_1164.all;

entity EdgeDetector is
	generic (
		SIGNAL_START_POLARITY : std_logic := '0');
	port (
		Clock_CI			   : in	 std_logic;
		Reset_RI			   : in	 std_logic;
		InputSignal_SI		   : in	 std_logic;
		-- Pulse will follow one cycle after the edge has been detected.
		RisingEdgeDetected_SO  : out std_logic;
		FallingEdgeDetected_SO : out std_logic);
end EdgeDetector;

architecture Behavioral of EdgeDetector is
	signal RisingEdgeDetectedReg_S	: std_logic;
	signal FallingEdgeDetectedReg_S : std_logic;

	signal InputSignalReg1_S, InputSignalReg2_S : std_logic;
begin
	RisingEdgeDetectedReg_S <= '1' when (InputSignalReg1_S = '1' and InputSignalReg2_S = '0') else '0';

	FallingEdgeDetectedReg_S <= '1' when (InputSignalReg1_S = '0' and InputSignalReg2_S = '1') else '0';

	-- Change state on clock edge (synchronous).
	p_memoryzing : process (Clock_CI, Reset_RI)
	begin  -- process p_memoryzing
		if Reset_RI = '1' then	-- asynchronous reset (active-high for FPGAs)
			InputSignalReg2_S <= SIGNAL_START_POLARITY;
			InputSignalReg1_S <= SIGNAL_START_POLARITY;

			RisingEdgeDetected_SO  <= '0';
			FallingEdgeDetected_SO <= '0';
		elsif rising_edge(Clock_CI) then
			InputSignalReg2_S <= InputSignalReg1_S;
			InputSignalReg1_S <= InputSignal_SI;

			RisingEdgeDetected_SO  <= RisingEdgeDetectedReg_S;
			FallingEdgeDetected_SO <= FallingEdgeDetectedReg_S;
		end if;
	end process p_memoryzing;
end Behavioral;
