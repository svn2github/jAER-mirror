library ieee;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Emit a one-cycle pulse every PULSE_EVERY_CYCLES.
-- Can be reset with the Clear_SI flag.
entity PulseGenerator is
	generic(
		PULSE_EVERY_CYCLES : integer;
		PULSE_POLARITY     : std_logic := '1');
	port(
		Clock_CI    : in  std_logic;
		Reset_RI    : in  std_logic;
		Clear_SI    : in  std_logic;
		PulseOut_SO : out std_logic);
end PulseGenerator;

architecture Behavioral of PulseGenerator is
	constant COUNTER_WIDTH : integer := integer(ceil(log2(real(PULSE_EVERY_CYCLES))));

	-- present and next state
	signal Count_DP, Count_DN : unsigned(COUNTER_WIDTH - 1 downto 0);

	signal PulseOut_S       : std_logic;
	signal PulseOutBuffer_S : std_logic;
begin
	-- Variable width counter, calculation of next state
	generatePulseLogic : process(Count_DP, Clear_SI)
	begin
		PulseOut_S <= not PULSE_POLARITY;

		if Clear_SI = '1' then
			-- Reset to one instead of zero, because we want PULSE_EVERY_CYCLES
			-- cycles to pass between the assertion of Clear_SI and the next
			-- pulse. This is the case without buffering the output, but with
			-- buffering, there is a one cycle delay, so we need to start with
			-- one increment already done to get the same behavior.
			Count_DN <= to_unsigned(1, Count_DN'length);
		elsif Count_DP = (PULSE_EVERY_CYCLES - 1) then
			Count_DN   <= (others => '0');
			PulseOut_S <= PULSE_POLARITY;
		else
			Count_DN <= Count_DP + 1;
		end if;
	end process generatePulseLogic;

	-- Change state on clock edge (synchronous).
	registerUpdate : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			Count_DP         <= (others => '0');
			PulseOutBuffer_S <= not PULSE_POLARITY;
		elsif rising_edge(Clock_CI) then
			Count_DP         <= Count_DN;
			PulseOutBuffer_S <= PulseOut_S;
		end if;
	end process registerUpdate;

	PulseOut_SO <= PulseOutBuffer_S;
end Behavioral;
