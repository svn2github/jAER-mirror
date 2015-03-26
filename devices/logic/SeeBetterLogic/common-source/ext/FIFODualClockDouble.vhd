library ieee;
use ieee.std_logic_1164.all;
use work.Settings.DEVICE_FAMILY;
use work.FIFORecords.all;

entity FIFODualClockDouble is
	generic(
		DATA_WIDTH        : integer;    -- This is OUTPUT data width.
		DATA_DEPTH        : integer;    -- This is OUTPUT data depth.
		ALMOST_EMPTY_FLAG : integer;
		ALMOST_FULL_FLAG  : integer;
		MEMORY            : string := "EBR");
	port(
		Reset_RI       : in  std_logic;
		WrClock_CI     : in  std_logic;
		RdClock_CI     : in  std_logic;
		FifoControl_SI : in  tToFifo;
		FifoControl_SO : out tFromFifo;
		FifoData_DI    : in  std_logic_vector((DATA_WIDTH / 2) - 1 downto 0);
		FifoData_DO    : out std_logic_vector(DATA_WIDTH - 1 downto 0));
end entity FIFODualClockDouble;

architecture Structural of FIFODualClockDouble is
	constant DATA_WIDTH_IN : integer := DATA_WIDTH / 2;
	constant DATA_DEPTH_IN : integer := DATA_DEPTH * 2;

	attribute syn_enum_encoding : string;

	type tState is (stInit, stGetData, stWaitRead);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : tState;

	signal DataInReg_D       : std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal DataInRegEnable_S : std_logic;

	signal EmptyReg_S       : std_logic;
	signal AlmostEmptyReg_S : std_logic;

	signal FIFOEmpty_S, FIFOAlmostEmpty_S, FIFORead_S : std_logic;
begin
	-- Use double-clock FIFO from the Lattice Portable Module Interfaces.
	-- This is a more portable variation than what you'd get with the other tools,
	-- but slightly less configurable. It has everything we need though, and allows
	-- for easy switching between underlying hardware implementations and tuning.
	pmiFifoDC : if DEVICE_FAMILY /= "ECP3" generate
		fifoDualClock : component work.pmi_components.pmi_fifo_dc
			generic map(
				pmi_data_width_w      => DATA_WIDTH_IN,
				pmi_data_width_r      => DATA_WIDTH,
				pmi_data_depth_w      => DATA_DEPTH_IN,
				pmi_data_depth_r      => DATA_DEPTH,
				pmi_full_flag         => DATA_DEPTH_IN,
				pmi_empty_flag        => 0,
				pmi_almost_full_flag  => DATA_DEPTH_IN - ALMOST_FULL_FLAG,
				pmi_almost_empty_flag => ALMOST_EMPTY_FLAG,
				pmi_regmode           => "noreg",
				pmi_resetmode         => "async",
				pmi_family            => DEVICE_FAMILY,
				pmi_implementation    => MEMORY)
			port map(
				Data        => FifoData_DI,
				WrClock     => WrClock_CI,
				RdClock     => RdClock_CI,
				WrEn        => FifoControl_SI.WriteSide.Write_S,
				RdEn        => FIFORead_S,
				Reset       => Reset_RI,
				RPReset     => Reset_RI,
				Q           => DataInReg_D,
				Empty       => FIFOEmpty_S,
				Full        => FifoControl_SO.WriteSide.Full_S,
				AlmostEmpty => FIFOAlmostEmpty_S,
				AlmostFull  => FifoControl_SO.WriteSide.AlmostFull_S);
	end generate pmiFifoDC;

	ipExpressFifoDC : if DEVICE_FAMILY = "ECP3" generate
		assert (DATA_WIDTH = 32) report "FIFODualClockDouble on ECP3 is hard-coded to 32bit data width." severity FAILURE;
		assert (DATA_DEPTH = 512) report "FIFODualClockDouble on ECP3 is hard-coded to 512 elements data depth." severity FAILURE;
		assert (ALMOST_EMPTY_FLAG = 8) report "FIFODualClockDouble on ECP3 is hard-coded to 8 elements for the almost empty flag." severity FAILURE;
		assert (ALMOST_FULL_FLAG = 2) report "FIFODualClockDouble on ECP3 is hard-coded to 2 elements for the almost full flag." severity FAILURE;

		fifoDualClock : entity work.FIFODualClockDoubleECP3
			port map(
				Data        => FifoData_DI,
				WrClock     => WrClock_CI,
				RdClock     => RdClock_CI,
				WrEn        => FifoControl_SI.WriteSide.Write_S,
				RdEn        => FIFORead_S,
				Reset       => Reset_RI,
				RPReset     => Reset_RI,
				Q           => DataInReg_D,
				Empty       => FIFOEmpty_S,
				Full        => FifoControl_SO.WriteSide.Full_S,
				AlmostEmpty => FIFOAlmostEmpty_S,
				AlmostFull  => FifoControl_SO.WriteSide.AlmostFull_S);
	end generate ipExpressFifoDC;

	readSideOutputsRegisteringLogic : process(State_DP, FIFOEmpty_S, FIFOAlmostEmpty_S, FifoControl_SI)
	begin
		State_DN <= State_DP;

		EmptyReg_S       <= '1';
		AlmostEmptyReg_S <= '1';

		DataInRegEnable_S <= '0';
		FIFORead_S        <= '0';

		case State_DP is
			when stInit =>
				if FIFOEmpty_S = '0' then
					FIFORead_S       <= '1';
					EmptyReg_S       <= '0';
					AlmostEmptyReg_S <= FIFOAlmostEmpty_S;
					State_DN         <= stGetData;
				end if;

			when stGetData =>
				DataInRegEnable_S <= '1';

				if FifoControl_SI.ReadSide.Read_S = '1' then
					if FIFOEmpty_S = '0' then
						FIFORead_S       <= '1';
						EmptyReg_S       <= '0';
						AlmostEmptyReg_S <= FIFOAlmostEmpty_S;
					else
						State_DN <= stInit;
					end if;
				else
					EmptyReg_S       <= '0';
					AlmostEmptyReg_S <= FIFOAlmostEmpty_S;
					State_DN         <= stWaitRead;
				end if;

			when stWaitRead =>
				if FifoControl_SI.ReadSide.Read_S = '1' then
					if FIFOEmpty_S = '0' then
						FIFORead_S       <= '1';
						EmptyReg_S       <= '0';
						AlmostEmptyReg_S <= FIFOAlmostEmpty_S;
						State_DN         <= stGetData;
					else
						State_DN <= stInit;
					end if;
				else
					EmptyReg_S       <= '0';
					AlmostEmptyReg_S <= FIFOAlmostEmpty_S;
				end if;

			when others => null;
		end case;
	end process readSideOutputsRegisteringLogic;

	registerUpdate : process(RdClock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			State_DP <= stInit;

			FifoControl_SO.ReadSide.Empty_S       <= '1';
			FifoControl_SO.ReadSide.AlmostEmpty_S <= '1';

			FifoData_DO <= (others => '0');
		elsif rising_edge(RdClock_CI) then -- rising clock edge
			State_DP <= State_DN;

			FifoControl_SO.ReadSide.Empty_S       <= EmptyReg_S;
			FifoControl_SO.ReadSide.AlmostEmpty_S <= AlmostEmptyReg_S;

			if DataInRegEnable_S = '1' then
				FifoData_DO <= DataInReg_D;
			end if;
		end if;
	end process registerUpdate;
end architecture Structural;
