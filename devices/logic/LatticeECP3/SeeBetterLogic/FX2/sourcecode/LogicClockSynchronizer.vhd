library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity LogicClockSynchronizer is
	port (
		LogicClock_CI : in	std_logic;
		Reset_RI	  : in	std_logic;
		ResetSync_RO  : out std_logic;

		-- Signals to synchronize and their synchronized counterparts.
		LogicRun_SI			 : in  std_logic;
		LogicRunSync_SO		 : out std_logic;
		DVSRun_SI			 : in  std_logic;
		DVSRunSync_SO		 : out std_logic;
		APSRun_SI			 : in  std_logic;
		APSRunSync_SO		 : out std_logic;
		IMURun_SI			 : in  std_logic;
		IMURunSync_SO		 : out std_logic;
		DVSAERReq_SBI		 : in  std_logic;
		DVSAERReqSync_SBO	 : out std_logic;
		IMUInterrupt_SI		 : in  std_logic;
		IMUInterruptSync_SO	 : out std_logic;
		SyncOutSwitch_SI	 : in  std_logic;
		SyncOutSwitchSync_SO : out std_logic;
		SyncInClock_CI		 : in  std_logic;
		SyncInClockSync_CO	 : out std_logic;
		SyncInSwitch_SI		 : in  std_logic;
		SyncInSwitchSync_SO	 : out std_logic;
		SyncInSignal_SI		 : in  std_logic;
		SyncInSignalSync_SO	 : out std_logic);
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
	syncLogicRun : DFFSynchronizer
		port map (
			SyncClock_CI	=> LogicClock_CI,
			Reset_RI		=> ResetSync_R,
			SignalToSync_SI => LogicRun_SI,
			SyncedSignal_SO => LogicRunSync_SO);

	syncDVSRun : DFFSynchronizer
		port map (
			SyncClock_CI	=> LogicClock_CI,
			Reset_RI		=> ResetSync_R,
			SignalToSync_SI => DVSRun_SI,
			SyncedSignal_SO => DVSRunSync_SO);

	syncAPSRun : DFFSynchronizer
		port map (
			SyncClock_CI	=> LogicClock_CI,
			Reset_RI		=> ResetSync_R,
			SignalToSync_SI => APSRun_SI,
			SyncedSignal_SO => APSRunSync_SO);

	syncIMURun : DFFSynchronizer
		port map (
			SyncClock_CI	=> LogicClock_CI,
			Reset_RI		=> ResetSync_R,
			SignalToSync_SI => IMURun_SI,
			SyncedSignal_SO => IMURunSync_SO);

	syncDVSAERReq : DFFSynchronizer
		port map (
			SyncClock_CI	=> LogicClock_CI,
			Reset_RI		=> ResetSync_R,
			SignalToSync_SI => DVSAERReq_SBI,
			SyncedSignal_SO => DVSAERReqSync_SBO);

	syncIMUInterrupt : DFFSynchronizer
		port map (
			SyncClock_CI	=> LogicClock_CI,
			Reset_RI		=> ResetSync_R,
			SignalToSync_SI => IMUInterrupt_SI,
			SyncedSignal_SO => IMUInterruptSync_SO);

	syncSyncOutSwitch : DFFSynchronizer
		port map (
			SyncClock_CI	=> LogicClock_CI,
			Reset_RI		=> ResetSync_R,
			SignalToSync_SI => SyncOutSwitch_SI,
			SyncedSignal_SO => SyncOutSwitchSync_SO);

	syncSyncInClock : DFFSynchronizer
		port map (
			SyncClock_CI	=> LogicClock_CI,
			Reset_RI		=> ResetSync_R,
			SignalToSync_SI => SyncInClock_CI,
			SyncedSignal_SO => SyncInClockSync_CO);

	syncSyncInSwitch : DFFSynchronizer
		port map (
			SyncClock_CI	=> LogicClock_CI,
			Reset_RI		=> ResetSync_R,
			SignalToSync_SI => SyncInSwitch_SI,
			SyncedSignal_SO => SyncInSwitchSync_SO);

	syncSyncInSignal : DFFSynchronizer
		port map (
			SyncClock_CI	=> LogicClock_CI,
			Reset_RI		=> ResetSync_R,
			SignalToSync_SI => SyncInSignal_SI,
			SyncedSignal_SO => SyncInSignalSync_SO);
end Structural;
