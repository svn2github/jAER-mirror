library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity FX2USBClockSynchronizer is
	port (
		USBClock_CI	 : in  std_logic;
		Reset_RI	 : in  std_logic;
		ResetSync_RO : out std_logic;

		-- Signals to synchronize and their synchronized counterparts.
		USBFifoFullFlag_SI			   : in	 std_logic;
		USBFifoFullFlagSync_SO		   : out std_logic;
		USBFifoProgrammableFlag_SI	   : in	 std_logic;
		USBFifoProgrammableFlagSync_SO : out std_logic);
end FX2USBClockSynchronizer;

architecture Structural of FX2USBClockSynchronizer is
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
	-- Synchronize the reset signal to the USB clock for that clock domain.
	ResetSync_RO <= ResetSync_R;

	syncReset : ResetSynchronizer
		port map (
			ExtClock_CI	 => USBClock_CI,
			ExtReset_RI	 => Reset_RI,
			SyncReset_RO => ResetSync_R);

	-- Ensure synchronization of FX2 inputs related to GPIF FIFO.
	syncUSBFifoFullFlag : DFFSynchronizer
		port map (
			SyncClock_CI	=> USBClock_CI,
			Reset_RI		=> ResetSync_R,
			SignalToSync_SI => USBFifoFullFlag_SI,
			SyncedSignal_SO => USBFifoFullFlagSync_SO);

	syncUSBFifoProgrammableFlag : DFFSynchronizer
		port map (
			SyncClock_CI	=> USBClock_CI,
			Reset_RI		=> ResetSync_R,
			SignalToSync_SI => USBFifoProgrammableFlag_SI,
			SyncedSignal_SO => USBFifoProgrammableFlagSync_SO);
end Structural;
