library ieee;
use ieee.std_logic_1164.all;

-- Watch one or more signals for any change on them between consecutive
-- clock cycles. If a change is detected, a signal is emitted on the
-- next clock cycle and kept acthive-high, until it is acknowledged by
-- the listener by pusling ChangeAcknowledged_SI. This works the same as
-- a BufferClear, please see its documentation for additional details.
entity ChangeDetector is
	generic(
		SIZE : integer);
	port(
		Clock_CI              : in  std_logic;
		Reset_RI              : in  std_logic;

		-- Input on which to detect changes.
		InputData_DI          : in  std_logic_vector(SIZE - 1 downto 0);

		-- Detection and its ACK.
		ChangeDetected_SO     : out std_logic;
		ChangeAcknowledged_SI : in  std_logic);
end entity ChangeDetector;

architecture Behavioral of ChangeDetector is
	signal PreviousData_DP, PreviousData_DN : std_logic_vector(SIZE - 1 downto 0);
	signal ChangeDetected_S                 : std_logic;
begin
	bufferChangeDetectedSignal : entity work.BufferClear
		port map(
			Clock_CI        => Clock_CI,
			Reset_RI        => Reset_RI,
			Clear_SI        => ChangeAcknowledged_SI,
			InputSignal_SI  => ChangeDetected_S,
			OutputSignal_SO => ChangeDetected_SO);

	detectChange : process(PreviousData_DP, InputData_DI)
	begin
		PreviousData_DN <= InputData_DI;

		if InputData_DI = PreviousData_DP then
			ChangeDetected_S <= '0';
		else
			ChangeDetected_S <= '1';
		end if;
	end process detectChange;

	registerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then
			PreviousData_DP <= (others => '0');
		elsif rising_edge(Clock_CI) then
			PreviousData_DP <= PreviousData_DN;
		end if;
	end process registerUpdate;
end architecture Behavioral;
