library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Detect a pulse on a signal of a certain minimal length.
-- If one is found, emit an active-high detection signal for
-- one clock cycle, and then wait for the current pulse to
-- finish, and a new one with the wanted length to arrive,
-- and the above repeats.
entity PulseDetector is
	generic(
		SIZE : integer);
	port(
		Clock_CI         : in  std_logic;
		Reset_RI         : in  std_logic;
		PulsePolarity_SI : in  std_logic;
		PulseLength_DI   : in  unsigned(SIZE - 1 downto 0);
		InputSignal_SI   : in  std_logic;
		-- Pulse will follow one cycle after the minimal length has been reached.
		PulseDetected_SO : out std_logic);
end PulseDetector;

architecture Behavioral of PulseDetector is
	attribute syn_enum_encoding : string;

	type tState is (stWaitForPulse, stPulseDetected, stPulseOverflowWait);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : tState;

	-- present and next state
	signal Count_DP, Count_DN : unsigned(SIZE - 1 downto 0);

	signal PulseDetected_S       : std_logic;
	signal PulseDetectedBuffer_S : std_logic;
begin
	-- Next counter value, calculation of next state.
	detectPulseLogic : process(State_DP, Count_DP, InputSignal_SI, PulseLength_DI, PulsePolarity_SI)
	begin
		State_DN <= State_DP;           -- Keep current state by default.
		Count_DN <= (others => '0');    -- Keep at zero by default.

		PulseDetected_S <= '0';

		case State_DP is
			when stWaitForPulse =>
				if InputSignal_SI = PulsePolarity_SI then
					-- Pulse detected!
					State_DN <= stPulseDetected;
				end if;

			when stPulseDetected =>
				-- Verify length of detected pulse.
				if Count_DP >= PulseLength_DI then
					-- Pulse hit expected length, send signal.
					PulseDetected_S <= '1';

					if InputSignal_SI = PulsePolarity_SI then
						-- Pulse continues existing, go to wait it out.
						State_DN <= stPulseOverflowWait;
					else
						-- Pulse disappeared right after reaching goal.
						State_DN <= stWaitForPulse;
					end if;
				else
					if InputSignal_SI = PulsePolarity_SI then
						-- Pulse continues, keep increasing count.
						Count_DN <= Count_DP + 1;
					else
						-- Pulse disappeared before reaching minimun length.
						State_DN <= stWaitForPulse;
					end if;
				end if;

			when stPulseOverflowWait =>
				-- Keep this state until the pulse changes.
				if InputSignal_SI = (not PulsePolarity_SI) then
					State_DN <= stWaitForPulse;
				end if;

			when others => null;
		end case;
	end process detectPulseLogic;

	-- Change state on clock edge (synchronous).
	registerUpdate : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP              <= stWaitForPulse;
			Count_DP              <= (others => '0');
			PulseDetectedBuffer_S <= '0';
		elsif rising_edge(Clock_CI) then
			State_DP              <= State_DN;
			Count_DP              <= Count_DN;
			PulseDetectedBuffer_S <= PulseDetected_S;
		end if;
	end process registerUpdate;

	PulseDetected_SO <= PulseDetectedBuffer_S;
end Behavioral;
