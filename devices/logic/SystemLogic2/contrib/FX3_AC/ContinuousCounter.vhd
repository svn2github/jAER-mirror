library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Variable width counter that just cycles thorugh all binary values,
-- incrementing by one each time its enable signal is assered,
-- until it hits a configurable limit. This limit is provided by the
-- DataLimit_DI input, if not needed, just keep it at all ones. The
-- limit can change during operation. When it is hit, the counter
-- emits a one-cycle pulse that signifies overflow on its Overflow_SO
-- signal, and then goes either back to zero or remains at its current
-- value until manually cleared (RESET_ON_OVERFLOW flag). While its
-- value is equal to the limit, it will continue to assert the overflow
-- flag. It is possible to force it to assert the flag for only one
-- cycle, by using the SHORT_OVERFLOW flag. Please note that this is
-- not supported in combination with the OVERFLOW_AT_ZERO flag.
-- It is further possible to specify that the overflow flag should not be
-- asserted when the limit value is reached, but instead when the counter
-- goes back to zero, thanks to the OVERFLOW_AT_ZERO flag.
-- Changing the limit value to be equal or smaller than the current counter
-- value is not supported and will lead to undefined behavior.
entity ContinuousCounter is
	generic(
		SIZE              : integer := 32;
		RESET_ON_OVERFLOW : boolean := true;
		GENERATE_OVERFLOW : boolean := true;
		SHORT_OVERFLOW    : boolean := false;
		OVERFLOW_AT_ZERO  : boolean := false);
	port(
		Clock_CI     : in  std_logic;
		Reset_RI     : in  std_logic;
		Clear_SI     : in  std_logic;
		Enable_SI    : in  std_logic;
		DataLimit_DI : in  unsigned(SIZE - 1 downto 0);
		Overflow_SO  : out std_logic;
		Data_DO      : out unsigned(SIZE - 1 downto 0));
end ContinuousCounter;

architecture Behavioral of ContinuousCounter is
	-- present and next state
	signal Count_DP, Count_DN : unsigned(SIZE - 1 downto 0);
begin
	-- Variable width counter, calculation of next value.
	counterLogic : process(Count_DP, Clear_SI, Enable_SI, DataLimit_DI)
	begin
		Count_DN <= Count_DP;           -- Keep value by default.

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
			Count_DN <= to_unsigned(1, SIZE);
		end if;
	end process counterLogic;

	-- Change state on clock edge (synchronous).
	counterRegisterUpdate : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			Count_DP <= (others => '0');
		elsif rising_edge(Clock_CI) then
			Count_DP <= Count_DN;
		end if;
	end process counterRegisterUpdate;

	-- Output present count (from register).
	Data_DO <= Count_DP;

	overflowLogicProcesses : if GENERATE_OVERFLOW = true generate
		signal Overflow_S, OverflowBuffer_S : std_logic;
	begin
		overflowLogic : process(Count_DP, Clear_SI, Enable_SI, DataLimit_DI)
		begin
			-- Determine overflow flag one cycle in advance, so that registering it
			-- at the output doesn't add more latency, since we want it to be
			-- asserted together with the limit value, on the cycle _before_ the
			-- buffer switches back to zero.
			Overflow_S <= '0';

			if not OVERFLOW_AT_ZERO then
				if Count_DP = (DataLimit_DI - 1) and Clear_SI = '0' and Enable_SI = '1' then
					Overflow_S <= '1';
				elsif not SHORT_OVERFLOW and Count_DP = DataLimit_DI then
					if Clear_SI = '0' and Enable_SI = '0' then
						Overflow_S <= '1';
					elsif Clear_SI = '0' and Enable_SI = '1' and not RESET_ON_OVERFLOW then
						Overflow_S <= '1';
					elsif Clear_SI = '1' and Enable_SI = '1' and DataLimit_DI = 1 then
						-- In this case, the next number is one, not zero. Since the
						-- minimum DataLimit_DI is one, it could be we're resetting
						-- directly into a value that produces the overflow flag, so we
						-- need to keep that in mind and check for it.
						Overflow_S <= '1';
					end if;
				end if;
			else
				if Count_DP = DataLimit_DI and Clear_SI = '0' and Enable_SI = '1' then
					Overflow_S <= '1';
				end if;
			-- Disabling SHORT_OVERFLOW is not supported in OVERFLOW_AT_ZERO mode.
			-- Doing so reliably would increase complexity and resource
			-- consumption to keep and check additional state, and no user of this
			-- module needs this functionality currently.
			end if;
		end process overflowLogic;

		-- Change state on clock edge (synchronous).
		overflowRegisterUpdate : process(Clock_CI, Reset_RI)
		begin
			if Reset_RI = '1' then      -- asynchronous reset (active-high for FPGAs)
				OverflowBuffer_S <= '0';
			elsif rising_edge(Clock_CI) then
				OverflowBuffer_S <= Overflow_S;
			end if;
		end process overflowRegisterUpdate;
		
		-- Output overflow (from register).
		Overflow_SO <= OverflowBuffer_S;
	end generate overflowLogicProcesses;

	overflowLogicDisabled : if GENERATE_OVERFLOW = false generate
		-- Output overflow (constant zero).
		Overflow_SO <= '0';
	end generate overflowLogicDisabled;
end Behavioral;
