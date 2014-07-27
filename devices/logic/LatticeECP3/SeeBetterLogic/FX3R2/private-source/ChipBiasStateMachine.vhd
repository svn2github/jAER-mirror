library ieee;
use ieee.std_logic_1164.all;
use work.ChipBiasConfigRecords.all;

entity ChipBiasStateMachine is
	port(
		Clock_CI      : in std_logic;
		Reset_RI      : in std_logic;

		-- Configuration inputs
		BiasConfig_DI : in tBiasConfig;
		ChipConfig_DI : in tChipConfig
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
	signal UseAOutChanged_S, UseAOutSent_S                         : std_logic;
	signal NArowChanged_S, NArowSent_S                             : std_logic;
	signal ResetTestPixelChanged_S, ResetTestPixelSent_S           : std_logic;
	signal TypeNCalibChanged_S, TypeNCalibSent_S                   : std_logic;
	signal ResetCalibChanged_S, ResetCalibSent_S                   : std_logic;
	signal HotPixelSuppressionChanged_S, HotPixelSuppressionSent_S : std_logic;
	signal GlobalShutterChanged_S, GlobalShutterSent_S             : std_logic;
begin
	sendConfig : process is
	begin
		State_DN <= State_DP;

		case State_DP is
			when stIdle           =>
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

	detectBias0Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.DiffBn_D,
			ChangeDetected_SO     => Bias0Changed_S,
			ChangeAcknowledged_SI => Bias0Sent_S);

	detectBias1Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.OnBn_D,
			ChangeDetected_SO     => Bias1Changed_S,
			ChangeAcknowledged_SI => Bias1Sent_S);

	detectBias2Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.OffBn_D,
			ChangeDetected_SO     => Bias2Changed_S,
			ChangeAcknowledged_SI => Bias2Sent_S);

	detectBias3Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.ApsCasEpc_D,
			ChangeDetected_SO     => Bias3Changed_S,
			ChangeAcknowledged_SI => Bias3Sent_S);

	detectBias4Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.DiffCasBnc_D,
			ChangeDetected_SO     => Bias4Changed_S,
			ChangeAcknowledged_SI => Bias4Sent_S);

	detectBias5Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.ApsROSFBn_D,
			ChangeDetected_SO     => Bias5Changed_S,
			ChangeAcknowledged_SI => Bias5Sent_S);

	detectBias6Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.LocalBufBn_D,
			ChangeDetected_SO     => Bias6Changed_S,
			ChangeAcknowledged_SI => Bias6Sent_S);

	detectBias7Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.PixInvBn_D,
			ChangeDetected_SO     => Bias7Changed_S,
			ChangeAcknowledged_SI => Bias7Sent_S);

	detectBias8Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.PrBp_D,
			ChangeDetected_SO     => Bias8Changed_S,
			ChangeAcknowledged_SI => Bias8Sent_S);

	detectBias9Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.PrSFBp_D,
			ChangeDetected_SO     => Bias9Changed_S,
			ChangeAcknowledged_SI => Bias9Sent_S);

	detectBias10Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.RefrBp_D,
			ChangeDetected_SO     => Bias10Changed_S,
			ChangeAcknowledged_SI => Bias10Sent_S);

	detectBias11Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.AEPdBn_D,
			ChangeDetected_SO     => Bias11Changed_S,
			ChangeAcknowledged_SI => Bias11Sent_S);

	detectBias12Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.LcolTimeoutBn_D,
			ChangeDetected_SO     => Bias12Changed_S,
			ChangeAcknowledged_SI => Bias12Sent_S);

	detectBias13Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.AEPuXBp_D,
			ChangeDetected_SO     => Bias13Changed_S,
			ChangeAcknowledged_SI => Bias13Sent_S);

	detectBias14Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.AEPuYBp_D,
			ChangeDetected_SO     => Bias14Changed_S,
			ChangeAcknowledged_SI => Bias14Sent_S);

	detectBias15Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.IFThrBn_D,
			ChangeDetected_SO     => Bias15Changed_S,
			ChangeAcknowledged_SI => Bias15Sent_S);

	detectBias16Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.IFRefrBn_D,
			ChangeDetected_SO     => Bias16Changed_S,
			ChangeAcknowledged_SI => Bias16Sent_S);

	detectBias17Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.PadFollBn_D,
			ChangeDetected_SO     => Bias17Changed_S,
			ChangeAcknowledged_SI => Bias17Sent_S);

	detectBias18Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.ApsOverflowLevel_D,
			ChangeDetected_SO     => Bias18Changed_S,
			ChangeAcknowledged_SI => Bias18Sent_S);

	detectBias19Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_CF_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.BiasBuffer_D,
			ChangeDetected_SO     => Bias19Changed_S,
			ChangeAcknowledged_SI => Bias19Sent_S);

	detectBias20Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_SS_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.SSP_D,
			ChangeDetected_SO     => Bias20Changed_S,
			ChangeAcknowledged_SI => Bias20Sent_S);

	detectBias21Change : entity work.ChangeDetector
		generic map(
			SIZE => BIAS_SS_LENGTH)
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			InputData_D           => BiasConfig_DI.SSN_D,
			ChangeDetected_SO     => Bias21Changed_S,
			ChangeAcknowledged_SI => Bias21Sent_S);
end architecture Behavioral;
