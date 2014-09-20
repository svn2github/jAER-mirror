library ieee;
use ieee.std_logic_1164.all;

entity LogicClockSynchronizer is
	port(
		LogicClock_CI          : in  std_logic;
		Reset_RI               : in  std_logic;
		ResetSync_RO           : out std_logic;

		-- Signals to synchronize and their synchronized counterparts.
		SPISlaveSelect_SBI     : in  std_logic;
		SPISlaveSelectSync_SBO : out std_logic;
		SPIClock_CI            : in  std_logic;
		SPIClockSync_CO        : out std_logic;
		SPIMOSI_DI             : in  std_logic;
		SPIMOSISync_DO         : out std_logic);
end LogicClockSynchronizer;

architecture Structural of LogicClockSynchronizer is
	signal ResetSync_R : std_logic;
begin
	-- Synchronize the reset signal to the logic clock for that clock domain.
	ResetSync_RO <= ResetSync_R;

	syncReset : entity work.ResetSynchronizer
		port map(
			ExtClock_CI  => LogicClock_CI,
			ExtReset_RI  => Reset_RI,
			SyncReset_RO => ResetSync_R);

	-- Ensure synchronization of FX2 inputs related to logic control.
	syncSPISlaveSelect : entity work.DFFSynchronizer
		generic map(
			RESET_VALUE => true)        -- active-low signal
		port map(
			SyncClock_CI       => LogicClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => SPISlaveSelect_SBI,
			SyncedSignal_SO(0) => SPISlaveSelectSync_SBO);

	syncSPIClock : entity work.DFFSynchronizer
		port map(
			SyncClock_CI       => LogicClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => SPIClock_CI,
			SyncedSignal_SO(0) => SPIClockSync_CO);

	syncSPIMOSI : entity work.DFFSynchronizer
		port map(
			SyncClock_CI       => LogicClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => SPIMOSI_DI,
			SyncedSignal_SO(0) => SPIMOSISync_DO);
end Structural;
