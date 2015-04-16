library ieee;
use ieee.std_logic_1164.all;

entity FX3USBClockSynchronizer is
	port(
		USBClock_CI                 : in  std_logic;
		Reset_RI                    : in  std_logic;
		ResetSync_RO                : out std_logic;

		-- Signals to synchronize and their synchronized counterparts.
		USBFifoThr0Ready_SI         : in  std_logic;
		USBFifoThr0ReadySync_SO     : out std_logic;
		USBFifoThr0Watermark_SI     : in  std_logic;
		USBFifoThr0WatermarkSync_SO : out std_logic;
		USBFifoThr1Ready_SI         : in  std_logic;
		USBFifoThr1ReadySync_SO     : out std_logic;
		USBFifoThr1Watermark_SI     : in  std_logic;
		USBFifoThr1WatermarkSync_SO : out std_logic);
end FX3USBClockSynchronizer;

architecture Structural of FX3USBClockSynchronizer is
	signal ResetSync_R : std_logic;
begin
	-- Synchronize the reset signal to the USB clock for that clock domain.
	ResetSync_RO <= ResetSync_R;

	syncReset : entity work.ResetSynchronizer
		port map(
			ExtClock_CI  => USBClock_CI,
			ExtReset_RI  => Reset_RI,
			SyncReset_RO => ResetSync_R);

	-- Ensure synchronization of FX3 inputs related to GPIF FIFO.
	syncUSBFifoThr0Ready : entity work.DFFSynchronizer
		port map(
			SyncClock_CI       => USBClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => USBFifoThr0Ready_SI,
			SyncedSignal_SO(0) => USBFifoThr0ReadySync_SO);

	syncUSBFifoThr0Watermark : entity work.DFFSynchronizer
		port map(
			SyncClock_CI       => USBClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => USBFifoThr0Watermark_SI,
			SyncedSignal_SO(0) => USBFifoThr0WatermarkSync_SO);

	syncUSBFifoThr1Ready : entity work.DFFSynchronizer
		port map(
			SyncClock_CI       => USBClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => USBFifoThr1Ready_SI,
			SyncedSignal_SO(0) => USBFifoThr1ReadySync_SO);

	syncUSBFifoThr1Watermark : entity work.DFFSynchronizer
		port map(
			SyncClock_CI       => USBClock_CI,
			Reset_RI           => ResetSync_R,
			SignalToSync_SI(0) => USBFifoThr1Watermark_SI,
			SyncedSignal_SO(0) => USBFifoThr1WatermarkSync_SO);
end Structural;
