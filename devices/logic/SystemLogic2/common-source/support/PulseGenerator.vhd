library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Emit a PulseLength_DI-cycle pulse every PulseInterval_DI.
-- Can be reset to zero with the Zero_SI signal.
-- Please note that if SIGNAL_INITIAL_POLARITY and the actual
-- PulsePolarity_SI are equal at reset, there will be a one
-- cycle glitch (false pulse).
entity PulseGenerator is
	generic(
		SIZE                    : integer;
		SIGNAL_INITIAL_POLARITY : std_logic := '0');
	port(
		Clock_CI         : in  std_logic;
		Reset_RI         : in  std_logic;
		PulsePolarity_SI : in  std_logic;
		PulseInterval_DI : in  unsigned(SIZE - 1 downto 0);
		PulseLength_DI   : in  unsigned(SIZE - 1 downto 0);
		Zero_SI          : in  std_logic;
		PulseOut_SO      : out std_logic);
end PulseGenerator;

architecture Behavioral of PulseGenerator is
	-- present and next counter value
	signal IntervalCount_DP, IntervalCount_DN : unsigned(SIZE - 1 downto 0);
	signal LengthCount_DP, LengthCount_DN     : unsigned(SIZE - 1 downto 0);

	signal PulseOut_S       : std_logic;
	signal PulseOutBuffer_S : std_logic;
begin
	-- Variable width counter, calculation of next state
	generatePulseLogic : process(IntervalCount_DP, LengthCount_DP, Zero_SI, PulseInterval_DI, PulsePolarity_SI, PulseLength_DI)
	begin
		PulseOut_S <= not PulsePolarity_SI;

		if Zero_SI = '1' then
			-- Reset to one instead of zero, because we want PULSE_EVERY_CYCLES
			-- cycles to pass between the assertion of Clear_SI and the next
			-- pulse. This is the case without buffering the output, but with
			-- buffering, there is a one cycle delay, so we need to start with
			-- one increment already done to get the same behavior.
			IntervalCount_DN <= to_unsigned(1, IntervalCount_DN'length);
			LengthCount_DN   <= (others => '0');
		elsif IntervalCount_DP >= (PulseInterval_DI - 1) then
			IntervalCount_DN <= (others => '0');
			LengthCount_DN   <= to_unsigned(1, LengthCount_DN'length);

			PulseOut_S <= PulsePolarity_SI;
		else
			IntervalCount_DN <= IntervalCount_DP + 1;

			if LengthCount_DP >= 1 and LengthCount_DP < PulseLength_DI then
				LengthCount_DN <= LengthCount_DP + 1;

				PulseOut_S <= PulsePolarity_SI;
			else
				LengthCount_DN <= (others => '0');
			end if;
		end if;
	end process generatePulseLogic;

	-- Change state on clock edge (synchronous).
	registerUpdate : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			IntervalCount_DP <= (others => '0');
			LengthCount_DP   <= (others => '0');

			PulseOutBuffer_S <= SIGNAL_INITIAL_POLARITY;
		elsif rising_edge(Clock_CI) then
			IntervalCount_DP <= IntervalCount_DN;
			LengthCount_DP   <= LengthCount_DN;

			PulseOutBuffer_S <= PulseOut_S;
		end if;
	end process registerUpdate;

	PulseOut_SO <= PulseOutBuffer_S;
end Behavioral;
