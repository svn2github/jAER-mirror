library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.all;

entity ExtTriggerStateMachine is
	port (
		Clock_CI		 : in std_logic;
		Reset_RI		 : in std_logic;
		ExtTriggerRun_SI : in std_logic;

		-- Fifo output (to Multiplexer)
		OutFifoFull_SI		 : in  std_logic;
		OutFifoAlmostFull_SI : in  std_logic;
		OutFifoWrite_SO		 : out std_logic;
		OutFifoData_DO		 : out std_logic_vector(EVENT_WIDTH-1 downto 0);

		ExtTriggerSwitch_SI : in std_logic;
		ExtTriggerSignal_SI : in std_logic);
end entity ExtTriggerStateMachine;

architecture Behavioral of ExtTriggerStateMachine is
	type state is (stIdle, stWriteEvent);

	attribute syn_enum_encoding			 : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;
begin
	p_memoryless : process (State_DP, ExtTriggerRun_SI, OutFifoFull_SI)
	begin
		State_DN <= State_DP;			-- Keep current state by default.

		OutFifoWrite_SO <= '0';
		OutFifoData_DO	<= (others => '0');

		case State_DP is
			when stIdle =>
				-- Only exit idle state if External Trigger data producer is active.
				if ExtTriggerRun_SI = '1' then
					if OutFifoFull_SI = '0' then
						-- If output fifo full, just wait for it to be empty.
						State_DN <= stWriteEvent;
					end if;
				end if;

			when stWriteEvent =>
				OutFifoData_DO	<= (others => '0');
				OutFifoWrite_SO <= '1';
				State_DN		<= stIdle;

			when others => null;
		end case;
	end process p_memoryless;

	-- Change state on clock edge (synchronous).
	p_memoryzing : process (Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then	-- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;
		end if;
	end process p_memoryzing;
end architecture Behavioral;
