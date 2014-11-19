library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.ExtInputConfigRecords.all;
use work.Settings.LOGIC_CLOCK_FREQ;

entity ExtInputStateMachine is
	generic(
		ENABLE_GENERATOR : boolean := true);
	port(
		Clock_CI              : in  std_logic;
		Reset_RI              : in  std_logic;

		-- Fifo output (to Multiplexer)
		OutFifoControl_SI     : in  tFromFifoWriteSide;
		OutFifoControl_SO     : out tToFifoWriteSide;
		OutFifoData_DO        : out std_logic_vector(EVENT_WIDTH - 1 downto 0);

		-- Input from jack
		ExtInputSignal_SI     : in  std_logic;

		-- Output to jack
		CustomOutputSignal_SI : in  std_logic;
		ExtInputSignal_SO     : out std_logic;

		-- Configuration input
		ExtInputConfig_DI     : in  tExtInputConfig);
end entity ExtInputStateMachine;

architecture Behavioral of ExtInputStateMachine is
	attribute syn_enum_encoding : string;

	type tState is (stIdle, stWriteRisingEdgeEvent, stWriteFallingEdgeEvent, stWritePulseEvent);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : tState;

	-- Number of cycles to get a 100 ns time slice at current logic frequency.
	constant INTERNAL_TIME_CYCLES      : integer := LOGIC_CLOCK_FREQ / 10;
	constant INTERNAL_TIME_CYCLES_SIZE : integer := integer(ceil(log2(real(INTERNAL_TIME_CYCLES + 1))));

	-- Multiply configuration input with number of cycles needed to attain right timing.
	constant EXTERNAL_CYCLES_SIZE : integer := MAX_TIME_SIZE + INTERNAL_TIME_CYCLES_SIZE;
	signal DetectPulseLength_D    : unsigned(EXTERNAL_CYCLES_SIZE - 1 downto 0);

	-- Detector signals.
	signal RisingEdgeDetected_S  : std_logic;
	signal FallingEdgeDetected_S : std_logic;
	signal PulseDetected_S       : std_logic;

	-- Register configuration inputs.
	signal ExtInputConfigReg_D : tExtInputConfig;
begin
	extInputDetectorLogic : process(State_DP, OutFifoControl_SI, ExtInputConfigReg_D, FallingEdgeDetected_S, PulseDetected_S, RisingEdgeDetected_S)
	begin
		State_DN <= State_DP;           -- Keep current state by default.

		OutFifoData_DO            <= (others => '0');
		OutFifoControl_SO.Write_S <= '0';

		case State_DP is
			when stIdle =>
				-- Only exit idle state if External Input data producer is active and FIFO has space.
				if ExtInputConfigReg_D.RunDetector_S = '1' and OutFifoControl_SI.Full_S = '0' then
					-- TODO: verify what happens if/when multiple fire together.
					if ExtInputConfigReg_D.DetectRisingEdges_S = '1' and RisingEdgeDetected_S = '1' then
						State_DN <= stWriteRisingEdgeEvent;
					end if;
					if ExtInputConfigReg_D.DetectFallingEdges_S = '1' and FallingEdgeDetected_S = '1' then
						State_DN <= stWriteFallingEdgeEvent;
					end if;
					if ExtInputConfigReg_D.DetectPulses_S = '1' and PulseDetected_S = '1' then
						State_DN <= stWritePulseEvent;
					end if;
				end if;

			when stWriteRisingEdgeEvent =>
				OutFifoData_DO            <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_EXT_INPUT_RISING;
				OutFifoControl_SO.Write_S <= '1';
				State_DN                  <= stIdle;

			when stWriteFallingEdgeEvent =>
				OutFifoData_DO            <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_EXT_INPUT_FALLING;
				OutFifoControl_SO.Write_S <= '1';
				State_DN                  <= stIdle;

			when stWritePulseEvent =>
				OutFifoData_DO            <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_EXT_INPUT_PULSE;
				OutFifoControl_SO.Write_S <= '1';
				State_DN                  <= stIdle;

			when others => null;
		end case;
	end process extInputDetectorLogic;

	-- Change state on clock edge (synchronous).
	registerUpdate : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;

			ExtInputConfigReg_D <= tExtInputConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			ExtInputConfigReg_D <= ExtInputConfig_DI;
		end if;
	end process registerUpdate;

	extInputEdgeDetector : entity work.EdgeDetector
		generic map(
			SIGNAL_INITIAL_POLARITY => not tExtInputConfigDefault.DetectPulsePolarity_S)
		port map(
			Clock_CI               => Clock_CI,
			Reset_RI               => Reset_RI,
			InputSignal_SI         => ExtInputSignal_SI,
			RisingEdgeDetected_SO  => RisingEdgeDetected_S,
			FallingEdgeDetected_SO => FallingEdgeDetected_S);

	-- Calculate values in cycles for pulse detector and generator, by multiplying time-slice number by cycles in that time-slice.
	DetectPulseLength_D <= ExtInputConfigReg_D.DetectPulseLength_D * to_unsigned(INTERNAL_TIME_CYCLES, INTERNAL_TIME_CYCLES_SIZE);

	extInputPulseDetector : entity work.PulseDetector
		generic map(
			SIZE => EXTERNAL_CYCLES_SIZE)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			PulsePolarity_SI => ExtInputConfigReg_D.DetectPulsePolarity_S,
			PulseLength_DI   => DetectPulseLength_D,
			InputSignal_SI   => ExtInputSignal_SI,
			PulseDetected_SO => PulseDetected_S);

	generator : if ENABLE_GENERATOR = true generate
		-- Generator signal.
		signal GeneratedPulse_S    : std_logic;
		signal ExtInputOut_S       : std_logic;
		signal ExtInputSignalOut_S : std_logic;

		-- Generator configuration signals.
		signal GeneratePulseInterval_D : unsigned(EXTERNAL_CYCLES_SIZE - 1 downto 0);
		signal GeneratePulseLength_D   : unsigned(EXTERNAL_CYCLES_SIZE - 1 downto 0);
	begin
		-- Calculate values in cycles for pulse detector and generator, by multiplying time-slice number by cycles in that time-slice.
		GeneratePulseInterval_D <= ExtInputConfigReg_D.GeneratePulseInterval_D * to_unsigned(INTERNAL_TIME_CYCLES, INTERNAL_TIME_CYCLES_SIZE);
		GeneratePulseLength_D   <= ExtInputConfigReg_D.GeneratePulseLength_D * to_unsigned(INTERNAL_TIME_CYCLES, INTERNAL_TIME_CYCLES_SIZE);

		extInputPulseGenerator : entity work.PulseGenerator
			generic map(
				SIZE                    => EXTERNAL_CYCLES_SIZE,
				SIGNAL_INITIAL_POLARITY => not tExtInputConfigDefault.GeneratePulsePolarity_S)
			port map(
				Clock_CI         => Clock_CI,
				Reset_RI         => Reset_RI,
				PulsePolarity_SI => ExtInputConfigReg_D.GeneratePulsePolarity_S,
				PulseInterval_DI => GeneratePulseInterval_D,
				PulseLength_DI   => GeneratePulseLength_D,
				Zero_SI          => not ExtInputConfigReg_D.RunGenerator_S or ExtInputConfigReg_D.GenerateUseCustomSignal_S,
				PulseOut_SO      => GeneratedPulse_S);

		ExtInputOut_S       <= CustomOutputSignal_SI when (ExtInputConfigReg_D.GenerateUseCustomSignal_S = '1') else GeneratedPulse_S;
		ExtInputSignalOut_S <= ExtInputOut_S when (ExtInputConfigReg_D.RunGenerator_S = '1') else ExtInputSignal_SI;

		-- Register output to meet timing specifications.
		extInputSignalOutBuffer : entity work.SimpleRegister
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => ExtInputSignalOut_S,
				Output_SO(0) => ExtInputSignal_SO);
	end generate generator;

	generatorDisabled : if ENABLE_GENERATOR = false generate
		-- If generator disabled, just redirect input to output.
		ExtInputSignal_SO <= ExtInputSignal_SI;
	end generate generatorDisabled;
end architecture Behavioral;
