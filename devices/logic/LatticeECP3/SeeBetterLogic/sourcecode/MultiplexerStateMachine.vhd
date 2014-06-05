library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.Settings.all;

entity MultiplexerStateMachine is
	port (
		Clock_CI : in std_logic;
		Reset_RI : in std_logic;
		FPGARun_SI : in std_logic;

		-- Timestamp input
		TimestampReset_SI : in std_logic;
		TimestampOverflow_SI : in std_logic;
		Timestamp_DI : in std_logic_vector(TIMESTAMP_WIDTH-1 downto 0);

		-- Fifo output (to USB)
		OutFifoFull_SI : in std_logic;
		OutFifoAlmostFull_SI : in std_logic;
		OutFifoWrite_SO : out std_logic;
		OutFifoData_DO : out std_logic_vector(USB_FIFO_WIDTH-1 downto 0);

		-- Fifo input (from DVS AER)
		DVSAERFifoEmpty_SI : in std_logic;
		DVSAERFifoAlmostEmpty_SI : in std_logic;
		DVSAERFifoRead_SO : out std_logic;
		DVSAERFifoData_DI : in std_logic_vector(EVENT_WIDTH-1 downto 0));
end MultiplexerStateMachine;

architecture Behavioral of MultiplexerStateMachine is
	type state is (stIdle, stTimestampReset, stTimestampWrap, stTimestamp, stDVSAER);

	attribute syn_enum_encoding : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;
begin
	p_memoryless : process (State_DP, FPGARun_SI, TimestampReset_SI, TimestampOverflow_SI, OutFifoFull_SI, OutFifoAlmostFull_SI, DVSAERFifoEmpty_SI, DVSAERFifoAlmostEmpty_SI)
	begin
		State_DN <= State_DP; -- Keep current state by default.

		OutFifoWrite_SO <= '0';
		OutFifoData_DO <= (others => '0');

		DVSAERFifoRead_SO <= '0';

		case State_DP is
			when stIdle =>
				-- Only exit idle state if FPGA is running.
				if FPGARun_SI = '1' then
					-- Now check various flags and see what data to send.
					
				end if;

			when others => null;
		end case;
	end process p_memoryless;
	
	-- Change state on clock edge (synchronous).
	p_memoryzing : process (Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;
		end if;
	end process p_memoryzing;
end Behavioral;
