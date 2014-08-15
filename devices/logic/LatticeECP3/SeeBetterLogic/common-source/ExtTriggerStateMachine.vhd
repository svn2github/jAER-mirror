library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.ExtTriggerConfigRecords.all;
use work.Settings.LOGIC_CLOCK_FREQ;

entity ExtTriggerStateMachine is
	generic(
		ENABLE_GENERATOR : boolean := true);
	port(
		Clock_CI               : in  std_logic;
		Reset_RI               : in  std_logic;

		-- Fifo output (to Multiplexer)
		OutFifoControl_SI      : in  tFromFifoWriteSide;
		OutFifoControl_SO      : out tToFifoWriteSide;
		OutFifoData_DO         : out std_logic_vector(EVENT_WIDTH - 1 downto 0);

		-- Input from jack
		ExtTriggerSignal_SI    : in  std_logic;

		-- Output to jack
		CustomTriggerSignal_SI : in  std_logic;
		ExtTriggerSignal_SO    : out std_logic;

		-- Configuration input
		ExtTriggerConfig_DI    : in  tExtTriggerConfig);
end entity ExtTriggerStateMachine;

architecture Behavioral of ExtTriggerStateMachine is
	attribute syn_enum_encoding : string;

	type state is (stIdle, stWriteRisingEdgeEvent, stWriteFallingEdgeEvent, stWritePulseEvent);
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

	-- Number of cycles to get a 100 ns time slice at current logic frequency.
	constant TRIGGER_TIME_CYCLES      : integer := LOGIC_CLOCK_FREQ / 10;
	constant TRIGGER_TIME_CYCLES_SIZE : integer := integer(ceil(log2(real(TRIGGER_TIME_CYCLES + 1))));

	-- Multiply configuration input with number of cycles needed to attain right timing.
	constant TRIGGER_CYCLES_SIZE : integer := MAX_TRIGGER_TIME_SIZE + TRIGGER_TIME_CYCLES_SIZE;
	signal DetectPulseLength_D   : unsigned(TRIGGER_CYCLES_SIZE - 1 downto 0);

	-- Detector signals.
	signal RisingEdgeDetected_S  : std_logic;
	signal FallingEdgeDetected_S : std_logic;
	signal PulseDetected_S       : std_logic;

	-- Register configuration inputs.
	signal ExtTriggerConfig_D : tExtTriggerConfig;
begin
	extTriggerDetectorLogic : process(State_DP, OutFifoControl_SI, ExtTriggerConfig_D, FallingEdgeDetected_S, PulseDetected_S, RisingEdgeDetected_S)
	begin
		State_DN <= State_DP;           -- Keep current state by default.

		OutFifoData_DO            <= (others => '0');
		OutFifoControl_SO.Write_S <= '0';

		case State_DP is
			when stIdle =>
				-- Only exit idle state if External Trigger data producer is active and FIFO has space.
				if ExtTriggerConfig_D.RunDetector_S = '1' and OutFifoControl_SI.Full_S = '0' then
					-- TODO: verify what happens if/when multiple fire together.
					if ExtTriggerConfig_D.DetectRisingEdges_S = '1' and RisingEdgeDetected_S = '1' then
						State_DN <= stWriteRisingEdgeEvent;
					end if;
					if ExtTriggerConfig_D.DetectFallingEdges_S = '1' and FallingEdgeDetected_S = '1' then
						State_DN <= stWriteFallingEdgeEvent;
					end if;
					if ExtTriggerConfig_D.DetectPulses_S = '1' and PulseDetected_S = '1' then
						State_DN <= stWritePulseEvent;
					end if;
				end if;

			when stWriteRisingEdgeEvent =>
				OutFifoData_DO            <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_EXT_TRIGGER_RISING;
				OutFifoControl_SO.Write_S <= '1';
				State_DN                  <= stIdle;

			when stWriteFallingEdgeEvent =>
				OutFifoData_DO            <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_EXT_TRIGGER_FALLING;
				OutFifoControl_SO.Write_S <= '1';
				State_DN                  <= stIdle;

			when stWritePulseEvent =>
				OutFifoData_DO            <= EVENT_CODE_SPECIAL & EVENT_CODE_SPECIAL_EXT_TRIGGER_PULSE;
				OutFifoControl_SO.Write_S <= '1';
				State_DN                  <= stIdle;

			when others => null;
		end case;
	end process extTriggerDetectorLogic;

	-- Change state on clock edge (synchronous).
	registerUpdate : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;

			ExtTriggerConfig_D <= tExtTriggerConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			ExtTriggerConfig_D <= ExtTriggerConfig_DI;
		end if;
	end process registerUpdate;

	extTriggerEdgeDetector : entity work.EdgeDetector
		generic map(
			SIGNAL_INITIAL_POLARITY => '0')
		port map(
			Clock_CI               => Clock_CI,
			Reset_RI               => Reset_RI,
			InputSignal_SI         => ExtTriggerSignal_SI,
			RisingEdgeDetected_SO  => RisingEdgeDetected_S,
			FallingEdgeDetected_SO => FallingEdgeDetected_S);

	-- Calculate values in cycles for pulse detector and generator, by multiplying time-slice number by cycles in that time-slice.
	DetectPulseLength_D <= ExtTriggerConfig_D.DetectPulseLength_D * to_unsigned(TRIGGER_TIME_CYCLES, TRIGGER_TIME_CYCLES_SIZE);

	extTriggerPulseDetector : entity work.PulseDetector
		generic map(
			SIZE => TRIGGER_CYCLES_SIZE)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			PulsePolarity_SI => ExtTriggerConfig_D.DetectPulsePolarity_S,
			PulseLength_DI   => DetectPulseLength_D,
			InputSignal_SI   => ExtTriggerSignal_SI,
			PulseDetected_SO => PulseDetected_S);

	generator : if ENABLE_GENERATOR = true generate
		-- Generator signal.
		signal GeneratedPulse_S      : std_logic;
		signal ExtTriggerSignalOut_S : std_logic;

		-- Generator configuration signals.
		signal GeneratePulseInterval_D : unsigned(TRIGGER_CYCLES_SIZE - 1 downto 0);
		signal GeneratePulseLength_D   : unsigned(TRIGGER_CYCLES_SIZE - 1 downto 0);
	begin
		-- Calculate values in cycles for pulse detector and generator, by multiplying time-slice number by cycles in that time-slice.
		GeneratePulseInterval_D <= ExtTriggerConfig_D.GeneratePulseInterval_D * to_unsigned(TRIGGER_TIME_CYCLES, TRIGGER_TIME_CYCLES_SIZE);
		GeneratePulseLength_D   <= ExtTriggerConfig_D.GeneratePulseLength_D * to_unsigned(TRIGGER_TIME_CYCLES, TRIGGER_TIME_CYCLES_SIZE);

		extTriggerPulseGenerator : entity work.PulseGenerator
			generic map(
				SIZE                    => TRIGGER_CYCLES_SIZE,
				SIGNAL_INITIAL_POLARITY => '0')
			port map(
				Clock_CI         => Clock_CI,
				Reset_RI         => Reset_RI,
				PulsePolarity_SI => ExtTriggerConfig_D.GeneratePulsePolarity_S,
				PulseInterval_DI => GeneratePulseInterval_D,
				PulseLength_DI   => GeneratePulseLength_D,
				Zero_SI          => not ExtTriggerConfig_D.RunGenerator_S,
				PulseOut_SO      => GeneratedPulse_S);

		ExtTriggerSignalOut_S <= CustomTriggerSignal_SI when (ExtTriggerConfig_D.RunGenerator_S = '1' and ExtTriggerConfig_D.GenerateUseCustomSignal_S = '1') else GeneratedPulse_S;

		-- Register output to meet timing specifications.
		extTriggerSignalOutBuffer : entity work.SimpleRegister
			generic map(
				SIZE        => 1,
				RESET_VALUE => false)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => ExtTriggerSignalOut_S,
				Output_SO(0) => ExtTriggerSignal_SO);
	end generate generator;

	generatorDisabled : if ENABLE_GENERATOR = false generate
		-- Output overflow (constant zero).
		ExtTriggerSignal_SO <= '0';
	end generate generatorDisabled;
end architecture Behavioral;
