library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.DVSAERConfigRecords.all;
use work.Settings.DVS_AER_BUS_WIDTH;
use work.Settings.CHIP_DVS_SIZE_ROWS;
use work.Settings.CHIP_DVS_SIZE_COLUMNS;

entity DVSAERStateMachine is
	generic(
		FLIP_ROW_ADDRESS                     : boolean := false;
		FLIP_COLUMN_ADDRESS                  : boolean := false;
		ENABLE_PIXEL_FILTERING               : boolean := false;
		ENABLE_BACKGROUND_ACTIVITY_FILTERING : boolean := false);
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
	signal AckCounter_DP, AckCounter_DN : unsigned(DVS_AER_ACK_COUNTER_WIDTH - 1 downto 0);

	-- Remember if what we're working on right now is an X or Y address.
	signal DVSIsRowAddress_SP, DVSIsRowAddress_SN : std_logic;

	-- Bits needed for each address.
	constant DVS_ROW_ADDRESS_WIDTH    : integer := integer(ceil(log2(real(to_integer(CHIP_DVS_SIZE_ROWS)))));
	constant DVS_COLUMN_ADDRESS_WIDTH : integer := integer(ceil(log2(real(to_integer(CHIP_DVS_SIZE_COLUMNS)))));

	-- Data incoming from DVS.
	signal DVSEventDataRegEnable_S : std_logic;
	signal DVSEventDataReg_D       : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal DVSEventValidReg_S      : std_logic;

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
begin
	dvsHandleAERComb : process(State_DP, OutFifoControl_SI, DVSAERReq_SBI, DVSAERData_DI, AckCounter_DP, DVSIsRowAddress_SP, DVSAERConfigReg_D)
	begin
		State_DN <= State_DP;           -- Keep current state by default.

		DVSIsRowAddress_SN <= DVSIsRowAddress_SP;

		DVSEventValidReg_S      <= '0';
		DVSEventDataRegEnable_S <= '0';
		DVSEventDataReg_D       <= (others => '0');

		DVSAERAckReg_SB   <= '1';       -- No AER ACK by default.
		DVSAERResetReg_SB <= '1';       -- Keep DVS out of reset by default, so we don't have to repeat this in every state.

		AckCounter_DN <= (others => '0');

		case State_DP is
			when stIdle =>
				-- Only exit idle state if DVS data producer is active.
				if DVSAERConfigReg_D.Run_S = '1' then
					if DVSAERReq_SBI = '0' then
						if OutFifoControl_SI.Full_S = '0' then
							-- Got a request on the AER bus, let's get the data.
							-- We do have space in the output FIFO for it.
							State_DN <= stDifferentiateRowCol;
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

			when stDifferentiateRowCol =>
				-- Get data and format it. AER(WIDTH-1) holds the axis.
				if DVSAERData_DI(DVS_AER_BUS_WIDTH - 1) = '0' then
					-- This is an Y address.
					DVSIsRowAddress_SN <= '1';
					State_DN           <= stAERHandleRow;
				else
					DVSIsRowAddress_SN <= '0';
					State_DN           <= stAERHandleCol;

					-- Let's see if the previously address was a row-address.
					-- If yes, we send it along on its path, since it has to be the valid row address
					-- for this column address. We only do this if row-only event filtering is enabled,
					-- since if not, row-addresses are sent right away.
					if DVSAERConfigReg_D.FilterRowOnlyEvents_S = '1' and DVSIsRowAddress_SP = '1' then
						DVSEventValidReg_S <= '1';
					end if;
				end if;

			when stAERHandleRow =>
				-- We might need to delay the ACK.
				if AckCounter_DP >= DVSAERConfigReg_D.AckDelayRow_D then
					-- Row address (Y).
					DVSEventDataReg_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_Y_ADDR;

					if FLIP_ROW_ADDRESS = true then
						DVSEventDataReg_D(DVS_ROW_ADDRESS_WIDTH - 1 downto 0) <= std_logic_vector(CHIP_DVS_SIZE_ROWS - 1 - unsigned(DVSAERData_DI(DVS_ROW_ADDRESS_WIDTH - 1 downto 0)));
					else
						DVSEventDataReg_D(DVS_ROW_ADDRESS_WIDTH - 1 downto 0) <= DVSAERData_DI(DVS_ROW_ADDRESS_WIDTH - 1 downto 0);
					end if;

					-- If we're not filtering row-only events, then we can just pass all row-events right away.
					if DVSAERConfigReg_D.FilterRowOnlyEvents_S = '0' then
						DVSEventValidReg_S <= '1';
					end if;

					DVSEventDataRegEnable_S <= '1';

					DVSAERAckReg_SB <= '0';
					State_DN        <= stAERAckRow;
				else
					AckCounter_DN <= AckCounter_DP + 1;
				end if;

			when stAERAckRow =>
				DVSAERAckReg_SB <= '0';

				if DVSAERReq_SBI = '1' then
					-- We might need to extend the ACK period.
					if AckCounter_DP >= DVSAERConfigReg_D.AckExtensionRow_D then
						DVSAERAckReg_SB <= '1';
						State_DN        <= stIdle;
					else
						AckCounter_DN <= AckCounter_DP + 1;
					end if;
				end if;

			when stAERHandleCol =>
				-- We might need to delay the ACK.
				if AckCounter_DP >= DVSAERConfigReg_D.AckDelayColumn_D then
					-- Column address (X).
					DVSEventDataReg_D(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) <= EVENT_CODE_X_ADDR & DVSAERData_DI(0);

					if FLIP_COLUMN_ADDRESS = true then
						DVSEventDataReg_D(DVS_COLUMN_ADDRESS_WIDTH - 1 downto 0) <= std_logic_vector(CHIP_DVS_SIZE_COLUMNS - 1 - unsigned(DVSAERData_DI(DVS_COLUMN_ADDRESS_WIDTH downto 1)));
					else
						DVSEventDataReg_D(DVS_COLUMN_ADDRESS_WIDTH - 1 downto 0) <= DVSAERData_DI(DVS_COLUMN_ADDRESS_WIDTH downto 1);
					end if;

					DVSEventValidReg_S <= '1';

					DVSEventDataRegEnable_S <= '1';

					DVSAERAckReg_SB <= '0';
					State_DN        <= stAERAckCol;
				else
					AckCounter_DN <= AckCounter_DP + 1;
				end if;

			when stAERAckCol =>
				DVSAERAckReg_SB <= '0';

				if DVSAERReq_SBI = '1' then
					-- We might need to extend the ACK period.
					if AckCounter_DP >= DVSAERConfigReg_D.AckExtensionColumn_D then
						DVSAERAckReg_SB <= '1';
						State_DN        <= stIdle;
					else
						AckCounter_DN <= AckCounter_DP + 1;
					end if;
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

			AckCounter_DP <= (others => '0');

			DVSAERAck_SBO   <= '1';
			DVSAERReset_SBO <= '0';

			DVSAERConfigReg_D <= tDVSAERConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			DVSIsRowAddress_SP <= DVSIsRowAddress_SN;

			AckCounter_DP <= AckCounter_DN;

			DVSAERAck_SBO   <= DVSAERAckReg_SB;
			DVSAERReset_SBO <= DVSAERResetReg_SB;

			DVSAERConfigReg_D <= DVSAERConfig_DI;
		end if;
	end process dvsHandleAERRegisterUpdate;

	dvsOnly : if ENABLE_PIXEL_FILTERING = false and ENABLE_BACKGROUND_ACTIVITY_FILTERING = false generate
	begin
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
	end generate dvsOnly;

	pixelFilteringOnly : if ENABLE_PIXEL_FILTERING = true and ENABLE_BACKGROUND_ACTIVITY_FILTERING = false generate
	begin
		dvsEventDataRegister : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_WIDTH)
			port map(
				Clock_CI  => Clock_CI,
				Reset_RI  => Reset_RI,
				Enable_SI => DVSEventDataRegEnable_S,
				Input_SI  => DVSEventDataReg_D,
				Output_SO => PixelFilterInDataReg_D);

		dvsEventValidRegister : entity work.SimpleRegister
			generic map(
				SIZE => 1)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => DVSEventValidReg_S,
				Output_SO(0) => PixelFilterInValidReg_S);

		pixelFilterDataRegister : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_WIDTH)
			port map(
				Clock_CI  => Clock_CI,
				Reset_RI  => Reset_RI,
				Enable_SI => '1',
				Input_SI  => PixelFilterOutDataReg_D,
				Output_SO => OutFifoData_DO);

		pixelFilterValidRegister : entity work.SimpleRegister
			generic map(
				SIZE => 1)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => PixelFilterOutValidReg_S,
				Output_SO(0) => OutFifoControl_SO.Write_S);
	end generate pixelFilteringOnly;

	baFilteringOnly : if ENABLE_PIXEL_FILTERING = false and ENABLE_BACKGROUND_ACTIVITY_FILTERING = true generate
	begin
		dvsEventDataRegister : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_WIDTH)
			port map(
				Clock_CI  => Clock_CI,
				Reset_RI  => Reset_RI,
				Enable_SI => DVSEventDataRegEnable_S,
				Input_SI  => DVSEventDataReg_D,
				Output_SO => BAFilterInDataReg_D);

		dvsEventValidRegister : entity work.SimpleRegister
			generic map(
				SIZE => 1)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => DVSEventValidReg_S,
				Output_SO(0) => BAFilterInValidReg_S);

		baFilterDataRegister : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_WIDTH)
			port map(
				Clock_CI  => Clock_CI,
				Reset_RI  => Reset_RI,
				Enable_SI => '1',
				Input_SI  => BAFilterOutDataReg_D,
				Output_SO => OutFifoData_DO);

		baFilterValidRegister : entity work.SimpleRegister
			generic map(
				SIZE => 1)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => BAFilterOutValidReg_S,
				Output_SO(0) => OutFifoControl_SO.Write_S);
	end generate baFilteringOnly;

	allFilters : if ENABLE_PIXEL_FILTERING = true and ENABLE_BACKGROUND_ACTIVITY_FILTERING = true generate
	begin
		dvsEventDataRegister : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_WIDTH)
			port map(
				Clock_CI  => Clock_CI,
				Reset_RI  => Reset_RI,
				Enable_SI => DVSEventDataRegEnable_S,
				Input_SI  => DVSEventDataReg_D,
				Output_SO => PixelFilterInDataReg_D);

		dvsEventValidRegister : entity work.SimpleRegister
			generic map(
				SIZE => 1)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => DVSEventValidReg_S,
				Output_SO(0) => PixelFilterInValidReg_S);

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
				Output_SO => OutFifoData_DO);

		baFilterValidRegister : entity work.SimpleRegister
			generic map(
				SIZE => 1)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Enable_SI    => '1',
				Input_SI(0)  => BAFilterOutValidReg_S,
				Output_SO(0) => OutFifoControl_SO.Write_S);
	end generate allFilters;

	pixelFilterSupport : if ENABLE_PIXEL_FILTERING = true generate
		signal LastRowAddress_DP, LastRowAddress_DN : unsigned(EVENT_DATA_WIDTH_MAX - 1 downto 0);
	begin
		pixelFilter : process(PixelFilterInDataReg_D, PixelFilterInValidReg_S, LastRowAddress_DP, DVSAERConfigReg_D)
			variable Pixel0Hit_S : boolean := false;
			variable Pixel1Hit_S : boolean := false;
			variable Pixel2Hit_S : boolean := false;
			variable Pixel3Hit_S : boolean := false;
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
					Pixel0Hit_S := LastRowAddress_DP = DVSAERConfigReg_D.FilterPixel0Row_D and unsigned(PixelFilterInDataReg_D(EVENT_DATA_WIDTH_MAX - 1 downto 0)) = DVSAERConfigReg_D.FilterPixel0Column_D;
					Pixel1Hit_S := LastRowAddress_DP = DVSAERConfigReg_D.FilterPixel1Row_D and unsigned(PixelFilterInDataReg_D(EVENT_DATA_WIDTH_MAX - 1 downto 0)) = DVSAERConfigReg_D.FilterPixel1Column_D;
					Pixel2Hit_S := LastRowAddress_DP = DVSAERConfigReg_D.FilterPixel2Row_D and unsigned(PixelFilterInDataReg_D(EVENT_DATA_WIDTH_MAX - 1 downto 0)) = DVSAERConfigReg_D.FilterPixel2Column_D;
					Pixel3Hit_S := LastRowAddress_DP = DVSAERConfigReg_D.FilterPixel3Row_D and unsigned(PixelFilterInDataReg_D(EVENT_DATA_WIDTH_MAX - 1 downto 0)) = DVSAERConfigReg_D.FilterPixel3Column_D;

					if Pixel0Hit_S or Pixel1Hit_S or Pixel2Hit_S or Pixel3Hit_S then
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

	baFilterSupport : if ENABLE_BACKGROUND_ACTIVITY_FILTERING = true generate
		type tTimestampMap is array (0 to 14, 0 to 11) of unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap_DP, TimestampMap_DN : tTimestampMap;

		signal Timestamp_D : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);

		signal LastRowAddress_DP, LastRowAddress_DN : unsigned(EVENT_DATA_WIDTH_MAX - 1 downto 0);
	begin
		baFilter : process(BAFilterInDataReg_D, BAFilterInValidReg_S, LastRowAddress_DP, TimestampMap_DP, Timestamp_D, DVSAERConfigReg_D)
			variable RowAddress_D    : integer := 0;
			variable ColumnAddress_D : integer := 0;
		begin
			BAFilterOutDataReg_D  <= BAFilterInDataReg_D;
			BAFilterOutValidReg_S <= BAFilterInValidReg_S;

			LastRowAddress_DN <= LastRowAddress_DP;
			TimestampMap_DN   <= TimestampMap_DP;

			if BAFilterInValidReg_S = '1' then
				if BAFilterInDataReg_D(EVENT_WIDTH - 2) = '0' then
					-- This is a row address, we just save it.
					LastRowAddress_DN <= unsigned(BAFilterInDataReg_D(EVENT_DATA_WIDTH_MAX - 1 downto 0));
				else
					-- This is a column address, check against previous value and filter if deltaT too big.
					RowAddress_D    := to_integer(LastRowAddress_DP(DVS_ROW_ADDRESS_WIDTH - 1 downto DVS_ROW_ADDRESS_WIDTH - 4));
					ColumnAddress_D := to_integer(unsigned(BAFilterInDataReg_D(DVS_COLUMN_ADDRESS_WIDTH - 1 downto DVS_COLUMN_ADDRESS_WIDTH - 4)));

					if (Timestamp_D - TimestampMap_DP(ColumnAddress_D, RowAddress_D)) >= DVSAERConfigReg_D.FilterBackgroundActivityDeltaTime_D then
						BAFilterOutValidReg_S <= '0';
					end if;

					-- Update all 8 neighbor cells with the new time.
					if ColumnAddress_D > 0 then
						TimestampMap_DN(ColumnAddress_D - 1, RowAddress_D) <= Timestamp_D;
					end if;
					if ColumnAddress_D < CHIP_DVS_SIZE_COLUMNS then
						TimestampMap_DN(ColumnAddress_D + 1, RowAddress_D) <= Timestamp_D;
					end if;

					if RowAddress_D > 0 then
						TimestampMap_DN(ColumnAddress_D, RowAddress_D - 1) <= Timestamp_D;
					end if;
					if RowAddress_D < CHIP_DVS_SIZE_ROWS then
						TimestampMap_DN(ColumnAddress_D, RowAddress_D + 1) <= Timestamp_D;
					end if;
				end if;
			end if;
		end process baFilter;

		baFilterTSMapUpdate : process(Clock_CI, Reset_RI) is
		begin
			if Reset_RI = '1' then
				TimestampMap_DP <= (others => (others => (others => '0')));
			elsif rising_edge(Clock_CI) then
				TimestampMap_DP <= TimestampMap_DN;
			end if;
		end process baFilterTSMapUpdate;

		baFilterTSCounter : entity work.ContinuousCounter
			generic map(
				SIZE              => DVS_FILTER_BA_DELTAT_WIDTH,
				RESET_ON_OVERFLOW => true,
				GENERATE_OVERFLOW => false)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Clear_SI     => not DVSAERConfigReg_D.Run_S,
				Enable_SI    => '1',
				DataLimit_DI => (others => '1'),
				Overflow_SO  => open,
				Data_DO      => Timestamp_D);

		baFilterLastRowAddressRegister : entity work.SimpleRegister
			generic map(
				SIZE => EVENT_DATA_WIDTH_MAX)
			port map(
				Clock_CI            => Clock_CI,
				Reset_RI            => Reset_RI,
				Enable_SI           => '1',
				Input_SI            => std_logic_vector(LastRowAddress_DN),
				unsigned(Output_SO) => LastRowAddress_DP);
	end generate baFilterSupport;
end Behavioral;
