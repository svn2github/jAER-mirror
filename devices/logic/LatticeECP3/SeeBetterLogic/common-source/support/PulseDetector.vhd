library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

entity PulseDetector is
	generic (
		PULSE_MINIMAL_LENGTH_CYCLES : integer	:= 50;
		PULSE_POLARITY				: std_logic := '1');
	port (
		Clock_CI		 : in  std_logic;
		Reset_RI		 : in  std_logic;
		InputSignal_SI	 : in  std_logic;
		-- Pulse will follow one cycle after the minimal length has been reached.
		PulseDetected_SO : out std_logic);
end PulseDetector;

architecture Behavioral of PulseDetector is
	type state is (stWaitForPulse, stPulseDetected, stPulseOverflow);

	attribute syn_enum_encoding			 : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

	constant COUNTER_WIDTH : integer := integer(ceil(log2(real(PULSE_MINIMAL_LENGTH_CYCLES))));

	-- present and next state
	signal Count_DP, Count_DN : unsigned(COUNTER_WIDTH-1 downto 0);

	signal PulseDetected_S		 : std_logic;
	signal PulseDetectedBuffer_S : std_logic;
begin
	-- Variable width counter, calculation of next state
	p_memoryless : process (State_DP, Count_DP, InputSignal_SI)
	begin  -- process p_memoryless
		State_DN <= State_DP;			-- Keep current state by default.
		Count_DN <= (others => '0');	-- Keep at zero by default.

		PulseDetected_S <= '0';

		case State_DP is
			when stWaitForPulse =>
				if InputSignal_SI = PULSE_POLARITY then
					-- Pulse detected!
					State_DN <= stPulseDetected;
				end if;

			when stPulseDetected =>
				-- Verify length of detected pulse.
				if Count_DP = (PULSE_MINIMAL_LENGTH_CYCLES - 1) then
					-- Pulse hit expected length, send signal.
					PulseDetected_S <= '1';

					if InputSignal_SI = PULSE_POLARITY then
						-- Pulse continues existing, go to wait it out.
						State_DN <= stPulseOverflow;
					else
						-- Pulse disappeared right after reaching goal.
						State_DN <= stWaitForPulse;
					end if;
				else
					if InputSignal_SI = PULSE_POLARITY then
						-- Pulse continues, keep increasing count.
						Count_DN <= Count_DP + 1;
					else
						-- Pulse disappeared before reaching minimun length.
						State_DN <= stWaitForPulse;
					end if;
				end if;

			when stPulseOverflow =>
				-- Keep this state until the pulse changes.
				if InputSignal_SI = not PULSE_POLARITY then
					State_DN <= stWaitForPulse;
				end if;

			when others => null;
		end case;
	end process p_memoryless;

	-- Change state on clock edge (synchronous).
	p_memoryzing : process (Clock_CI, Reset_RI)
	begin  -- process p_memoryzing
		if Reset_RI = '1' then	-- asynchronous reset (active-high for FPGAs)
			State_DP			  <= stWaitForPulse;
			Count_DP			  <= (others => '0');
			PulseDetectedBuffer_S <= '0';
		elsif rising_edge(Clock_CI) then
			State_DP			  <= State_DN;
			Count_DP			  <= Count_DN;
			PulseDetectedBuffer_S <= PulseDetected_S;
		end if;
	end process p_memoryzing;

	PulseDetected_SO <= PulseDetectedBuffer_S;
end Behavioral;
