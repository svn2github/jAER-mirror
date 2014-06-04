library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity USBClockSynchronizer is
	port (
		USBClock_CI : in std_logic;
		Reset_RI : in std_logic;
		ResetSync_RO : out std_logic;

		-- Signals to synchronize and their synchronized counterparts.
		USBFifoThr0Ready_SI : in std_logic;
		USBFifoThr0ReadySync_SO : out std_logic;
		USBFifoThr0Watermark_SI : in std_logic;
		USBFifoThr0WatermarkSync_SO : out std_logic;
		USBFifoThr1Ready_SI : in std_logic;
		USBFifoThr1ReadySync_SO : out std_logic;
		USBFifoThr1Watermark_SI : in std_logic;
		USBFifoThr1WatermarkSync_SO : out std_logic);
end USBClockSynchronizer;

architecture Structural of USBClockSynchronizer is
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
	-- Synchronize the reset signal to the USB clock for that clock domain.
	ResetSync_RO <= ResetSync_R;

	syncReset : ResetSynchronizer
	port map (
		ExtClock_CI => USBClock_CI,
		ExtReset_RI => Reset_RI,
		SyncReset_RO => ResetSync_R);

	-- Ensure synchronization of FX3 inputs related to GPIF FIFO.
	syncUSBFifoThr0Ready : DFFSynchronizer
	port map (
		SyncClock_CI => USBClock_CI,
		Reset_RI => ResetSync_R,
		SignalToSync_SI => USBFifoThr0Ready_SI,
		SyncedSignal_SO => USBFifoThr0ReadySync_SO);

	syncUSBFifoThr0Watermark : DFFSynchronizer
	port map (
		SyncClock_CI => USBClock_CI,
		Reset_RI => ResetSync_R,
		SignalToSync_SI => USBFifoThr0Watermark_SI,
		SyncedSignal_SO => USBFifoThr0WatermarkSync_SO);

	syncUSBFifoThr1Ready : DFFSynchronizer
	port map (
		SyncClock_CI => USBClock_CI,
		Reset_RI => ResetSync_R,
		SignalToSync_SI => USBFifoThr1Ready_SI,
		SyncedSignal_SO => USBFifoThr1ReadySync_SO);

	syncUSBFifoThr1Watermark : DFFSynchronizer
	port map (
		SyncClock_CI => USBClock_CI,
		Reset_RI => ResetSync_R,
		SignalToSync_SI => USBFifoThr1Watermark_SI,
		SyncedSignal_SO => USBFifoThr1WatermarkSync_SO);
end Structural;
