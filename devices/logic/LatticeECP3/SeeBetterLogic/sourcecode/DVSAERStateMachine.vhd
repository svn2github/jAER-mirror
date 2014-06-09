library ieee;
use ieee.std_logic_1164.all;
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
	type state is (stIdle, stWriteAddr, stAck);

	attribute syn_enum_encoding			 : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

	constant CODE_Y_ADDR : std_logic_vector(2 downto 0) := "001";
	-- The third bit of X address is the polarity. It gets encoded later on
	-- directly from the AER bus input.
	constant CODE_X_ADDR : std_logic_vector(1 downto 0) := "01";
begin
	p_memoryless : process (State_DP, DVSRun_SI, OutFifoFull_SI, DVSAERReq_SBI, DVSAERData_DI)
	begin
		State_DN <= State_DP;			-- Keep current state by default.

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
						State_DN <= stWriteAddr;
					end if;
				end if;

			when stWriteAddr =>
				DVSAERReset_SBO <= '1';	 -- Keep DVS out of reset.

				-- Get data and format it. AER(9) holds the axis.
				if DVSAERData_DI(9) = '0' then
					-- This is an Y address.
					OutFifoData_DO <= CODE_Y_ADDR & "0000" & DVSAERData_DI(7 downto 0);
				else
					-- This is an X address. AER(8) holds the polarity.
					OutFifoData_DO <= CODE_X_ADDR & DVSAERData_DI(8) & "0000" & DVSAERData_DI(7 downto 0);
				end if;

				OutFifoWrite_SO <= '1';
				State_DN		<= stAck;

			when stAck =>
				DVSAERReset_SBO <= '1';	 -- Keep DVS out of reset.

				DVSAERAck_SBO <= '0';

				if DVSAERReq_SBI = '1' then
					State_DN <= stIdle;
				end if;

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
