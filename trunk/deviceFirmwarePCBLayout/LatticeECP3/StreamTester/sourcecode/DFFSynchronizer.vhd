library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity DFFSynchronizer is
	port (
		SyncClock_CI : in std_logic;
		Reset_RBI : in std_logic;
		
		-- Signal to synchronize in and out.
		SignalToSync_SI : in std_logic;
		SyncedSignal_SO : out std_logic);
end DFFSynchronizer;

architecture Behavioral of DFFSynchronizer is
	signal SyncSignalDemetFF_S, SyncSignalSyncFF_S : std_logic;
begin
	-- Output the result of the sync FF directly.
	SyncedSignal_SO <= SyncSignalSyncFF_S;

	-- Change state on clock edge (synchronous).
	p_synchronizing : process (SyncClock_CI, Reset_RBI)
	begin
		if Reset_RBI = '0' then -- asynchronous reset (active-low)
			SyncSignalSyncFF_S <= '0';
			SyncSignalDemetFF_S <= '0';
		elsif rising_edge(SyncClock_CI) then
			SyncSignalSyncFF_S <= SyncSignalDemetFF_S;
			SyncSignalDemetFF_S <= SignalToSync_SI;
		end if;
	end process p_synchronizing;
end Behavioral;