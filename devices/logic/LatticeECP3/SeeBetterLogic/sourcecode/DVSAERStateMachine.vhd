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

	type state is (stIdle, stDifferentiateYX, stHandleY, stAckY, stHandleX, stAckX);

	attribute syn_enum_encoding			 : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

	-- ACK delay counter (prolongs dAckUP)
	signal ackDelayCount_S, ackDelayNotify_S : std_logic;

	-- ACK extension counter (prolongs dAckDOWN)
	signal ackExtensionCount_S, ackExtensionNotify_S : std_logic;
begin
	ackDelayCounter : ContinuousCounter
		generic map (
			COUNTER_WIDTH => 5)
		port map (
			Clock_CI	 => Clock_CI,
			Reset_RI	 => Reset_RI,
			Clear_SI	 => '0',
			Enable_SI	 => ackDelayCount_S,
			DataLimit_DI => to_unsigned(1, 5),
			Overflow_SO	 => ackDelayNotify_S,
			Data_DO		 => open);

	ackExtensionCounter : ContinuousCounter
		generic map (
			COUNTER_WIDTH => 5)
		port map (
			Clock_CI	 => Clock_CI,
			Reset_RI	 => Reset_RI,
			Clear_SI	 => '0',
			Enable_SI	 => ackExtensionCount_S,
			DataLimit_DI => to_unsigned(1, 5),
			Overflow_SO	 => ackExtensionNotify_S,
			Data_DO		 => open);

	p_memoryless : process (State_DP, DVSRun_SI, OutFifoFull_SI, DVSAERReq_SBI, DVSAERData_DI, ackDelayNotify_S, ackExtensionNotify_S)
	begin
		State_DN <= State_DP;			-- Keep current state by default.

		OutFifoWrite_SO <= '0';
		OutFifoData_DO	<= (others => '0');

		DVSAERAck_SBO	<= '1';			-- No AER ACK by default.
		DVSAERReset_SBO <= '1';			-- Keep DVS out of reset by default.

		ackDelayCount_S		<= '0';
		ackExtensionCount_S <= '0';

		case State_DP is
			when stIdle =>
				-- Only exit idle state if DVS data producer is active.
				if DVSRun_SI = '1' then
					if DVSAERReq_SBI = '0' and OutFifoFull_SI = '0' then
						-- Got a request on the AER bus, let's get the data.
						-- If output fifo full, just wait for it to be empty.
						State_DN <= stDifferentiateYX;
					end if;
				else
					-- Keep the DVS in reset if data producer turned off.
					DVSAERReset_SBO <= '0';
				end if;

			when stDifferentiateYX =>
				-- Get data and format it. AER(9) holds the axis.
				if DVSAERData_DI(9) = '0' then
					-- This is an Y address.
					-- They are differentiated here because Y addresses have
					-- all kinds of special timing requirements.
					State_DN		<= stHandleY;
					ackDelayCount_S <= '1';
				else
					-- This is an X address.
					State_DN <= stHandleX;
				end if;

			when stHandleY =>
				-- We might need to delay the ACK.
				if ackDelayNotify_S = '1' then
					OutFifoData_DO	<= EVENT_CODE_Y_ADDR & "0000" & DVSAERData_DI(7 downto 0);
					OutFifoWrite_SO <= '1';

					State_DN			<= stAckY;
					ackExtensionCount_S <= '1';
				end if;

				ackDelayCount_S <= '1';

			when stAckY =>
				DVSAERAck_SBO <= '0';

				if DVSAERReq_SBI = '1' then
					-- We might need to extend the ACK period.
					if ackExtensionNotify_S = '1' then
						State_DN <= stIdle;
					end if;

					ackExtensionCount_S <= '1';
				end if;

			when stHandleX =>
				-- This is an X address. AER(0) holds the polarity. The
				-- address is shifted by one to AER(8 downto 1).
				OutFifoData_DO	<= EVENT_CODE_X_ADDR & DVSAERData_DI(0) & "0000" & DVSAERData_DI(8 downto 1);
				OutFifoWrite_SO <= '1';

				State_DN <= stAckX;

			when stAckX =>
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
