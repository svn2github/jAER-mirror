library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Variable width counter that just cycles thorugh all binary values,
-- until it hits a configurable limit. This limit is provided by the
-- DataLimit_DI input, if not needed, just keep it at all ones.
entity ContinuousCounter is
	generic (
		COUNTER_WIDTH	  : integer := 16;
		RESET_ON_OVERFLOW : boolean := true);
	port (
		Clock_CI	 : in  std_logic;
		Reset_RI	 : in  std_logic;
		Clear_SI	 : in  std_logic;
		Enable_SI	 : in  std_logic;
		DataLimit_DI : in  unsigned(COUNTER_WIDTH-1 downto 0);
		Overflow_SO	 : out std_logic;
		Data_DO		 : out unsigned(COUNTER_WIDTH-1 downto 0));
end ContinuousCounter;

architecture Behavioral of ContinuousCounter is
	-- present and next state
	signal Count_DP, Count_DN : unsigned(COUNTER_WIDTH-1 downto 0);

	signal Overflow_S		: std_logic;
	signal OverflowBuffer_S : std_logic;
begin
	-- Variable width counter, calculation of next state
	p_memoryless : process (Count_DP, Clear_SI, Enable_SI, DataLimit_DI)
	begin  -- process p_memoryless
		Count_DN <= Count_DP;			-- Keep value by default.

		if Clear_SI = '1' and Enable_SI = '0' then
			Count_DN <= (others => '0');
		elsif Clear_SI = '0' and Enable_SI = '1' then
			Count_DN <= Count_DP + 1;

			if Count_DP = DataLimit_DI then
				if RESET_ON_OVERFLOW then
					Count_DN <= (others => '0');
				else
					Count_DN <= Count_DP;
				end if;
			end if;
		elsif Clear_SI = '1' and Enable_SI = '1' then
			-- Forget your count and reset to zero, as well as increment your
			-- count by one: end result is next count of one.
			Count_DN <= to_unsigned(1, COUNTER_WIDTH);
		end if;

		-- Determine overflow flag one cycle in advance, so that registering it
		-- at the output doesn't add more latency, since we want it to be
		-- asserted the cycle _before_ the buffer switches back to zero.
		Overflow_S <= '0';

		if Count_DP = (DataLimit_DI - 1) and Clear_SI = '0' and Enable_SI = '1' then
			Overflow_S <= '1';
		elsif Count_DP = DataLimit_DI and not RESET_ON_OVERFLOW then
			Overflow_S <= '1';
		end if;
	end process p_memoryless;

	-- Change state on clock edge (synchronous).
	p_memoryzing : process (Clock_CI, Reset_RI)
	begin  -- process p_memoryzing
		if Reset_RI = '1' then	-- asynchronous reset (active-high for FPGAs)
			Count_DP		 <= (others => '0');
			OverflowBuffer_S <= '0';
		elsif rising_edge(Clock_CI) then
			Count_DP		 <= Count_DN;
			OverflowBuffer_S <= Overflow_S;
		end if;
	end process p_memoryzing;

	-- Output present count (from register).
	Data_DO <= Count_DP;

	-- Output overflow (from register).
	Overflow_SO <= OverflowBuffer_S;
end Behavioral;
