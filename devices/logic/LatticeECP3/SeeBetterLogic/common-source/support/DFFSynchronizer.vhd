library ieee;
use ieee.std_logic_1164.all;

-- Synchronize signal to new clock domain, represented by SyncClock_CI,
-- by using two Flip-Flops in series, to avoid meta-stability problems.
entity DFFSynchronizer is
	generic(
		SIZE        : integer := 1;
		RESET_VALUE : boolean := false);
	port(
		SyncClock_CI    : in  std_logic;
		Reset_RI        : in  std_logic;

		-- Signal(s) to synchronize in and out.
		SignalToSync_SI : in  std_logic_vector(SIZE - 1 downto 0);
		SyncedSignal_SO : out std_logic_vector(SIZE - 1 downto 0));
end DFFSynchronizer;

architecture Behavioral of DFFSynchronizer is
	signal SyncSignalDemetFF_S, SyncSignalSyncFF_S : std_logic_vector(SIZE - 1 downto 0);
begin
	-- Output the result of the sync FF directly.
	SyncedSignal_SO <= SyncSignalSyncFF_S;

	-- Change state on clock edge (synchronous).
	registerUpdate : process(SyncClock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			if RESET_VALUE then
				SyncSignalSyncFF_S  <= (others => '1');
				SyncSignalDemetFF_S <= (others => '1');
			else
				SyncSignalSyncFF_S  <= (others => '0');
				SyncSignalDemetFF_S <= (others => '0');
			end if;
		elsif rising_edge(SyncClock_CI) then
			SyncSignalSyncFF_S  <= SyncSignalDemetFF_S;
			SyncSignalDemetFF_S <= SignalToSync_SI;
		end if;
	end process registerUpdate;
end Behavioral;
