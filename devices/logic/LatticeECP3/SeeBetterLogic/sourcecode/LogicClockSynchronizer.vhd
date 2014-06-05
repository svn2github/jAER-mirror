library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity LogicClockSynchronizer is
	port (
		LogicClock_CI : in std_logic;
		Reset_RI : in std_logic;
		ResetSync_RO : out std_logic;

		-- Signals to synchronize and their synchronized counterparts.
		FPGARun_SI : in std_logic;
		FPGARunSync_SO : out std_logic;
		DVSRun_SI : in std_logic;
		DVSRunSync_SO : out std_logic;
		ADCRun_SI : in std_logic;
		ADCRunSync_SO : out std_logic;
		IMURun_SI : in std_logic;
		IMURunSync_SO : out std_logic;
		FPGATimestampReset_SI : in std_logic;
		FPGATimestampResetSync_SO : out std_logic;
		DVSAERReq_SBI : in std_logic;
		DVSAERReqSync_SBO : out std_logic;
		IMUInterrupt_SI : in std_logic;
		IMUInterruptSync_SO : out std_logic);
end LogicClockSynchronizer;

architecture Structural of LogicClockSynchronizer is
	component ResetSynchronizer
	port (
		ExtClock_CI : in std_logic;
		ExtReset_RI : in std_logic;
		SyncReset_RO : out std_logic);
	end component;

	component DFFSynchronizer
	port (
		SyncClock_CI : in std_logic;
		Reset_RI : in std_logic;
		SignalToSync_SI : in std_logic;
		SyncedSignal_SO : out std_logic);
	end component;

	signal ResetSync_R : std_logic;
begin
	-- Synchronize the reset signal to the logic clock for that clock domain.
	ResetSync_RO <= ResetSync_R;

	syncReset : ResetSynchronizer
	port map (
		ExtClock_CI => LogicClock_CI,
		ExtReset_RI => Reset_RI,
		SyncReset_RO => ResetSync_R);

	-- Ensure synchronization of FX3 inputs related to logic control.
	syncFPGARun : DFFSynchronizer
	port map (
		SyncClock_CI => LogicClock_CI,
		Reset_RI => ResetSync_R,
		SignalToSync_SI => FPGARun_SI,
		SyncedSignal_SO => FPGARunSync_SO);

	syncDVSRun : DFFSynchronizer
	port map (
		SyncClock_CI => LogicClock_CI,
		Reset_RI => ResetSync_R,
		SignalToSync_SI => DVSRun_SI,
		SyncedSignal_SO => DVSRunSync_SO);

	syncADCRun : DFFSynchronizer
	port map (
		SyncClock_CI => LogicClock_CI,
		Reset_RI => ResetSync_R,
		SignalToSync_SI => ADCRun_SI,
		SyncedSignal_SO => ADCRunSync_SO);

	syncIMURun : DFFSynchronizer
	port map (
		SyncClock_CI => LogicClock_CI,
		Reset_RI => ResetSync_R,
		SignalToSync_SI => IMURun_SI,
		SyncedSignal_SO => IMURunSync_SO);

	syncFPGATimestampReset : DFFSynchronizer
	port map (
		SyncClock_CI => LogicClock_CI,
		Reset_RI => ResetSync_R,
		SignalToSync_SI => FPGATimestampReset_SI,
		SyncedSignal_SO => FPGATimestampResetSync_SO);

	syncDVSAERReq : DFFSynchronizer
	port map (
		SyncClock_CI => LogicClock_CI,
		Reset_RI => ResetSync_R,
		SignalToSync_SI => DVSAERReq_SBI,
		SyncedSignal_SO => DVSAERReqSync_SBO);

	syncIMUInterrupt : DFFSynchronizer
	port map (
		SyncClock_CI => LogicClock_CI,
		Reset_RI => ResetSync_R,
		SignalToSync_SI => IMUInterrupt_SI,
		SyncedSignal_SO => IMUInterruptSync_SO);
end Structural;
