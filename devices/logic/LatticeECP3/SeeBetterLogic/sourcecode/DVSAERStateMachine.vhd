library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.all;

entity DVSAERStateMachine is
	port (
		Clock_CI  : in std_logic;
		Reset_RI  : in std_logic;
		DVSRun_SI : in std_logic;

		-- Fifo output (to Multiplexer)
		OutFifoFull_SI		 : in  std_logic;
		OutFifoAlmostFull_SI : in  std_logic;
		OutFifoWrite_SO		 : out std_logic;
		OutFifoData_DO		 : out std_logic_vector(EVENT_WIDTH-1 downto 0);

		DVSAERData_DI	: in  std_logic_vector(AER_BUS_WIDTH-1 downto 0);
		DVSAERReq_SBI	: in  std_logic;
		DVSAERAck_SBO	: out std_logic;
		DVSAERReset_SBO : out std_logic);
end DVSAERStateMachine;

architecture Behavioral of DVSAERStateMachine is
	component ContinuousCounter is
		generic (
			COUNTER_WIDTH	  : integer := 16;
			RESET_ON_OVERFLOW : boolean := true;
			SHORT_OVERFLOW	  : boolean := false;
			OVERFLOW_AT_ZERO  : boolean := false);
		port (
			Clock_CI	 : in  std_logic;
			Reset_RI	 : in  std_logic;
			Clear_SI	 : in  std_logic;
			Enable_SI	 : in  std_logic;
			DataLimit_DI : in  unsigned(COUNTER_WIDTH-1 downto 0);
			Overflow_SO	 : out std_logic;
			Data_DO		 : out unsigned(COUNTER_WIDTH-1 downto 0));
	end component ContinuousCounter;

	type state is (stIdle, stDelayBeforeWrite, stWriteEvent, stDelayAfterWrite, stAck, stDelayAfterAck);

	attribute syn_enum_encoding			 : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

	-- AER delay counter
	signal CyclesCount_S, CyclesNotify_S : std_logic;
begin
	writeCyclesCounter : ContinuousCounter
		generic map (
			COUNTER_WIDTH => 4)
		port map (
			Clock_CI	 => Clock_CI,
			Reset_RI	 => Reset_RI,
			Clear_SI	 => '0',
			Enable_SI	 => CyclesCount_S,
			DataLimit_DI => to_unsigned(12, 4),
			Overflow_SO	 => CyclesNotify_S,
			Data_DO		 => open);

	p_memoryless : process (State_DP, CyclesNotify_S, DVSRun_SI, OutFifoFull_SI, DVSAERReq_SBI, DVSAERData_DI)
	begin
		State_DN <= State_DP;			-- Keep current state by default.

		CyclesCount_S <= '0';  -- Do not count up in the write-cycles counter.

		OutFifoWrite_SO <= '0';
		OutFifoData_DO	<= (others => '0');

		DVSAERAck_SBO	<= '1';			-- No acknowledge by default.
		DVSAERReset_SBO <= '0';			-- Keep DVS in reset by default.

		case State_DP is
			when stIdle =>
				-- Only exit idle state if DVS data producer is active.
				if DVSRun_SI = '1' then
					DVSAERReset_SBO <= '1';	 -- Keep DVS out of reset.

					if DVSAERReq_SBI = '0' and OutFifoFull_SI = '0' then
						-- Got a request on the AER bus, let's get the data.
						-- If output fifo full, just wait for it to be empty.
						State_DN <= stDelayBeforeWrite;
					end if;
				end if;

			when stDelayBeforeWrite =>
				DVSAERReset_SBO <= '1';	 -- Keep DVS out of reset.

				if CyclesNotify_S = '1' then
					State_DN <= stWriteEvent;
				end if;

				CyclesCount_S <= '1';

			when stWriteEvent =>
				DVSAERReset_SBO <= '1';	 -- Keep DVS out of reset.

				-- Get data and format it. AER(9) holds the axis.
				if DVSAERData_DI(9) = '0' then
					-- This is an Y address.
					OutFifoData_DO <= EVENT_CODE_Y_ADDR & "0000" & DVSAERData_DI(7 downto 0);
				else
					-- This is an X address. AER(8) holds the polarity.
					OutFifoData_DO <= EVENT_CODE_X_ADDR & DVSAERData_DI(0) & "0000" & DVSAERData_DI(8 downto 1);
				end if;

				OutFifoWrite_SO <= '1';
				State_DN		<= stDelayAfterWrite;

			when stDelayAfterWrite =>
				DVSAERReset_SBO <= '1';	 -- Keep DVS out of reset.

				if CyclesNotify_S = '1' then
					State_DN <= stAck;
				end if;

				CyclesCount_S <= '1';

			when stAck =>
				DVSAERReset_SBO <= '1';	 -- Keep DVS out of reset.

				DVSAERAck_SBO <= '0';

				if DVSAERReq_SBI = '1' then
					State_DN <= stDelayAfterAck;
				end if;

			when stDelayAfterAck =>
				DVSAERReset_SBO <= '1';	 -- Keep DVS out of reset.

				if CyclesNotify_S = '1' then
					State_DN <= stIdle;
				end if;

				CyclesCount_S <= '1';

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
end Behavioral;
