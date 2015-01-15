library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.DEVICE_FAMILY;

-- Variable width counter that just cycles thorugh all binary values,
-- incrementing by one each time its enable signal is asserted,
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
-- Please be caerful about the counter size and its limit value.
-- If you need to count N times, you will need a counter of size
-- ceil(log2(N)) and a limit of N-1, since zero also counts!
-- If you need to count up to N, you will instead need a counter of
-- size ceil(log2(N+1)) and the limit will have to be N.
entity ContinuousCounter is
	generic(
		SIZE                : integer;
		RESET_ON_OVERFLOW   : boolean := true;
		GENERATE_OVERFLOW   : boolean := true;
		SHORT_OVERFLOW      : boolean := false;
		OVERFLOW_AT_ZERO    : boolean := false;
		OVERFLOW_OUT_BUFFER : boolean := (DEVICE_FAMILY /= "XO"));
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

			if Count_DP >= DataLimit_DI then
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
		signal Overflow_S : std_logic;
	begin
		overflowOutputBuffered : if OVERFLOW_OUT_BUFFER = true generate
			signal OverflowBuffer_SP, OverflowBuffer_SN : std_logic;
		begin
			overflowPredictLogic : process(Count_DP, Clear_SI, Enable_SI, DataLimit_DI)
			begin
				-- Determine overflow flag one cycle in advance, so that registering it
				-- at the output doesn't add more latency, since we want it to be
				-- asserted together with the limit value, on the cycle _before_ the
				-- buffer switches back to zero.
				Overflow_S <= '0';

				if not OVERFLOW_AT_ZERO then
					if Count_DP = (DataLimit_DI - 1) and Clear_SI = '0' and Enable_SI = '1' then
						Overflow_S <= '1';
					end if;

					if not SHORT_OVERFLOW and Count_DP >= DataLimit_DI then
						if Clear_SI = '0' and Enable_SI = '0' then
							Overflow_S <= '1';
						end if;

						if Clear_SI = '0' and Enable_SI = '1' and not RESET_ON_OVERFLOW then
							Overflow_S <= '1';
						end if;

						if Clear_SI = '1' and Enable_SI = '0' and DataLimit_DI = 0 then
							-- In this case, the next number zero. Since the minimum
							-- DataLimit_DI is also zero, it could be we're resetting
							-- directly into a value that produces the overflow flag, so we
							-- need to keep that in mind and check for it.
							Overflow_S <= '1';
						end if;

						if Clear_SI = '1' and Enable_SI = '1' and DataLimit_DI = 1 then
							-- In this case, the next number is one, not zero. Since the
							-- minimum DataLimit_DI is one, it could be we're resetting
							-- directly into a value that produces the overflow flag, so we
							-- need to keep that in mind and check for it.
							Overflow_S <= '1';
						end if;
					end if;
				else
					-- This only ever makes sense if we also reset on overflow, since that's
					-- the only case where we overflow into zero automatically (with Enable_SI).
					assert (RESET_ON_OVERFLOW) report "OVERFLOW_AT_ZERO requires RESET_ON_OVERFLOW enabled." severity FAILURE;

					-- Disabling SHORT_OVERFLOW is not supported in OVERFLOW_AT_ZERO mode.
					-- It will always generate a short overflow signal.
					-- Doing so reliably would increase complexity and resource
					-- consumption to keep and check additional state, and no user of this
					-- module needs this functionality currently.
					assert (SHORT_OVERFLOW) report "OVERFLOW_AT_ZERO requires SHORT_OVERFLOW enabled." severity FAILURE;

					if Count_DP >= DataLimit_DI and Clear_SI = '0' and Enable_SI = '1' then
						Overflow_S <= '1';
					end if;
				end if;
			end process overflowPredictLogic;

			OverflowBuffer_SN <= Overflow_S;

			-- Change state on clock edge (synchronous).
			overflowRegisterUpdate : process(Clock_CI, Reset_RI)
			begin
				if Reset_RI = '1' then  -- asynchronous reset (active-high for FPGAs)
					OverflowBuffer_SP <= '0';
				elsif rising_edge(Clock_CI) then
					OverflowBuffer_SP <= OverflowBuffer_SN;
				end if;
			end process overflowRegisterUpdate;

			-- Output overflow (from register).
			Overflow_SO <= OverflowBuffer_SP;
		end generate overflowOutputBuffered;

		overflowOutputNoBuffer : if OVERFLOW_OUT_BUFFER = false generate
		begin
			overflowDirectLogic : process(Count_DP, DataLimit_DI)
			begin
				Overflow_S <= '0';

				if not OVERFLOW_AT_ZERO then
					-- It is impossible to implement SHORT_OVERFLOW when not having any kind of output
					-- buffer for the overflow signal that delays it. It would require another register to
					-- buffer the signal, which is exactly what we don't want here. So let's just leave it
					-- as unsupported for now. Might be reevaluated if anyone ever needs this combination.
					assert (not SHORT_OVERFLOW) report "SHORT_OVERFLOW is not supported with OVERFLOW_OUT_BUFFER disabled." severity FAILURE;

					if Count_DP >= DataLimit_DI then
						Overflow_S <= '1';
					end if;
				else
					-- This only ever makes sense if we also reset on overflow, since that's
					-- the only case where we overflow into zero automatically (with Enable_SI).
					assert (RESET_ON_OVERFLOW) report "OVERFLOW_AT_ZERO requires RESET_ON_OVERFLOW enabled." severity FAILURE;

					-- Disabling SHORT_OVERFLOW is not supported in OVERFLOW_AT_ZERO mode.
					-- It will always generate a short overflow signal.
					-- Doing so reliably would increase complexity and resource
					-- consumption to keep and check additional state, and no user of this
					-- module needs this functionality currently.
					assert (SHORT_OVERFLOW) report "OVERFLOW_AT_ZERO requires SHORT_OVERFLOW enabled." severity FAILURE;

					-- It is impossible to implement OVERFLOW_AT_ZERO when not having any kind of output
					-- buffer for the overflow signal that delays it. It would require another register to
					-- buffer the signal, which is exactly what we don't want here. So let's just leave it
					-- as unsupported for now. Might be reevaluated if anyone ever needs this combination.
					assert (not OVERFLOW_AT_ZERO) report "OVERFLOW_AT_ZERO is not supported with OVERFLOW_OUT_BUFFER disabled." severity FAILURE;
				end if;
			end process overflowDirectLogic;

			-- Output overflow (directly).
			Overflow_SO <= Overflow_S;
		end generate overflowOutputNoBuffer;
	end generate overflowLogicProcesses;

	overflowLogicDisabled : if GENERATE_OVERFLOW = false generate
		-- Output overflow (constant zero).
		Overflow_SO <= '0';
	end generate overflowLogicDisabled;
end Behavioral;
