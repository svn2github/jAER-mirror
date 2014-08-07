library ieee;
use ieee.std_logic_1164.all;

entity FX2USBClockSynchronizer is
	port(
		USBClock_CI                    : in  std_logic;
		Reset_RI                       : in  std_logic;
		ResetSync_RO                   : out std_logic;

		-- Signals to synchronize and their synchronized counterparts.
		USBFifoFullFlag_SI             : in  std_logic;
		USBFifoFullFlagSync_SO         : out std_logic;
		USBFifoProgrammableFlag_SI     : in  std_logic;
		USBFifoProgrammableFlagSync_SO : out std_logic);
end FX2USBClockSynchronizer;

architecture Structural of FX2USBClockSynchronizer is
	signal ResetSync_R : std_logic;
begin
	-- Synchronize the reset signal to the USB clock for that clock domain.
	ResetSync_RO <= ResetSync_R;

	syncReset : entity work.ResetSynchronizer
		port map(
			ExtClock_CI  => USBClock_CI,
			ExtReset_RI  => Reset_RI,
			SyncReset_RO => ResetSync_R);

	-- Ensure synchronization of FX2 inputs related to GPIF FIFO.
	syncUSBFifoFullFlag : entity work.DFFSynchronizer
		port map(
			SyncClock_CI       => USBClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => USBFifoFullFlag_SI,
			SyncedSignal_SO(0) => USBFifoFullFlagSync_SO);

	syncUSBFifoProgrammableFlag : entity work.DFFSynchronizer
		port map(
			SyncClock_CI       => USBClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => USBFifoProgrammableFlag_SI,
			SyncedSignal_SO(0) => USBFifoProgrammableFlagSync_SO);
end Structural;
