library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use work.EventCodes.all;
use work.Settings.CHIP_DVS_SIZE_ROWS;
use work.Settings.CHIP_DVS_SIZE_COLUMNS;
use work.Settings.CHIP_DVS_AXES_INVERT;
use work.ChipGeometry.AXES_KEEP;
use work.FIFORecords.all;

entity DVSSerialToParallel is
	port(
		Clock_CI                  : in  std_logic;
		Reset_RI                  : in  std_logic;

		-- Parallel output, derived from serialized input.
		DVSAERParallelValid_SO    : out std_logic;
		DVSAERParallelColumn_DO   : out unsigned(EVENT_DATA_WIDTH_MAX - 1 downto 0);
		DVSAERParallelRow_DO      : out unsigned(EVENT_DATA_WIDTH_MAX - 1 downto 0);
		DVSAERParallelPolarity_SO : out std_logic;

		-- Fifo input (from DVS AER)
		DVSAERFifoControl_SI      : in  tFromFifoReadSide;
		DVSAERFifoControl_SO      : out tToFifoReadSide;
		DVSAERFifoData_DI         : in  std_logic_vector(EVENT_WIDTH - 1 downto 0));
end entity DVSSerialToParallel;

architecture Behavioral of DVSSerialToParallel is
	attribute syn_enum_encoding : string;

	type tState is (stIdle, stReadOut);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- Bits needed for each address.
	constant DVS_ROW_ADDRESS_WIDTH    : integer := integer(ceil(log2(real(to_integer(CHIP_DVS_SIZE_ROWS)))));
	constant DVS_COLUMN_ADDRESS_WIDTH : integer := integer(ceil(log2(real(to_integer(CHIP_DVS_SIZE_COLUMNS)))));

	signal State_DP, State_DN : tState;
	signal LastY_DP, LastY_DN : unsigned(DVS_ROW_ADDRESS_WIDTH - 1 downto 0);
begin                                   -- architecture Behavioral
	dvsSerialToParallel : process(State_DP, LastY_DP, DVSAERFifoControl_SI, DVSAERFifoData_DI)
	begin
		State_DN <= State_DP;           -- Keep state by default.
		LastY_DN <= LastY_DP;           -- Keep track of last Y address in serial protocol.

		DVSAERFifoControl_SO.Read_S <= '0';

		DVSAERParallelValid_SO    <= '0';
		DVSAERParallelColumn_DO   <= (others => '0');
		DVSAERParallelRow_DO      <= (others => '0');
		DVSAERParallelPolarity_SO <= '0';

		case State_DP is
			when stIdle =>
				if DVSAERFifoControl_SI.Empty_S = '0' then
					State_DN <= stReadOut;
				end if;

			when stReadOut =>
				if DVSAERFifoData_DI(EVENT_WIDTH - 1 downto EVENT_WIDTH - 3) = EVENT_CODE_Y_ADDR then
					LastY_DN <= unsigned(DVSAERFifoData_DI(DVS_ROW_ADDRESS_WIDTH - 1 downto 0));
				else
					-- Valid, X, Y, Polarity.
					DVSAERParallelValid_SO <= '1';
					if CHIP_DVS_AXES_INVERT = AXES_KEEP then
						DVSAERParallelColumn_DO(DVS_COLUMN_ADDRESS_WIDTH - 1 downto 0) <= unsigned(DVSAERFifoData_DI(DVS_COLUMN_ADDRESS_WIDTH - 1 downto 0));
						DVSAERParallelRow_DO(DVS_ROW_ADDRESS_WIDTH - 1 downto 0)       <= LastY_DP;
					else
						-- Invert X/Y on certain systems.
						DVSAERParallelRow_DO(DVS_COLUMN_ADDRESS_WIDTH - 1 downto 0) <= unsigned(DVSAERFifoData_DI(DVS_COLUMN_ADDRESS_WIDTH - 1 downto 0));
						DVSAERParallelColumn_DO(DVS_ROW_ADDRESS_WIDTH - 1 downto 0) <= LastY_DP;
					end if;
					DVSAERParallelPolarity_SO <= DVSAERFifoData_DI(12);
				end if;

				DVSAERFifoControl_SO.Read_S <= '1';

				State_DN <= stIdle;

			when others => null;
		end case;
	end process dvsSerialToParallel;

	dvsSerialToParallelRegUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then
			State_DP <= stIdle;
			LastY_DP <= (others => '0');
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;
			LastY_DP <= LastY_DN;
		end if;
	end process dvsSerialToParallelRegUpdate;
end architecture Behavioral;