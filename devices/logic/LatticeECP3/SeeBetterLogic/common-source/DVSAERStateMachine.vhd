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
use work.Settings.CHIP_DVS_SIZE_ROWS;
use work.Settings.CHIP_DVS_SIZE_COLUMNS;
use work.Settings.LOGIC_CLOCK_FREQ;
use work.Settings.DEVICE_FAMILY;

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
		constant BA_ADDRESS_SUBSAMPLE_BY : integer := 3;
		constant BA_COLUMN_ADDRESS_WIDTH : integer := DVS_COLUMN_ADDRESS_WIDTH - BA_ADDRESS_SUBSAMPLE_BY;
		constant BA_ROW_ADDRESS_WIDTH    : integer := DVS_ROW_ADDRESS_WIDTH - BA_ADDRESS_SUBSAMPLE_BY;
		constant BA_COLUMN_CELL_NUMBER   : integer := integer(ceil(real(to_integer(CHIP_DVS_SIZE_COLUMNS)) / (2 ** real(BA_ADDRESS_SUBSAMPLE_BY))));
		constant BA_ROW_CELL_NUMBER      : integer := integer(ceil(real(to_integer(CHIP_DVS_SIZE_ROWS)) / (2 ** real(BA_ADDRESS_SUBSAMPLE_BY))));
		constant BA_COLUMN_CELL_ADDRESS  : integer := integer(ceil(real(BA_COLUMN_CELL_NUMBER) / 4.0));
		constant BA_ROW_CELL_ADDRESS     : integer := integer(ceil(real(BA_ROW_CELL_NUMBER) / 4.0));
		constant BA_ADDRESS_DEPTH        : integer := BA_COLUMN_CELL_ADDRESS * BA_ROW_CELL_ADDRESS;
		constant BA_ADDRESS_WIDTH        : integer := integer(ceil(log2(real(BA_ADDRESS_DEPTH))));

		signal TimestampMap0_DP, TimestampMap0_DN   : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap1_DP, TimestampMap1_DN   : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap2_DP, TimestampMap2_DN   : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap3_DP, TimestampMap3_DN   : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap4_DP, TimestampMap4_DN   : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap5_DP, TimestampMap5_DN   : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap6_DP, TimestampMap6_DN   : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap7_DP, TimestampMap7_DN   : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap8_DP, TimestampMap8_DN   : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap9_DP, TimestampMap9_DN   : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap10_DP, TimestampMap10_DN : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap11_DP, TimestampMap11_DN : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap12_DP, TimestampMap12_DN : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap13_DP, TimestampMap13_DN : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap14_DP, TimestampMap14_DN : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampMap15_DP, TimestampMap15_DN : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);

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

		signal TimestampMap0En_S  : std_logic;
		signal TimestampMap1En_S  : std_logic;
		signal TimestampMap2En_S  : std_logic;
		signal TimestampMap3En_S  : std_logic;
		signal TimestampMap4En_S  : std_logic;
		signal TimestampMap5En_S  : std_logic;
		signal TimestampMap6En_S  : std_logic;
		signal TimestampMap7En_S  : std_logic;
		signal TimestampMap8En_S  : std_logic;
		signal TimestampMap9En_S  : std_logic;
		signal TimestampMap10En_S : std_logic;
		signal TimestampMap11En_S : std_logic;
		signal TimestampMap12En_S : std_logic;
		signal TimestampMap13En_S : std_logic;
		signal TimestampMap14En_S : std_logic;
		signal TimestampMap15En_S : std_logic;

		signal TimestampMap0WrEn_S  : std_logic;
		signal TimestampMap1WrEn_S  : std_logic;
		signal TimestampMap2WrEn_S  : std_logic;
		signal TimestampMap3WrEn_S  : std_logic;
		signal TimestampMap4WrEn_S  : std_logic;
		signal TimestampMap5WrEn_S  : std_logic;
		signal TimestampMap6WrEn_S  : std_logic;
		signal TimestampMap7WrEn_S  : std_logic;
		signal TimestampMap8WrEn_S  : std_logic;
		signal TimestampMap9WrEn_S  : std_logic;
		signal TimestampMap10WrEn_S : std_logic;
		signal TimestampMap11WrEn_S : std_logic;
		signal TimestampMap12WrEn_S : std_logic;
		signal TimestampMap13WrEn_S : std_logic;
		signal TimestampMap14WrEn_S : std_logic;
		signal TimestampMap15WrEn_S : std_logic;

		constant TS_TICK      : integer := LOGIC_CLOCK_FREQ;
		constant TS_TICK_SIZE : integer := integer(ceil(log2(real(TS_TICK + 1))));

		signal Timestamp_D       : unsigned(DVS_FILTER_BA_DELTAT_WIDTH - 1 downto 0);
		signal TimestampEnable_S : std_logic;

		signal LastRowAddress_DP, LastRowAddress_DN : unsigned(EVENT_DATA_WIDTH_MAX - 1 downto 0);

		function BooleanToStdLogic(BOOL : boolean) return std_logic is
		begin
			if BOOL then
				return '1';
			else
				return '0';
			end if;
		end function BooleanToStdLogic;
	begin
		baFilter : process(BAFilterInDataReg_D, BAFilterInValidReg_S, LastRowAddress_DP, Timestamp_D)
			variable ColumnAddress_D : unsigned(BA_COLUMN_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
			variable RowAddress_D    : unsigned(BA_ROW_ADDRESS_WIDTH - 1 downto 0)    := (others => '0');

			variable ColumnAddressLeft_D  : unsigned(BA_COLUMN_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
			variable RowAddressLeft_D     : unsigned(BA_ROW_ADDRESS_WIDTH - 1 downto 0)    := (others => '0');
			variable ColumnAddressDown_D  : unsigned(BA_COLUMN_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
			variable RowAddressDown_D     : unsigned(BA_ROW_ADDRESS_WIDTH - 1 downto 0)    := (others => '0');
			variable ColumnAddressRight_D : unsigned(BA_COLUMN_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
			variable RowAddressRight_D    : unsigned(BA_ROW_ADDRESS_WIDTH - 1 downto 0)    := (others => '0');
			variable ColumnAddressUp_D    : unsigned(BA_COLUMN_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
			variable RowAddressUp_D       : unsigned(BA_ROW_ADDRESS_WIDTH - 1 downto 0)    := (others => '0');

			variable ColumnAddressLeftDown_D  : unsigned(BA_COLUMN_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
			variable RowAddressLeftDown_D     : unsigned(BA_ROW_ADDRESS_WIDTH - 1 downto 0)    := (others => '0');
			variable ColumnAddressRightDown_D : unsigned(BA_COLUMN_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
			variable RowAddressRightDown_D    : unsigned(BA_ROW_ADDRESS_WIDTH - 1 downto 0)    := (others => '0');
			variable ColumnAddressRightUp_D   : unsigned(BA_COLUMN_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
			variable RowAddressRightUp_D      : unsigned(BA_ROW_ADDRESS_WIDTH - 1 downto 0)    := (others => '0');
			variable ColumnAddressLeftUp_D    : unsigned(BA_COLUMN_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
			variable RowAddressLeftUp_D       : unsigned(BA_ROW_ADDRESS_WIDTH - 1 downto 0)    := (others => '0');

			variable BorderLeft_S  : std_logic := '0';
			variable BorderDown_S  : std_logic := '0';
			variable BorderRight_S : std_logic := '0';
			variable BorderUp_S    : std_logic := '0';

			variable Column0_S : std_logic := '0';
			variable Column1_S : std_logic := '0';
			variable Column2_S : std_logic := '0';
			variable Column3_S : std_logic := '0';

			variable Row0_S : std_logic := '0';
			variable Row1_S : std_logic := '0';
			variable Row2_S : std_logic := '0';
			variable Row3_S : std_logic := '0';

			variable Column0Active_S : std_logic := '0';
			variable Column1Active_S : std_logic := '0';
			variable Column2Active_S : std_logic := '0';
			variable Column3Active_S : std_logic := '0';

			variable Row0Active_S : std_logic := '0';
			variable Row1Active_S : std_logic := '0';
			variable Row2Active_S : std_logic := '0';
			variable Row3Active_S : std_logic := '0';
		begin
			BAFilterOutDataReg_D  <= BAFilterInDataReg_D;
			BAFilterOutValidReg_S <= BAFilterInValidReg_S;

			LastRowAddress_DN <= LastRowAddress_DP;

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

			if BAFilterInValidReg_S = '1' then
				if BAFilterInDataReg_D(EVENT_WIDTH - 2) = '0' then
					-- This is a row address, we just save it.
					LastRowAddress_DN <= unsigned(BAFilterInDataReg_D(EVENT_DATA_WIDTH_MAX - 1 downto 0));
				else
					-- This is a column address, let's determine all valid RAM parameters.
					-- The address is downsampled here, right at the start.
					ColumnAddress_D := unsigned(BAFilterInDataReg_D(DVS_COLUMN_ADDRESS_WIDTH - 1 downto BA_ADDRESS_SUBSAMPLE_BY));
					RowAddress_D    := LastRowAddress_DP(DVS_ROW_ADDRESS_WIDTH - 1 downto BA_ADDRESS_SUBSAMPLE_BY);

					ColumnAddressLeft_D  := ColumnAddress_D - 1;
					RowAddressLeft_D     := RowAddress_D;
					ColumnAddressDown_D  := ColumnAddress_D;
					RowAddressDown_D     := RowAddress_D - 1;
					ColumnAddressRight_D := ColumnAddress_D + 1;
					RowAddressRight_D    := RowAddress_D;
					ColumnAddressUp_D    := ColumnAddress_D;
					RowAddressUp_D       := RowAddress_D + 1;

					ColumnAddressLeftDown_D  := ColumnAddress_D - 1;
					RowAddressLeftDown_D     := RowAddress_D - 1;
					ColumnAddressRightDown_D := ColumnAddress_D + 1;
					RowAddressRightDown_D    := RowAddress_D - 1;
					ColumnAddressRightUp_D   := ColumnAddress_D + 1;
					RowAddressRightUp_D      := RowAddress_D + 1;
					ColumnAddressLeftUp_D    := ColumnAddress_D - 1;
					RowAddressLeftUp_D       := RowAddress_D + 1;

					BorderLeft_S  := BooleanToStdLogic(ColumnAddress_D = 0);
					BorderDown_S  := BooleanToStdLogic(RowAddress_D = 0);
					BorderRight_S := BooleanToStdLogic(ColumnAddress_D = (BA_COLUMN_CELL_NUMBER - 1));
					BorderUp_S    := BooleanToStdLogic(RowAddress_D = (BA_ROW_CELL_NUMBER - 1));

					Column0_S := BooleanToStdLogic(ColumnAddress_D(1 downto 0) = "00");
					Column1_S := BooleanToStdLogic(ColumnAddress_D(1 downto 0) = "01");
					Column2_S := BooleanToStdLogic(ColumnAddress_D(1 downto 0) = "10");
					Column3_S := BooleanToStdLogic(ColumnAddress_D(1 downto 0) = "11");

					Row0_S := BooleanToStdLogic(RowAddress_D(1 downto 0) = "00");
					Row1_S := BooleanToStdLogic(RowAddress_D(1 downto 0) = "01");
					Row2_S := BooleanToStdLogic(RowAddress_D(1 downto 0) = "10");
					Row3_S := BooleanToStdLogic(RowAddress_D(1 downto 0) = "11");

					Column0Active_S := Column0_S or (Column1_S and not BorderLeft_S) or (Column3_S and not BorderRight_S);
					Column1Active_S := Column1_S or (Column2_S and not BorderLeft_S) or (Column0_S and not BorderRight_S);
					Column2Active_S := Column2_S or (Column3_S and not BorderLeft_S) or (Column1_S and not BorderRight_S);
					Column3Active_S := Column3_S or (Column0_S and not BorderLeft_S) or (Column2_S and not BorderRight_S);

					Row0Active_S := Row0_S or (Row1_S and not BorderDown_S) or (Row3_S and not BorderUp_S);
					Row1Active_S := Row1_S or (Row2_S and not BorderDown_S) or (Row0_S and not BorderUp_S);
					Row2Active_S := Row2_S or (Row3_S and not BorderDown_S) or (Row1_S and not BorderUp_S);
					Row3Active_S := Row3_S or (Row0_S and not BorderDown_S) or (Row2_S and not BorderUp_S);

					TimestampMap0En_S  <= Column0Active_S and Row0Active_S;
					TimestampMap1En_S  <= Column1Active_S and Row0Active_S;
					TimestampMap2En_S  <= Column2Active_S and Row0Active_S;
					TimestampMap3En_S  <= Column3Active_S and Row0Active_S;
					TimestampMap4En_S  <= Column0Active_S and Row1Active_S;
					TimestampMap5En_S  <= Column1Active_S and Row1Active_S;
					TimestampMap6En_S  <= Column2Active_S and Row1Active_S;
					TimestampMap7En_S  <= Column3Active_S and Row1Active_S;
					TimestampMap8En_S  <= Column0Active_S and Row2Active_S;
					TimestampMap9En_S  <= Column1Active_S and Row2Active_S;
					TimestampMap10En_S <= Column2Active_S and Row2Active_S;
					TimestampMap11En_S <= Column3Active_S and Row2Active_S;
					TimestampMap12En_S <= Column0Active_S and Row3Active_S;
					TimestampMap13En_S <= Column1Active_S and Row3Active_S;
					TimestampMap14En_S <= Column2Active_S and Row3Active_S;
					TimestampMap15En_S <= Column3Active_S and Row3Active_S;

					TimestampMap0WrEn_S  <= Column0_S nand Row0_S;
					TimestampMap1WrEn_S  <= Column1_S nand Row0_S;
					TimestampMap2WrEn_S  <= Column2_S nand Row0_S;
					TimestampMap3WrEn_S  <= Column3_S nand Row0_S;
					TimestampMap4WrEn_S  <= Column0_S nand Row1_S;
					TimestampMap5WrEn_S  <= Column1_S nand Row1_S;
					TimestampMap6WrEn_S  <= Column2_S nand Row1_S;
					TimestampMap7WrEn_S  <= Column3_S nand Row1_S;
					TimestampMap8WrEn_S  <= Column0_S nand Row2_S;
					TimestampMap9WrEn_S  <= Column1_S nand Row2_S;
					TimestampMap10WrEn_S <= Column2_S nand Row2_S;
					TimestampMap11WrEn_S <= Column3_S nand Row2_S;
					TimestampMap12WrEn_S <= Column0_S nand Row3_S;
					TimestampMap13WrEn_S <= Column1_S nand Row3_S;
					TimestampMap14WrEn_S <= Column2_S nand Row3_S;
					TimestampMap15WrEn_S <= Column3_S nand Row3_S;

					if Column0_S = '1' then
						if Row0_S = '1' then
						-- Left/Down Corner
						elsif Row3_S = '1' then
						-- Left/Up Corner
						else            -- Rows 1/2
						-- Left Border
						end if;
					elsif Column3_S = '1' then
						if Row0_S = '1' then
						-- Right/Down Corner
						elsif Row3_S = '1' then
						-- Right/Up Corner
						else            -- Rows 1/2
						-- Right Border
						end if;
					else                -- Columns 1/2
						if Row0_S = '1' then
						-- Down Border
						elsif Row3_S = '1' then
						-- Up Border
						else            -- Rows 1/2
							-- Normal
							TimestampMap0Address_D  <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap1Address_D  <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap2Address_D  <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap3Address_D  <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap4Address_D  <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap5Address_D  <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap6Address_D  <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap7Address_D  <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap8Address_D  <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap9Address_D  <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap10Address_D <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap11Address_D <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap12Address_D <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap13Address_D <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap14Address_D <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
							TimestampMap15Address_D <= RowAddress_D(BA_ROW_ADDRESS_WIDTH - 1 downto 2) & ColumnAddress_D(BA_COLUMN_ADDRESS_WIDTH - 1 downto 2);
						end if;
					end if;
				end if;
			end if;
		end process baFilter;

		TSMap0 : entity work.BlockRAM
			generic map(
				ADDRESS_DEPTH => BA_ADDRESS_DEPTH,
				ADDRESS_WIDTH => BA_ADDRESS_WIDTH,
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
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
				DATA_WIDTH    => DVS_FILTER_BA_DELTAT_WIDTH)
			port map(
				Clock_CI          => Clock_CI,
				Reset_RI          => Reset_RI,
				Address_DI        => TimestampMap15Address_D,
				Enable_SI         => TimestampMap15En_S,
				WriteEnable_SI    => TimestampMap15WrEn_S,
				Data_DI           => std_logic_vector(TimestampMap15_DN),
				unsigned(Data_DO) => TimestampMap15_DP);

		baFilterTSCounter : entity work.ContinuousCounter
			generic map(
				SIZE              => DVS_FILTER_BA_DELTAT_WIDTH,
				RESET_ON_OVERFLOW => true,
				GENERATE_OVERFLOW => false)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Clear_SI     => not DVSAERConfigReg_D.Run_S,
				Enable_SI    => TimestampEnable_S,
				DataLimit_DI => (others => '1'),
				Overflow_SO  => open,
				Data_DO      => Timestamp_D);

		baFilterTSTick : entity work.ContinuousCounter
			generic map(
				SIZE              => TS_TICK_SIZE,
				RESET_ON_OVERFLOW => true,
				GENERATE_OVERFLOW => true)
			port map(
				Clock_CI     => Clock_CI,
				Reset_RI     => Reset_RI,
				Clear_SI     => not DVSAERConfigReg_D.Run_S,
				Enable_SI    => '1',
				DataLimit_DI => to_unsigned(TS_TICK, TS_TICK_SIZE),
				Overflow_SO  => TimestampEnable_S,
				Data_DO      => open);

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
