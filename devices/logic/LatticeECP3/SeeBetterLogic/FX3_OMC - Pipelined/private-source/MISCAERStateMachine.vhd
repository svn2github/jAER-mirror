library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.FIFORecords.all;

entity MISCAERStateMachine is
	generic(
		MISC_OBT_AER_BUS_WIDTH : integer);
	port(
		Clock_CI          : in  std_logic;
		Reset_RI          : in  std_logic;
 
		-- Fifo output (to Multiplexer)
		OutFifoControl_SI : in  tFromFifoWriteSide;
		OutFifoControl_SO : out tToFifoWriteSide;
		OutFifoData_DO    : out std_logic_vector(EVENT_WIDTH - 1 downto 0);

		MISCAERData_DI     : in  std_logic_vector(MISC_OBT_AER_BUS_WIDTH - 1 downto 0);
		MISCAERReq_SBI     : in  std_logic;
		MISCAERAck_SBO     : out std_logic
		);
end MISCAERStateMachine;

architecture Behavioral of MISCAERStateMachine is 
	attribute syn_enum_encoding : string;
	
	type state is (stIdle, stDifferentiateYX, stHandleY, stAckY, stHandleMISC, stWaitMISC, stHandleX, stAckX);
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
	signal MISCAERAckReg_SB   : std_logic;
	--signal MISCAERResetReg_SB : std_logic;

--	signal DVSAERConfigReg_D : tDVSAERConfig;
begin

	p_memoryless : process(State_DP, OutFifoControl_SI, MISCAERReq_SBI, MISCAERData_DI, ackDelayNotify_S, ackExtensionNotify_S)
	begin 
		State_DN <= State_DP;           -- Keep current state by default.

		OutFifoWriteReg_S      <= '0';
		OutFifoDataRegEnable_S <= '0';
		OutFifoDataReg_D       <= (others => '0');

		MISCAERAckReg_SB   <= '1';       -- No AER ACK by default.
		--MISCAERResetReg_SB <= '1';       

		ackDelayCount_S     <= '0';
		ackExtensionCount_S <= '0';

		case State_DP is
			when stIdle =>
				-- Only exit idle state if DVS data producer is active.
				--if DVSAERConfigReg_D.Run_S = '1' then
					if MISCAERReq_SBI = '0' then -- and OutFifoControl_SI.Full_S = '0' then
						-- Got a request on the AER bus, let's get the data.
						-- If output fifo full, just wait for it to be empty.
						State_DN <= stDifferentiateYX;
					end if;
				--else
					-- Keep the DVS in reset if data producer turned off.
				--	MISCAERResetReg_SB <= '0';
				--end if;

			when stDifferentiateYX =>
				-- Get data and format it. AER(9) holds the axis.
				if MISCAERData_DI(9) = '0' then
					-- This is an Y address.
					-- They are differentiated here because Y addresses have
					-- all kinds of special timing requirements.
					State_DN        <= stHandleY;
					--ackDelayCount_S <= '1';
				else
					-- This is an X address.
					State_DN <= stHandleMISC;
				end if;

			when stHandleY =>
				-- We might need to delay the ACK.
				--if ackDelayNotify_S = '1' then
					OutFifoDataReg_D       <= EVENT_CODE_Y_ADDR & "0000" & MISCAERData_DI(7 downto 0);
					OutFifoDataRegEnable_S <= '1';
					OutFifoWriteReg_S      <= '1';

					MISCAERAckReg_SB     <= '0';
					State_DN            <= stAckY;
					--ackExtensionCount_S <= '1';
				--end if;

				--ackDelayCount_S <= '1';

			when stAckY =>
				MISCAERAckReg_SB <= '0';

				if MISCAERReq_SBI = '1' then
					-- We might need to extend the ACK period.
					--if ackExtensionNotify_S = '1' then
						MISCAERAckReg_SB <= '1';
						State_DN        <= stIdle;
					--end if;

					--ackExtensionCount_S <= '1';
				end if;

			when stHandleMISC =>
				-- We might need to delay the ACK.
				--if ackDelayNotify_S = '1' then
					OutFifoDataReg_D       <= EVENT_CODE_MISC_DATA8 & EVENT_CODE_MISC_DATA8_OMC & MISCAERData_DI(17 downto 10);
					OutFifoDataRegEnable_S <= '1';
					OutFifoWriteReg_S      <= '1';

					MISCAERAckReg_SB     <= '1';
					State_DN            <= stWaitMISC;
					--ackExtensionCount_S <= '1';
				--end if;

				--ackDelayCount_S <= '1';

			when stWaitMISC =>
				MISCAERAckReg_SB <= '1';

				--if MISCAERReq_SBI = '1' then
					-- We might need to extend the ACK period.
					--if ackExtensionNotify_S = '1' then
					--	MISCAERAckReg_SB <= '1';
						State_DN        <= stHandleX;
					--end if;

					--ackExtensionCount_S <= '1';
				--end if;			

			when stHandleX =>
				-- This is an X address. AER(0) holds the polarity. The
				-- address is shifted by one to AER(8 downto 1).
				OutFifoDataReg_D       <= EVENT_CODE_X_ADDR & MISCAERData_DI(0) & "0000" & MISCAERData_DI(8 downto 1);
				OutFifoDataRegEnable_S <= '1';
				OutFifoWriteReg_S      <= '1';

				MISCAERAckReg_SB <= '0';
				State_DN        <= stAckX;

			when stAckX =>
				MISCAERAckReg_SB <= '0';

				if MISCAERReq_SBI = '1' then
					MISCAERAckReg_SB <= '1';
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

			MISCAERAck_SBO   <= '1';
	--		MISCAERReset_SBO <= '0';

			--DVSAERConfigReg_D <= tDVSAERConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			OutFifoControl_SO.Write_S <= OutFifoWriteReg_S;
			if OutFifoDataRegEnable_S = '1' then
				OutFifoData_DO <= OutFifoDataReg_D;
			end if;

			MISCAERAck_SBO   <= MISCAERAckReg_SB;
	--		MISCAERReset_SBO <= MISCAERResetReg_SB;

			--DVSAERConfigReg_D <= DVSAERConfig_DI;
		end if;
	end process p_memoryzing;
end Behavioral;
