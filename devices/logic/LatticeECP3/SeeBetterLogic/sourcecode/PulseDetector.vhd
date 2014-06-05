library IEEE;
use IEEE.MATH_REAL."ceil";
use IEEE.MATH_REAL."log2";
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity PulseDetector is
	generic (
		PULSE_MINIMAL_LENGTH_CYCLES : integer := 50;
		PULSE_POLARITY : std_logic := '1');
	port (
		Clock_CI : in std_logic;
		Reset_RI : in std_logic;
		InputSignal_SI : in std_logic;
		PulseDetected_SO : out std_logic);
end PulseDetector;

architecture Behavioral of PulseDetector is
	type state is (stWaitForPulse, stPulseDetected, stPulseOverflow);

	attribute syn_enum_encoding : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

	constant COUNTER_WIDTH : integer := integer(ceil(log2(real(PULSE_MINIMAL_LENGTH_CYCLES))));

	-- present and next state
	signal Count_DP, Count_DN : unsigned(COUNTER_WIDTH-1 downto 0);
begin
	-- Variable width counter, calculation of next state
	p_memoryless : process (State_DP, Count_DP, InputSignal_SI)
	begin -- process p_memoryless
		State_DN <= State_DP; -- Keep current state by default.
		Count_DN <= (others => '0'); -- Keep at zero by default.

		PulseDetected_SO <= '0';

		case State_DP is
			when stWaitForPulse =>
				if InputSignal_SI = PULSE_POLARITY then
					-- Pulse detected!
					State_DN <= stPulseDetected;
				end if;

			when stPulseDetected =>
				if InputSignal_SI = PULSE_POLARITY then
					-- Pulse continues, keep increasing count.
					Count_DN <= Count_DP + 1;

					-- Verify length of detected pulse.
					if Count_DP = (PULSE_MINIMAL_LENGTH_CYCLES - 1) then
						-- Pulse hit expected length, send signal.
						PulseDetected_SO <= '1';
						State_DN <= stPulseOverflow;
					end if;
				else
					-- Pulse disappeared before reaching minimun lenght.
					State_DN <= stWaitForPulse;
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
		if Reset_RI = '1' then -- asynchronous reset (active-high for FPGAs)
			State_DP <= stWaitForPulse;
			Count_DP <= (others => '0');
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;
			Count_DP <= Count_DN;
		end if;
	end process p_memoryzing;
end Behavioral;
