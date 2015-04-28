library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.DVSAERCorrFilterConfigRecords.all;
use work.Settings.AER_BUS_WIDTH;
use work.Settings.AER_BUS_WIDTH_ROW;
use work.Settings.AER_BUS_WIDTH_COL;

entity DVSAERCorrFilterStateMachine is
	port(
		Clock_CI                   : in  std_logic;
		Reset_RI                   : in  std_logic;

		-- Fifo output (to Multiplexer)
		OutFifoControl_SI          : in  tFromFifoWriteSide;
		OutFifoControl_SO          : out tToFifoWriteSide;
		OutFifoData_DO             : out std_logic_vector(EVENT_WIDTH - 1 downto 0);

		DVSAERData_DI              : in  std_logic_vector(AER_BUS_WIDTH - 1 downto 0);
		DVSAERReq_SBI              : in  std_logic;
		DVSAERAck_SBO              : out std_logic;
		DVSAERReset_SBO            : out std_logic;

		-- AERCorrFilter signals
		AERCorrFilterPass_SI       : in  std_logic;
		AERCorrFilterPassEnable_SO : out std_logic;

		-- Configuration input
		DVSAERCorrFilterConfig_DI  : in  tDVSAERCorrFilterConfig);
end DVSAERCorrFilterStateMachine;

architecture Behavioral of DVSAERCorrFilterStateMachine is
	attribute syn_enum_encoding : string;

	type tState is (stIdle, stDifferentiateRowCol, stAERHandleRow, stAERAckRow, stAERHandleCol, stAERAckCol, stFIFOFull, stAERCorrFilterDelayPass);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : tState;

	-- Counter to influence acknowledge delays.
	signal AckCount_S, AckDone_S : std_logic;
	signal AckLimit_D            : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);

	-- Remember if what we're working on right now is an X or Y address.
	signal DVSIsRowAddress_SP, DVSIsRowAddress_SN : std_logic;

	-- Data incoming from DVS.
	signal DVSEventDataRegEnable_S : std_logic;
	signal DVSEventDataReg_D       : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal DVSEventValidReg_S      : std_logic;

	-- Register outputs to DVS.
	signal DVSAERAckReg_SB   : std_logic;
	signal DVSAERResetReg_SB : std_logic;

	signal AERCorrFilterPassEnableReg_S : std_logic;

	-- Register configuration input.
	signal DVSAERCorrFilterConfigReg_D : tDVSAERCorrFilterConfig;
begin
	aerAckCounter : entity work.ContinuousCounter
		generic map(
			SIZE => DVS_AER_ACK_COUNTER_WIDTH)
		port map(Clock_CI     => Clock_CI,
			     Reset_RI     => Reset_RI,
			     Clear_SI     => '0',
			     Enable_SI    => AckCount_S,
			     DataLimit_DI => AckLimit_D,
			     Overflow_SO  => AckDone_S,
			     Data_DO      => open);

	dvsHandleAERComb : process(State_DP, OutFifoControl_SI, DVSAERReq_SBI, DVSAERData_DI, DVSIsRowAddress_SP, DVSAERCorrFilterConfigReg_D, AckDone_S, AERCorrFilterPass_SI)
	begin
		State_DN <= State_DP;           -- Keep current state by default.

		DVSIsRowAddress_SN <= DVSIsRowAddress_SP;

		DVSEventValidReg_S      <= '0';
		DVSEventDataRegEnable_S <= '0';
		DVSEventDataReg_D       <= (others => '0');

		DVSAERAckReg_SB   <= '1';       -- No AER ACK by default.
		DVSAERResetReg_SB <= '1';       -- Keep DVS out of reset by default, so we don't have to repeat this in every state.

		AckCount_S <= '0';
		AckLimit_D <= (others => '1');

		AERCorrFilterPassEnableReg_S <= '0';

		case State_DP is
			when stIdle =>
				-- Only exit idle state if DVS data producer is active.
				if DVSAERCorrFilterConfigReg_D.Run_S = '1' then
					if DVSAERReq_SBI = '0' then
						if OutFifoControl_SI.AlmostFull_S = '0' then
							-- Got a request on the AER bus, let's get the data.
							-- We do have space in the output FIFO for it.
							State_DN <= stDifferentiateRowCol;
						elsif DVSAERCorrFilterConfigReg_D.WaitOnTransferStall_S = '0' then
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
				if OutFifoControl_SI.AlmostFull_S = '0' and DVSAERReq_SBI = '1' then
					State_DN <= stIdle;
				end if;

			when stDifferentiateRowCol =>
				-- Get data and format it. AER(WIDTH-1) holds the axis.
				if DVSAERData_DI(AER_BUS_WIDTH - 1) = '0' then
					-- This is an Y address.
					DVSIsRowAddress_SN <= '1';
					State_DN           <= stAERHandleRow;
				else
					DVSIsRowAddress_SN <= '0';
					State_DN           <= stAERCorrFilterDelayPass;

					-- Let's see if the previously address was a row-address.
					-- If yes, we send it along on its path, since it has to be the valid row address
					-- for this column address. We only do this if row-only event filtering is enabled,
					-- since if not, row-addresses are sent right away.
					if DVSAERCorrFilterConfigReg_D.FilterRowOnlyEvents_S = '1' and DVSIsRowAddress_SP = '1' then
						DVSEventValidReg_S <= '1';
					end if;
				end if;

			when stAERHandleRow =>
				AckLimit_D <= DVSAERCorrFilterConfigReg_D.AckDelayRow_D;

				-- We might need to delay the ACK.
				if AckDone_S = '1' then
					-- Row address (Y).
					DVSEventDataReg_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_Y_ADDR;

					DVSEventDataReg_D(AER_BUS_WIDTH_ROW - 1 downto 0) <= DVSAERData_DI(AER_BUS_WIDTH_ROW - 1 downto 0);

					-- If we're not filtering row-only events, then we can just pass all row-events right away.
					if DVSAERCorrFilterConfigReg_D.FilterRowOnlyEvents_S = '0' then
						DVSEventValidReg_S <= '1';
					end if;

					DVSEventDataRegEnable_S <= '1';

					DVSAERAckReg_SB <= '0';
					State_DN        <= stAERAckRow;
				end if;

				AckCount_S <= '1';

			when stAERAckRow =>
				AckLimit_D <= DVSAERCorrFilterConfigReg_D.AckExtensionRow_D;

				DVSAERAckReg_SB <= '0';

				if DVSAERReq_SBI = '1' then
					-- We might need to extend the ACK period.
					if AckDone_S = '1' then
						DVSAERAckReg_SB <= '1';
						State_DN        <= stIdle;
					end if;

					AckCount_S <= '1';
				end if;

			when stAERCorrFilterDelayPass =>
				AckLimit_D <= DVSAERCorrFilterConfigReg_D.PassDelayTime_D;

				-- Wait to raise PassEnable signal (reuse AckCounter for this).
				if AckDone_S = '1' then
					AERCorrFilterPassEnableReg_S <= '1';

					State_DN <= stAERHandleCol;
				end if;

				AckCount_S <= '1';

			when stAERHandleCol =>
				AERCorrFilterPassEnableReg_S <= '1';

				AckLimit_D <= DVSAERCorrFilterConfigReg_D.AckDelayColumn_D;

				-- We might need to delay the ACK.
				if AckDone_S = '1' then
					-- Column address (X).
					DVSEventDataReg_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_X_ADDR & DVSAERData_DI(0);

					DVSEventDataReg_D(AER_BUS_WIDTH_COL - 1 downto 0) <= DVSAERData_DI(AER_BUS_WIDTH_COL downto 1);

					DVSEventValidReg_S <= AERCorrFilterPass_SI; -- Event valid only if PASS is '1'.

					DVSEventDataRegEnable_S <= '1';

					AERCorrFilterPassEnableReg_S <= '0';

					DVSAERAckReg_SB <= '0';
					State_DN        <= stAERAckCol;
				end if;

				AckCount_S <= '1';

			when stAERAckCol =>
				AckLimit_D <= DVSAERCorrFilterConfigReg_D.AckExtensionColumn_D;

				DVSAERAckReg_SB <= '0';

				if DVSAERReq_SBI = '1' then
					-- We might need to extend the ACK period.
					if AckDone_S = '1' then
						DVSAERAckReg_SB <= '1';
						State_DN        <= stIdle;
					end if;

					AckCount_S <= '1';
				end if;

			when others => null;
		end case;
	end process dvsHandleAERComb;

	-- Change state on clock edge (synchronous).
	dvsHandleAERRegisterUpdate : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;

			DVSIsRowAddress_SP <= '0';

			DVSAERAck_SBO   <= '1';
			DVSAERReset_SBO <= '0';

			AERCorrFilterPassEnable_SO <= '0';

			DVSAERCorrFilterConfigReg_D <= tDVSAERCorrFilterConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			DVSIsRowAddress_SP <= DVSIsRowAddress_SN;

			DVSAERAck_SBO   <= DVSAERAckReg_SB;
			DVSAERReset_SBO <= DVSAERResetReg_SB;

			AERCorrFilterPassEnable_SO <= AERCorrFilterPassEnableReg_S;

			DVSAERCorrFilterConfigReg_D <= DVSAERCorrFilterConfig_DI;
		end if;
	end process dvsHandleAERRegisterUpdate;

	dvsEventDataRegister : entity work.SimpleRegister
		generic map(
			SIZE => EVENT_WIDTH)
		port map(
			Clock_CI  => Clock_CI,
			Reset_RI  => Reset_RI,
			Enable_SI => DVSEventDataRegEnable_S,
			Input_SI  => DVSEventDataReg_D,
			Output_SO => OutFifoData_DO);

	dvsEventValidRegister : entity work.SimpleRegister
		generic map(
			SIZE => 1)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Enable_SI    => '1',
			Input_SI(0)  => DVSEventValidReg_S,
			Output_SO(0) => OutFifoControl_SO.Write_S);
end Behavioral;
