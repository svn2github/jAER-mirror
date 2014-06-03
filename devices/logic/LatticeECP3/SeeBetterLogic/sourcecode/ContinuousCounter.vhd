library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Variable width counter that just cycles thorugh all binary values,
-- until it hits a configurable limit. This limit is provided by the
-- DataLimit_DI input, if not needed, just keep it at all ones.
entity ContinuousCounter is
	generic (
		COUNTER_WIDTH : integer := 16;
		RESET_ON_OVERFLOW : boolean := true);
	port (
		Clock_CI : in std_logic;
		Reset_RBI : in std_logic;
		Clear_SI : in std_logic;
		Enable_SI : in std_logic;
		DataLimit_DI : in unsigned(COUNTER_WIDTH-1 downto 0);
		Overflow_SO : out std_logic;
		Data_DO : out unsigned(COUNTER_WIDTH-1 downto 0));
end ContinuousCounter;

architecture Behavioral of ContinuousCounter is
	-- present and next state
	signal Count_DP, Count_DN : unsigned(COUNTER_WIDTH-1 downto 0);
begin
	-- Output present count.
	Data_DO <= Count_DP;

	-- Variable width counter, calculation of next state
	p_memoryless : process (Count_DP, Clear_SI, Enable_SI, DataLimit_DI)
	begin -- process p_memoryless
		Count_DN <= Count_DP; -- Keep value by default.

		Overflow_SO <= '0'; -- No overflow, only on equality.

		if Clear_SI = '1' then
			Count_DN <= (others => '0');
		elsif Count_DP = DataLimit_DI then
			Overflow_SO <= '1';

			if RESET_ON_OVERFLOW then
				Count_DN <= (others => '0');
			end if;
		elsif Enable_SI = '1' then
			Count_DN <= Count_DP + 1;
		end if;
	end process p_memoryless;

	-- Change state on clock edge (synchronous).
	p_memoryzing : process (Clock_CI, Reset_RBI)
	begin  -- process p_memoryzing
		if Reset_RBI = '0' then -- asynchronous reset (active low)
			Count_DP <= (others => '0');
		elsif rising_edge(Clock_CI) then
			Count_DP <= Count_DN;
		end if;
	end process p_memoryzing;
end Behavioral;
