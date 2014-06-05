library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Implement a Reset Synchronizer to synchronize the external asynchronous reset
-- with a given clock domain. This is important to avoid problems at asynchronous
-- reset deassertion. See the "Asynchronous & Synchronous Reset" paper by C. Cummings,
-- D. Mills and S. Golson (2003), as well as the following article on active-high resets
-- and synchronization: http://www.eetimes.com/document.asp?doc_id=1278998
entity ResetSynchronizer is
	port (
		ExtClock_CI : in std_logic;
		ExtReset_RI : in std_logic;
		SyncReset_RO : out std_logic);
end ResetSynchronizer;

architecture Behavioral of ResetSynchronizer is
	signal SyncSignalDemetFF_S, SyncSignalSyncFF_S : std_logic;
begin
	-- Output the result of the sync FF directly.
	SyncReset_RO <= SyncSignalSyncFF_S;

	-- Change state on clock edge (synchronous).
	p_synchronizing : process (ExtClock_CI, ExtReset_RI)
	begin
		if ExtReset_RI = '1' then -- asynchronous set (active-high for FPGAs)
			SyncSignalSyncFF_S <= '1';
			SyncSignalDemetFF_S <= '1';
		elsif rising_edge(ExtClock_CI) then
			SyncSignalSyncFF_S <= SyncSignalDemetFF_S;
			SyncSignalDemetFF_S <= '0';
		end if;
	end process p_synchronizing;
end Behavioral;
