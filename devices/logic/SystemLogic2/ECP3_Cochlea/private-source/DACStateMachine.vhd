library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use work.ShiftRegisterModes.all;
use work.Settings.LOGIC_CLOCK_FREQ;
use work.DACConfigRecords.all;

entity DACStateMachine is
	port(
		Clock_CI      : in  std_logic;
		Reset_RI      : in  std_logic;

		-- DAC control I/O
		DACSelect_SBO : out std_logic_vector(3 downto 0); -- Support up to 4 DACs.
		DACClock_CO   : out std_logic;
		DACDataOut_DO : out std_logic;

		-- Configuration input
		DACConfig_DI  : in  tDACConfig);
end entity DACStateMachine;

architecture Behavioral of DACStateMachine is
	attribute syn_enum_encoding : string;

	type tState is (stStartup, stIdle, stStartTransaction, stWriteData, stStopTransaction, stPowerUp, stPowerDown);
	attribute syn_enum_encoding of tState : type is "onehot";

	signal State_DP, State_DN : tState;

	constant DAC_REG_LENGTH : integer := 24;

	-- SPI clock frequency in MHz.
	constant DAC_CLOCK_FREQ : integer := 10;

	-- Calculated values in cycles.
	constant DAC_CLOCK_CYCLES : integer := LOGIC_CLOCK_FREQ / DAC_CLOCK_FREQ;

	-- Calcualted length of cycles counter.
	constant WAIT_CYCLES_COUNTER_SIZE : integer := integer(ceil(log2(real(DAC_CLOCK_CYCLES))));

	-- Counts number of sent bits.
	constant SENT_BITS_COUNTER_SIZE : integer := integer(ceil(log2(real(DAC_REG_LENGTH))));

	-- Output data register (to DAC).
	signal DACDataOutSRMode_S                      : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0);
	signal DACDataOutSRWrite_D, DACDataOutSRRead_D : std_logic_vector(DAC_REG_LENGTH - 1 downto 0);

	-- Counter for keeping track of output bits.
	signal SentBitsCounterClear_S, SentBitsCounterEnable_S : std_logic;
	signal SentBitsCounterData_D                           : unsigned(SENT_BITS_COUNTER_SIZE - 1 downto 0);

	-- Counter to introduce delays between operations, and generate the clock.
	signal WaitCyclesCounterClear_S, WaitCyclesCounterEnable_S : std_logic;
	signal WaitCyclesCounterData_D                             : unsigned(WAIT_CYCLES_COUNTER_SIZE - 1 downto 0);

	-- Signal when to latch the registers and start a transaction.
	signal SetPulse_S : std_logic;
	signal SetAck_S   : std_logic;
	signal Set_S      : std_logic;

	-- Keep track if the DACs are running or not.
	signal DACRunning_SP, DACRunning_SN : std_logic;

	-- Register outputs. Keep DACSelectReg accessible internally.
	signal DACSelectReg_SP, DACSelectReg_SN : std_logic_vector(3 downto 0); -- Support up to 4 DACs.
	signal DACClockReg_C, DACDataOutReg_D   : std_logic;

	-- Register configuration input to improve timing.
	signal DACConfigReg_D : tDACConfig;
begin
	detectSetPulse : entity work.PulseDetector
		generic map(
			SIZE => 2)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			PulsePolarity_SI => '1',
			PulseLength_DI   => to_unsigned(2, 2),
			InputSignal_SI   => DACConfigReg_D.Set_S,
			PulseDetected_SO => SetPulse_S);

	bufferSet : entity work.BufferClear
		port map(
			Clock_CI        => Clock_CI,
			Reset_RI        => Reset_RI,
			Clear_SI        => SetAck_S,
			InputSignal_SI  => SetPulse_S,
			OutputSignal_SO => Set_S);

	dacDataOutShiftRegister : entity work.ShiftRegister
		generic map(
			SIZE => DAC_REG_LENGTH)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			Mode_SI          => DACDataOutSRMode_S,
			DataIn_DI        => '0',
			ParallelWrite_DI => DACDataOutSRWrite_D,
			ParallelRead_DO  => DACDataOutSRRead_D);

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

	dacControl : process(State_DP, DACConfigReg_D, DACDataOutSRRead_D, DACSelectReg_SP, SentBitsCounterData_D, WaitCyclesCounterData_D, Set_S, DACRunning_SP)
	begin
		-- Keep state by default.
		State_DN <= State_DP;

		DACRunning_SN <= DACRunning_SP;

		DACSelectReg_SN <= DACSelectReg_SP;
		DACClockReg_C   <= '0';
		DACDataOutReg_D <= '0';

		WaitCyclesCounterClear_S  <= '0';
		WaitCyclesCounterEnable_S <= '0';

		SentBitsCounterClear_S  <= '0';
		SentBitsCounterEnable_S <= '0';

		SetAck_S <= '0';

		DACDataOutSRMode_S  <= SHIFTREGISTER_MODE_DO_NOTHING;
		DACDataOutSRWrite_D <= (others => '0');

		case State_DP is
			when stStartup =>
				-- At startup, right after main system reset, we need to
				-- ensure the DAC's control register is correctly configured
				-- for proper operation.
				-- The register is 24 bits long:
				-- 0W00 AAAA RRDD DDDD DDDD DDxx
				-- 0000 1100 0011 0101 0000 0000
				--    0    C    3    5    0    0
				-- See Table 27 of AD5391 doc for explanation.
				DACDataOutSRWrite_D <= "000011000011010100000000";
				DACDataOutSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Bypass the StartTransaction state and select all DACs,
				-- so they can be configured concurrently.
				DACSelectReg_SN <= (others => '1');

				-- DACs are considered running at startup after configuration.
				DACRunning_SN <= '1';

				State_DN <= stWriteData;

			when stPowerUp =>
				DACRunning_SN <= '1';

				-- Do soft power-up.
				-- The register is 24 bits long:
				-- 0W00 AAAA RRDD DDDD DDDD DDxx
				-- 0000 1001 0000 0000 0000 0000
				--    0    9    0    0    0    0
				-- See Table 27 of AD5391 doc for explanation.
				DACDataOutSRWrite_D <= "000010010000000000000000";
				DACDataOutSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Bypass the StartTransaction state and select all DACs,
				-- so they can be configured concurrently.
				DACSelectReg_SN <= (others => '1');

				State_DN <= stWriteData;

			when stPowerDown =>
				DACRunning_SN <= '0';

				-- Do soft power-down.
				-- The register is 24 bits long:
				-- 0W00 AAAA RRDD DDDD DDDD DDxx
				-- 0000 1000 0000 0000 0000 0000
				--    0    8    0    0    0    0
				-- See Table 27 of AD5391 doc for explanation.
				DACDataOutSRWrite_D <= "000010000000000000000000";
				DACDataOutSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Bypass the StartTransaction state and select all DACs,
				-- so they can be configured concurrently.
				DACSelectReg_SN <= (others => '1');

				State_DN <= stWriteData;

			when stIdle =>
				if DACConfigReg_D.Run_S = '1' and DACRunning_SP = '1' then
					-- DAC is running fine, keep watch for new transaction requests.
					DACDataOutSRWrite_D(19 downto 16)                   <= std_logic_vector(DACConfigReg_D.Channel_D);
					DACDataOutSRWrite_D(15 downto 14)                   <= std_logic_vector(DACConfigReg_D.Register_D);
					DACDataOutSRWrite_D(13 downto 14 - DAC_DATA_LENGTH) <= std_logic_vector(DACConfigReg_D.DataWrite_D);
					DACDataOutSRMode_S                                  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

					if Set_S = '1' then
						SetAck_S <= '1';

						-- Start next transaction.
						State_DN <= stStartTransaction;
					end if;
				elsif DACConfigReg_D.Run_S = '1' and DACRunning_SP = '0' then
					-- DAC should be running but isn't. Power it up.
					State_DN <= stPowerUp;
				elsif DACConfigReg_D.Run_S = '0' and DACRunning_SP = '1' then
					-- DAC is running but should be turned off. Power it down.
					State_DN <= stPowerDown;
				end if;

			when stStartTransaction =>
				-- Select the correct DAC and enable it.
				DACSelectReg_SN(to_integer(DACConfigReg_D.DAC_D)) <= '1';

				State_DN <= stWriteData;

			when stWriteData =>
				-- Shift it out, slowly, over the SPI output ports.
				DACDataOutReg_D <= DACDataOutSRRead_D(DAC_REG_LENGTH - 1);

				-- Wait for one full clock cycle, then switch to the next bit.
				WaitCyclesCounterEnable_S <= '1';

				if WaitCyclesCounterData_D = to_unsigned(DAC_CLOCK_CYCLES - 1, WAIT_CYCLES_COUNTER_SIZE) then
					WaitCyclesCounterEnable_S <= '0';
					WaitCyclesCounterClear_S  <= '1';

					-- Move to next bit.
					DACDataOutSRMode_S <= SHIFTREGISTER_MODE_SHIFT_LEFT;

					-- Count up one, this bit is done!
					SentBitsCounterEnable_S <= '1';

					if SentBitsCounterData_D = to_unsigned(DAC_REG_LENGTH - 1, SENT_BITS_COUNTER_SIZE) then
						SentBitsCounterEnable_S <= '0';
						SentBitsCounterClear_S  <= '1';

						-- Move to next state, this SR is fully shifted out now.
						State_DN <= stStopTransaction;
					end if;
				end if;

				-- Clock data. Default clock is LOW, so we pull it HIGH during the middle half of its period.
				-- This way both clock edges happen when the data is stable.
				if WaitCyclesCounterData_D >= to_unsigned(DAC_CLOCK_CYCLES / 4, WAIT_CYCLES_COUNTER_SIZE) and WaitCyclesCounterData_D <= to_unsigned(DAC_CLOCK_CYCLES / 4 * 3, WAIT_CYCLES_COUNTER_SIZE) then
					DACClockReg_C <= '1';
				end if;

			when stStopTransaction =>
				DACSelectReg_SN <= (others => '0');

				State_DN <= stIdle;

			when others =>
				null;
		end case;
	end process dacControl;

	registerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then
			State_DP <= stStartup;

			DACRunning_SP <= '0';

			DACSelectReg_SP <= (others => '0');

			DACClock_CO   <= '0';
			DACDataOut_DO <= '0';

			DACConfigReg_D <= tDACConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			DACRunning_SP <= DACRunning_SN;

			DACSelectReg_SP <= DACSelectReg_SN;

			DACClock_CO   <= DACClockReg_C;
			DACDataOut_DO <= DACDataOutReg_D;

			DACConfigReg_D <= DACConfig_DI;
		end if;
	end process registerUpdate;

	DACSelect_SBO <= not DACSelectReg_SP;
end architecture Behavioral;
