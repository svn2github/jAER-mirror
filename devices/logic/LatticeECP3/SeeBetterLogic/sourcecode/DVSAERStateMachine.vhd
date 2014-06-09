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
begin
	p_memoryless : process (State_DP, DVSRun_SI, OutFifoFull_SI, OutFifoAlmostFull_SI, DVSAERReq_SBI)
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

					if DVSAERReq_SBI = '0' then
						-- Got a request on the AER bus, let's get the data.
						State_DN <= stWriteAddr;
					end if;
				end if;

			when stWriteAddr =>
				DVSAERReset_SBO <= '1';	 -- Keep DVS out of reset.

				-- Get data and format it.
				if DVSAERData_DI(9) = '0' then
					-- This is an Y address.
					OutFifoData_DO <= "0010000" & DVSAERData_DI(7 downto 0);
				else
					-- This is an X address. AER(8) holds the polarity.
					if DVSAERData_DI(8) = '1' then
						-- ON polarity.
						OutFifoData_DO <= "0110000" & DVSAERData_DI(7 downto 0);
					else
						-- OFF polarity.
						OutFifoData_DO <= "0100000" & DVSAERData_DI(7 downto 0);
					end if;
				end if;

				OutFifoWrite_SO <= '1';

				State_DN <= stAck;

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
