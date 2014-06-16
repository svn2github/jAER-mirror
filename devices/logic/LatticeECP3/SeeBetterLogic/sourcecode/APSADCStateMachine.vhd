library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.all;

entity APSADCStateMachine is
	port (
		Clock_CI  : in std_logic;
		Reset_RI  : in std_logic;
		APSRun_SI : in std_logic;

		-- Fifo output (to Multiplexer)
		OutFifoFull_SI		 : in  std_logic;
		OutFifoAlmostFull_SI : in  std_logic;
		OutFifoWrite_SO		 : out std_logic;
		OutFifoData_DO		 : out std_logic_vector(EVENT_WIDTH-1 downto 0);

		APSChipRowSRClock_SO : out std_logic;
		APSChipRowSRIn_SO	 : out std_logic;
		APSChipColSRClock_SO : out std_logic;
		APSChipColSRIn_SO	 : out std_logic;
		APSChipColMode_DO	 : out std_logic_vector(1 downto 0);
		APSChipTXGate_SO	 : out std_logic;

		APSADCData_DI		   : in	 std_logic_vector(ADC_BUS_WIDTH-1 downto 0);
		APSADCOverflow_SI	   : in	 std_logic;
		APSADCClock_CO		   : out std_logic;
		APSADCOutputEnable_SBO : out std_logic;
		APSADCStandby_SO	   : out std_logic);
end entity APSADCStateMachine;

architecture Behavioral of APSADCStateMachine is
	type state is (stIdle, stWriteEvent);

	attribute syn_enum_encoding			 : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;
begin
	p_memoryless : process (State_DP, APSRun_SI, OutFifoFull_SI)
	begin
		State_DN <= State_DP;			-- Keep current state by default.

		OutFifoWrite_SO <= '0';
		OutFifoData_DO	<= (others => '0');

		case State_DP is
			when stIdle =>
				-- Only exit idle state if APS data producer is active.
				if APSRun_SI = '1' then
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
