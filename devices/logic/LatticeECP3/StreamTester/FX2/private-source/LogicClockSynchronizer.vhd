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
		SPIMOSISync_DO         : out std_logic;
		DVSAERReq_SBI          : in  std_logic;
		DVSAERReqSync_SBO      : out std_logic;
		IMUInterrupt_SI        : in  std_logic;
		IMUInterruptSync_SO    : out std_logic;
		SyncOutSwitch_SI       : in  std_logic;
		SyncOutSwitchSync_SO   : out std_logic;
		SyncInClock_CI         : in  std_logic;
		SyncInClockSync_CO     : out std_logic;
		SyncInSwitch_SI        : in  std_logic;
		SyncInSwitchSync_SO    : out std_logic;
		SyncInSignal_SI        : in  std_logic;
		SyncInSignalSync_SO    : out std_logic);
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

	syncDVSAERReq : entity work.DFFSynchronizer
		generic map(
			RESET_VALUE => true)        -- active-low signal
		port map(
			SyncClock_CI       => LogicClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => DVSAERReq_SBI,
			SyncedSignal_SO(0) => DVSAERReqSync_SBO);

	syncIMUInterrupt : entity work.DFFSynchronizer
		port map(
			SyncClock_CI       => LogicClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => IMUInterrupt_SI,
			SyncedSignal_SO(0) => IMUInterruptSync_SO);

	syncSyncOutSwitch : entity work.DFFSynchronizer
		port map(
			SyncClock_CI       => LogicClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => SyncOutSwitch_SI,
			SyncedSignal_SO(0) => SyncOutSwitchSync_SO);

	syncSyncInClock : entity work.DFFSynchronizer
		port map(
			SyncClock_CI       => LogicClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => SyncInClock_CI,
			SyncedSignal_SO(0) => SyncInClockSync_CO);

	syncSyncInSwitch : entity work.DFFSynchronizer
		port map(
			SyncClock_CI       => LogicClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => SyncInSwitch_SI,
			SyncedSignal_SO(0) => SyncInSwitchSync_SO);

	syncSyncInSignal : entity work.DFFSynchronizer
		port map(
			SyncClock_CI       => LogicClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => SyncInSignal_SI,
			SyncedSignal_SO(0) => SyncInSignalSync_SO);
end Structural;
