library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.DVSAERConfigRecords.all;

entity GenericAERStateMachine is
	generic(
		AER_BUS_WIDTH : integer);
	port(
		Clock_CI          : in  std_logic;
		Reset_RI          : in  std_logic;

		-- Fifo output (to Multiplexer)
		OutFifoControl_SI : in  tFromFifoWriteSide;
		OutFifoControl_SO : out tToFifoWriteSide;
		OutFifoData_DO    : out std_logic_vector(EVENT_WIDTH - 1 downto 0);

		AERData_DI        : in  std_logic_vector(AER_BUS_WIDTH - 1 downto 0);
		AERReq_SBI        : in  std_logic;
		AERAck_SBO        : out std_logic;
		AERReset_SBO      : out std_logic;

		-- Configuration input
		AERConfig_DI      : in  tDVSAERConfig);
end GenericAERStateMachine;

architecture Behavioral of GenericAERStateMachine is
	attribute syn_enum_encoding : string;

	type tState is (stIdle, stAERHandle, stAERAck, stFIFOFull);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : tState;

	-- Counter to influence acknowledge delays.
	signal AckCount_S, AckDone_S : std_logic;
	signal AckLimit_D            : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);

	-- Data incoming from AER bus.
	signal AEREventDataRegEnable_S : std_logic;
	signal AEREventDataReg_D       : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal AEREventValidReg_S      : std_logic;

	-- Register outputs to AER bus.
	signal AERAckReg_SB   : std_logic;
	signal AERResetReg_SB : std_logic;

	-- Register configuration input.
	signal AERConfigReg_D : tDVSAERConfig;
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

	handleAERComb : process(State_DP, OutFifoControl_SI, AERReq_SBI, AERData_DI, AERConfigReg_D, AckDone_S)
	begin
		State_DN <= State_DP;           -- Keep current state by default.

		AEREventValidReg_S      <= '0';
		AEREventDataRegEnable_S <= '0';
		AEREventDataReg_D       <= (others => '0');

		AERAckReg_SB   <= '1';          -- No AER ACK by default.
		AERResetReg_SB <= '1';          -- Keep AER bus out of reset by default, so we don't have to repeat this in every state.

		AckCount_S <= '0';
		AckLimit_D <= (others => '1');

		case State_DP is
			when stIdle =>
				-- Only exit idle state if AER bus data producer is active.
				if AERConfigReg_D.Run_S = '1' then
					if AERReq_SBI = '0' then
						if OutFifoControl_SI.Full_S = '0' then
							-- Got a request on the AER bus, let's get the data.
							-- We do have space in the output FIFO for it.
							State_DN <= stAERHandle;
						elsif AERConfigReg_D.WaitOnTransferStall_S = '0' then
							-- FIFO full, keep ACKing.
							State_DN <= stFIFOFull;
						end if;
					end if;
				else
					if AERConfigReg_D.ExternalAERControl_S = '1' then
						-- Support handing off control of AER to external systems connected through the CAVIAR
						-- connector on the board. This ensures the chip is kept out of reset and the ACK is
						-- not driven from our logic.
						AERAckReg_SB   <= 'Z';
						AERResetReg_SB <= '1';
					else
						-- Keep the DVS in reset if data producer turned off.
						AERResetReg_SB <= '0';
					end if;
				end if;

			when stFIFOFull =>
				-- Output FIFO is full, just ACK the data, so that, when
				-- we'll have space in the FIFO again, the newest piece of
				-- data is the next to be inserted, and not stale old data.
				AERAckReg_SB <= AERReq_SBI;

				-- Only go back to idle when FIFO has space again, and when
				-- the sender is not requesting (to avoid AER races).
				if OutFifoControl_SI.Full_S = '0' and AERReq_SBI = '1' then
					State_DN <= stIdle;
				end if;

			when stAERHandle =>
				AckLimit_D <= AERConfigReg_D.AckDelayColumn_D;

				-- We might need to delay the ACK.
				if AckDone_S = '1' then
					-- AER address.
					AEREventDataReg_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_Y_ADDR;
					AEREventDataReg_D(AER_BUS_WIDTH - 1 downto 0)             <= AERData_DI;

					AEREventValidReg_S      <= '1';
					AEREventDataRegEnable_S <= '1';

					AERAckReg_SB <= '0';
					State_DN     <= stAERAck;
				end if;

				AckCount_S <= '1';

			when stAERAck =>
				AckLimit_D <= AERConfigReg_D.AckExtensionColumn_D;

				AERAckReg_SB <= '0';

				if AERReq_SBI = '1' then
					-- We might need to extend the ACK period.
					if AckDone_S = '1' then
						AERAckReg_SB <= '1';
						State_DN     <= stIdle;
					end if;

					AckCount_S <= '1';
				end if;

			when others => null;
		end case;
	end process handleAERComb;

	-- Change state on clock edge (synchronous).
	dvsHandleAERRegisterUpdate : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;

			AERAck_SBO   <= '1';
			AERReset_SBO <= '0';

			AERConfigReg_D <= tDVSAERConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			AERAck_SBO   <= AERAckReg_SB;
			AERReset_SBO <= AERResetReg_SB;

			AERConfigReg_D <= AERConfig_DI;
		end if;
	end process dvsHandleAERRegisterUpdate;

	aerEventDataRegister : entity work.SimpleRegister
		generic map(
			SIZE => EVENT_WIDTH)
		port map(
			Clock_CI  => Clock_CI,
			Reset_RI  => Reset_RI,
			Enable_SI => AEREventDataRegEnable_S,
			Input_SI  => AEREventDataReg_D,
			Output_SO => OutFifoData_DO);

	aerEventValidRegister : entity work.SimpleRegister
		generic map(
			SIZE => 1)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Enable_SI    => '1',
			Input_SI(0)  => AEREventValidReg_S,
			Output_SO(0) => OutFifoControl_SO.Write_S);
end Behavioral;
