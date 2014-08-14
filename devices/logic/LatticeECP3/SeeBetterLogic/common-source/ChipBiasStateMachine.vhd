library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ShiftRegisterModes.all;
use work.ChipBiasConfigRecords.all;
use work.Settings.LOGIC_CLOCK_FREQ;
use ieee.math_real.ceil;
use ieee.math_real.log2;

entity ChipBiasStateMachine is
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
		BiasConfig_DI          : in  tBiasConfig;
		ChipConfig_DI          : in  tChipConfig);
end entity ChipBiasStateMachine;

architecture Behavioral of ChipBiasStateMachine is
	attribute syn_enum_encoding : string;

	type state is (stIdle, stAckAndLoadBias0, stAckAndLoadBias1, stAckAndLoadBias2, stAckAndLoadBias3, stAckAndLoadBias4, stAckAndLoadBias5, stAckAndLoadBias6,
		           stAckAndLoadBias7, stAckAndLoadBias8, stAckAndLoadBias9, stAckAndLoadBias10, stAckAndLoadBias11, stAckAndLoadBias12, stAckAndLoadBias13,
		           stAckAndLoadBias14, stAckAndLoadBias15, stAckAndLoadBias16, stAckAndLoadBias17, stAckAndLoadBias18, stAckAndLoadBias19, stAckAndLoadBias20,
		           stAckAndLoadBias21, stPrepareSendBiasAddress, stSendBiasAddress, stPrepareSendBias, stSendBias, stAckAndLoadChip, stPrepareSendChip,
		           stSendChip, stLatch);
	attribute syn_enum_encoding of state : type is "onehot";

	signal State_DP, State_DN : state;

	-- Bias clock frequency in MHz.
	constant BIAS_CLOCK_FREQ : integer := 20;

	-- How long the latch should be asserted, based on bias clock frequency.
	constant LATCH_LENGTH : integer := 2;

	-- Calculated values in cycles.
	constant BIAS_CLOCK_CYCLES : integer := LOGIC_CLOCK_FREQ / BIAS_CLOCK_FREQ;
	constant LATCH_CYCLES      : integer := BIAS_CLOCK_CYCLES * LATCH_LENGTH;

	-- Calcualted length of cycles counter. Based on latch cycles, since biggest value.
	constant WAIT_CYCLES_COUNTER_SIZE : integer := integer(ceil(log2(real(LATCH_CYCLES))));

	-- Counts number of sent bits. Biggest value is 56 bits of chip SR, so 6 bits are enough.
	constant SENT_BITS_COUNTER_SIZE : integer := 6;

	-- Effectively used bits in chip register.
	constant CHIP_REG_USED_SIZE : integer := (8 * CHIP_MUX_LENGTH) + 7;

	-- Chip changes and acknowledges.
	signal ChipChangedInput_D        : std_logic_vector(CHIP_REG_USED_SIZE - 1 downto 0);
	signal ChipChanged_S, ChipSent_S : std_logic;

	-- Bias changes and acknowledges.
	signal Bias0Changed_S, Bias0Sent_S   : std_logic;
	signal Bias1Changed_S, Bias1Sent_S   : std_logic;
	signal Bias2Changed_S, Bias2Sent_S   : std_logic;
	signal Bias3Changed_S, Bias3Sent_S   : std_logic;
	signal Bias4Changed_S, Bias4Sent_S   : std_logic;
	signal Bias5Changed_S, Bias5Sent_S   : std_logic;
	signal Bias6Changed_S, Bias6Sent_S   : std_logic;
	signal Bias7Changed_S, Bias7Sent_S   : std_logic;
	signal Bias8Changed_S, Bias8Sent_S   : std_logic;
	signal Bias9Changed_S, Bias9Sent_S   : std_logic;
	signal Bias10Changed_S, Bias10Sent_S : std_logic;
	signal Bias11Changed_S, Bias11Sent_S : std_logic;
	signal Bias12Changed_S, Bias12Sent_S : std_logic;
	signal Bias13Changed_S, Bias13Sent_S : std_logic;
	signal Bias14Changed_S, Bias14Sent_S : std_logic;
	signal Bias15Changed_S, Bias15Sent_S : std_logic;
	signal Bias16Changed_S, Bias16Sent_S : std_logic;
	signal Bias17Changed_S, Bias17Sent_S : std_logic;
	signal Bias18Changed_S, Bias18Sent_S : std_logic;
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
	signal BiasConfigReg_D : tBiasConfig;
	signal ChipConfigReg_D : tChipConfig;

	-- Register all outputs.
	signal ChipBiasDiagSelectReg_S  : std_logic;
	signal ChipBiasAddrSelectReg_SB : std_logic;
	signal ChipBiasClockReg_CB      : std_logic;
	signal ChipBiasBitInReg_D       : std_logic;
	signal ChipBiasLatchReg_SB      : std_logic;

	function CoarseBiasFixBits(CFBIAS : in std_logic_vector(BIAS_CF_LENGTH - 1 downto 0)) return std_logic_vector is
	begin
		return not CFBIAS(12) & not CFBIAS(13) & not CFBIAS(14) & CFBIAS(11 downto 0);
	end function CoarseBiasFixBits;
begin
	sendConfig : process(State_DP, BiasConfigReg_D, BiasAddrSROutput_D, BiasSROutput_D, Bias0Changed_S, Bias10Changed_S, Bias11Changed_S, Bias12Changed_S, Bias13Changed_S, Bias14Changed_S, Bias15Changed_S, Bias16Changed_S, Bias17Changed_S, Bias18Changed_S, Bias19Changed_S, Bias1Changed_S, Bias20Changed_S, Bias21Changed_S, Bias2Changed_S, Bias3Changed_S, Bias4Changed_S, Bias5Changed_S, Bias6Changed_S, Bias7Changed_S, Bias8Changed_S, Bias9Changed_S, ChipConfigReg_D, ChipSROutput_D, ChipChanged_S, SentBitsCounterData_D, WaitCyclesCounterData_D)
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
		Bias2Sent_S  <= '0';
		Bias3Sent_S  <= '0';
		Bias4Sent_S  <= '0';
		Bias5Sent_S  <= '0';
		Bias6Sent_S  <= '0';
		Bias7Sent_S  <= '0';
		Bias8Sent_S  <= '0';
		Bias9Sent_S  <= '0';
		Bias10Sent_S <= '0';
		Bias11Sent_S <= '0';
		Bias12Sent_S <= '0';
		Bias13Sent_S <= '0';
		Bias14Sent_S <= '0';
		Bias15Sent_S <= '0';
		Bias16Sent_S <= '0';
		Bias17Sent_S <= '0';
		Bias18Sent_S <= '0';
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
				if Bias2Changed_S = '1' then
					State_DN <= stAckAndLoadBias2;
				end if;
				if Bias3Changed_S = '1' then
					State_DN <= stAckAndLoadBias3;
				end if;
				if Bias4Changed_S = '1' then
					State_DN <= stAckAndLoadBias4;
				end if;
				if Bias5Changed_S = '1' then
					State_DN <= stAckAndLoadBias5;
				end if;
				if Bias6Changed_S = '1' then
					State_DN <= stAckAndLoadBias6;
				end if;
				if Bias7Changed_S = '1' then
					State_DN <= stAckAndLoadBias7;
				end if;
				if Bias8Changed_S = '1' then
					State_DN <= stAckAndLoadBias8;
				end if;
				if Bias9Changed_S = '1' then
					State_DN <= stAckAndLoadBias9;
				end if;
				if Bias10Changed_S = '1' then
					State_DN <= stAckAndLoadBias10;
				end if;
				if Bias11Changed_S = '1' then
					State_DN <= stAckAndLoadBias11;
				end if;
				if Bias12Changed_S = '1' then
					State_DN <= stAckAndLoadBias12;
				end if;
				if Bias13Changed_S = '1' then
					State_DN <= stAckAndLoadBias13;
				end if;
				if Bias14Changed_S = '1' then
					State_DN <= stAckAndLoadBias14;
				end if;
				if Bias15Changed_S = '1' then
					State_DN <= stAckAndLoadBias15;
				end if;
				if Bias16Changed_S = '1' then
					State_DN <= stAckAndLoadBias16;
				end if;
				if Bias17Changed_S = '1' then
					State_DN <= stAckAndLoadBias17;
				end if;
				if Bias18Changed_S = '1' then
					State_DN <= stAckAndLoadBias18;
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
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.DiffBn_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias1 =>
				-- Acknowledge this particular bias.
				Bias1Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(1, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.OnBn_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias2 =>
				-- Acknowledge this particular bias.
				Bias2Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(2, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.OffBn_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias3 =>
				-- Acknowledge this particular bias.
				Bias3Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(3, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.ApsCasEpc_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias4 =>
				-- Acknowledge this particular bias.
				Bias4Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(4, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.DiffCasBnc_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias5 =>
				-- Acknowledge this particular bias.
				Bias5Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(5, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.ApsROSFBn_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias6 =>
				-- Acknowledge this particular bias.
				Bias6Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(6, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.LocalBufBn_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias7 =>
				-- Acknowledge this particular bias.
				Bias7Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(7, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.PixInvBn_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias8 =>
				-- Acknowledge this particular bias.
				Bias8Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(8, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.PrBp_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias9 =>
				-- Acknowledge this particular bias.
				Bias9Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(9, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.PrSFBp_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias10 =>
				-- Acknowledge this particular bias.
				Bias10Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(10, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.RefrBp_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias11 =>
				-- Acknowledge this particular bias.
				Bias11Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(11, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.AEPdBn_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias12 =>
				-- Acknowledge this particular bias.
				Bias12Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(12, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.LcolTimeoutBn_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias13 =>
				-- Acknowledge this particular bias.
				Bias13Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(13, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.AEPuXBp_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias14 =>
				-- Acknowledge this particular bias.
				Bias14Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(14, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.AEPuYBp_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias15 =>
				-- Acknowledge this particular bias.
				Bias15Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(15, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.IFThrBn_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias16 =>
				-- Acknowledge this particular bias.
				Bias16Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(16, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.IFRefrBn_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias17 =>
				-- Acknowledge this particular bias.
				Bias17Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(17, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.PadFollBn_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias18 =>
				-- Acknowledge this particular bias.
				Bias18Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(18, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.ApsOverflowLevel_D);
				BiasSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				State_DN <= stPrepareSendBiasAddress;

			when stAckAndLoadBias19 =>
				-- Acknowledge this particular bias.
				Bias19Sent_S <= '1';

				-- Load shiftreg with current bias address.
				BiasAddrSRInput_D <= std_logic_vector(to_unsigned(19, BIASADDR_REG_LENGTH));
				BiasAddrSRMode_S  <= SHIFTREGISTER_MODE_PARALLEL_LOAD;

				-- Load shiftreg with current bias config content.
				BiasSRInput_D <= '0' & CoarseBiasFixBits(BiasConfigReg_D.BiasBuffer_D);
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
						State_DN <= stPrepareSendBias;
					end if;
				end if;

				-- Clock data. Default clock is HIGH, so we pull it LOW during the second half of its period.
				if WaitCyclesCounterData_D >= to_unsigned(BIAS_CLOCK_CYCLES / 2, WAIT_CYCLES_COUNTER_SIZE) then
					ChipBiasClockReg_CB <= '0';
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
						State_DN <= stLatch;
					end if;
				end if;

				-- Clock data. Default clock is HIGH, so we pull it LOW during the second half of its period.
				if WaitCyclesCounterData_D >= to_unsigned(BIAS_CLOCK_CYCLES / 2, WAIT_CYCLES_COUNTER_SIZE) then
					ChipBiasClockReg_CB <= '0';
				end if;

			when stAckAndLoadChip =>
				-- Acknowledge all chip config changes, since we're getting the up-to-date
				-- content of all of them anyway, so we can just ACk them all.
				ChipSent_S <= '1';

				-- Load shiftreg with current chip config content.
				ChipSRInput_D(55 downto 52) <= std_logic_vector(ChipConfigReg_D.DigitalMux3_D);
				ChipSRInput_D(51 downto 48) <= std_logic_vector(ChipConfigReg_D.DigitalMux2_D);
				ChipSRInput_D(47 downto 44) <= std_logic_vector(ChipConfigReg_D.DigitalMux1_D);
				ChipSRInput_D(43 downto 40) <= std_logic_vector(ChipConfigReg_D.DigitalMux0_D);
				ChipSRInput_D(22)           <= ChipConfigReg_D.GlobalShutter_S;
				ChipSRInput_D(21)           <= ChipConfigReg_D.UseAOut_S;
				ChipSRInput_D(20)           <= ChipConfigReg_D.AERnArow_S;
				ChipSRInput_D(19)           <= ChipConfigReg_D.HotPixelSuppression_S;
				ChipSRInput_D(18)           <= ChipConfigReg_D.ResetTestPixel_S;
				ChipSRInput_D(17)           <= ChipConfigReg_D.TypeNCalibNeuron_S;
				ChipSRInput_D(16)           <= ChipConfigReg_D.ResetCalibNeuron_S;
				ChipSRInput_D(15 downto 12) <= std_logic_vector(ChipConfigReg_D.AnalogMux2_D);
				ChipSRInput_D(11 downto 8)  <= std_logic_vector(ChipConfigReg_D.AnalogMux1_D);
				ChipSRInput_D(7 downto 4)   <= std_logic_vector(ChipConfigReg_D.AnalogMux0_D);
				ChipSRInput_D(3 downto 0)   <= std_logic_vector(ChipConfigReg_D.BiasOutMux_D);
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

					if SentBitsCounterData_D = to_unsigned(BIAS_REG_LENGTH - 1, SENT_BITS_COUNTER_SIZE) then
						SentBitsCounterEnable_S <= '0';
						SentBitsCounterClear_S  <= '1';

						-- Move to next state, this SR is fully shifted out now.
						State_DN <= stLatch;
					end if;
				end if;

				-- Clock data. Default clock is HIGH, so we pull it LOW during the second half of its period.
				if WaitCyclesCounterData_D >= to_unsigned(BIAS_CLOCK_CYCLES / 2, WAIT_CYCLES_COUNTER_SIZE) then
					ChipBiasClockReg_CB <= '0';
				end if;

			when stLatch =>
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

			BiasConfigReg_D <= tBiasConfigDefault;
			ChipConfigReg_D <= tChipConfigDefault;

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
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.DiffBn_D,
			ChangeDetected_SO     => Bias0Changed_S,
			ChangeAcknowledged_SI => Bias0Sent_S);

	detectBias1Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.OnBn_D,
			ChangeDetected_SO     => Bias1Changed_S,
			ChangeAcknowledged_SI => Bias1Sent_S);

	detectBias2Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.OffBn_D,
			ChangeDetected_SO     => Bias2Changed_S,
			ChangeAcknowledged_SI => Bias2Sent_S);

	detectBias3Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.ApsCasEpc_D,
			ChangeDetected_SO     => Bias3Changed_S,
			ChangeAcknowledged_SI => Bias3Sent_S);

	detectBias4Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.DiffCasBnc_D,
			ChangeDetected_SO     => Bias4Changed_S,
			ChangeAcknowledged_SI => Bias4Sent_S);

	detectBias5Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.ApsROSFBn_D,
			ChangeDetected_SO     => Bias5Changed_S,
			ChangeAcknowledged_SI => Bias5Sent_S);

	detectBias6Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.LocalBufBn_D,
			ChangeDetected_SO     => Bias6Changed_S,
			ChangeAcknowledged_SI => Bias6Sent_S);

	detectBias7Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.PixInvBn_D,
			ChangeDetected_SO     => Bias7Changed_S,
			ChangeAcknowledged_SI => Bias7Sent_S);

	detectBias8Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.PrBp_D,
			ChangeDetected_SO     => Bias8Changed_S,
			ChangeAcknowledged_SI => Bias8Sent_S);

	detectBias9Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.PrSFBp_D,
			ChangeDetected_SO     => Bias9Changed_S,
			ChangeAcknowledged_SI => Bias9Sent_S);

	detectBias10Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.RefrBp_D,
			ChangeDetected_SO     => Bias10Changed_S,
			ChangeAcknowledged_SI => Bias10Sent_S);

	detectBias11Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.AEPdBn_D,
			ChangeDetected_SO     => Bias11Changed_S,
			ChangeAcknowledged_SI => Bias11Sent_S);

	detectBias12Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.LcolTimeoutBn_D,
			ChangeDetected_SO     => Bias12Changed_S,
			ChangeAcknowledged_SI => Bias12Sent_S);

	detectBias13Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.AEPuXBp_D,
			ChangeDetected_SO     => Bias13Changed_S,
			ChangeAcknowledged_SI => Bias13Sent_S);

	detectBias14Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.AEPuYBp_D,
			ChangeDetected_SO     => Bias14Changed_S,
			ChangeAcknowledged_SI => Bias14Sent_S);

	detectBias15Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.IFThrBn_D,
			ChangeDetected_SO     => Bias15Changed_S,
			ChangeAcknowledged_SI => Bias15Sent_S);

	detectBias16Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.IFRefrBn_D,
			ChangeDetected_SO     => Bias16Changed_S,
			ChangeAcknowledged_SI => Bias16Sent_S);

	detectBias17Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.PadFollBn_D,
			ChangeDetected_SO     => Bias17Changed_S,
			ChangeAcknowledged_SI => Bias17Sent_S);

	detectBias18Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.ApsOverflowLevel_D,
			ChangeDetected_SO     => Bias18Changed_S,
			ChangeAcknowledged_SI => Bias18Sent_S);

	detectBias19Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.BiasBuffer_D,
			ChangeDetected_SO     => Bias19Changed_S,
			ChangeAcknowledged_SI => Bias19Sent_S);

	detectBias20Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_SS_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.SSP_D,
			ChangeDetected_SO     => Bias20Changed_S,
			ChangeAcknowledged_SI => Bias20Sent_S);

	detectBias21Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_SS_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_DI          => BiasConfigReg_D.SSN_D,
			ChangeDetected_SO     => Bias21Changed_S,
			ChangeAcknowledged_SI => Bias21Sent_S);

	-- Put all chip register configuration parameters together, and then detect changes
	-- on the whole lot of them. This is easier to handle and slightly more efficient.
	ChipChangedInput_D <= std_logic_vector(ChipConfigReg_D.DigitalMux0_D) & std_logic_vector(ChipConfigReg_D.DigitalMux1_D) & std_logic_vector(ChipConfigReg_D.DigitalMux2_D) & std_logic_vector(ChipConfigReg_D.DigitalMux3_D) & std_logic_vector(ChipConfigReg_D.AnalogMux0_D) & std_logic_vector(
			ChipConfigReg_D.AnalogMux1_D) & std_logic_vector(ChipConfigReg_D.AnalogMux2_D) & std_logic_vector(ChipConfigReg_D.BiasOutMux_D) & ChipConfigReg_D.ResetCalibNeuron_S & ChipConfigReg_D.TypeNCalibNeuron_S & ChipConfigReg_D.ResetTestPixel_S & ChipConfigReg_D.HotPixelSuppression_S &
		ChipConfigReg_D.AERnArow_S & ChipConfigReg_D.UseAOut_S & ChipConfigReg_D.GlobalShutter_S;

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
