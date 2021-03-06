library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use ieee.math_real."**";
use work.EventCodes.all;
use work.FIFORecords.all;
use work.DVSAERConfigRecords.all;
use work.Settings.DVS_AER_BUS_WIDTH;
use work.Settings.CHIP_DVS_ORIGIN_POINT;
use work.Settings.CHIP_DVS_SIZE_ROWS;
use work.Settings.CHIP_DVS_SIZE_COLUMNS;
use work.Settings.LOGIC_CLOCK_FREQ;
use work.Settings.DEVICE_FAMILY;

entity DVSAERStateMachine is
	generic(
		ENABLE_PIXEL_FILTERING     : boolean := false;
		ENABLE_BA_FILTERING        : boolean := false;
		BA_FILTER_SUBSAMPLE_COLUMN : integer := 2;
		BA_FILTER_SUBSAMPLE_ROW    : integer := 2;
		ENABLE_TEST_GENERATOR      : boolean := false);
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

	type tState is (stIdle, stDifferentiateRowCol, stAERHandleRow, stAERAckRow, stAERHandleCol, stAERAckCol, stFIFOFull);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : tState;

	-- Counter to influence acknowledge delays.
	signal AckCount_S, AckDone_S : std_logic;
	signal AckLimit_D            : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);

	-- Bits needed for each address.
	constant DVS_ROW_ADDRESS_WIDTH    : integer := integer(ceil(log2(real(to_integer(CHIP_DVS_SIZE_ROWS)))));
	constant DVS_COLUMN_ADDRESS_WIDTH : integer := integer(ceil(log2(real(to_integer(CHIP_DVS_SIZE_COLUMNS)))));

	-- Data incoming from DVS.
	signal DVSEventDataRegEnable_S : std_logic;
	signal DVSEventDataReg_D       : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal DVSEventValidReg_S      : std_logic;
	signal DVSEventOutDataReg_D    : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal DVSEventOutValidReg_S   : std_logic;

	-- Register outputs to DVS.
	signal DVSAERAckReg_SB   : std_logic;
	signal DVSAERResetReg_SB : std_logic;

	-- Register configuration input.
	signal DVSAERConfigReg_D : tDVSAERConfig;

	-- Pixel filtering support.
	signal PixelFilterInDataReg_D   : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal PixelFilterInValidReg_S  : std_logic;
	signal PixelFilterOutDataReg_D  : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal PixelFilterOutValidReg_S : std_logic;

	-- Background Activity filtering support.
	signal BAFilterInDataReg_D   : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal BAFilterInValidReg_S  : std_logic;
	signal BAFilterOutDataReg_D  : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal BAFilterOutValidReg_S : std_logic;

	-- Row Only filtering support (at end to catch all the row-only events that
	-- are generated from the other filters due to dropping column events).
	signal RowOnlyFilterInDataReg_D   : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal RowOnlyFilterInValidReg_S  : std_logic;
	signal RowOnlyFilterOutDataReg_D  : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal RowOnlyFilterOutValidReg_S : std_logic;
	signal RowOnlyFilterFIFOWrite_S   : std_logic;
	signal RowOnlyFilterFIFOPassRow_S : std_logic;

	-- Test Event Generator support (generates fake sequential addresses).
	signal TestDVSEventDataRegEnable_S : std_logic;
	signal TestDVSEventDataReg_D       : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal TestDVSEventValidReg_S      : std_logic;
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

	dvsHandleAERComb : process(State_DP, OutFifoControl_SI, DVSAERReq_SBI, DVSAERData_DI, DVSAERConfigReg_D, AckDone_S)
	begin
		State_DN <= State_DP;           -- Keep current state by default.

		DVSEventValidReg_S      <= '0';
		DVSEventDataRegEnable_S <= '0';
		DVSEventDataReg_D       <= (others => '0');

		DVSAERAckReg_SB   <= '1';       -- No AER ACK by default.
		DVSAERResetReg_SB <= '1';       -- Keep DVS out of reset by default, so we don't have to repeat this in every state.

		AckCount_S <= '0';
		AckLimit_D <= (others => '1');

		case State_DP is
			when stIdle =>
				-- Only exit idle state if DVS data producer is active.
				if DVSAERConfigReg_D.Run_S = '1' then
					if DVSAERReq_SBI = '0' then
						if OutFifoControl_SI.AlmostFull_S = '0' then
							-- Got a request on the AER bus, let's get the data.
							-- We do have space in the output FIFO for it.
							State_DN <= stDifferentiateRowCol;
						elsif DVSAERConfigReg_D.WaitOnTransferStall_S = '0' then
							-- FIFO full, keep ACKing.
							State_DN <= stFIFOFull;
						end if;
					end if;
				else
					if DVSAERConfigReg_D.ExternalAERControl_S = '1' then
						-- Support handing off control of AER to external systems connected through the CAVIAR
						-- connector on the board. This ensures the chip is kept out of reset and the ACK is
						-- not driven from our logic.
						DVSAERAckReg_SB   <= 'Z';
						DVSAERResetReg_SB <= '1';
					else
						-- Keep the DVS in reset if data producer turned off.
						DVSAERResetReg_SB <= '0';
					end if;
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
				if DVSAERData_DI(DVS_AER_BUS_WIDTH - 1) = '0' then
					-- This is an Y address.
					State_DN <= stAERHandleRow;
				else
					State_DN <= stAERHandleCol;
				end if;

			when stAERHandleRow =>
				AckLimit_D <= DVSAERConfigReg_D.AckDelayRow_D;

				-- We might need to delay the ACK.
				if AckDone_S = '1' then
					-- Row address (Y).
					DVSEventDataReg_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_Y_ADDR;

					if CHIP_DVS_ORIGIN_POINT(0) = '1' then
						DVSEventDataReg_D(DVS_ROW_ADDRESS_WIDTH - 1 downto 0) <= std_logic_vector(resize(CHIP_DVS_SIZE_ROWS - 1, DVS_ROW_ADDRESS_WIDTH) - unsigned(DVSAERData_DI(DVS_ROW_ADDRESS_WIDTH - 1 downto 0)));
					else
						DVSEventDataReg_D(DVS_ROW_ADDRESS_WIDTH - 1 downto 0) <= DVSAERData_DI(DVS_ROW_ADDRESS_WIDTH - 1 downto 0);
					end if;

					DVSEventValidReg_S <= '1';

					DVSEventDataRegEnable_S <= '1';

					DVSAERAckReg_SB <= '0';
					State_DN        <= stAERAckRow;
				end if;

				AckCount_S <= '1';

			when stAERAckRow =>
				AckLimit_D <= DVSAERConfigReg_D.AckExtensionRow_D;

				DVSAERAckReg_SB <= '0';

				if DVSAERReq_SBI = '1' then
					-- We might need to extend the ACK period.
					if AckDone_S = '1' then
						DVSAERAckReg_SB <= '1';
						State_DN        <= stIdle;
					end if;

					AckCount_S <= '1';
				end if;

			when stAERHandleCol =>
				AckLimit_D <= DVSAERConfigReg_D.AckDelayColumn_D;

				-- We might need to delay the ACK.
				if AckDone_S = '1' then
					-- Column address (X).
					DVSEventDataReg_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_X_ADDR & DVSAERData_DI(0);

					if CHIP_DVS_ORIGIN_POINT(1) = '1' then
						DVSEventDataReg_D(DVS_COLUMN_ADDRESS_WIDTH - 1 downto 0) <= std_logic_vector(resize(CHIP_DVS_SIZE_COLUMNS - 1, DVS_COLUMN_ADDRESS_WIDTH) - unsigned(DVSAERData_DI(DVS_COLUMN_ADDRESS_WIDTH downto 1)));
					else
						DVSEventDataReg_D(DVS_COLUMN_ADDRESS_WIDTH - 1 downto 0) <= DVSAERData_DI(DVS_COLUMN_ADDRESS_WIDTH downto 1);
					end if;

					DVSEventValidReg_S <= '1';

					DVSEventDataRegEnable_S <= '1';

					DVSAERAckReg_SB <= '0';
					State_DN        <= stAERAckCol;
				end if;

				AckCount_S <= '1';

			when stAERAckCol =>
				AckLimit_D <= DVSAERConfigReg_D.AckExtensionColumn_D;

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

			DVSAERAck_SBO   <= '1';
			DVSAERReset_SBO <= '0';

			DVSAERConfigReg_D <= tDVSAERConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			DVSAERAck_SBO   <= DVSAERAckReg_SB;
			DVSAERReset_SBO <= DVSAERResetReg_SB;

			DVSAERConfigReg_D <= DVSAERConfig_DI;
		end if;
	end process dvsHandleAERRegisterUpdate;

	dvsEventDataRegister : entity work.SimpleRegister
		generic map(
			SIZE => EVENT_WIDTH)
		port map(
			Clock_CI                            => Clock_CI,
			Reset_RI                            => Reset_RI,
			Enable_SI                           => DVSEventDataRegEnable_S or TestDVSEventDataRegEnable_S,
			Input_SI(EVENT_WIDTH - 1 downto 0)  => DVSEventDataReg_D or TestDVSEventDataReg_D,
			Output_SO(EVENT_WIDTH - 1 downto 0) => DVSEventOutDataReg_D);

	dvsEventValidRegister : entity work.SimpleRegister
		generic map(
			SIZE => 1)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Enable_SI    => '1',
			Input_SI(0)  => DVSEventValidReg_S or TestDVSEventValidReg_S,
			Output_SO(0) => DVSEventOutValidReg_S);

	testGeneratorProcesses : if ENABLE_TEST_GENERATOR = true generate
		attribute syn_enum_encoding : string;

		type tTestState is (stIdle, stTestGenerateAddressRow, stTestGenerateAddressColOn, stTestGenerateAddressColOff);
		attribute syn_enum_encoding of tTestState : type is "onehot";

		-- present and next state
		signal TestState_DP, TestState_DN : tTestState;

		-- Test Event Generator support (generates fake sequential addresses).
		signal TestGeneratorRowCount_S    : std_logic;
		signal TestGeneratorRowDone_S     : std_logic;
		signal TestGeneratorRow_D         : unsigned(DVS_ROW_ADDRESS_WIDTH - 1 downto 0);
		signal TestGeneratorColumnCount_S : std_logic;
		signal TestGeneratorColumnDone_S  : std_logic;
		signal TestGeneratorColumn_D      : unsigned(DVS_COLUMN_ADDRESS_WIDTH - 1 downto 0);
	begin
		dvsTestGeneratorComb : process(TestState_DP, OutFifoControl_SI, DVSAERConfigReg_D, TestGeneratorColumnDone_S, TestGeneratorColumn_D, TestGeneratorRowDone_S, TestGeneratorRow_D)
		begin
			TestState_DN <= TestState_DP; -- Keep current state by default.

			-- Test Event Generator always disabled in normal operation.
			TestGeneratorRowCount_S    <= '0';
			TestGeneratorColumnCount_S <= '0';

			TestDVSEventValidReg_S      <= '0';
			TestDVSEventDataRegEnable_S <= '0';
			TestDVSEventDataReg_D       <= (others => '0');

			case TestState_DP is
				when stIdle =>
					-- If requested, produce fake events that sequentially span the whole array size.
					if DVSAERConfigReg_D.TestEventGeneratorEnable_S = '1' and DVSAERConfigReg_D.Run_S = '0' and DVSAERConfigReg_D.ExternalAERControl_S = '0' then
						-- Inject fake address.
						TestState_DN <= stTestGenerateAddressRow;
					end if;

				when stTestGenerateAddressRow =>
					if OutFifoControl_SI.AlmostFull_S = '0' then
						-- Send out fake row address (Y).
						TestDVSEventDataReg_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_Y_ADDR;
						TestDVSEventDataReg_D(DVS_ROW_ADDRESS_WIDTH - 1 downto 0)     <= std_logic_vector(TestGeneratorRow_D);
						TestDVSEventValidReg_S                                        <= '1';
						TestDVSEventDataRegEnable_S                                   <= '1';

						-- Increase row count for next pass.
						TestGeneratorRowCount_S <= '1';

						if TestGeneratorRowDone_S = '1' then
							-- Once done, go back to Idle state.
							TestState_DN <= stIdle;

							-- Don't forward at this point due to maximum address reached.
							TestDVSEventValidReg_S <= '0';
						else
							-- Go to send all columns for this row.
							TestState_DN <= stTestGenerateAddressColOn;
						end if;
					end if;

				when stTestGenerateAddressColOn =>
					if OutFifoControl_SI.AlmostFull_S = '0' then
						-- Send out fake column address (X) with ON polarity.
						TestDVSEventDataReg_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_X_ADDR_POL_ON;
						TestDVSEventDataReg_D(DVS_COLUMN_ADDRESS_WIDTH - 1 downto 0)  <= std_logic_vector(TestGeneratorColumn_D);
						TestDVSEventValidReg_S                                        <= '1';
						TestDVSEventDataRegEnable_S                                   <= '1';

						-- Increase column count for next pass.
						TestGeneratorColumnCount_S <= '1';

						-- Send next column ON value, or when maximum reached, go and send OFF events for all columns.
						if TestGeneratorColumnDone_S = '1' then
							TestState_DN <= stTestGenerateAddressColOff;
						else
							TestState_DN <= stTestGenerateAddressColOn;
						end if;
					end if;

				when stTestGenerateAddressColOff =>
					if OutFifoControl_SI.AlmostFull_S = '0' then
						-- Send out fake column address (X) with OFF polarity.
						TestDVSEventDataReg_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_X_ADDR_POL_OFF;
						TestDVSEventDataReg_D(DVS_COLUMN_ADDRESS_WIDTH - 1 downto 0)  <= std_logic_vector(TestGeneratorColumn_D);
						TestDVSEventValidReg_S                                        <= '1';
						TestDVSEventDataRegEnable_S                                   <= '1';

						-- Increase column count for next pass.
						TestGeneratorColumnCount_S <= '1';

						-- Send next column OFF value, or when maximum reached, go to next row.
						if TestGeneratorColumnDone_S = '1' then
							TestState_DN <= stTestGenerateAddressRow;
						else
							TestState_DN <= stTestGenerateAddressColOff;
						end if;
					end if;

				when others => null;
			end case;
		end process dvsTestGeneratorComb;

		-- Change state on clock edge (synchronous).
		dvsTestGeneratorRegisterUpdate : process(Clock_CI, Reset_RI)
		begin
			if Reset_RI = '1' then      -- asynchronous reset (active-high for FPGAs)
				TestState_DP <= stIdle;
			elsif rising_edge(Clock_CI) then
				TestState_DP <= TestState_DN;
			end if;
		end process dvsTestGeneratorRegisterUpdate;

		testGeneratorRowCounter : entity work.ContinuousCounter
			generic map(
				SIZE              => integer(ceil(log2(real(to_integer(CHIP_DVS_SIZE_ROWS + 1))))),
				RESET_ON_OVERFLOW => true,
				GENERATE_OVERFLOW => true)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Clear_SI     => '0',
				Enable_SI    => TestGeneratorRowCount_S,
				DataLimit_DI => CHIP_DVS_SIZE_ROWS,
				Overflow_SO  => TestGeneratorRowDone_S,
				Data_DO      => TestGeneratorRow_D);

		testGeneratorColumnCounter : entity work.ContinuousCounter
			generic map(
				SIZE              => DVS_COLUMN_ADDRESS_WIDTH,
				RESET_ON_OVERFLOW => true,
				GENERATE_OVERFLOW => true)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Clear_SI     => '0',
				Enable_SI    => TestGeneratorColumnCount_S,
				DataLimit_DI => CHIP_DVS_SIZE_COLUMNS - 1,
				Overflow_SO  => TestGeneratorColumnDone_S,
				Data_DO      => TestGeneratorColumn_D);
	end generate testGeneratorProcesses;

	testGeneratorDisabled : if ENABLE_TEST_GENERATOR = false generate
	begin
		TestDVSEventValidReg_S      <= '0';
		TestDVSEventDataRegEnable_S <= '0';
		TestDVSEventDataReg_D       <= (others => '0');
	end generate testGeneratorDisabled;

	rowOnlyFilter : process(RowOnlyFilterInDataReg_D, RowOnlyFilterInValidReg_S, DVSAERConfigReg_D)
	begin
		RowOnlyFilterOutDataReg_D  <= RowOnlyFilterInDataReg_D;
		RowOnlyFilterOutValidReg_S <= RowOnlyFilterInValidReg_S;
		RowOnlyFilterFIFOPassRow_S <= '0'; -- Bypass register and control FIFO directly.

		if DVSAERConfigReg_D.FilterRowOnlyEvents_S = '1' and RowOnlyFilterInValidReg_S = '1' then
			if RowOnlyFilterInDataReg_D(EVENT_WIDTH - 2) = '0' then
				-- This is a row address, we force it to be invalid, so that it is not automatically
				-- forwarded to the FIFO. We'll forward it later when encountering a column address.
				RowOnlyFilterOutValidReg_S <= '0';
			else
				-- Column address, we pass the previously stored row to FIFO at this point.
				-- The column address will go to the register and be forwarded as usual one
				-- cycle later.
				RowOnlyFilterFIFOPassRow_S <= '1';
			end if;
		end if;
	end process rowOnlyFilter;

	rowOnlyFilterDataRegister : entity work.SimpleRegister
		generic map(
			SIZE => EVENT_WIDTH)
		port map(
			Clock_CI  => Clock_CI,
			Reset_RI  => Reset_RI,
			Enable_SI => '1',
			Input_SI  => RowOnlyFilterOutDataReg_D,
			Output_SO => OutFifoData_DO);

	rowOnlyFilterValidRegister : entity work.SimpleRegister
		generic map(
			SIZE => 1)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Enable_SI    => '1',
			Input_SI(0)  => RowOnlyFilterOutValidReg_S,
			Output_SO(0) => RowOnlyFilterFIFOWrite_S);

	OutFifoControl_SO.Write_S <= RowOnlyFilterFIFOWrite_S xor RowOnlyFilterFIFOPassRow_S;

	dvsOnly : if ENABLE_PIXEL_FILTERING = false and ENABLE_BA_FILTERING = false generate
	begin
		RowOnlyFilterInDataReg_D  <= DVSEventOutDataReg_D;
		RowOnlyFilterInValidReg_S <= DVSEventOutValidReg_S;
	end generate dvsOnly;

	pixelFilteringOnly : if ENABLE_PIXEL_FILTERING = true and ENABLE_BA_FILTERING = false generate
	begin
		PixelFilterInDataReg_D  <= DVSEventOutDataReg_D;
		PixelFilterInValidReg_S <= DVSEventOutValidReg_S;

		pixelFilterDataRegister : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_WIDTH)
			port map(
				Clock_CI  => Clock_CI,
				Reset_RI  => Reset_RI,
				Enable_SI => '1',
				Input_SI  => PixelFilterOutDataReg_D,
				Output_SO => RowOnlyFilterInDataReg_D);

		pixelFilterValidRegister : entity work.SimpleRegister
			generic map(
				SIZE => 1)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => PixelFilterOutValidReg_S,
				Output_SO(0) => RowOnlyFilterInValidReg_S);
	end generate pixelFilteringOnly;

	baFilteringOnly : if ENABLE_PIXEL_FILTERING = false and ENABLE_BA_FILTERING = true generate
	begin
		BAFilterInDataReg_D  <= DVSEventOutDataReg_D;
		BAFilterInValidReg_S <= DVSEventOutValidReg_S;

		baFilterDataRegister : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_WIDTH)
			port map(
				Clock_CI  => Clock_CI,
				Reset_RI  => Reset_RI,
				Enable_SI => '1',
				Input_SI  => BAFilterOutDataReg_D,
				Output_SO => RowOnlyFilterInDataReg_D);

		baFilterValidRegister : entity work.SimpleRegister
			generic map(
				SIZE => 1)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => BAFilterOutValidReg_S,
				Output_SO(0) => RowOnlyFilterInValidReg_S);
	end generate baFilteringOnly;

	allFilters : if ENABLE_PIXEL_FILTERING = true and ENABLE_BA_FILTERING = true generate
	begin
		PixelFilterInDataReg_D  <= DVSEventOutDataReg_D;
		PixelFilterInValidReg_S <= DVSEventOutValidReg_S;

		pixelFilterDataRegister : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_WIDTH)
			port map(
				Clock_CI  => Clock_CI,
				Reset_RI  => Reset_RI,
				Enable_SI => '1',
				Input_SI  => PixelFilterOutDataReg_D,
				Output_SO => BAFilterInDataReg_D);

		pixelFilterValidRegister : entity work.SimpleRegister
			generic map(
				SIZE => 1)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => PixelFilterOutValidReg_S,
				Output_SO(0) => BAFilterInValidReg_S);

		baFilterDataRegister : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_WIDTH)
			port map(
				Clock_CI  => Clock_CI,
				Reset_RI  => Reset_RI,
				Enable_SI => '1',
				Input_SI  => BAFilterOutDataReg_D,
				Output_SO => RowOnlyFilterInDataReg_D);

		baFilterValidRegister : entity work.SimpleRegister
			generic map(
				SIZE => 1)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => BAFilterOutValidReg_S,
				Output_SO(0) => RowOnlyFilterInValidReg_S);
	end generate allFilters;

	pixelFilterSupport : if ENABLE_PIXEL_FILTERING = true generate
		signal LastRowAddress_DP, LastRowAddress_DN : unsigned(EVENT_DATA_WIDTH_MAX - 1 downto 0);
	begin
		pixelFilter : process(PixelFilterInDataReg_D, PixelFilterInValidReg_S, LastRowAddress_DP, DVSAERConfigReg_D)
			variable ColumnAddress_D : unsigned(EVENT_DATA_WIDTH_MAX - 1 downto 0) := (others => '0');
			variable RowAddress_D    : unsigned(EVENT_DATA_WIDTH_MAX - 1 downto 0) := (others => '0');

			variable Pixel0Hit_S : boolean := false;
			variable Pixel1Hit_S : boolean := false;
			variable Pixel2Hit_S : boolean := false;
			variable Pixel3Hit_S : boolean := false;
			variable Pixel4Hit_S : boolean := false;
			variable Pixel5Hit_S : boolean := false;
			variable Pixel6Hit_S : boolean := false;
			variable Pixel7Hit_S : boolean := false;
		begin
			PixelFilterOutDataReg_D  <= PixelFilterInDataReg_D;
			PixelFilterOutValidReg_S <= PixelFilterInValidReg_S;

			LastRowAddress_DN <= LastRowAddress_DP;

			if PixelFilterInValidReg_S = '1' then
				if PixelFilterInDataReg_D(EVENT_WIDTH - 2) = '0' then
					-- This is a row address, we just save it.
					LastRowAddress_DN <= unsigned(PixelFilterInDataReg_D(EVENT_DATA_WIDTH_MAX - 1 downto 0));
				else
					-- This is a column address, we do the full comparison at this point.
					-- If it matches any of the pixels that should be filtered, we set the column
					-- address to be invalid.
					ColumnAddress_D := unsigned(PixelFilterInDataReg_D(EVENT_DATA_WIDTH_MAX - 1 downto 0));
					RowAddress_D    := LastRowAddress_DP;

					Pixel0Hit_S := RowAddress_D = DVSAERConfigReg_D.FilterPixel0Row_D and ColumnAddress_D = DVSAERConfigReg_D.FilterPixel0Column_D;
					Pixel1Hit_S := RowAddress_D = DVSAERConfigReg_D.FilterPixel1Row_D and ColumnAddress_D = DVSAERConfigReg_D.FilterPixel1Column_D;
					Pixel2Hit_S := RowAddress_D = DVSAERConfigReg_D.FilterPixel2Row_D and ColumnAddress_D = DVSAERConfigReg_D.FilterPixel2Column_D;
					Pixel3Hit_S := RowAddress_D = DVSAERConfigReg_D.FilterPixel3Row_D and ColumnAddress_D = DVSAERConfigReg_D.FilterPixel3Column_D;
					Pixel4Hit_S := RowAddress_D = DVSAERConfigReg_D.FilterPixel4Row_D and ColumnAddress_D = DVSAERConfigReg_D.FilterPixel4Column_D;
					Pixel5Hit_S := RowAddress_D = DVSAERConfigReg_D.FilterPixel5Row_D and ColumnAddress_D = DVSAERConfigReg_D.FilterPixel5Column_D;
					Pixel6Hit_S := RowAddress_D = DVSAERConfigReg_D.FilterPixel6Row_D and ColumnAddress_D = DVSAERConfigReg_D.FilterPixel6Column_D;
					Pixel7Hit_S := RowAddress_D = DVSAERConfigReg_D.FilterPixel7Row_D and ColumnAddress_D = DVSAERConfigReg_D.FilterPixel7Column_D;

					if Pixel0Hit_S or Pixel1Hit_S or Pixel2Hit_S or Pixel3Hit_S or Pixel4Hit_S or Pixel5Hit_S or Pixel6Hit_S or Pixel7Hit_S then
						PixelFilterOutValidReg_S <= '0';
					end if;
				end if;
			end if;
		end process pixelFilter;

		pixelFilterLastRowAddressRegister : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_DATA_WIDTH_MAX)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(LastRowAddress_DN),
				unsigned(Output_SO) => LastRowAddress_DP);
	end generate pixelFilterSupport;

	baFilterSupport : if ENABLE_BA_FILTERING = true generate
		constant BA_COLUMN_ADDRESS_WIDTH : integer := DVS_COLUMN_ADDRESS_WIDTH - BA_FILTER_SUBSAMPLE_COLUMN;
		constant BA_ROW_ADDRESS_WIDTH    : integer := DVS_ROW_ADDRESS_WIDTH - BA_FILTER_SUBSAMPLE_ROW;
		constant BA_COLUMN_CELL_NUMBER   : integer := integer(ceil(real(to_integer(CHIP_DVS_SIZE_COLUMNS)) / (2.0 ** real(BA_FILTER_SUBSAMPLE_COLUMN))));
		constant BA_ROW_CELL_NUMBER      : integer := integer(ceil(real(to_integer(CHIP_DVS_SIZE_ROWS)) / (2.0 ** real(BA_FILTER_SUBSAMPLE_ROW))));
		constant BA_COLUMN_CELL_ADDRESS  : integer := integer(ceil(real(BA_COLUMN_CELL_NUMBER) / 4.0));
		constant BA_ROW_CELL_ADDRESS     : integer := integer(ceil(real(BA_ROW_CELL_NUMBER) / 4.0));
		constant BA_ADDRESS_DEPTH        : integer := BA_COLUMN_CELL_ADDRESS * BA_ROW_CELL_ADDRESS;
		constant BA_ADDRESS_WIDTH        : integer := integer(ceil(log2(real(BA_ADDRESS_DEPTH))));
		constant BA_TIMESTAMP_WIDTH      : integer := 18;

		signal TimestampMapAddress_DP, TimestampMapAddress_DN                   : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMapAddressLeft_DP, TimestampMapAddressLeft_DN           : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMapAddressRight_DP, TimestampMapAddressRight_DN         : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMapAddressDown_DP, TimestampMapAddressDown_DN           : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMapAddressDownLeft_DP, TimestampMapAddressDownLeft_DN   : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMapAddressDownRight_DP, TimestampMapAddressDownRight_DN : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMapAddressUp_DP, TimestampMapAddressUp_DN               : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMapAddressUpLeft_DP, TimestampMapAddressUpLeft_DN       : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMapAddressUpRight_DP, TimestampMapAddressUpRight_DN     : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);

		signal TimestampMap0_DP, TimestampMap0_DN   : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap1_DP, TimestampMap1_DN   : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap2_DP, TimestampMap2_DN   : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap3_DP, TimestampMap3_DN   : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap4_DP, TimestampMap4_DN   : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap5_DP, TimestampMap5_DN   : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap6_DP, TimestampMap6_DN   : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap7_DP, TimestampMap7_DN   : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap8_DP, TimestampMap8_DN   : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap9_DP, TimestampMap9_DN   : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap10_DP, TimestampMap10_DN : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap11_DP, TimestampMap11_DN : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap12_DP, TimestampMap12_DN : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap13_DP, TimestampMap13_DN : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap14_DP, TimestampMap14_DN : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampMap15_DP, TimestampMap15_DN : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);

		signal TimestampMap0En_S, TimestampMap0WrEn_S   : std_logic;
		signal TimestampMap1En_S, TimestampMap1WrEn_S   : std_logic;
		signal TimestampMap2En_S, TimestampMap2WrEn_S   : std_logic;
		signal TimestampMap3En_S, TimestampMap3WrEn_S   : std_logic;
		signal TimestampMap4En_S, TimestampMap4WrEn_S   : std_logic;
		signal TimestampMap5En_S, TimestampMap5WrEn_S   : std_logic;
		signal TimestampMap6En_S, TimestampMap6WrEn_S   : std_logic;
		signal TimestampMap7En_S, TimestampMap7WrEn_S   : std_logic;
		signal TimestampMap8En_S, TimestampMap8WrEn_S   : std_logic;
		signal TimestampMap9En_S, TimestampMap9WrEn_S   : std_logic;
		signal TimestampMap10En_S, TimestampMap10WrEn_S : std_logic;
		signal TimestampMap11En_S, TimestampMap11WrEn_S : std_logic;
		signal TimestampMap12En_S, TimestampMap12WrEn_S : std_logic;
		signal TimestampMap13En_S, TimestampMap13WrEn_S : std_logic;
		signal TimestampMap14En_S, TimestampMap14WrEn_S : std_logic;
		signal TimestampMap15En_S, TimestampMap15WrEn_S : std_logic;

		signal TimestampMap0Address_D  : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap1Address_D  : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap2Address_D  : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap3Address_D  : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap4Address_D  : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap5Address_D  : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap6Address_D  : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap7Address_D  : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap8Address_D  : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap9Address_D  : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap10Address_D : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap11Address_D : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap12Address_D : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap13Address_D : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap14Address_D : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);
		signal TimestampMap15Address_D : unsigned(BA_ADDRESS_WIDTH - 1 downto 0);

		-- Generate microsecond continuous timestamp value.
		constant TS_TICK      : integer := LOGIC_CLOCK_FREQ;
		constant TS_TICK_SIZE : integer := integer(ceil(log2(real(TS_TICK + 1))));

		signal TimestampTick_S   : std_logic;
		signal Timestamp_D       : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);
		signal TimestampBuffer_D : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0);

		-- Intermediate TS Map Lookup stages support.
		signal BAFilterTSAddressInDataReg_D   : std_logic_vector(EVENT_WIDTH - 1 downto 0);
		signal BAFilterTSAddressInValidReg_S  : std_logic;
		signal BAFilterTSAddressOutDataReg_D  : std_logic_vector(EVENT_WIDTH - 1 downto 0);
		signal BAFilterTSAddressOutValidReg_S : std_logic;

		signal BAFilterTSLookupInDataReg_D   : std_logic_vector(EVENT_WIDTH - 1 downto 0);
		signal BAFilterTSLookupInValidReg_S  : std_logic;
		signal BAFilterTSLookupOutDataReg_D  : std_logic_vector(EVENT_WIDTH - 1 downto 0);
		signal BAFilterTSLookupOutValidReg_S : std_logic;

		-- Remember TS Map number for second stage, to get right value from RAM.
		signal BAFilterTSLookupMapReg_DP, BAFilterTSLookupMapReg_DN : std_logic_vector(3 downto 0);

		signal LastRowAddress0_DP, LastRowAddress0_DN : unsigned(EVENT_DATA_WIDTH_MAX - 1 downto 0);
		signal LastRowAddress1_DP, LastRowAddress1_DN : unsigned(EVENT_DATA_WIDTH_MAX - 1 downto 0);
	begin
		baFilter0 : process(BAFilterInDataReg_D, BAFilterInValidReg_S, LastRowAddress0_DP)
			variable ColumnAddress_D : unsigned(BA_COLUMN_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
			variable RowAddress_D    : unsigned(BA_ROW_ADDRESS_WIDTH - 1 downto 0)    := (others => '0');

			variable TimestampMapAddress_D     : unsigned(BA_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
			variable TimestampMapAddressDown_D : unsigned(BA_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
			variable TimestampMapAddressUp_D   : unsigned(BA_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
		begin
			BAFilterTSAddressOutDataReg_D  <= BAFilterInDataReg_D;
			BAFilterTSAddressOutValidReg_S <= BAFilterInValidReg_S;

			LastRowAddress0_DN <= LastRowAddress0_DP;

			TimestampMapAddress_DN          <= (others => '0');
			TimestampMapAddressLeft_DN      <= (others => '0');
			TimestampMapAddressRight_DN     <= (others => '0');
			TimestampMapAddressDown_DN      <= (others => '0');
			TimestampMapAddressDownleft_DN  <= (others => '0');
			TimestampMapAddressDownRight_DN <= (others => '0');
			TimestampMapAddressUp_DN        <= (others => '0');
			TimestampMapAddressUpLeft_DN    <= (others => '0');
			TimestampMapAddressUpRight_DN   <= (others => '0');

			if BAFilterInValidReg_S = '1' then
				if BAFilterInDataReg_D(EVENT_WIDTH - 2) = '0' then
					-- This is a row address, we just save it.
					LastRowAddress0_DN <= unsigned(BAFilterInDataReg_D(EVENT_DATA_WIDTH_MAX - 1 downto 0));
				else
					-- This is a column address, let's determine the TS Map addresses first to pipeline the
					-- multiplication and separate it, for better timing closure.
					-- The address is downsampled here, right at the start.
					ColumnAddress_D := unsigned(BAFilterInDataReg_D(DVS_COLUMN_ADDRESS_WIDTH - 1 downto BA_FILTER_SUBSAMPLE_COLUMN));
					RowAddress_D    := LastRowAddress0_DP(DVS_ROW_ADDRESS_WIDTH - 1 downto BA_FILTER_SUBSAMPLE_ROW);

					TimestampMapAddress_D       := resize(RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) * to_unsigned(BA_COLUMN_CELL_ADDRESS, BA_COLUMN_ADDRESS_WIDTH - 1) + ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2), BA_ADDRESS_WIDTH);
					TimestampMapAddress_DN      <= TimestampMapAddress_D;
					TimestampMapAddressLeft_DN  <= TimestampMapAddress_D - 1;
					TimestampMapAddressRight_DN <= TimestampMapAddress_D + 1;

					TimestampMapAddressDown_D       := resize((RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) - 1) * to_unsigned(BA_COLUMN_CELL_ADDRESS, BA_COLUMN_ADDRESS_WIDTH - 1) + ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2), BA_ADDRESS_WIDTH);
					TimestampMapAddressDown_DN      <= TimestampMapAddressDown_D;
					TimestampMapAddressDownLeft_DN  <= TimestampMapAddressDown_D - 1;
					TimestampMapAddressDownRight_DN <= TimestampMapAddressDown_D + 1;

					TimestampMapAddressUp_D       := resize((RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) + 1) * to_unsigned(BA_COLUMN_CELL_ADDRESS, BA_COLUMN_ADDRESS_WIDTH - 1) + ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2), BA_ADDRESS_WIDTH);
					TimestampMapAddressUp_DN      <= TimestampMapAddressUp_D;
					TimestampMapAddressUpLeft_DN  <= TimestampMapAddressUp_D - 1;
					TimestampMapAddressUpRight_DN <= TimestampMapAddressUp_D + 1;
				end if;
			end if;
		end process baFilter0;

		baFilter1 : process(BAFilterTSAddressInDataReg_D, BAFilterTSAddressInValidReg_S, LastRowAddress1_DP, Timestamp_D, TimestampMapAddressDownLeft_DP, TimestampMapAddressDownRight_DP, TimestampMapAddressDown_DP, TimestampMapAddressLeft_DP, TimestampMapAddressRight_DP, TimestampMapAddressUpLeft_DP, TimestampMapAddressUpRight_DP, TimestampMapAddressUp_DP, TimestampMapAddress_DP)
			variable ColumnAddress_D : unsigned(BA_COLUMN_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
			variable RowAddress_D    : unsigned(BA_ROW_ADDRESS_WIDTH - 1 downto 0)    := (others => '0');

			variable BorderLeft_S  : boolean := false;
			variable BorderDown_S  : boolean := false;
			variable BorderRight_S : boolean := false;
			variable BorderUp_S    : boolean := false;

			variable Column0_S : boolean := false;
			variable Column1_S : boolean := false;
			variable Column2_S : boolean := false;
			variable Column3_S : boolean := false;

			variable Row0_S : boolean := false;
			variable Row1_S : boolean := false;
			variable Row2_S : boolean := false;
			variable Row3_S : boolean := false;

			variable Column0Active_S : boolean := false;
			variable Column1Active_S : boolean := false;
			variable Column2Active_S : boolean := false;
			variable Column3Active_S : boolean := false;

			variable Row0Active_S : boolean := false;
			variable Row1Active_S : boolean := false;
			variable Row2Active_S : boolean := false;
			variable Row3Active_S : boolean := false;

			function BooleanToStdLogic(BOOL : boolean) return std_logic is
			begin
				if BOOL then
					return '1';
				else
					return '0';
				end if;
			end function BooleanToStdLogic;
		begin
			BAFilterTSLookupOutDataReg_D  <= BAFilterTSAddressInDataReg_D;
			BAFilterTSLookupOutValidReg_S <= BAFilterTSAddressInValidReg_S;

			BAFilterTSLookupMapReg_DN <= (others => '0');

			LastRowAddress1_DN <= LastRowAddress1_DP;

			-- The next value, if and when we're going to write to a RAM address, is
			-- always going to be the current timestamp. So we can just hardcode that.
			TimestampMap0_DN  <= Timestamp_D;
			TimestampMap1_DN  <= Timestamp_D;
			TimestampMap2_DN  <= Timestamp_D;
			TimestampMap3_DN  <= Timestamp_D;
			TimestampMap4_DN  <= Timestamp_D;
			TimestampMap5_DN  <= Timestamp_D;
			TimestampMap6_DN  <= Timestamp_D;
			TimestampMap7_DN  <= Timestamp_D;
			TimestampMap8_DN  <= Timestamp_D;
			TimestampMap9_DN  <= Timestamp_D;
			TimestampMap10_DN <= Timestamp_D;
			TimestampMap11_DN <= Timestamp_D;
			TimestampMap12_DN <= Timestamp_D;
			TimestampMap13_DN <= Timestamp_D;
			TimestampMap14_DN <= Timestamp_D;
			TimestampMap15_DN <= Timestamp_D;

			TimestampMap0En_S  <= '0';
			TimestampMap1En_S  <= '0';
			TimestampMap2En_S  <= '0';
			TimestampMap3En_S  <= '0';
			TimestampMap4En_S  <= '0';
			TimestampMap5En_S  <= '0';
			TimestampMap6En_S  <= '0';
			TimestampMap7En_S  <= '0';
			TimestampMap8En_S  <= '0';
			TimestampMap9En_S  <= '0';
			TimestampMap10En_S <= '0';
			TimestampMap11En_S <= '0';
			TimestampMap12En_S <= '0';
			TimestampMap13En_S <= '0';
			TimestampMap14En_S <= '0';
			TimestampMap15En_S <= '0';

			TimestampMap0WrEn_S  <= '0';
			TimestampMap1WrEn_S  <= '0';
			TimestampMap2WrEn_S  <= '0';
			TimestampMap3WrEn_S  <= '0';
			TimestampMap4WrEn_S  <= '0';
			TimestampMap5WrEn_S  <= '0';
			TimestampMap6WrEn_S  <= '0';
			TimestampMap7WrEn_S  <= '0';
			TimestampMap8WrEn_S  <= '0';
			TimestampMap9WrEn_S  <= '0';
			TimestampMap10WrEn_S <= '0';
			TimestampMap11WrEn_S <= '0';
			TimestampMap12WrEn_S <= '0';
			TimestampMap13WrEn_S <= '0';
			TimestampMap14WrEn_S <= '0';
			TimestampMap15WrEn_S <= '0';

			TimestampMap0Address_D  <= (others => '0');
			TimestampMap1Address_D  <= (others => '0');
			TimestampMap2Address_D  <= (others => '0');
			TimestampMap3Address_D  <= (others => '0');
			TimestampMap4Address_D  <= (others => '0');
			TimestampMap5Address_D  <= (others => '0');
			TimestampMap6Address_D  <= (others => '0');
			TimestampMap7Address_D  <= (others => '0');
			TimestampMap8Address_D  <= (others => '0');
			TimestampMap9Address_D  <= (others => '0');
			TimestampMap10Address_D <= (others => '0');
			TimestampMap11Address_D <= (others => '0');
			TimestampMap12Address_D <= (others => '0');
			TimestampMap13Address_D <= (others => '0');
			TimestampMap14Address_D <= (others => '0');
			TimestampMap15Address_D <= (others => '0');

			if BAFilterTSAddressInValidReg_S = '1' then
				if BAFilterTSAddressInDataReg_D(EVENT_WIDTH - 2) = '0' then
					-- This is a row address, we just save it.
					LastRowAddress1_DN <= unsigned(BAFilterTSAddressInDataReg_D(EVENT_DATA_WIDTH_MAX - 1 downto 0));
				else
					-- This is a column address, let's determine all valid RAM parameters.
					-- The address is downsampled here, right at the start.
					ColumnAddress_D := unsigned(BAFilterTSAddressInDataReg_D(DVS_COLUMN_ADDRESS_WIDTH - 1 downto BA_FILTER_SUBSAMPLE_COLUMN));
					RowAddress_D    := LastRowAddress1_DP(DVS_ROW_ADDRESS_WIDTH - 1 downto BA_FILTER_SUBSAMPLE_ROW);

					BAFilterTSLookupMapReg_DN <= std_logic_vector(RowAddress_D(1 downto 0) & ColumnAddress_D(1 downto 0));

					BorderLeft_S  := ColumnAddress_D = 0;
					BorderDown_S  := RowAddress_D = 0;
					BorderRight_S := ColumnAddress_D = (BA_COLUMN_CELL_NUMBER - 1);
					BorderUp_S    := RowAddress_D = (BA_ROW_CELL_NUMBER - 1);

					Column0_S := ColumnAddress_D(1 downto 0) = "00";
					Column1_S := ColumnAddress_D(1 downto 0) = "01";
					Column2_S := ColumnAddress_D(1 downto 0) = "10";
					Column3_S := ColumnAddress_D(1 downto 0) = "11";

					Row0_S := RowAddress_D(1 downto 0) = "00";
					Row1_S := RowAddress_D(1 downto 0) = "01";
					Row2_S := RowAddress_D(1 downto 0) = "10";
					Row3_S := RowAddress_D(1 downto 0) = "11";

					-- BorderLeft can happen only when column is zero.
					Column0Active_S := Column0_S or Column1_S or (Column3_S and not BorderRight_S);
					Column1Active_S := Column1_S or Column2_S or (Column0_S and not BorderRight_S);
					Column2Active_S := Column2_S or Column3_S or (Column1_S and not BorderRight_S);
					Column3Active_S := Column3_S or (Column0_S and not BorderLeft_S) or (Column2_S and not BorderRight_S);

					-- BorderDown can happen only when row is zero.
					Row0Active_S := Row0_S or Row1_S or (Row3_S and not BorderUp_S);
					Row1Active_S := Row1_S or Row2_S or (Row0_S and not BorderUp_S);
					Row2Active_S := Row2_S or Row3_S or (Row1_S and not BorderUp_S);
					Row3Active_S := Row3_S or (Row0_S and not BorderDown_S) or (Row2_S and not BorderUp_S);

					TimestampMap0En_S  <= BooleanToStdLogic(Column0Active_S and Row0Active_S);
					TimestampMap1En_S  <= BooleanToStdLogic(Column1Active_S and Row0Active_S);
					TimestampMap2En_S  <= BooleanToStdLogic(Column2Active_S and Row0Active_S);
					TimestampMap3En_S  <= BooleanToStdLogic(Column3Active_S and Row0Active_S);
					TimestampMap4En_S  <= BooleanToStdLogic(Column0Active_S and Row1Active_S);
					TimestampMap5En_S  <= BooleanToStdLogic(Column1Active_S and Row1Active_S);
					TimestampMap6En_S  <= BooleanToStdLogic(Column2Active_S and Row1Active_S);
					TimestampMap7En_S  <= BooleanToStdLogic(Column3Active_S and Row1Active_S);
					TimestampMap8En_S  <= BooleanToStdLogic(Column0Active_S and Row2Active_S);
					TimestampMap9En_S  <= BooleanToStdLogic(Column1Active_S and Row2Active_S);
					TimestampMap10En_S <= BooleanToStdLogic(Column2Active_S and Row2Active_S);
					TimestampMap11En_S <= BooleanToStdLogic(Column3Active_S and Row2Active_S);
					TimestampMap12En_S <= BooleanToStdLogic(Column0Active_S and Row3Active_S);
					TimestampMap13En_S <= BooleanToStdLogic(Column1Active_S and Row3Active_S);
					TimestampMap14En_S <= BooleanToStdLogic(Column2Active_S and Row3Active_S);
					TimestampMap15En_S <= BooleanToStdLogic(Column3Active_S and Row3Active_S);

					TimestampMap0WrEn_S  <= BooleanToStdLogic(Column0_S nand Row0_S);
					TimestampMap1WrEn_S  <= BooleanToStdLogic(Column1_S nand Row0_S);
					TimestampMap2WrEn_S  <= BooleanToStdLogic(Column2_S nand Row0_S);
					TimestampMap3WrEn_S  <= BooleanToStdLogic(Column3_S nand Row0_S);
					TimestampMap4WrEn_S  <= BooleanToStdLogic(Column0_S nand Row1_S);
					TimestampMap5WrEn_S  <= BooleanToStdLogic(Column1_S nand Row1_S);
					TimestampMap6WrEn_S  <= BooleanToStdLogic(Column2_S nand Row1_S);
					TimestampMap7WrEn_S  <= BooleanToStdLogic(Column3_S nand Row1_S);
					TimestampMap8WrEn_S  <= BooleanToStdLogic(Column0_S nand Row2_S);
					TimestampMap9WrEn_S  <= BooleanToStdLogic(Column1_S nand Row2_S);
					TimestampMap10WrEn_S <= BooleanToStdLogic(Column2_S nand Row2_S);
					TimestampMap11WrEn_S <= BooleanToStdLogic(Column3_S nand Row2_S);
					TimestampMap12WrEn_S <= BooleanToStdLogic(Column0_S nand Row3_S);
					TimestampMap13WrEn_S <= BooleanToStdLogic(Column1_S nand Row3_S);
					TimestampMap14WrEn_S <= BooleanToStdLogic(Column2_S nand Row3_S);
					TimestampMap15WrEn_S <= BooleanToStdLogic(Column3_S nand Row3_S);

					TimestampMap0Address_D  <= TimestampMapAddress_DP;
					TimestampMap1Address_D  <= TimestampMapAddress_DP;
					TimestampMap2Address_D  <= TimestampMapAddress_DP;
					TimestampMap3Address_D  <= TimestampMapAddress_DP;
					TimestampMap4Address_D  <= TimestampMapAddress_DP;
					TimestampMap5Address_D  <= TimestampMapAddress_DP;
					TimestampMap6Address_D  <= TimestampMapAddress_DP;
					TimestampMap7Address_D  <= TimestampMapAddress_DP;
					TimestampMap8Address_D  <= TimestampMapAddress_DP;
					TimestampMap9Address_D  <= TimestampMapAddress_DP;
					TimestampMap10Address_D <= TimestampMapAddress_DP;
					TimestampMap11Address_D <= TimestampMapAddress_DP;
					TimestampMap12Address_D <= TimestampMapAddress_DP;
					TimestampMap13Address_D <= TimestampMapAddress_DP;
					TimestampMap14Address_D <= TimestampMapAddress_DP;
					TimestampMap15Address_D <= TimestampMapAddress_DP;

					if Column0_S = true then
						if Row0_S = true then
							-- Left/Down Corner
							TimestampMap3Address_D  <= TimestampMapAddressLeft_DP;
							TimestampMap7Address_D  <= TimestampMapAddressLeft_DP;
							TimestampMap12Address_D <= TimestampMapAddressDown_DP;
							TimestampMap13Address_D <= TimestampMapAddressDown_DP;
							TimestampMap15Address_D <= TimestampMapAddressDownLeft_DP;
						elsif Row3_S = true then
							-- Left/Up Corner
							TimestampMap0Address_D  <= TimestampMapAddressUp_DP;
							TimestampMap1Address_D  <= TimestampMapAddressUp_DP;
							TimestampMap3Address_D  <= TimestampMapAddressUpLeft_DP;
							TimestampMap11Address_D <= TimestampMapAddressLeft_DP;
							TimestampMap15Address_D <= TimestampMapAddressLeft_DP;
						else            -- Rows 1/2
							-- Left Border
							TimestampMap3Address_D  <= TimestampMapAddressLeft_DP;
							TimestampMap7Address_D  <= TimestampMapAddressLeft_DP;
							TimestampMap11Address_D <= TimestampMapAddressLeft_DP;
							TimestampMap15Address_D <= TimestampMapAddressLeft_DP;
						end if;
					elsif Column3_S = true then
						if Row0_S = true then
							-- Right/Down Corner
							TimestampMap0Address_D  <= TimestampMapAddressRight_DP;
							TimestampMap4Address_D  <= TimestampMapAddressRight_DP;
							TimestampMap12Address_D <= TimestampMapAddressDownRight_DP;
							TimestampMap14Address_D <= TimestampMapAddressDown_DP;
							TimestampMap15Address_D <= TimestampMapAddressDown_DP;
						elsif Row3_S = true then
							-- Right/Up Corner
							TimestampMap0Address_D  <= TimestampMapAddressUpRight_DP;
							TimestampMap2Address_D  <= TimestampMapAddressUp_DP;
							TimestampMap3Address_D  <= TimestampMapAddressUp_DP;
							TimestampMap8Address_D  <= TimestampMapAddressRight_DP;
							TimestampMap12Address_D <= TimestampMapAddressRight_DP;
						else            -- Rows 1/2
							-- Right Border
							TimestampMap0Address_D  <= TimestampMapAddressRight_DP;
							TimestampMap4Address_D  <= TimestampMapAddressRight_DP;
							TimestampMap8Address_D  <= TimestampMapAddressRight_DP;
							TimestampMap12Address_D <= TimestampMapAddressRight_DP;
						end if;
					else                -- Columns 1/2
						if Row0_S = true then
							-- Down Border
							TimestampMap12Address_D <= TimestampMapAddressDown_DP;
							TimestampMap13Address_D <= TimestampMapAddressDown_DP;
							TimestampMap14Address_D <= TimestampMapAddressDown_DP;
							TimestampMap15Address_D <= TimestampMapAddressDown_DP;
						elsif Row3_S = true then
							-- Up Border
							TimestampMap0Address_D <= TimestampMapAddressUp_DP;
							TimestampMap1Address_D <= TimestampMapAddressUp_DP;
							TimestampMap2Address_D <= TimestampMapAddressUp_DP;
							TimestampMap3Address_D <= TimestampMapAddressUp_DP;
						end if;
					end if;
				end if;
			end if;
		end process baFilter1;

		baFilterTSAddressDataRegister : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_WIDTH)
			port map(
				Clock_CI  => Clock_CI,
				Reset_RI  => Reset_RI,
				Enable_SI => '1',
				Input_SI  => BAFilterTSAddressOutDataReg_D,
				Output_SO => BAFilterTSAddressInDataReg_D);

		baFilterTSAddressValidRegister : entity work.SimpleRegister
			generic map(
				SIZE => 1)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => BAFilterTSAddressOutValidReg_S,
				Output_SO(0) => BAFilterTSAddressInValidReg_S);

		baFilterTSLookupDataRegister : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_WIDTH)
			port map(
				Clock_CI  => Clock_CI,
				Reset_RI  => Reset_RI,
				Enable_SI => '1',
				Input_SI  => BAFilterTSLookupOutDataReg_D,
				Output_SO => BAFilterTSLookupInDataReg_D);

		baFilterTSLookupValidRegister : entity work.SimpleRegister
			generic map(
				SIZE => 1)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => BAFilterTSLookupOutValidReg_S,
				Output_SO(0) => BAFilterTSLookupInValidReg_S);

		baFilterTSLookupMapRegister : entity work.SimpleRegister
			generic map(
				SIZE => 2 + 2)
			port map(
				Clock_CI  => Clock_CI,
				Reset_RI  => Reset_RI,
				Enable_SI => '1',
				Input_SI  => BAFilterTSLookupMapReg_DN,
				Output_SO => BAFilterTSLookupMapReg_DP);

		baFilter2 : process(BAFilterTSLookupInDataReg_D, BAFilterTSLookupInValidReg_S, TimestampBuffer_D, BAFilterTSLookupMapReg_DP, DVSAERConfigReg_D, TimestampMap0_DP, TimestampMap10_DP, TimestampMap11_DP, TimestampMap12_DP, TimestampMap13_DP, TimestampMap14_DP, TimestampMap15_DP, TimestampMap1_DP, TimestampMap2_DP, TimestampMap3_DP, TimestampMap4_DP, TimestampMap5_DP, TimestampMap6_DP, TimestampMap7_DP, TimestampMap8_DP, TimestampMap9_DP)
			variable TimestampResult_D : unsigned(BA_TIMESTAMP_WIDTH - 1 downto 0) := (others => '0');
		begin
			BAFilterOutDataReg_D  <= BAFilterTSLookupInDataReg_D;
			BAFilterOutValidReg_S <= BAFilterTSLookupInValidReg_S;

			case BAFilterTSLookupMapReg_DP is
				when "0000" =>
					TimestampResult_D := TimestampMap0_DP;

				when "0001" =>
					TimestampResult_D := TimestampMap1_DP;

				when "0010" =>
					TimestampResult_D := TimestampMap2_DP;

				when "0011" =>
					TimestampResult_D := TimestampMap3_DP;

				when "0100" =>
					TimestampResult_D := TimestampMap4_DP;

				when "0101" =>
					TimestampResult_D := TimestampMap5_DP;

				when "0110" =>
					TimestampResult_D := TimestampMap6_DP;

				when "0111" =>
					TimestampResult_D := TimestampMap7_DP;

				when "1000" =>
					TimestampResult_D := TimestampMap8_DP;

				when "1001" =>
					TimestampResult_D := TimestampMap9_DP;

				when "1010" =>
					TimestampResult_D := TimestampMap10_DP;

				when "1011" =>
					TimestampResult_D := TimestampMap11_DP;

				when "1100" =>
					TimestampResult_D := TimestampMap12_DP;

				when "1101" =>
					TimestampResult_D := TimestampMap13_DP;

				when "1110" =>
					TimestampResult_D := TimestampMap14_DP;

				when "1111" =>
					TimestampResult_D := TimestampMap15_DP;

				when others => null;
			end case;

			if BAFilterTSLookupInValidReg_S = '1' and BAFilterTSLookupInDataReg_D(EVENT_WIDTH - 2) = '1' and DVSAERConfigReg_D.FilterBackgroundActivity_S = '1' and (TimestampBuffer_D - TimestampResult_D) >= DVSAERConfigReg_D.FilterBackgroundActivityDeltaTime_D then
				-- This is a valid column address event, which means that in the previous BAFilter stage,
				-- the various timestamp maps were updated and one was selected for reading, based on
				-- which we now do the actual background activity filtering.
				BAFilterOutValidReg_S <= '0';
			end if;
		end process baFilter2;

		TSMap0 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap0Address_D,
				Enable_SI         => TimestampMap0En_S,
				WriteEnable_SI    => TimestampMap0WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap0_DN),
				unsigned(Data_DO) => TimestampMap0_DP);

		TSMap1 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap1Address_D,
				Enable_SI         => TimestampMap1En_S,
				WriteEnable_SI    => TimestampMap1WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap1_DN),
				unsigned(Data_DO) => TimestampMap1_DP);

		TSMap2 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap2Address_D,
				Enable_SI         => TimestampMap2En_S,
				WriteEnable_SI    => TimestampMap2WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap2_DN),
				unsigned(Data_DO) => TimestampMap2_DP);

		TSMap3 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap3Address_D,
				Enable_SI         => TimestampMap3En_S,
				WriteEnable_SI    => TimestampMap3WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap3_DN),
				unsigned(Data_DO) => TimestampMap3_DP);

		TSMap4 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap4Address_D,
				Enable_SI         => TimestampMap4En_S,
				WriteEnable_SI    => TimestampMap4WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap4_DN),
				unsigned(Data_DO) => TimestampMap4_DP);

		TSMap5 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap5Address_D,
				Enable_SI         => TimestampMap5En_S,
				WriteEnable_SI    => TimestampMap5WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap5_DN),
				unsigned(Data_DO) => TimestampMap5_DP);

		TSMap6 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap6Address_D,
				Enable_SI         => TimestampMap6En_S,
				WriteEnable_SI    => TimestampMap6WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap6_DN),
				unsigned(Data_DO) => TimestampMap6_DP);

		TSMap7 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap7Address_D,
				Enable_SI         => TimestampMap7En_S,
				WriteEnable_SI    => TimestampMap7WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap7_DN),
				unsigned(Data_DO) => TimestampMap7_DP);

		TSMap8 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap8Address_D,
				Enable_SI         => TimestampMap8En_S,
				WriteEnable_SI    => TimestampMap8WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap8_DN),
				unsigned(Data_DO) => TimestampMap8_DP);

		TSMap9 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap9Address_D,
				Enable_SI         => TimestampMap9En_S,
				WriteEnable_SI    => TimestampMap9WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap9_DN),
				unsigned(Data_DO) => TimestampMap9_DP);

		TSMap10 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap10Address_D,
				Enable_SI         => TimestampMap10En_S,
				WriteEnable_SI    => TimestampMap10WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap10_DN),
				unsigned(Data_DO) => TimestampMap10_DP);

		TSMap11 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap11Address_D,
				Enable_SI         => TimestampMap11En_S,
				WriteEnable_SI    => TimestampMap11WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap11_DN),
				unsigned(Data_DO) => TimestampMap11_DP);

		TSMap12 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap12Address_D,
				Enable_SI         => TimestampMap12En_S,
				WriteEnable_SI    => TimestampMap12WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap12_DN),
				unsigned(Data_DO) => TimestampMap12_DP);

		TSMap13 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap13Address_D,
				Enable_SI         => TimestampMap13En_S,
				WriteEnable_SI    => TimestampMap13WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap13_DN),
				unsigned(Data_DO) => TimestampMap13_DP);

		TSMap14 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap14Address_D,
				Enable_SI         => TimestampMap14En_S,
				WriteEnable_SI    => TimestampMap14WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap14_DN),
				unsigned(Data_DO) => TimestampMap14_DP);

		TSMap15 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap15Address_D,
				Enable_SI         => TimestampMap15En_S,
				WriteEnable_SI    => TimestampMap15WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap15_DN),
				unsigned(Data_DO) => TimestampMap15_DP);

		TSMapAddress : entity work.SimpleRegister
			generic map(
				SIZE => BA_ADDRESS_WIDTH)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(TimestampMapAddress_DN),
				unsigned(Output_SO) => TimestampMapAddress_DP);

		TSMapAddressLeft : entity work.SimpleRegister
			generic map(
				SIZE => BA_ADDRESS_WIDTH)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(TimestampMapAddressLeft_DN),
				unsigned(Output_SO) => TimestampMapAddressLeft_DP);

		TSMapAddressRight : entity work.SimpleRegister
			generic map(
				SIZE => BA_ADDRESS_WIDTH)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(TimestampMapAddressRight_DN),
				unsigned(Output_SO) => TimestampMapAddressRight_DP);

		TSMapAddressDown : entity work.SimpleRegister
			generic map(
				SIZE => BA_ADDRESS_WIDTH)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(TimestampMapAddressDown_DN),
				unsigned(Output_SO) => TimestampMapAddressDown_DP);

		TSMapAddressDownLeft : entity work.SimpleRegister
			generic map(
				SIZE => BA_ADDRESS_WIDTH)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(TimestampMapAddressDownLeft_DN),
				unsigned(Output_SO) => TimestampMapAddressDownLeft_DP);

		TSMapAddressDownRight : entity work.SimpleRegister
			generic map(
				SIZE => BA_ADDRESS_WIDTH)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(TimestampMapAddressDownRight_DN),
				unsigned(Output_SO) => TimestampMapAddressDownRight_DP);

		TSMapAddressUp : entity work.SimpleRegister
			generic map(
				SIZE => BA_ADDRESS_WIDTH)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(TimestampMapAddressUp_DN),
				unsigned(Output_SO) => TimestampMapAddressUp_DP);

		TSMapAddressUpLeft : entity work.SimpleRegister
			generic map(
				SIZE => BA_ADDRESS_WIDTH)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(TimestampMapAddressUpLeft_DN),
				unsigned(Output_SO) => TimestampMapAddressUpLeft_DP);

		TSMapAddressUpRight : entity work.SimpleRegister
			generic map(
				SIZE => BA_ADDRESS_WIDTH)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(TimestampMapAddressUpRight_DN),
				unsigned(Output_SO) => TimestampMapAddressUpRight_DP);

		baFilterTSTick : entity work.ContinuousCounter
			generic map(
				SIZE => TS_TICK_SIZE)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Clear_SI     => not DVSAERConfigReg_D.Run_S,
				Enable_SI    => '1',
				DataLimit_DI => to_unsigned(TS_TICK, TS_TICK_SIZE),
				Overflow_SO  => TimestampTick_S,
				Data_DO      => open);

		baFilterTSCounter : entity work.ContinuousCounter
			generic map(
				SIZE              => BA_TIMESTAMP_WIDTH,
				GENERATE_OVERFLOW => false)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Clear_SI     => not DVSAERConfigReg_D.Run_S,
				Enable_SI    => TimestampTick_S,
				DataLimit_DI => (others => '1'),
				Overflow_SO  => open,
				Data_DO      => Timestamp_D);

		baFilterTSBuffer : entity work.SimpleRegister
			generic map(
				SIZE => BA_TIMESTAMP_WIDTH)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(Timestamp_D),
				unsigned(Output_SO) => TimestampBuffer_D);

		baFilterLastRowAddress0Register : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_DATA_WIDTH_MAX)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(LastRowAddress0_DN),
				unsigned(Output_SO) => LastRowAddress0_DP);

		baFilterLastRowAddress1Register : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_DATA_WIDTH_MAX)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(LastRowAddress1_DN),
				unsigned(Output_SO) => LastRowAddress1_DP);
	end generate baFilterSupport;
end Behavioral;
