library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ShiftRegisterModes.all;
use work.ChipBiasConfigRecords.all;

entity ChipBiasStateMachine is
	port(
		Clock_CI           : in  std_logic;
		Reset_RI           : in  std_logic;

		-- Bias configuration outputs (to chip)
		BiasDiagSelect_SO  : out std_logic;
		BiasAddrSelect_SBO : out std_logic;
		BiasClock_CBO      : out std_logic;
		BiasBitIn_DO       : out std_logic;
		BiasLatch_SBO      : out std_logic;

		-- Configuration inputs
		BiasConfig_DI      : in  tBiasConfig;
		ChipConfig_DI      : in  tChipConfig
	);
end entity ChipBiasStateMachine;

architecture Behavioral of ChipBiasStateMachine is
	type state is (stIdle, stLoadAndAckBias, stSendBiasAddress, stSendBias, stLoadAndAckChip, stSendChip);

	attribute syn_enum_encoding : string;
	attribute syn_enum_encoding of state : type is "onehot";

	signal State_DP, State_DN : state;

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

	-- Chip changes and acknowledges.
	signal DigitalMux0Changed_S, DigitalMux0Sent_S                 : std_logic;
	signal DigitalMux1Changed_S, DigitalMux1Sent_S                 : std_logic;
	signal DigitalMux2Changed_S, DigitalMux2Sent_S                 : std_logic;
	signal DigitalMux3Changed_S, DigitalMux3Sent_S                 : std_logic;
	signal AnalogMux0Changed_S, AnalogMux0Sent_S                   : std_logic;
	signal AnalogMux1Changed_S, AnalogMux1Sent_S                   : std_logic;
	signal AnalogMux2Changed_S, AnalogMux2Sent_S                   : std_logic;
	signal BiasOutMuxChanged_S, BiasOutMuxSent_S                   : std_logic;
	signal ResetCalibNeuronChanged_S, ResetCalibNeuronSent_S       : std_logic;
	signal TypeNCalibNeuronChanged_S, TypeNCalibNeuronSent_S       : std_logic;
	signal ResetTestPixelChanged_S, ResetTestPixelSent_S           : std_logic;
	signal HotPixelSuppressionChanged_S, HotPixelSuppressionSent_S : std_logic;
	signal AERnArowChanged_S, AERnArowSent_S                       : std_logic;
	signal UseAOutChanged_S, UseAOutSent_S                         : std_logic;
	signal GlobalShutterChanged_S, GlobalShutterSent_S             : std_logic;

	-- Data shift register for output.
	signal BiasAddrSRMode_S                      : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0);
	signal BiasAddrSRInput_D, BiasAddrSROutput_D : std_logic_vector(BIASADDR_REG_LENGTH - 1 downto 0);

	signal BiasSRMode_S                  : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0);
	signal BiasSRInput_D, BiasSROutput_D : std_logic_vector(BIAS_REG_LENGTH - 1 downto 0);

	signal ChipSRMode_S                  : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0);
	signal ChipSRInput_D, ChipSROutput_D : std_logic_vector(CHIP_REG_LENGTH - 1 downto 0);

	signal BiasConfigReg_D : tBiasConfig;
	signal ChipConfigReg_D : tChipConfig;
begin
	sendConfig : process(State_DP, Bias0Changed_S, Bias1Changed_S, Bias2Changed_S)
	begin
		State_DN <= State_DP;

		case State_DP is
			when stIdle =>
				if Bias0Changed_S = '1' then
					BiasAddrSRInput_D <= std_logic_vector(to_unsigned(0, BIASADDR_REG_LENGTH));
				end if;

				if Bias1Changed_S = '1' then
					BiasAddrSRInput_D <= std_logic_vector(to_unsigned(1, BIASADDR_REG_LENGTH));
				end if;

				if Bias2Changed_S = '1' then
					BiasAddrSRInput_D <= std_logic_vector(to_unsigned(2, BIASADDR_REG_LENGTH));
				end if;

			when stLoadAndAckBias =>
			-- Acknowledge this particular bias.

			-- Load shiftreg with current bias address.

			-- Load shiftreg with current bias config content.

			when stSendBiasAddress =>
			-- Set flags as needed for chip address SR.

			-- Shift it out, slowly, over the bias ports.

			when stSendBias =>
			-- Set flags as needed for chip bias SR.

			-- Shift it out, slowly, over the bias ports.

			when stLoadAndAckChip =>
			-- Acknowledge all chip config changes, since we're getting the up-to-date
			-- content of all of them anyway, so we can just ACk them all indiscrminately.

			-- Load shiftreg with current chip config content.

			when stSendChip =>
			-- Set flags as needed for chip diag SR.

			-- Shift it out, slowly, over the bias ports.

			when others => null;
		end case;
	end process sendConfig;

	regUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then
			State_DP <= stIdle;

			BiasConfigReg_D <= tBiasConfigDefault;
			ChipConfigReg_D <= tChipConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			BiasConfigReg_D <= BiasConfig_DI;
			ChipConfigReg_D <= ChipConfig_DI;
		end if;
	end process regUpdate;

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
			InputData_D           => BiasConfigReg_D.DiffBn_D,
			ChangeDetected_SO     => Bias0Changed_S,
			ChangeAcknowledged_SI => Bias0Sent_S);

	detectBias1Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.OnBn_D,
			ChangeDetected_SO     => Bias1Changed_S,
			ChangeAcknowledged_SI => Bias1Sent_S);

	detectBias2Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.OffBn_D,
			ChangeDetected_SO     => Bias2Changed_S,
			ChangeAcknowledged_SI => Bias2Sent_S);

	detectBias3Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.ApsCasEpc_D,
			ChangeDetected_SO     => Bias3Changed_S,
			ChangeAcknowledged_SI => Bias3Sent_S);

	detectBias4Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.DiffCasBnc_D,
			ChangeDetected_SO     => Bias4Changed_S,
			ChangeAcknowledged_SI => Bias4Sent_S);

	detectBias5Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.ApsROSFBn_D,
			ChangeDetected_SO     => Bias5Changed_S,
			ChangeAcknowledged_SI => Bias5Sent_S);

	detectBias6Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.LocalBufBn_D,
			ChangeDetected_SO     => Bias6Changed_S,
			ChangeAcknowledged_SI => Bias6Sent_S);

	detectBias7Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.PixInvBn_D,
			ChangeDetected_SO     => Bias7Changed_S,
			ChangeAcknowledged_SI => Bias7Sent_S);

	detectBias8Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.PrBp_D,
			ChangeDetected_SO     => Bias8Changed_S,
			ChangeAcknowledged_SI => Bias8Sent_S);

	detectBias9Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.PrSFBp_D,
			ChangeDetected_SO     => Bias9Changed_S,
			ChangeAcknowledged_SI => Bias9Sent_S);

	detectBias10Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.RefrBp_D,
			ChangeDetected_SO     => Bias10Changed_S,
			ChangeAcknowledged_SI => Bias10Sent_S);

	detectBias11Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.AEPdBn_D,
			ChangeDetected_SO     => Bias11Changed_S,
			ChangeAcknowledged_SI => Bias11Sent_S);

	detectBias12Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.LcolTimeoutBn_D,
			ChangeDetected_SO     => Bias12Changed_S,
			ChangeAcknowledged_SI => Bias12Sent_S);

	detectBias13Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.AEPuXBp_D,
			ChangeDetected_SO     => Bias13Changed_S,
			ChangeAcknowledged_SI => Bias13Sent_S);

	detectBias14Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.AEPuYBp_D,
			ChangeDetected_SO     => Bias14Changed_S,
			ChangeAcknowledged_SI => Bias14Sent_S);

	detectBias15Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.IFThrBn_D,
			ChangeDetected_SO     => Bias15Changed_S,
			ChangeAcknowledged_SI => Bias15Sent_S);

	detectBias16Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.IFRefrBn_D,
			ChangeDetected_SO     => Bias16Changed_S,
			ChangeAcknowledged_SI => Bias16Sent_S);

	detectBias17Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.PadFollBn_D,
			ChangeDetected_SO     => Bias17Changed_S,
			ChangeAcknowledged_SI => Bias17Sent_S);

	detectBias18Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.ApsOverflowLevel_D,
			ChangeDetected_SO     => Bias18Changed_S,
			ChangeAcknowledged_SI => Bias18Sent_S);

	detectBias19Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.BiasBuffer_D,
			ChangeDetected_SO     => Bias19Changed_S,
			ChangeAcknowledged_SI => Bias19Sent_S);

	detectBias20Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_SS_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.SSP_D,
			ChangeDetected_SO     => Bias20Changed_S,
			ChangeAcknowledged_SI => Bias20Sent_S);

	detectBias21Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_SS_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfigReg_D.SSN_D,
			ChangeDetected_SO     => Bias21Changed_S,
			ChangeAcknowledged_SI => Bias21Sent_S);

	detectDigitalMux0Change : entity work.ChangeDetector
		generic map(
			SIZE => tChipConfig.DigitalMux0_D'length)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => std_logic_vector(ChipConfigReg_D.DigitalMux0_D),
			ChangeDetected_SO     => DigitalMux0Changed_S,
			ChangeAcknowledged_SI => DigitalMux0Sent_S);

	detectDigitalMux1Change : entity work.ChangeDetector
		generic map(
			SIZE => tChipConfig.DigitalMux1_D'length)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => std_logic_vector(ChipConfigReg_D.DigitalMux1_D),
			ChangeDetected_SO     => DigitalMux1Changed_S,
			ChangeAcknowledged_SI => DigitalMux1Sent_S);

	detectDigitalMux2Change : entity work.ChangeDetector
		generic map(
			SIZE => tChipConfig.DigitalMux2_D'length)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => std_logic_vector(ChipConfigReg_D.DigitalMux2_D),
			ChangeDetected_SO     => DigitalMux2Changed_S,
			ChangeAcknowledged_SI => DigitalMux2Sent_S);

	detectDigitalMux3Change : entity work.ChangeDetector
		generic map(
			SIZE => tChipConfig.DigitalMux3_D'length)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => std_logic_vector(ChipConfigReg_D.DigitalMux3_D),
			ChangeDetected_SO     => DigitalMux3Changed_S,
			ChangeAcknowledged_SI => DigitalMux3Sent_S);

	detectAnalogMux0Change : entity work.ChangeDetector
		generic map(
			SIZE => tChipConfig.AnalogMux0_D'length)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => std_logic_vector(ChipConfigReg_D.AnalogMux0_D),
			ChangeDetected_SO     => AnalogMux0Changed_S,
			ChangeAcknowledged_SI => AnalogMux0Sent_S);

	detectAnalogMux1Change : entity work.ChangeDetector
		generic map(
			SIZE => tChipConfig.AnalogMux1_D'length)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => std_logic_vector(ChipConfigReg_D.AnalogMux1_D),
			ChangeDetected_SO     => AnalogMux1Changed_S,
			ChangeAcknowledged_SI => AnalogMux1Sent_S);

	detectAnalogMux2Change : entity work.ChangeDetector
		generic map(
			SIZE => tChipConfig.AnalogMux2_D'length)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => std_logic_vector(ChipConfigReg_D.AnalogMux2_D),
			ChangeDetected_SO     => AnalogMux2Changed_S,
			ChangeAcknowledged_SI => AnalogMux2Sent_S);

	detectBiasOutMuxChange : entity work.ChangeDetector
		generic map(
			SIZE => tChipConfig.BiasOutMux_D'length)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => std_logic_vector(ChipConfigReg_D.BiasOutMux_D),
			ChangeDetected_SO     => BiasOutMuxChanged_S,
			ChangeAcknowledged_SI => BiasOutMuxSent_S);

	detectResetCalibNeuronChange : entity work.ChangeDetector
		generic map(
			SIZE => 1)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D(0)        => ChipConfigReg_D.ResetCalibNeuron_S,
			ChangeDetected_SO     => ResetCalibNeuronChanged_S,
			ChangeAcknowledged_SI => ResetCalibNeuronSent_S);

	detectTypeNCalibNeuronChange : entity work.ChangeDetector
		generic map(
			SIZE => 1)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D(0)        => ChipConfigReg_D.TypeNCalibNeuron_S,
			ChangeDetected_SO     => TypeNCalibNeuronChanged_S,
			ChangeAcknowledged_SI => TypeNCalibNeuronSent_S);

	detectResetTestPixelChange : entity work.ChangeDetector
		generic map(
			SIZE => 1)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D(0)        => ChipConfigReg_D.ResetTestPixel_S,
			ChangeDetected_SO     => ResetTestPixelChanged_S,
			ChangeAcknowledged_SI => ResetTestPixelSent_S);

	detectHotPixelSuppressionChange : entity work.ChangeDetector
		generic map(
			SIZE => 1)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D(0)        => ChipConfigReg_D.HotPixelSuppression_S,
			ChangeDetected_SO     => HotPixelSuppressionChanged_S,
			ChangeAcknowledged_SI => HotPixelSuppressionSent_S);

	detectAERnArowChange : entity work.ChangeDetector
		generic map(
			SIZE => 1)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D(0)        => ChipConfigReg_D.AERnArow_S,
			ChangeDetected_SO     => AERnArowChanged_S,
			ChangeAcknowledged_SI => AERnArowSent_S);

	detectUseAOutChange : entity work.ChangeDetector
		generic map(
			SIZE => 1)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D(0)        => ChipConfigReg_D.UseAOut_S,
			ChangeDetected_SO     => UseAOutChanged_S,
			ChangeAcknowledged_SI => UseAOutSent_S);

	detectGlobalShutterChange : entity work.ChangeDetector
		generic map(
			SIZE => 1)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D(0)        => ChipConfigReg_D.GlobalShutter_S,
			ChangeDetected_SO     => GlobalShutterChanged_S,
			ChangeAcknowledged_SI => GlobalShutterSent_S);
end architecture Behavioral;
