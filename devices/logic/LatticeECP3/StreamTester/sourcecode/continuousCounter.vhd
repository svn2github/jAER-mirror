library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

-- 16 bit counter that just cycles thorugh all binary values.
-- Used for verification purposes (stream testing).
entity continuousCounter is
	port (
		Clock_CI : in std_logic;
		Reset_RBI : in std_logic;
		CountEnable_SI : in std_logic;
		Data_DO : out std_logic_vector(15 downto 0));
end continuousCounter;

architecture Behavioral of continuousCounter is
	-- present and next state
	signal Count_DP, Count_DN : std_logic_vector(15 downto 0);
begin
	-- Output present count.
	Data_DO <= Count_DP;

	-- 16bit counter, calculation of next state
	p_memoryless : process (Count_DP, CountEnable_SI)
	begin -- process p_memoryless
		if CountEnable_SI = '1' then
			Count_DN <= Count_DP + 1;
		else
			Count_DN <= Count_DP;
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
