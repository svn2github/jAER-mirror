library ieee;
use ieee.std_logic_1164.all;

entity DFFBusSynchronizer is
	generic (
		BUS_WIDTH : integer := 4);
	port (
		SyncClock_CI : in std_logic;
		Reset_RI	 : in std_logic;

		-- Bus to synchronize in and out.
		BusToSync_SI : in  std_logic_vector(BUS_WIDTH-1 downto 0);
		SyncedBus_SO : out std_logic_vector(BUS_WIDTH-1 downto 0));
end DFFBusSynchronizer;

architecture Behavioral of DFFBusSynchronizer is
	signal SyncBusDemetFF_S, SyncBusSyncFF_S : std_logic_vector(BUS_WIDTH-1 downto 0);
begin
	-- Output the result of the sync FF directly.
	SyncedBus_SO <= SyncBusSyncFF_S;

	-- Change state on clock edge (synchronous).
	p_synchronizing : process (SyncClock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then	-- asynchronous reset (active-high for FPGAs)
			SyncBusSyncFF_S	 <= (others => '0');
			SyncBusDemetFF_S <= (others => '0');
		elsif rising_edge(SyncClock_CI) then
			SyncBusSyncFF_S	 <= SyncBusDemetFF_S;
			SyncBusDemetFF_S <= BusToSync_SI;
		end if;
	end process p_synchronizing;
end Behavioral;
