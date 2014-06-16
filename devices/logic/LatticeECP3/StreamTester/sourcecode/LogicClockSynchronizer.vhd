library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity LogicClockSynchronizer is
	port (
		LogicClock_CI : in	std_logic;
		Reset_RI	  : in	std_logic;
		ResetSync_RO  : out std_logic;

		-- Signals to synchronize and their synchronized counterparts.
		FPGARun_SI	   : in	 std_logic;
		FPGARunSync_SO : out std_logic);
end LogicClockSynchronizer;

architecture Structural of LogicClockSynchronizer is
	component ResetSynchronizer is
		port (
			ExtClock_CI	 : in  std_logic;
			ExtReset_RI	 : in  std_logic;
			SyncReset_RO : out std_logic);
	end component ResetSynchronizer;

	component DFFSynchronizer is
		port (
			SyncClock_CI	: in  std_logic;
			Reset_RI		: in  std_logic;
			SignalToSync_SI : in  std_logic;
			SyncedSignal_SO : out std_logic);
	end component DFFSynchronizer;

	signal ResetSync_R : std_logic;
begin
	-- Synchronize the reset signal to the logic clock for that clock domain.
	ResetSync_RO <= ResetSync_R;

	syncReset : ResetSynchronizer
		port map (
			ExtClock_CI	 => LogicClock_CI,
			ExtReset_RI	 => Reset_RI,
			SyncReset_RO => ResetSync_R);

	-- Ensure synchronization of FX3 inputs related to logic control.
	syncFPGARun : DFFSynchronizer
		port map (
			SyncClock_CI	=> LogicClock_CI,
			Reset_RI		=> ResetSync_R,
			SignalToSync_SI => FPGARun_SI,
			SyncedSignal_SO => FPGARunSync_SO);
end Structural;
