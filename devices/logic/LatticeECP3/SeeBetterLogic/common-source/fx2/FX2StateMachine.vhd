library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use work.Settings.USB_CLOCK_FREQ;
use work.Settings.USB_BURST_WRITE_LENGTH;
use work.FIFORecords.all;
use work.FX2ConfigRecords.all;

entity FX2Statemachine is
	port(
		Clock_CI                : in  std_logic;
		Reset_RI                : in  std_logic;

		-- USB FIFO flags
		USBFifoEP2Full_SI       : in  std_logic;
		USBFifoEP2AlmostFull_SI : in  std_logic;

		-- USB FIFO control lines
		USBFifoWrite_SBO        : out std_logic;
		USBFifoPktEnd_SBO       : out std_logic;

		-- Input FIFO (from Multiplexer)
		InFifoControl_SI        : in  tFromFifoReadSide;
		InFifoControl_SO        : out tToFifoReadSide;

		-- Signal when really running or not (used for upstream FIFO resets).
		FX2Running_SO           : out std_logic;

		-- Configuration input
		FX2Config_DI            : in  tFX2Config);
end FX2Statemachine;

architecture Behavioral of FX2Statemachine is
	attribute syn_enum_encoding : string;

	type tState is (stFullFlagWait1, stFullFlagWait2, stIdle, stPrepareEarlyPacket, stEarlyPacket, stSwitchEarlyPacket, stPrepareWrite, stWriteFirst, stWriteMiddle, stWriteLast, stPrepareSwitch, stSwitch);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : tState;

	-- calculated constants
	constant USB_EARLY_PACKET_CYCLES       : integer := USB_CLOCK_FREQ * 125; -- 125 microsecond steps, as per USB specification.
	constant USB_EARLY_PACKET_CYCLES_WIDTH : integer := integer(ceil(log2(real(USB_EARLY_PACKET_CYCLES + 1))));
	constant USB_EARLY_PACKET_WIDTH        : integer := USB_EARLY_PACKET_CYCLES_WIDTH + tFX2Config.EarlyPacketDelay_D'length;

	-- number of intermediate writes to perform
	constant USB_BURST_WRITE_CYCLES : integer := USB_BURST_WRITE_LENGTH - 2;
	constant USB_BURST_WRITE_WIDTH  : integer := integer(ceil(log2(real(USB_BURST_WRITE_CYCLES))));

	-- write burst counter
	signal CyclesCount_S, CyclesNotify_S : std_logic;

	-- early packet counter, to keep a certain flow of USB traffic going even in the case of low event rates
	signal EarlyPacketClear_S, EarlyPacketNotify_S : std_logic;
	signal EarlyPacketCyclesLimit_D                : unsigned(USB_EARLY_PACKET_WIDTH - 1 downto 0);

	-- register outputs for better behavior
	signal USBFifoWriteReg_SB, USBFifoPktEndReg_SB : std_logic;
	signal FX2RunningReg_S                         : std_logic;

	-- Double register configuration input, since it comes from a different clock domain (LogicClock), it
	-- needs to go through a double-flip-flop synchronizer to guarantee correctness.
	signal FX2ConfigSyncReg_D, FX2ConfigReg_D : tFX2Config;
begin
	writeCyclesCounter : entity work.ContinuousCounter
		generic map(
			SIZE => USB_BURST_WRITE_WIDTH)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => CyclesCount_S,
			DataLimit_DI => to_unsigned(USB_BURST_WRITE_CYCLES - 1, USB_BURST_WRITE_WIDTH),
			Overflow_SO  => CyclesNotify_S,
			Data_DO      => open);

	EarlyPacketCyclesLimit_D <= FX2ConfigReg_D.EarlyPacketDelay_D * to_unsigned(USB_EARLY_PACKET_CYCLES, USB_EARLY_PACKET_CYCLES_WIDTH);

	earlyPacketCounter : entity work.ContinuousCounter
		generic map(
			SIZE              => USB_EARLY_PACKET_WIDTH,
			RESET_ON_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => EarlyPacketClear_S,
			Enable_SI    => '1',
			DataLimit_DI => EarlyPacketCyclesLimit_D,
			Overflow_SO  => EarlyPacketNotify_S,
			Data_DO      => open);

	p_memoryless : process(State_DP, CyclesNotify_S, EarlyPacketNotify_S, USBFifoEP2Full_SI, USBFifoEP2AlmostFull_SI, InFifoControl_SI, FX2ConfigReg_D)
	begin
		State_DN <= State_DP;           -- Keep current state by default.

		CyclesCount_S <= '0';           -- Do not count up in the write-cycles counter.

		EarlyPacketClear_S <= '0';      -- Do not clear the early packet counter.

		USBFifoWriteReg_SB  <= '1';
		USBFifoPktEndReg_SB <= '1';

		InFifoControl_SO.Read_S <= '0'; -- Don't read from input FIFO until we know we can write.

		FX2RunningReg_S <= '1';

		case State_DP is
			-- We wait for two clock cycles here, to leave time for the EP2Full
			-- Flag to clear the USB Synchronizer (which adds a two-cycle delay).
			-- The Synchronizer is needed for safety and to meet the extremely
			-- short timing constraints of the flags. The FX3 doesn't need
			-- those supplementary states, since by switching between two
			-- threads, there is no case in which it fills a buffer and queries
			-- its state within the problematic time-frame, which on the other
			-- hand is the case for the FX2, as it does no switching.
			when stFullFlagWait1 =>
				State_DN <= stFullFlagWait2;

			when stFullFlagWait2 =>
				State_DN <= stIdle;

			when stIdle =>
				if FX2ConfigReg_D.Run_S = '1' then
					if USBFifoEP2Full_SI = '0' then
						if EarlyPacketNotify_S = '1' then
							State_DN <= stPrepareEarlyPacket;
						elsif InFifoControl_SI.AlmostEmpty_S = '0' then
							State_DN <= stPrepareWrite;
						end if;
					end if;
				else
					FX2RunningReg_S <= '0';
				end if;

			when stPrepareEarlyPacket =>
				State_DN <= stEarlyPacket;

				-- If available, read one element more and then send off the short packet.
				-- This also ensures the FIFO is drained over time at system shutdown.
				if InFifoControl_SI.Empty_S = '0' then
					InFifoControl_SO.Read_S <= '1';
					USBFifoWriteReg_SB      <= '0';
				end if;

			when stEarlyPacket =>
				State_DN            <= stSwitchEarlyPacket;
				USBFifoPktEndReg_SB <= '0';

			when stSwitchEarlyPacket =>
				State_DN           <= stFullFlagWait1;
				EarlyPacketClear_S <= '1';

			when stPrepareWrite =>
				State_DN                <= stWriteFirst;
				InFifoControl_SO.Read_S <= '1';
				USBFifoWriteReg_SB      <= '0';

			when stWriteFirst =>
				if USBFifoEP2AlmostFull_SI = '1' then
					State_DN <= stPrepareSwitch;
				else
					State_DN <= stWriteMiddle;
				end if;

				InFifoControl_SO.Read_S <= '1';
				USBFifoWriteReg_SB      <= '0';

			when stWriteMiddle =>
				if CyclesNotify_S = '1' then
					State_DN <= stWriteLast;
				end if;

				CyclesCount_S <= '1';

				InFifoControl_SO.Read_S <= '1';
				USBFifoWriteReg_SB      <= '0';

			when stWriteLast =>
				if InFifoControl_SI.AlmostEmpty_S = '1' then
					State_DN <= stIdle;
				else
					State_DN                <= stWriteFirst;
					InFifoControl_SO.Read_S <= '1';
					USBFifoWriteReg_SB      <= '0';
				end if;

			when stPrepareSwitch =>
				if CyclesNotify_S = '1' then
					State_DN <= stSwitch;
				end if;

				CyclesCount_S <= '1';

				InFifoControl_SO.Read_S <= '1';
				USBFifoWriteReg_SB      <= '0';

			when stSwitch =>
				State_DN           <= stFullFlagWait1;
				EarlyPacketClear_S <= '1';

			when others => null;
		end case;
	end process p_memoryless;

	-- Change state on clock edge (synchronous).
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP          <= stIdle;
			USBFifoWrite_SBO  <= '1';
			USBFifoPktEnd_SBO <= '1';

			FX2Running_SO <= tFX2ConfigDefault.Run_S;

			-- USB config from another clock domain.
			FX2ConfigReg_D     <= tFX2ConfigDefault;
			FX2ConfigSyncReg_D <= tFX2ConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP          <= State_DN;
			USBFifoWrite_SBO  <= USBFifoWriteReg_SB;
			USBFifoPktEnd_SBO <= USBFifoPktEndReg_SB;

			FX2Running_SO <= FX2RunningReg_S;

			-- USB config from another clock domain.
			FX2ConfigReg_D     <= FX2ConfigSyncReg_D;
			FX2ConfigSyncReg_D <= FX2Config_DI;
		end if;
	end process p_memoryzing;
end Behavioral;
