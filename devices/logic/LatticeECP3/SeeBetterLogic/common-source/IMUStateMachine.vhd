library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.all;
use work.FIFORecords.all;

entity IMUStateMachine is
	port(
		Clock_CI          : in    std_logic;
		Reset_RI          : in    std_logic;

		-- Fifo output (to Multiplexer)
		OutFifoControl_SI : in    tFromFifoWriteSide;
		OutFifoControl_SO : out   tToFifoWriteSide;
		OutFifoData_DO    : out   std_logic_vector(EVENT_WIDTH - 1 downto 0);

		IMUClock_ZO       : inout std_logic; -- this is inout because it must be tristateable
		IMUData_ZIO       : inout std_logic;
		IMUInterrupt_SI   : in    std_logic);
end entity IMUStateMachine;

architecture Behavioral of IMUStateMachine is
	type state is (stIdle, stWriteEvent);

	attribute syn_enum_encoding : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;
begin
	p_memoryless : process(State_DP, OutFifoControl_SI)
	begin
		State_DN <= State_DP;           -- Keep current state by default.

		OutFifoControl_SO.Write_S <= '0';
		OutFifoData_DO            <= (others => '0');

		case State_DP is
			when stIdle =>
			-- Only exit idle state if IMU data producer is active.
			--if IMURun_SI = '1' then
			--if OutFifo_I.Full_S = '0' then
			-- If output fifo full, just wait for it to be empty.
			--State_DN <= stWriteEvent;
			--end if;
			--end if;

			when stWriteEvent =>
				OutFifoData_DO            <= (others => '0');
				OutFifoControl_SO.Write_S <= '1';
				State_DN                  <= stIdle;

			when others => null;
		end case;
	end process p_memoryless;

	-- Change state on clock edge (synchronous).
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;
		end if;
	end process p_memoryzing;
end architecture Behavioral;
