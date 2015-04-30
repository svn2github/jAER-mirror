--------------------------------------------------------------------------------
-- Company: INI, iniLabs
-- Engineer: Diederik Paul Moeys, Luca Longinotti
--
-- Create Date:  23.04.2015
-- Design Name:  DAVIS208
-- Module Name:  PreAmplifierBiasStateMachine
-- Project Name: VISUALISE
-- Description:	 Module to automatically change the bias setting of the 
--               pre-amplifier in the pixel so that it does not saturate
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Libraries -------------------------------------------------------------------
-------------------------------------------------------------------------------- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ChipBiasConfigRecords.BIAS_CF_LENGTH;
use work.PreAmplifierBiasConfigRecords.all;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Entity Declaration ----------------------------------------------------------
--------------------------------------------------------------------------------
entity PreAmplifierBiasStateMachine is
	port(
		-- Clock and reset inputs
		Clock_CI                  : in  std_logic;
		Reset_RI                  : in  std_logic;
		
		-- Input and Outputs
		VpreAmpAvg_DI             : in  unsigned(9 downto 0); -- Mean pre-amplifier output as sampled by 10-bit ADC
		VrefSsBn_DO               : out unsigned(BIAS_CF_LENGTH - 1 downto 0); -- Chosen bias to be applied to the Shifted-source OTA
		BiasChangeFlag_DO         : out std_logic; -- Flag telling that the change is needed

		-- Receive Parameters
		PreAmplifierBiasConfig_DI : in  tPreAmplifierBiasConfig);
end PreAmplifierBiasStateMachine;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------  

--------------------------------------------------------------------------------
-- Architecture Declaration ----------------------------------------------------
--------------------------------------------------------------------------------
architecture Behavioral of PreAmplifierBiasStateMachine is
	-- States
	type tState is (Idle, ADCSample1, ADCSample2, ADCSample3, ADCSample4, Average, Compare, IncreaseBias, DecreaseBias);
	signal State_DP, State_DN : tState; -- Current state and Next state

	-- Register the configuration.
	signal PreAmplifierBiasConfigReg_D : tPreAmplifierBiasConfig;

	-- Only count when actually needed.
	signal ADCSamplingCounterEnable_S : std_logic;

	-- Signals
	signal ADCSamplingCounterOVF_S                      : std_logic; -- Counter overflow
	signal VpreAmpAccumulator_DP, VpreAmpAccumulator_DN : unsigned(9 downto 0); -- Accumulate and keep the current value.

	type tBiasArray is array (7 downto 0) of unsigned(BIAS_CF_LENGTH - 1 downto 0);
	constant BIAS_LUT : tBiasArray := ("000000000000000",
		                               "000000000000000",
		                               "000000000000000",
		                               "000000000000000",
		                               "000000000000000",
		                               "000000000000000",
		                               "000000000000000",
		                               "000000000000000"); -- Lookup table of biases to use
	signal LUTIndex_DP, LUTIndex_DN : unsigned(2 downto 0);
begin
	VrefSsBn_DO <= BIAS_LUT(to_integer(LUTIndex_DP));

	--------------------------------------------------------------------------------
	-- Instantiate ADCSamplingCounter
	ADCSamplingCounter : entity work.ContinuousCounter
		generic map(
			SIZE              => ADC_SAMPLE_TIME_SIZE, -- Maximum possible size
			RESET_ON_OVERFLOW => true,  -- Reset when full (independent) 
			GENERATE_OVERFLOW => true,  -- Don't generate overflow
			SHORT_OVERFLOW    => false, -- Keep the overflow
			OVERFLOW_AT_ZERO  => false) -- Overflow at "111.." not "000.." (Reset)
		port map(
			Clock_CI     => Clock_CI,   -- Share the same clock
			Reset_RI     => Reset_RI,   -- Share the same asynchronous reset
			Clear_SI     => '0',        -- Clear with reset as well
			Enable_SI    => ADCSamplingCounterEnable_S, -- Only when needed
			DataLimit_DI => PreAmplifierBiasConfigReg_D.ADCSamplingTime_S, -- Set the counter's limit (set the maximum counting time)
			Overflow_SO  => ADCSamplingCounterOVF_S, -- Get the counter's overflow
			Data_DO      => open);      -- Leave unconnected
	--------------------------------------------------------------------------------
	Sequential : process(Clock_CI, Reset_RI) -- Sequential Process
	begin
		-- External reset
		if (Reset_RI = '1') then
			State_DP <= Idle;

			PreAmplifierBiasConfigReg_D <= tPreAmplifierBiasConfigDefault;

			VpreAmpAccumulator_DP <= (others => '0');
			LUTIndex_DP           <= to_unsigned(4, 3);
		---------------------------------------------------------------------------------
		-- At every clock cycle
		elsif (Rising_edge(Clock_CI)) then
			State_DP <= State_DN;       -- Assign next state to current state

			PreAmplifierBiasConfigReg_D <= PreAmplifierBiasConfig_DI;

			VpreAmpAccumulator_DP <= VpreAmpAccumulator_DN;
			LUTIndex_DP           <= LUTIndex_DN;
		end if;
	end process Sequential;

	--------------------------------------------------------------------------------
	Combinational : process(State_DP, ADCSamplingCounterOVF_S, VpreAmpAccumulator_DP, LUTIndex_DP, PreAmplifierBiasConfigReg_D, VpreAmpAvg_DI) -- Combinational Process
	begin
		State_DN <= State_DP;           -- Keep the same state

		VpreAmpAccumulator_DN <= VpreAmpAccumulator_DP; -- By default, keep value intact.
		LUTIndex_DN           <= LUTIndex_DP;

		ADCSamplingCounterEnable_S <= '0';

		BiasChangeFlag_DO <= '0';

		case State_DP is
			when Idle =>
				if PreAmplifierBiasConfigReg_D.Run_S = '1' then
					State_DN <= ADCSample1;
				end if;

			when ADCSample1 =>
				ADCSamplingCounterEnable_S <= '1';

				if (ADCSamplingCounterOVF_S = '1') then
					State_DN <= ADCSample2;

					VpreAmpAccumulator_DN <= VpreAmpAvg_DI;
				end if;

			when ADCSample2 =>
				ADCSamplingCounterEnable_S <= '1';

				if (ADCSamplingCounterOVF_S = '1') then
					State_DN <= ADCSample3;

					VpreAmpAccumulator_DN <= VpreAmpAvg_DI + VpreAmpAccumulator_DP;
				end if;

			when ADCSample3 =>
				ADCSamplingCounterEnable_S <= '1';

				if (ADCSamplingCounterOVF_S = '1') then
					State_DN <= ADCSample4;

					VpreAmpAccumulator_DN <= VpreAmpAvg_DI + VpreAmpAccumulator_DP;
				end if;

			when ADCSample4 =>
				ADCSamplingCounterEnable_S <= '1';

				if (ADCSamplingCounterOVF_S = '1') then
					State_DN <= Average;

					VpreAmpAccumulator_DN <= VpreAmpAvg_DI + VpreAmpAccumulator_DP;
				end if;

			when Average =>
				VpreAmpAccumulator_DN <= "00" & VpreAmpAccumulator_DP(9 downto 2);

				State_DN <= Compare;

			when Compare =>
				if (VpreAmpAccumulator_DP > PreAmplifierBiasConfigReg_D.HighThreshold_S) then
					State_DN <= IncreaseBias;
				elsif (VpreAmpAccumulator_DP < PreAmplifierBiasConfigReg_D.LowThreshold_S) then
					State_DN <= DecreaseBias;
				else
					-- If in good range, no change.
					State_DN <= Idle;
				end if;

			when IncreaseBias =>
				State_DN <= Idle;

				if LUTIndex_DP /= 7 then
					LUTIndex_DN       <= LUTIndex_DP + 1;
					BiasChangeFlag_DO <= '1';
				end if;

			when DecreaseBias =>
				State_DN <= Idle;

				if LUTIndex_DP /= 0 then
					LUTIndex_DN       <= LUTIndex_DP - 1;
					BiasChangeFlag_DO <= '1';
				end if;

			when others => null;
		end case;
	end process Combinational;

--------------------------------------------------------------------------------
end Behavioral;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------