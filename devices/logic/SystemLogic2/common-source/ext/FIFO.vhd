library ieee;
use ieee.std_logic_1164.all;
use work.Settings.DEVICE_FAMILY;
use work.FIFORecords.all;

entity FIFO is
	generic(
		DATA_WIDTH        : integer;
		DATA_DEPTH        : integer;
		ALMOST_EMPTY_FLAG : integer;
		ALMOST_FULL_FLAG  : integer;
		MEMORY            : string := "EBR");
	port(
		Clock_CI       : in  std_logic;
		Reset_RI       : in  std_logic;
		FifoControl_SI : in  tToFifo;
		FifoControl_SO : out tFromFifo;
		FifoData_DI    : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
		FifoData_DO    : out std_logic_vector(DATA_WIDTH - 1 downto 0));
end entity FIFO;

architecture Structural of FIFO is
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
	fifo : component work.pmi_components.pmi_fifo
		generic map(
			pmi_data_width        => DATA_WIDTH,
			pmi_data_depth        => DATA_DEPTH,
			pmi_full_flag         => DATA_DEPTH,
			pmi_empty_flag        => 0,
			pmi_almost_full_flag  => DATA_DEPTH - ALMOST_FULL_FLAG,
			pmi_almost_empty_flag => ALMOST_EMPTY_FLAG,
			pmi_regmode           => "noreg",
			pmi_family            => DEVICE_FAMILY,
			pmi_implementation    => MEMORY)
		port map(
			Data        => FifoData_DI,
			Clock       => Clock_CI,
			WrEn        => FifoControl_SI.WriteSide.Write_S,
			RdEn        => FIFORead_S,
			Reset       => Reset_RI,
			Q           => DataInReg_D,
			Empty       => FIFOEmpty_S,
			Full        => FifoControl_SO.WriteSide.Full_S,
			AlmostEmpty => FIFOAlmostEmpty_S,
			AlmostFull  => FifoControl_SO.WriteSide.AlmostFull_S);

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

	registerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			State_DP <= stInit;

			FifoControl_SO.ReadSide.Empty_S       <= '1';
			FifoControl_SO.ReadSide.AlmostEmpty_S <= '1';

			FifoData_DO <= (others => '0');
		elsif rising_edge(Clock_CI) then -- rising clock edge
			State_DP <= State_DN;

			FifoControl_SO.ReadSide.Empty_S       <= EmptyReg_S;
			FifoControl_SO.ReadSide.AlmostEmpty_S <= AlmostEmptyReg_S;

			if DataInRegEnable_S = '1' then
				FifoData_DO <= DataInReg_D;
			end if;
		end if;
	end process registerUpdate;
end architecture Structural;
