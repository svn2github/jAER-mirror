library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.all;
use work.FIFORecords.all;
use work.DVSAERConfigRecords.all;

entity DVSAERStateMachine is
	port(
		Clock_CI          : in  std_logic;
		Reset_RI          : in  std_logic;

		-- Fifo output (to Multiplexer)
		OutFifoControl_SI : in  tFromFifoWriteSide;
		OutFifoControl_SO : out tToFifoWriteSide;
		OutFifoData_DO    : out std_logic_vector(EVENT_WIDTH - 1 downto 0);

		DVSAERData_DI     : in  std_logic_vector(AER_BUS_WIDTH - 1 downto 0);
		DVSAERReq_SBI     : in  std_logic;
		DVSAERAck_SBO     : out std_logic;
		DVSAERReset_SBO   : out std_logic;

		-- Configuration input
		DVSAERConfig_DI   : in  tDVSAERConfig);
end DVSAERStateMachine;

architecture Behavioral of DVSAERStateMachine is
	type state is (stIdle, stDifferentiateYX, stHandleY, stAckY, stHandleX, stAckX);

	attribute syn_enum_encoding : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

	-- ACK delay counter (prolongs dAckUP)
	signal ackDelayCount_S, ackDelayNotify_S : std_logic;

	-- ACK extension counter (prolongs dAckDOWN)
	signal ackExtensionCount_S, ackExtensionNotify_S : std_logic;

	-- Register outputs to FIFO.
	signal OutFifoWriteReg_S      : std_logic;
	signal OutFifoDataRegEnable_S : std_logic;
	signal OutFifoDataReg_D       : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	-- Register outputs to DVS.
	signal DVSAERAckReg_SB   : std_logic;
	signal DVSAERResetReg_SB : std_logic;
begin
	ackDelayCounter : entity work.ContinuousCounter
		generic map(
			COUNTER_WIDTH => 5)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => ackDelayCount_S,
			DataLimit_DI => DVSAERConfig_DI.AckDelay_D,
			Overflow_SO  => ackDelayNotify_S,
			Data_DO      => open);

	ackExtensionCounter : entity work.ContinuousCounter
		generic map(
			COUNTER_WIDTH => 5)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => ackExtensionCount_S,
			DataLimit_DI => DVSAERConfig_DI.AckExtension_D,
			Overflow_SO  => ackExtensionNotify_S,
			Data_DO      => open);

	p_memoryless : process(State_DP, OutFifoControl_SI, DVSAERReq_SBI, DVSAERData_DI, ackDelayNotify_S, ackExtensionNotify_S, DVSAERConfig_DI)
	begin
		State_DN <= State_DP;           -- Keep current state by default.

		OutFifoWriteReg_S      <= '0';
		OutFifoDataRegEnable_S <= '0';
		OutFifoDataReg_D       <= (others => '0');

		DVSAERAckReg_SB   <= '1';       -- No AER ACK by default.
		DVSAERResetReg_SB <= '1';       -- Keep DVS out of reset by default, so we don't have to repeat this in every state.

		ackDelayCount_S     <= '0';
		ackExtensionCount_S <= '0';

		case State_DP is
			when stIdle =>
				-- Only exit idle state if DVS data producer is active.
				if DVSAERConfig_DI.Run_S = '1' then
					if DVSAERReq_SBI = '0' and OutFifoControl_SI.Full_S = '0' then
						-- Got a request on the AER bus, let's get the data.
						-- If output fifo full, just wait for it to be empty.
						State_DN <= stDifferentiateYX;
					end if;
				else
					-- Keep the DVS in reset if data producer turned off.
					DVSAERResetReg_SB <= '0';
				end if;

			when stDifferentiateYX =>
				-- Get data and format it. AER(9) holds the axis.
				if DVSAERData_DI(9) = '0' then
					-- This is an Y address.
					-- They are differentiated here because Y addresses have
					-- all kinds of special timing requirements.
					State_DN        <= stHandleY;
					ackDelayCount_S <= '1';
				else
					-- This is an X address.
					State_DN <= stHandleX;
				end if;

			when stHandleY =>
				-- We might need to delay the ACK.
				if ackDelayNotify_S = '1' then
					OutFifoDataReg_D       <= EVENT_CODE_Y_ADDR & "0000" & DVSAERData_DI(7 downto 0);
					OutFifoDataRegEnable_S <= '1';
					OutFifoWriteReg_S      <= '1';

					DVSAERAckReg_SB     <= '0';
					State_DN            <= stAckY;
					ackExtensionCount_S <= '1';
				end if;

				ackDelayCount_S <= '1';

			when stAckY =>
				DVSAERAckReg_SB <= '0';

				if DVSAERReq_SBI = '1' then
					-- We might need to extend the ACK period.
					if ackExtensionNotify_S = '1' then
						DVSAERAckReg_SB <= '1';
						State_DN        <= stIdle;
					end if;

					ackExtensionCount_S <= '1';
				end if;

			when stHandleX =>
				-- This is an X address. AER(0) holds the polarity. The
				-- address is shifted by one to AER(8 downto 1).
				OutFifoDataReg_D       <= EVENT_CODE_X_ADDR & DVSAERData_DI(0) & "0000" & DVSAERData_DI(8 downto 1);
				OutFifoDataRegEnable_S <= '1';
				OutFifoWriteReg_S      <= '1';

				DVSAERAckReg_SB <= '0';
				State_DN        <= stAckX;

			when stAckX =>
				DVSAERAckReg_SB <= '0';

				if DVSAERReq_SBI = '1' then
					DVSAERAckReg_SB <= '1';
					State_DN        <= stIdle;
				end if;

			when others => null;
		end case;
	end process p_memoryless;

	-- Change state on clock edge (synchronous).
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;

			OutFifoControl_SO.Write_S <= '0';
			OutFifoData_DO            <= (others => '0');

			DVSAERAck_SBO   <= '1';
			DVSAERReset_SBO <= '0';
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			OutFifoControl_SO.Write_S <= OutFifoWriteReg_S;
			if OutFifoDataRegEnable_S = '1' then
				OutFifoData_DO <= OutFifoDataReg_D;
			end if;

			DVSAERAck_SBO   <= DVSAERAckReg_SB;
			DVSAERReset_SBO <= DVSAERResetReg_SB;
		end if;
	end process p_memoryzing;
end Behavioral;
