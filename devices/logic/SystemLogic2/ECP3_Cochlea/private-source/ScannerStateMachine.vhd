library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use ieee.math_real."**";
use work.ShiftRegisterModes.all;
use work.Settings.LOGIC_CLOCK_FREQ;
use work.ScannerConfigRecords.all;

entity ScannerStateMachine is
	generic(
		EAR_SIZE : integer := 1);
	port(
		Clock_CI         : in  std_logic;
		Reset_RI         : in  std_logic;

		-- Scanner control I/O
		ScannerClock_CO  : out std_logic;
		ScannerBitIn_DO  : out std_logic;

		-- Configuration input
		ScannerConfig_DI : in  tScannerConfig);
end entity ScannerStateMachine;

architecture Behavioral of ScannerStateMachine is
	attribute syn_enum_encoding : string;

	type tState is (stClear, stScanOut, stIdle);
	attribute syn_enum_encoding of tState : type is "onehot";

	signal State_DP, State_DN : tState;

	constant SCANNER_REG_LENGTH : integer := integer(2.0 ** real(EAR_SIZE + tScannerConfig.ScannerChannel_D'length));

	-- Scanner clock frequency in KHz.
	constant SCANNER_CLOCK_FREQ : integer := 100;

	-- Calculated values in cycles.
	constant SCANNER_CLOCK_CYCLES : integer := LOGIC_CLOCK_FREQ * (1000 / SCANNER_CLOCK_FREQ);

	-- Calcualted length of cycles counter.
	constant WAIT_CYCLES_COUNTER_SIZE : integer := integer(ceil(log2(real(SCANNER_CLOCK_CYCLES))));

	-- Counts number of sent bits.
	constant SENT_BITS_COUNTER_SIZE : integer := integer(ceil(log2(real(SCANNER_REG_LENGTH))));

	-- Output data register (to Scanner).
	signal ScannerDataOutSRMode_S                          : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0);
	signal ScannerDataOutSRWrite_D, ScannerDataOutSRRead_D : std_logic_vector(SCANNER_REG_LENGTH - 1 downto 0);

	-- Counter for keeping track of output bits.
	signal SentBitsCounterClear_S, SentBitsCounterEnable_S : std_logic;
	signal SentBitsCounterData_D                           : unsigned(SENT_BITS_COUNTER_SIZE - 1 downto 0);

	-- Counter to introduce delays between operations, and generate the clock.
	signal WaitCyclesCounterClear_S, WaitCyclesCounterEnable_S : std_logic;
	signal WaitCyclesCounterData_D                             : unsigned(WAIT_CYCLES_COUNTER_SIZE - 1 downto 0);

	-- Detect changes in scanner configuration.
	signal EarChangeDetected_S, EarChangeAcknowledged_S         : std_logic;
	signal ChannelChangeDetected_S, ChannelChangeAcknowledged_S : std_logic;

	-- Keep track if the scanner register has been fully cleared or not.
	signal IsClear_SP, IsClear_SN : std_logic;

	-- Register outputs.
	signal ScannerClockReg_C, ScannerBitInReg_D : std_logic;

	-- Register configuration input to improve timing.
	signal ScannerConfigReg_D : tScannerConfig;
begin
	scannerDataOutShiftRegister : entity work.ShiftRegister
		generic map(
			SIZE => SCANNER_REG_LENGTH)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			Mode_SI          => ScannerDataOutSRMode_S,
			DataIn_DI        => '0',
			ParallelWrite_DI => ScannerDataOutSRWrite_D,
			ParallelRead_DO  => ScannerDataOutSRRead_D);

	waitCyclesCounter : entity work.ContinuousCounter
		generic map(
			SIZE              => WAIT_CYCLES_COUNTER_SIZE,
			GENERATE_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => WaitCyclesCounterClear_S,
			Enable_SI    => WaitCyclesCounterEnable_S,
			DataLimit_DI => (others => '1'),
			Overflow_SO  => open,
			Data_DO      => WaitCyclesCounterData_D);

	sentBitsCounter : entity work.ContinuousCounter
		generic map(
			SIZE              => SENT_BITS_COUNTER_SIZE,
			GENERATE_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => SentBitsCounterClear_S,
			Enable_SI    => SentBitsCounterEnable_S,
			DataLimit_DI => (others => '1'),
			Overflow_SO  => open,
			Data_DO      => SentBitsCounterData_D);

	detectEarChange : entity work.ChangeDetector
		generic map(
			SIZE => tScannerConfig.ScannerEar_D'length)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => std_logic_vector(ScannerConfigReg_D.ScannerEar_D),
			ChangeDetected_SO     => EarChangeDetected_S,
			ChangeAcknowledged_SI => EarChangeAcknowledged_S);

	detectChannelChange : entity work.ChangeDetector
		generic map(
			SIZE => tScannerConfig.ScannerChannel_D'length)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => std_logic_vector(ScannerConfigReg_D.ScannerChannel_D),
			ChangeDetected_SO     => ChannelChangeDetected_S,
			ChangeAcknowledged_SI => ChannelChangeAcknowledged_S);

	dacControl : process(State_DP, ScannerConfigReg_D, ScannerDataOutSRRead_D, SentBitsCounterData_D, WaitCyclesCounterData_D, ChannelChangeDetected_S, EarChangeDetected_S)
	begin
		-- Keep state by default.
		State_DN <= State_DP;

		ScannerClockReg_C <= '0';
		ScannerBitInReg_D <= '0';

		WaitCyclesCounterClear_S  <= '0';
		WaitCyclesCounterEnable_S <= '0';

		SentBitsCounterClear_S  <= '0';
		SentBitsCounterEnable_S <= '0';

		ScannerDataOutSRMode_S  <= SHIFTREGISTER_MODE_DO_NOTHING;
		ScannerDataOutSRWrite_D <= (others => '0');

		EarChangeAcknowledged_S     <= '0';
		ChannelChangeAcknowledged_S <= '0';

		IsClear_SN <= IsClear_SP;

		case State_DP is
			when stIdle =>
				if ScannerConfigReg_D.ScannerEnabled_S = '1' then
					if EarChangeDetected_S = '1' or ChannelChangeDetected_S = '1' then
						EarChangeAcknowledged_S     <= '1';
						ChannelChangeAcknowledged_S <= '1';

						IsClear_SN <= '0';

						-- Set appropriate bit to 1 and send new SR out to chip.
						ScannerDataOutSRWrite_D(to_integer(ScannerConfigReg_D.ScannerEar_D(EAR_SIZE - 1 downto 0) & ScannerConfigReg_D.ScannerChannel_D)) <= '1';

						ScannerDataOutSRMode_S <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

						State_DN <= stClear;
					end if;
				else
					if IsClear_SP = '0' then
						IsClear_SN <= '1';

						ScannerDataOutSRMode_S <= SHIFTREGISTER_MODE_PARALLEL_CLEAR;

						State_DN <= stClear;
					end if;
				end if;

			when stClear =>
				-- Shift it out all zeroes, slowly, over the scanner output ports.
				ScannerBitInReg_D <= '0';

				-- Wait for one full clock cycle, then switch to the next bit.
				WaitCyclesCounterEnable_S <= '1';

				if WaitCyclesCounterData_D = to_unsigned(SCANNER_CLOCK_CYCLES - 1, WAIT_CYCLES_COUNTER_SIZE) then
					WaitCyclesCounterEnable_S <= '0';
					WaitCyclesCounterClear_S  <= '1';

					-- Count up one, this bit is done!
					SentBitsCounterEnable_S <= '1';

					if SentBitsCounterData_D = to_unsigned(SCANNER_REG_LENGTH - 1, SENT_BITS_COUNTER_SIZE) then
						SentBitsCounterEnable_S <= '0';
						SentBitsCounterClear_S  <= '1';

						-- Move to next state, the scanner SR is clear now.
						State_DN <= stScanOut;
					end if;
				end if;

				-- Clock data. Default clock is LOW, so we pull it HIGH during the middle half of its period.
				-- This way both clock edges happen when the data is stable.
				if WaitCyclesCounterData_D >= to_unsigned(SCANNER_CLOCK_CYCLES / 4, WAIT_CYCLES_COUNTER_SIZE) and WaitCyclesCounterData_D <= to_unsigned(SCANNER_CLOCK_CYCLES / 4 * 3, WAIT_CYCLES_COUNTER_SIZE) then
					ScannerClockReg_C <= '1';
				end if;

			when stScanOut =>
				-- Shift it out, slowly, over the scanner output ports.
				ScannerBitInReg_D <= ScannerDataOutSRRead_D(SCANNER_REG_LENGTH - 1);

				-- Wait for one full clock cycle, then switch to the next bit.
				WaitCyclesCounterEnable_S <= '1';

				if WaitCyclesCounterData_D = to_unsigned(SCANNER_CLOCK_CYCLES - 1, WAIT_CYCLES_COUNTER_SIZE) then
					WaitCyclesCounterEnable_S <= '0';
					WaitCyclesCounterClear_S  <= '1';

					-- Move to next bit.
					ScannerDataOutSRMode_S <= SHIFTREGISTER_MODE_SHIFT_LEFT;

					-- Count up one, this bit is done!
					SentBitsCounterEnable_S <= '1';

					if SentBitsCounterData_D = to_unsigned(SCANNER_REG_LENGTH - 1, SENT_BITS_COUNTER_SIZE) then
						SentBitsCounterEnable_S <= '0';
						SentBitsCounterClear_S  <= '1';

						-- Move to next state, this SR is fully shifted out now.
						State_DN <= stIdle;
					end if;
				end if;

				-- Clock data. Default clock is LOW, so we pull it HIGH during the middle half of its period.
				-- This way both clock edges happen when the data is stable.
				if WaitCyclesCounterData_D >= to_unsigned(SCANNER_CLOCK_CYCLES / 4, WAIT_CYCLES_COUNTER_SIZE) and WaitCyclesCounterData_D <= to_unsigned(SCANNER_CLOCK_CYCLES / 4 * 3, WAIT_CYCLES_COUNTER_SIZE) then
					ScannerClockReg_C <= '1';
				end if;

			when others =>
				null;
		end case;
	end process dacControl;

	registerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then
			State_DP <= stIdle;

			IsClear_SP <= '0';

			ScannerClock_CO <= '0';
			ScannerBitIn_DO <= '0';

			ScannerConfigReg_D <= tScannerConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			IsClear_SP <= IsClear_SN;

			ScannerClock_CO <= ScannerClockReg_C;
			ScannerBitIn_DO <= ScannerBitInReg_D;

			ScannerConfigReg_D <= ScannerConfig_DI;
		end if;
	end process registerUpdate;
end architecture Behavioral;
