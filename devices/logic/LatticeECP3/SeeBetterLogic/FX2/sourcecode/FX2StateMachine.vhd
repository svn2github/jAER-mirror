library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.Settings.all;

entity FX2Statemachine is
	port (
		Clock_CI : in std_logic;
		Reset_RI : in std_logic;

		-- USB FIFO flags
		USBFifoEP6Full_SI		: in std_logic;
		USBFifoEP6AlmostFull_SI : in std_logic;

		-- USB FIFO control lines
		USBFifoWrite_SBO  : out std_logic;
		USBFifoPktEnd_SBO : out std_logic;

		-- Input FIFO flags
		InFifoEmpty_SI		 : in std_logic;
		InFifoAlmostEmpty_SI : in std_logic;

		-- Input FIFO control lines
		InFifoRead_SO : out std_logic);
end FX2Statemachine;

architecture Behavioral of FX2Statemachine is
	component ContinuousCounter is
		generic (
			COUNTER_WIDTH	  : integer := 16;
			RESET_ON_OVERFLOW : boolean := true;
			SHORT_OVERFLOW	  : boolean := false;
			OVERFLOW_AT_ZERO  : boolean := false);
		port (
			Clock_CI	 : in  std_logic;
			Reset_RI	 : in  std_logic;
			Clear_SI	 : in  std_logic;
			Enable_SI	 : in  std_logic;
			DataLimit_DI : in  unsigned(COUNTER_WIDTH-1 downto 0);
			Overflow_SO	 : out std_logic;
			Data_DO		 : out unsigned(COUNTER_WIDTH-1 downto 0));
	end component ContinuousCounter;

	type state is (stFullFlagWait1, stFullFlagWait2, stIdle, stPrepareEarlyPacket, stEarlyPacket, stPrepareWrite, stWriteFirst, stWriteMiddle, stWriteLast, stPrepareSwitch, stSwitch);

	attribute syn_enum_encoding			 : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

	-- write burst counter
	signal CyclesCount_S, CyclesNotify_S : std_logic;

	-- early packet counter, to keep a certain flow of USB traffic going even in the case of low event rates
	signal EarlyPacketClear_S, EarlyPacketNotify_S : std_logic;

	-- register outputs for better behavior
	signal USBFifoWriteReg_SB, USBFifoPktEndReg_SB : std_logic;
begin
	writeCyclesCounter : ContinuousCounter
		generic map (
			COUNTER_WIDTH => USB_BURST_WRITE_WIDTH)
		port map (
			Clock_CI	 => Clock_CI,
			Reset_RI	 => Reset_RI,
			Clear_SI	 => '0',
			Enable_SI	 => CyclesCount_S,
			DataLimit_DI => to_unsigned(USB_BURST_WRITE_CYCLES, USB_BURST_WRITE_WIDTH),
			Overflow_SO	 => CyclesNotify_S,
			Data_DO		 => open);

	earlyPacketCounter : ContinuousCounter
		generic map (
			COUNTER_WIDTH	  => USB_EARLY_PACKET_WIDTH,
			RESET_ON_OVERFLOW => false)
		port map (
			Clock_CI	 => Clock_CI,
			Reset_RI	 => Reset_RI,
			Clear_SI	 => EarlyPacketClear_S,
			Enable_SI	 => '1',
			DataLimit_DI => to_unsigned(USB_EARLY_PACKET_CYCLES, USB_EARLY_PACKET_WIDTH),
			Overflow_SO	 => EarlyPacketNotify_S,
			Data_DO		 => open);

	p_memoryless : process (State_DP, CyclesNotify_S, EarlyPacketNotify_S, USBFifoEP6Full_SI, USBFifoEP6AlmostFull_SI, InFifoAlmostEmpty_SI)
	begin
		State_DN <= State_DP;			-- Keep current state by default.

		CyclesCount_S <= '0';  -- Do not count up in the write-cycles counter.

		EarlyPacketClear_S <= '0';	-- Do not clear the early packet counter.

		USBFifoWriteReg_SB	<= '1';
		USBFifoPktEndReg_SB <= '1';

		InFifoRead_SO <= '0';  -- Don't read from input FIFO until we know we can write.

		case State_DP is
			-- We wait for two clock cycles here, to leave time for the EP6Full
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
				if USBFifoEP6Full_SI = '0' then
					if EarlyPacketNotify_S = '1' then
						State_DN <= stPrepareEarlyPacket;
					elsif InFifoAlmostEmpty_SI = '0' then
						State_DN <= stPrepareWrite;
					end if;
				end if;

			when stPrepareEarlyPacket =>
				State_DN			<= stEarlyPacket;
				USBFifoPktEndReg_SB <= '0';

			when stEarlyPacket =>
				State_DN		   <= stFullFlagWait1;
				EarlyPacketClear_S <= '1';

			when stPrepareWrite =>
				State_DN		   <= stWriteFirst;
				InFifoRead_SO	   <= '1';
				USBFifoWriteReg_SB <= '0';

			when stWriteFirst =>
				if USBFifoEP6AlmostFull_SI = '1' then
					State_DN <= stPrepareSwitch;
				else
					State_DN <= stWriteMiddle;
				end if;

				InFifoRead_SO	   <= '1';
				USBFifoWriteReg_SB <= '0';

			when stWriteMiddle =>
				if CyclesNotify_S = '1' then
					State_DN <= stWriteLast;
				end if;

				CyclesCount_S <= '1';

				InFifoRead_SO	   <= '1';
				USBFifoWriteReg_SB <= '0';

			when stWriteLast =>
				if InFifoAlmostEmpty_SI = '1' then
					State_DN <= stIdle;
				else
					State_DN		   <= stWriteFirst;
					InFifoRead_SO	   <= '1';
					USBFifoWriteReg_SB <= '0';
				end if;

			when stPrepareSwitch =>
				if CyclesNotify_S = '1' then
					State_DN <= stSwitch;
				end if;

				CyclesCount_S <= '1';

				InFifoRead_SO	   <= '1';
				USBFifoWriteReg_SB <= '0';

			when stSwitch =>
				State_DN		   <= stFullFlagWait1;
				EarlyPacketClear_S <= '1';

			when others => null;
		end case;
	end process p_memoryless;

	-- Change state on clock edge (synchronous).
	p_memoryzing : process (Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then	-- asynchronous reset (active-high for FPGAs)
			State_DP		  <= stIdle;
			USBFifoWrite_SBO  <= '1';
			USBFifoPktEnd_SBO <= '1';
		elsif rising_edge(Clock_CI) then
			State_DP		  <= State_DN;
			USBFifoWrite_SBO  <= USBFifoWriteReg_SB;
			USBFifoPktEnd_SBO <= USBFifoPktEndReg_SB;
		end if;
	end process p_memoryzing;
end Behavioral;
