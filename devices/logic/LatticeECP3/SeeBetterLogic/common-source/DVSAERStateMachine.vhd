library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.DVSAERConfigRecords.all;
use work.Settings.DVS_AER_BUS_WIDTH;

entity DVSAERStateMachine is
	port(
		Clock_CI          : in  std_logic;
		Reset_RI          : in  std_logic;

		-- Fifo output (to Multiplexer)
		OutFifoControl_SI : in  tFromFifoWriteSide;
		OutFifoControl_SO : out tToFifoWriteSide;
		OutFifoData_DO    : out std_logic_vector(EVENT_WIDTH - 1 downto 0);

		DVSAERData_DI     : in  std_logic_vector(DVS_AER_BUS_WIDTH - 1 downto 0);
		DVSAERReq_SBI     : in  std_logic;
		DVSAERAck_SBO     : out std_logic;
		DVSAERReset_SBO   : out std_logic;

		-- Configuration input
		DVSAERConfig_DI   : in  tDVSAERConfig);
end DVSAERStateMachine;

architecture Behavioral of DVSAERStateMachine is
	attribute syn_enum_encoding : string;

	type tState is (stIdle, stDifferentiateYX, stHandleY, stAckY, stHandleX, stAckX, stFIFOFull);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : tState;

	-- ACK delay counter (prolongs dAckUP)
	signal AckDelayCount_S, AckDelayNotify_S : std_logic;

	-- ACK extension counter (prolongs dAckDOWN)
	signal AckExtensionCount_S, AckExtensionNotify_S : std_logic;

	-- Pad address output with zeros.
	constant ADDR_OUT_ZERO_PAD : std_logic_vector(EVENT_DATA_WIDTH_MAX - DVS_AER_BUS_WIDTH + 1 downto 0) := (others => '0');

	-- Register outputs to FIFO.
	signal OutFifoWriteReg_S      : std_logic;
	signal OutFifoDataRegEnable_S : std_logic;
	signal OutFifoDataReg_D       : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	-- Register outputs to DVS.
	signal DVSAERAckReg_SB   : std_logic;
	signal DVSAERResetReg_SB : std_logic;

	signal DVSAERConfigReg_D : tDVSAERConfig;
begin
	ackDelayCounter : entity work.ContinuousCounter
		generic map(
			SIZE => DVSAERConfigReg_D.AckDelay_D'length)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => AckDelayCount_S,
			DataLimit_DI => DVSAERConfigReg_D.AckDelay_D,
			Overflow_SO  => AckDelayNotify_S,
			Data_DO      => open);

	ackExtensionCounter : entity work.ContinuousCounter
		generic map(
			SIZE => DVSAERConfigReg_D.AckExtension_D'length)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => AckExtensionCount_S,
			DataLimit_DI => DVSAERConfigReg_D.AckExtension_D,
			Overflow_SO  => AckExtensionNotify_S,
			Data_DO      => open);

	p_memoryless : process(State_DP, OutFifoControl_SI, DVSAERReq_SBI, DVSAERData_DI, AckDelayNotify_S, AckExtensionNotify_S, DVSAERConfigReg_D)
	begin
		State_DN <= State_DP;           -- Keep current state by default.

		OutFifoWriteReg_S      <= '0';
		OutFifoDataRegEnable_S <= '0';
		OutFifoDataReg_D       <= (others => '0');

		DVSAERAckReg_SB   <= '1';       -- No AER ACK by default.
		DVSAERResetReg_SB <= '1';       -- Keep DVS out of reset by default, so we don't have to repeat this in every state.

		AckDelayCount_S     <= '0';
		AckExtensionCount_S <= '0';

		case State_DP is
			when stIdle =>
				-- Only exit idle state if DVS data producer is active.
				if DVSAERConfigReg_D.Run_S = '1' then
					if DVSAERReq_SBI = '0' then
						if OutFifoControl_SI.Full_S = '0' then
							-- Got a request on the AER bus, let's get the data.
							-- We do have space in the output FIFO for it.
							State_DN <= stDifferentiateYX;
						elsif DVSAERConfigReg_D.WaitOnTransferStall_S = '0' then
							-- FIFO full, keep ACKing.
							State_DN <= stFIFOFull;
						end if;
					end if;
				else
					-- Keep the DVS in reset if data producer turned off.
					DVSAERResetReg_SB <= '0';
				end if;

			when stFIFOFull =>
				-- Output FIFO is full, just ACK the data, so that, when
				-- we'll have space in the FIFO again, the newest piece of
				-- data is the next to be inserted, and not stale old data.
				DVSAERAckReg_SB <= DVSAERReq_SBI;

				-- Only go back to idle when FIFO has space again, and when
				-- the sender is not requesting (to avoid AER races).
				if OutFifoControl_SI.Full_S = '0' and DVSAERReq_SBI = '1' then
					State_DN <= stIdle;
				end if;

			when stDifferentiateYX =>
				-- Get data and format it. AER(WIDTH-1) holds the axis.
				if DVSAERData_DI(DVS_AER_BUS_WIDTH - 1) = '0' then
					-- This is an Y address.
					-- They are differentiated here because Y addresses have
					-- all kinds of special timing requirements.
					State_DN        <= stHandleY;
					AckDelayCount_S <= '1';
				else
					-- This is an X address.
					State_DN <= stHandleX;
				end if;

			when stHandleY =>
				-- We might need to delay the ACK.
				if AckDelayNotify_S = '1' then
					OutFifoDataReg_D       <= EVENT_CODE_Y_ADDR & ADDR_OUT_ZERO_PAD & DVSAERData_DI(DVS_AER_BUS_WIDTH - 3 downto 0);
					OutFifoDataRegEnable_S <= '1';
					OutFifoWriteReg_S      <= '1';

					DVSAERAckReg_SB     <= '0';
					State_DN            <= stAckY;
					AckExtensionCount_S <= '1';
				end if;

				AckDelayCount_S <= '1';

			when stAckY =>
				DVSAERAckReg_SB <= '0';

				if DVSAERReq_SBI = '1' then
					-- We might need to extend the ACK period.
					if AckExtensionNotify_S = '1' then
						DVSAERAckReg_SB <= '1';
						State_DN        <= stIdle;
					end if;

					AckExtensionCount_S <= '1';
				end if;

			when stHandleX =>
				-- This is an X address. AER(0) holds the polarity. The
				-- address is shifted by one to AER(8 downto 1).
				OutFifoDataReg_D       <= EVENT_CODE_X_ADDR & DVSAERData_DI(0) & ADDR_OUT_ZERO_PAD & DVSAERData_DI(DVS_AER_BUS_WIDTH - 2 downto 1);
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

	outputDataRegister : entity work.SimpleRegister
		generic map(
			SIZE => EVENT_WIDTH)
		port map(
			Clock_CI  => Clock_CI,
			Reset_RI  => Reset_RI,
			Enable_SI => OutFifoDataRegEnable_S,
			Input_SI  => OutFifoDataReg_D,
			Output_SO => OutFifoData_DO);

	-- Change state on clock edge (synchronous).
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;

			OutFifoControl_SO.Write_S <= '0';

			DVSAERAck_SBO   <= '1';
			DVSAERReset_SBO <= '0';

			DVSAERConfigReg_D <= tDVSAERConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			OutFifoControl_SO.Write_S <= OutFifoWriteReg_S;

			DVSAERAck_SBO   <= DVSAERAckReg_SB;
			DVSAERReset_SBO <= DVSAERResetReg_SB;

			DVSAERConfigReg_D <= DVSAERConfig_DI;
		end if;
	end process p_memoryzing;
end Behavioral;
