library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use work.ShiftRegisterModes.all;
use work.Settings.LOGIC_CLOCK_FREQ;
use work.ChipBiasConfigRecords.all;
use work.CochleaLPChipBiasConfigRecords.all;

entity CochleaLPStateMachine is
	port(
		Clock_CI               : in  std_logic;
		Reset_RI               : in  std_logic;

		-- Bias configuration outputs (to chip)
		ChipBiasDiagSelect_SO  : out std_logic;
		ChipBiasAddrSelect_SBO : out std_logic;
		ChipBiasClock_CBO      : out std_logic;
		ChipBiasBitIn_DO       : out std_logic;
		ChipBiasLatch_SBO      : out std_logic;

		-- Configuration inputs
		BiasConfig_DI          : in  tCochleaLPBiasConfig;
		ChipConfig_DI          : in  tCochleaLPChipConfig);
end entity CochleaLPStateMachine;

architecture Behavioral of CochleaLPStateMachine is
	attribute syn_enum_encoding : string;

	type tState is (stIdle, stAckAndLoadBias0, stAckAndLoadBias1, stAckAndLoadBias8, stAckAndLoadBias11, stAckAndLoadBias14, stAckAndLoadBias19, stAckAndLoadBias20, stAckAndLoadBias21, stPrepareSendBiasAddress, stSendBiasAddress, stPrepareSendBias, stSendBias, stAckAndLoadChip, stPrepareSendChip,
		            stSendChip, stLatchBiasAddress, stLatchBias, stLatchChip);
	attribute syn_enum_encoding of tState : type is "onehot";

	signal State_DP, State_DN : tState;

	-- Bias clock frequency in KHz.
	constant BIAS_CLOCK_FREQ : integer := 100;

	-- How long the latch should be asserted, based on bias clock frequency.
	constant LATCH_LENGTH : integer := 10;

	-- Calculated values in cycles.
	constant BIAS_CLOCK_CYCLES : integer := LOGIC_CLOCK_FREQ * (1000 / BIAS_CLOCK_FREQ);
	constant LATCH_CYCLES      : integer := BIAS_CLOCK_CYCLES * LATCH_LENGTH;

	-- Calcualted length of cycles counter. Based on latch cycles, since biggest value.
	constant WAIT_CYCLES_COUNTER_SIZE : integer := integer(ceil(log2(real(LATCH_CYCLES))));

	-- Counts number of sent bits. Biggest value is 60 bits of chip SR, so 6 bits are enough.
	constant SENT_BITS_COUNTER_SIZE : integer := 6;

	-- Chip changes and acknowledges.
	signal ChipChangedInput_D        : std_logic_vector(CHIP_REG_USED_SIZE - 1 downto 0);
	signal ChipChanged_S, ChipSent_S : std_logic;

	-- Bias changes and acknowledges.
	signal Bias0Changed_S, Bias0Sent_S   : std_logic;
	signal Bias1Changed_S, Bias1Sent_S   : std_logic;
	signal Bias8Changed_S, Bias8Sent_S   : std_logic;
	signal Bias11Changed_S, Bias11Sent_S : std_logic;
	signal Bias14Changed_S, Bias14Sent_S : std_logic;
	signal Bias19Changed_S, Bias19Sent_S : std_logic;
	signal Bias20Changed_S, Bias20Sent_S : std_logic;
	signal Bias21Changed_S, Bias21Sent_S : std_logic;

	-- Data shift registers for output.
	signal BiasAddrSRMode_S                      : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0);
	signal BiasAddrSRInput_D, BiasAddrSROutput_D : std_logic_vector(BIASADDR_REG_LENGTH - 1 downto 0);

	signal BiasSRMode_S                  : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0);
	signal BiasSRInput_D, BiasSROutput_D : std_logic_vector(BIAS_REG_LENGTH - 1 downto 0);

	signal ChipSRMode_S                  : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0);
	signal ChipSRInput_D, ChipSROutput_D : std_logic_vector(CHIP_REG_LENGTH - 1 downto 0);

	-- Counter for keeping track of output bits.
	signal SentBitsCounterClear_S, SentBitsCounterEnable_S : std_logic;
	signal SentBitsCounterData_D                           : unsigned(SENT_BITS_COUNTER_SIZE - 1 downto 0);

	-- Counter to introduce delays between operations, and generate the clock.
	signal WaitCyclesCounterClear_S, WaitCyclesCounterEnable_S : std_logic;
	signal WaitCyclesCounterData_D                             : unsigned(WAIT_CYCLES_COUNTER_SIZE - 1 downto 0);

	-- Register configuration inputs.
	signal BiasConfigReg_D : tCochleaLPBiasConfig;
	signal ChipConfigReg_D : tCochleaLPChipConfig;

	-- Register all outputs.
	signal ChipBiasDiagSelectReg_S  : std_logic;
	signal ChipBiasAddrSelectReg_SB : std_logic;
	signal ChipBiasClockReg_CB      : std_logic;
	signal ChipBiasBitInReg_D       : std_logic;
	signal ChipBiasLatchReg_SB      : std_logic;

	function BiasGenerateCoarseFine(CFBIAS : in std_logic_vector(BIAS_CF_LENGTH - 1 downto 0)) return std_logic_vector is
	begin
		return '0' & not CFBIAS(12) & not CFBIAS(13) & not CFBIAS(14) & CFBIAS(11 downto 0);
	end function BiasGenerateCoarseFine;
begin
	sendConfig : process(State_DP, BiasConfigReg_D, BiasAddrSROutput_D, BiasSROutput_D, ChipConfigReg_D, ChipSROutput_D, ChipChanged_S, SentBitsCounterData_D, WaitCyclesCounterData_D)
	begin
		-- Keep state by default.
		State_DN <= State_DP;

		-- Default state for bias config outputs.
		ChipBiasDiagSelectReg_S  <= '0';
		ChipBiasAddrSelectReg_SB <= '1';
		ChipBiasClockReg_CB      <= '1';
		ChipBiasBitInReg_D       <= '0';
		ChipBiasLatchReg_SB      <= '1';

		Bias0Sent_S  <= '0';
		Bias1Sent_S  <= '0';
		Bias8Sent_S  <= '0';
		Bias11Sent_S <= '0';
		Bias14Sent_S <= '0';
		Bias19Sent_S <= '0';
		Bias20Sent_S <= '0';
		Bias21Sent_S <= '0';

		ChipSent_S <= '0';

		BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_DO_NOTHING;
		BiasAddrSRInput_D <= (others => '0');

		BiasSRMode_S  <= SHIFTREGISTER_MODE_DO_NOTHING;
		BiasSRInput_D <= (others => '0');

		ChipSRMode_S  <= SHIFTREGISTER_MODE_DO_NOTHING;
		ChipSRInput_D <= (others => '0');

		WaitCyclesCounterClear_S  <= '0';
		WaitCyclesCounterEnable_S <= '0';

		SentBitsCounterClear_S  <= '0';
		SentBitsCounterEnable_S <= '0';

		case State_DP is
			when stIdle =>
				if Bias0Changed_S = '1' then
					State_DN <= stAckAndLoadBias0;
				end if;
				if Bias1Changed_S = '1' then
					State_DN <= stAckAndLoadBias1;
				end if;
				if Bias8Changed_S = '1' then
					State_DN <= stAckAndLoadBias8;
				end if;
				if Bias11Changed_S = '1' then
					State_DN <= stAckAndLoadBias11;
				end if;
				if Bias14Changed_S = '1' then
					State_DN <= stAckAndLoadBias14;
				end if;
				if Bias19Changed_S = '1' then
					State_DN <= stAckAndLoadBias19;
				end if;
				if Bias20Changed_S = '1' then
					State_DN <= stAckAndLoadBias20;
				end if;
				if Bias21Changed_S = '1' then
					State_DN <= stAckAndLoadBias21;
				end if;

				if ChipChanged_S = '1' then
					State_DN <= stAckAndLoadChip;
				end if;

			when stAckAndLoadBias0 =>
				-- Acknowledge this particular bias.
				Bias0Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(0, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= BiasGenerateCoarseFine(BiasConfigReg_D.VBNIBias_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias1 =>
				-- Acknowledge this particular bias.
				Bias1Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(1, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= BiasGenerateCoarseFine(BiasConfigReg_D.VBNTest_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias8 =>
				-- Acknowledge this particular bias.
				Bias8Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(8, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= BiasGenerateCoarseFine(BiasConfigReg_D.VBPScan_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias11 =>
				-- Acknowledge this particular bias.
				Bias11Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(11, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= BiasGenerateCoarseFine(BiasConfigReg_D.AEPdBn_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias14 =>
				-- Acknowledge this particular bias.
				Bias14Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(14, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= BiasGenerateCoarseFine(BiasConfigReg_D.AEPuYBp_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias19 =>
				-- Acknowledge this particular bias.
				Bias19Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(19, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= BiasGenerateCoarseFine(BiasConfigReg_D.BiasBuffer_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias20 =>
				-- Acknowledge this particular bias.
				Bias20Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(20, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= BiasConfigReg_D.SSP_D;
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias21 =>
				-- Acknowledge this particular bias.
				Bias21Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(21, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= BiasConfigReg_D.SSN_D;
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stPrepareSendBiasAddress =>
				-- Set flags as needed for bias address SR.
				ChipBiasAddrSelectReg_SB <= '0';

				-- Wait for one bias clock cycle, to ensure the chip has had time to switch to the right SR.
				WaitCyclesCounterEnable_S <= '1';

				if WaitCyclesCounterData_D = to_unsigned(BIAS_CLOCK_CYCLES, WAIT_CYCLES_COUNTER_SIZE) then
					WaitCyclesCounterEnable_S <= '0';
					WaitCyclesCounterClear_S  <= '1';

					State_DN <= stSendBiasAddress;
				end if;

			when stSendBiasAddress =>
				-- Set flags as needed for bias address SR.
				ChipBiasAddrSelectReg_SB <= '0';

				-- Shift it out, slowly, over the bias ports.
				ChipBiasBitInReg_D <= BiasAddrSROutput_D(BIASADDR_REG_LENGTH - 1);

				-- Wait for one full clock cycle, then switch to the next bit.
				WaitCyclesCounterEnable_S <= '1';

				if WaitCyclesCounterData_D = to_unsigned(BIAS_CLOCK_CYCLES - 1, WAIT_CYCLES_COUNTER_SIZE) then
					WaitCyclesCounterEnable_S <= '0';
					WaitCyclesCounterClear_S  <= '1';

					-- Move to next bit.
					BiasAddrSRMode_S <= SHIFTREGISTER_MODE_SHIFT_LEFT;

					-- Count up one, this bit is done!
					SentBitsCounterEnable_S <= '1';

					if SentBitsCounterData_D = to_unsigned(BIASADDR_REG_LENGTH - 1, SENT_BITS_COUNTER_SIZE) then
						SentBitsCounterEnable_S <= '0';
						SentBitsCounterClear_S  <= '1';

						-- Move to next state, this SR is fully shifted out now.
						State_DN <= stLatchBiasAddress;
					end if;
				end if;

				-- Clock data. Default clock is HIGH, so we pull it LOW during the middle half of its period.
				-- This way both clock edges happen when the data is stable.
				if WaitCyclesCounterData_D >= to_unsigned(BIAS_CLOCK_CYCLES / 4, WAIT_CYCLES_COUNTER_SIZE) and WaitCyclesCounterData_D <= to_unsigned(BIAS_CLOCK_CYCLES / 4 * 3, WAIT_CYCLES_COUNTER_SIZE) then
					ChipBiasClockReg_CB <= '0';
				end if;

			when stLatchBiasAddress =>
				-- Set flags as needed for bias address SR.
				ChipBiasAddrSelectReg_SB <= '0';

				-- Latch new config.
				ChipBiasLatchReg_SB <= '0';

				-- Keep latch active for a few cycles.
				WaitCyclesCounterEnable_S <= '1';

				if WaitCyclesCounterData_D = to_unsigned(LATCH_CYCLES - 1, WAIT_CYCLES_COUNTER_SIZE) then
					WaitCyclesCounterEnable_S <= '0';
					WaitCyclesCounterClear_S  <= '1';

					State_DN <= stPrepareSendBias;
				end if;

			when stPrepareSendBias =>
				-- Default flags are fine here for bias SR. We just delay.

				-- Wait for one bias clock cycle, to ensure the chip has had time to switch to the right SR.
				WaitCyclesCounterEnable_S <= '1';

				if WaitCyclesCounterData_D = to_unsigned(BIAS_CLOCK_CYCLES, WAIT_CYCLES_COUNTER_SIZE) then
					WaitCyclesCounterEnable_S <= '0';
					WaitCyclesCounterClear_S  <= '1';

					State_DN <= stSendBias;
				end if;

			when stSendBias =>
				-- Default flags are fine here for bias SR.

				-- Shift it out, slowly, over the bias ports.
				ChipBiasBitInReg_D <= BiasSROutput_D(BIAS_REG_LENGTH - 1);

				-- Wait for one full clock cycle, then switch to the next bit.
				WaitCyclesCounterEnable_S <= '1';

				if WaitCyclesCounterData_D = to_unsigned(BIAS_CLOCK_CYCLES - 1, WAIT_CYCLES_COUNTER_SIZE) then
					WaitCyclesCounterEnable_S <= '0';
					WaitCyclesCounterClear_S  <= '1';

					-- Move to next bit.
					BiasSRMode_S <= SHIFTREGISTER_MODE_SHIFT_LEFT;

					-- Count up one, this bit is done!
					SentBitsCounterEnable_S <= '1';

					if SentBitsCounterData_D = to_unsigned(BIAS_REG_LENGTH - 1, SENT_BITS_COUNTER_SIZE) then
						SentBitsCounterEnable_S <= '0';
						SentBitsCounterClear_S  <= '1';

						-- Move to next state, this SR is fully shifted out now.
						State_DN <= stLatchBias;
					end if;
				end if;

				-- Clock data. Default clock is HIGH, so we pull it LOW during the middle half of its period.
				-- This way both clock edges happen when the data is stable.
				if WaitCyclesCounterData_D >= to_unsigned(BIAS_CLOCK_CYCLES / 4, WAIT_CYCLES_COUNTER_SIZE) and WaitCyclesCounterData_D <= to_unsigned(BIAS_CLOCK_CYCLES / 4 * 3, WAIT_CYCLES_COUNTER_SIZE) then
					ChipBiasClockReg_CB <= '0';
				end if;

			when stLatchBias =>
				-- Default flags are fine here for bias SR.

				-- Latch new config.
				ChipBiasLatchReg_SB <= '0';

				-- Keep latch active for a few cycles.
				WaitCyclesCounterEnable_S <= '1';

				if WaitCyclesCounterData_D = to_unsigned(LATCH_CYCLES - 1, WAIT_CYCLES_COUNTER_SIZE) then
					WaitCyclesCounterEnable_S <= '0';
					WaitCyclesCounterClear_S  <= '1';

					State_DN <= stIdle;
				end if;

			when stAckAndLoadChip =>
				-- Acknowledge all chip config changes, since we're getting the up-to-date
				-- content of all of them anyway, so we can just ACk them all.
				ChipSent_S <= '1';

				-- Load shiftreg with current chip config content.
				ChipSRInput_D(10)           <= ChipConfigReg_D.LNADoubleInputSelect_S;
				ChipSRInput_D(9)           <= ChipConfigReg_D.TestScannerBias_S;
				ChipSRInput_D(8 downto 6)           <= std_logic_vector(ChipConfigReg_D.LNAGainConfig_D);
				ChipSRInput_D(5)           <= ChipConfigReg_D.ComparatorSelfOsc_S;
				ChipSRInput_D(4 downto 2) <= std_logic_vector(ChipConfigReg_D.DelayCapConfigADM_D);
				ChipSRInput_D(1 downto 0) <= std_logic_vector(ChipConfigReg_D.ResetCapConfigADM_D);
				ChipSRMode_S                <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendChip;

			when stPrepareSendChip =>
				-- Set flags as needed for chip diag SR.
				ChipBiasDiagSelectReg_S <= '1';

				-- Wait for one bias clock cycle, to ensure the chip has had time to switch to the right SR.
				WaitCyclesCounterEnable_S <= '1';

				if WaitCyclesCounterData_D = to_unsigned(BIAS_CLOCK_CYCLES, WAIT_CYCLES_COUNTER_SIZE) then
					WaitCyclesCounterEnable_S <= '0';
					WaitCyclesCounterClear_S  <= '1';

					State_DN <= stSendChip;
				end if;

			when stSendChip =>
				-- Set flags as needed for chip diag SR.
				ChipBiasDiagSelectReg_S <= '1';

				-- Shift it out, slowly, over the bias ports.
				ChipBiasBitInReg_D <= ChipSROutput_D(CHIP_REG_LENGTH - 1);

				-- Wait for one full clock cycle, then switch to the next bit.
				WaitCyclesCounterEnable_S <= '1';

				if WaitCyclesCounterData_D = to_unsigned(BIAS_CLOCK_CYCLES - 1, WAIT_CYCLES_COUNTER_SIZE) then
					WaitCyclesCounterEnable_S <= '0';
					WaitCyclesCounterClear_S  <= '1';

					-- Move to next bit.
					ChipSRMode_S <= SHIFTREGISTER_MODE_SHIFT_LEFT;

					-- Count up one, this bit is done!
					SentBitsCounterEnable_S <= '1';

					if SentBitsCounterData_D = to_unsigned(CHIP_REG_LENGTH - 1, SENT_BITS_COUNTER_SIZE) then
						SentBitsCounterEnable_S <= '0';
						SentBitsCounterClear_S  <= '1';

						-- Move to next state, this SR is fully shifted out now.
						State_DN <= stLatchChip;
					end if;
				end if;

				-- Clock data. Default clock is HIGH, so we pull it LOW during the middle half of its period.
				-- This way both clock edges happen when the data is stable.
				if WaitCyclesCounterData_D >= to_unsigned(BIAS_CLOCK_CYCLES / 4, WAIT_CYCLES_COUNTER_SIZE) and WaitCyclesCounterData_D <= to_unsigned(BIAS_CLOCK_CYCLES / 4 * 3, WAIT_CYCLES_COUNTER_SIZE) then
					ChipBiasClockReg_CB <= '0';
				end if;

			when stLatchChip =>
				-- Set flags as needed for chip diag SR.
				ChipBiasDiagSelectReg_S <= '1';

				-- Latch new config.
				ChipBiasLatchReg_SB <= '0';

				-- Keep latch active for a few cycles.
				WaitCyclesCounterEnable_S <= '1';

				if WaitCyclesCounterData_D = to_unsigned(LATCH_CYCLES - 1, WAIT_CYCLES_COUNTER_SIZE) then
					WaitCyclesCounterEnable_S <= '0';
					WaitCyclesCounterClear_S  <= '1';

					State_DN <= stIdle;
				end if;

			when others => null;
		end case;
	end process sendConfig;

	regUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then
			State_DP <= stIdle;

			BiasConfigReg_D <= tCochleaLPBiasConfigDefault;
			ChipConfigReg_D <= tCochleaLPChipConfigDefault;

			ChipBiasDiagSelect_SO  <= '0';
			ChipBiasAddrSelect_SBO <= '1';
			ChipBiasClock_CBO      <= '1';
			ChipBiasBitIn_DO       <= '0';
			ChipBiasLatch_SBO      <= '1';
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			BiasConfigReg_D <= BiasConfig_DI;
			ChipConfigReg_D <= ChipConfig_DI;

			ChipBiasDiagSelect_SO  <= ChipBiasDiagSelectReg_S;
			ChipBiasAddrSelect_SBO <= ChipBiasAddrSelectReg_SB;
			ChipBiasClock_CBO      <= ChipBiasClockReg_CB;
			ChipBiasBitIn_DO       <= ChipBiasBitInReg_D;
			ChipBiasLatch_SBO      <= ChipBiasLatchReg_SB;
		end if;
	end process regUpdate;

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

	biasAddrSR : entity work.ShiftRegister
		generic map(
			SIZE => BIASADDR_REG_LENGTH)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			Mode_SI          => BiasAddrSRMode_S,
			DataIn_DI        => '0',
			ParallelWrite_DI => BiasAddrSRInput_D,
			ParallelRead_DO  => BiasAddrSROutput_D);

	biasSR : entity work.ShiftRegister
		generic map(
			SIZE => BIAS_REG_LENGTH)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			Mode_SI          => BiasSRMode_S,
			DataIn_DI        => '0',
			ParallelWrite_DI => BiasSRInput_D,
			ParallelRead_DO  => BiasSROutput_D);

	chipSR : entity work.ShiftRegister
		generic map(
			SIZE => CHIP_REG_LENGTH)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			Mode_SI          => ChipSRMode_S,
			DataIn_DI        => '0',
			ParallelWrite_DI => ChipSRInput_D,
			ParallelRead_DO  => ChipSROutput_D);

	detectBias0Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_VD_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.Vth_D,
			ChangeDetected_SO     => Bias0Changed_S,
			ChangeAcknowledged_SI => Bias0Sent_S);

	detectBias1Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_VD_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.Vrs_D,
			ChangeDetected_SO     => Bias1Changed_S,
			ChangeAcknowledged_SI => Bias1Sent_S);

	detectBias8Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.LocalBufBn_D,
			ChangeDetected_SO     => Bias8Changed_S,
			ChangeAcknowledged_SI => Bias8Sent_S);

	detectBias9Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.PadFollBn_D,
			ChangeDetected_SO     => Bias9Changed_S,
			ChangeAcknowledged_SI => Bias9Sent_S);

	detectBias14Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.BiasComp_D,
			ChangeDetected_SO     => Bias14Changed_S,
			ChangeAcknowledged_SI => Bias14Sent_S);

	detectBias20Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.ILeak_D,
			ChangeDetected_SO     => Bias20Changed_S,
			ChangeAcknowledged_SI => Bias20Sent_S);

	detectBias26Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.IFRefrBn_D,
			ChangeDetected_SO     => Bias26Changed_S,
			ChangeAcknowledged_SI => Bias26Sent_S);

	detectBias27Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.IFThrBn_D,
			ChangeDetected_SO     => Bias27Changed_S,
			ChangeAcknowledged_SI => Bias27Sent_S);

	detectBias34Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.BiasBuffer_D,
			ChangeDetected_SO     => Bias34Changed_S,
			ChangeAcknowledged_SI => Bias34Sent_S);

	detectBias35Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_SS_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.SSP_D,
			ChangeDetected_SO     => Bias35Changed_S,
			ChangeAcknowledged_SI => Bias35Sent_S);

	detectBias36Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_SS_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.SSN_D,
			ChangeDetected_SO     => Bias36Changed_S,
			ChangeAcknowledged_SI => Bias36Sent_S);

	-- Put all chip register configuration parameters together, and then detect changes
	-- on the whole lot of them. This is easier to handle and slightly more efficient.
	ChipChangedInput_D <= std_logic_vector(ChipConfigReg_D.DigitalMux0_D) & std_logic_vector(ChipConfigReg_D.DigitalMux1_D) & std_logic_vector(ChipConfigReg_D.DigitalMux2_D) & std_logic_vector(ChipConfigReg_D.DigitalMux3_D) & std_logic_vector(ChipConfigReg_D.AnalogMux0_D) & std_logic_vector(
			ChipConfigReg_D.AnalogMux1_D) & std_logic_vector(ChipConfigReg_D.AnalogMux2_D) & std_logic_vector(ChipConfigReg_D.AnalogMux3_D) & std_logic_vector(ChipConfigReg_D.BiasMux0_D) & ChipConfigReg_D.ResetCalibNeuron_S & ChipConfigReg_D.TypeNCalibNeuron_S & ChipConfigReg_D.UseAOut_S &
		ChipConfigReg_D.ChipIDX0_S & ChipConfigReg_D.ChipIDX1_S & ChipConfigReg_D.AMCX0_S & ChipConfigReg_D.AMCX1_S & ChipConfigReg_D.AMDX0_S & ChipConfigReg_D.AMDX1_S & ChipConfigReg_D.ChipIDY0_S & ChipConfigReg_D.ChipIDY1_S & ChipConfigReg_D.AMCY0_S & ChipConfigReg_D.AMCY1_S & ChipConfigReg_D.AMDY0_S &
		ChipConfigReg_D.AMDY1_S;

	detectChipChange : entity work.ChangeDetector
		generic map(
			SIZE => CHIP_REG_USED_SIZE)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => ChipChangedInput_D,
			ChangeDetected_SO     => ChipChanged_S,
			ChangeAcknowledged_SI => ChipSent_S);
end architecture Behavioral;
