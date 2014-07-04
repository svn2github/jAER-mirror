library ieee;
use ieee.std_logic_1164.all;
use work.Settings.all;
use work.FIFORecords.all;

entity FIFO is
	generic (
		DATA_WIDTH		  : integer := 16;
		DATA_DEPTH		  : integer := 64;
		EMPTY_FLAG		  : integer := 0;
		ALMOST_EMPTY_FLAG : integer := 4;
		FULL_FLAG		  : integer := 64;
		ALMOST_FULL_FLAG  : integer := 60);
	port (
		Clock_CI : in  std_logic;
		Reset_RI : in  std_logic;
		Fifo_I	 : in  tToFifo(WriteSide(Data_D(DATA_WIDTH-1 downto 0)));
		Fifo_O	 : out tFromFifo(ReadSide(Data_D(DATA_WIDTH-1 downto 0))));
end entity FIFO;

architecture Structural of FIFO is
	component pmi_fifo is
		generic (
			pmi_data_width		  : integer := 8;
			pmi_data_depth		  : integer := 256;
			pmi_full_flag		  : integer := 256;
			pmi_empty_flag		  : integer := 0;
			pmi_almost_full_flag  : integer := 252;
			pmi_almost_empty_flag : integer := 4;
			pmi_regmode			  : string	:= "reg";
			pmi_family			  : string	:= "EC";
			module_type			  : string	:= "pmi_fifo";
			pmi_implementation	  : string	:= "EBR");
		port (
			Data		: in  std_logic_vector(pmi_data_width-1 downto 0);
			Clock		: in  std_logic;
			WrEn		: in  std_logic;
			RdEn		: in  std_logic;
			Reset		: in  std_logic;
			Q			: out std_logic_vector(pmi_data_width-1 downto 0);
			Empty		: out std_logic;
			Full		: out std_logic;
			AlmostEmpty : out std_logic;
			AlmostFull	: out std_logic);
	end component pmi_fifo;

	type state is (stInit, stGetData, stWaitRead);

	attribute syn_enum_encoding			 : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

	signal DataInReg_D		 : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal DataInRegEnable_S : std_logic;

	signal EmptyReg_S		: std_logic;
	signal AlmostEmptyReg_S : std_logic;

	signal FIFOEmpty_S, FIFOAlmostEmpty_S, FIFORead_S : std_logic;
begin  -- architecture Structural
	fifo_1 : pmi_fifo
		generic map (
			pmi_data_width		  => DATA_WIDTH,
			pmi_data_depth		  => DATA_DEPTH,
			pmi_full_flag		  => FULL_FLAG,
			pmi_empty_flag		  => EMPTY_FLAG,
			pmi_almost_full_flag  => ALMOST_FULL_FLAG,
			pmi_almost_empty_flag => ALMOST_EMPTY_FLAG,
			pmi_regmode			  => "noreg",
			pmi_family			  => DEVICE_FAMILY,
			pmi_implementation	  => "LUT")
		port map (
			Data		=> Fifo_I.WriteSide.Data_D,
			Clock		=> Clock_CI,
			WrEn		=> Fifo_I.WriteSide.Write_S,
			RdEn		=> FIFORead_S,
			Reset		=> Reset_RI,
			Q			=> DataInReg_D,
			Empty		=> FIFOEmpty_S,
			Full		=> Fifo_O.WriteSide.Full_S,
			AlmostEmpty => FIFOAlmostEmpty_S,
			AlmostFull	=> Fifo_O.WriteSide.AlmostFull_S);

	p_comb : process (State_DP, FIFOEmpty_S, FIFOAlmostEmpty_S, Fifo_I)
	begin
		State_DN <= State_DP;

		EmptyReg_S		 <= '1';
		AlmostEmptyReg_S <= '1';

		DataInRegEnable_S <= '0';
		FIFORead_S		  <= '0';

		case State_DP is
			when stInit =>
				if FIFOEmpty_S = '0' then
					FIFORead_S		 <= '1';
					EmptyReg_S		 <= '0';
					AlmostEmptyReg_S <= FIFOAlmostEmpty_S;
					State_DN		 <= stGetData;
				end if;

			when stGetData =>
				DataInRegEnable_S <= '1';

				if Fifo_I.ReadSide.Read_S = '1' then
					if FIFOEmpty_S = '0' then
						FIFORead_S		 <= '1';
						EmptyReg_S		 <= '0';
						AlmostEmptyReg_S <= FIFOAlmostEmpty_S;
					else
						State_DN <= stInit;
					end if;
				else
					EmptyReg_S		 <= '0';
					AlmostEmptyReg_S <= FIFOAlmostEmpty_S;
					State_DN		 <= stWaitRead;
				end if;

			when stWaitRead =>
				if Fifo_I.ReadSide.Read_S = '1' then
					if FIFOEmpty_S = '0' then
						FIFORead_S		 <= '1';
						EmptyReg_S		 <= '0';
						AlmostEmptyReg_S <= FIFOAlmostEmpty_S;
						State_DN		 <= stGetData;
					else
						State_DN <= stInit;
					end if;
				else
					EmptyReg_S		 <= '0';
					AlmostEmptyReg_S <= FIFOAlmostEmpty_S;
				end if;

			when others => null;
		end case;
	end process p_comb;

	p_reg : process (Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then			-- asynchronous reset (active high)
			State_DP <= stInit;

			Fifo_O.ReadSide.Empty_S		  <= '1';
			Fifo_O.ReadSide.AlmostEmpty_S <= '1';

			Fifo_O.ReadSide.Data_D <= (others => '0');
		elsif rising_edge(Clock_CI) then  -- rising clock edge
			State_DP <= State_DN;

			Fifo_O.ReadSide.Empty_S		  <= EmptyReg_S;
			Fifo_O.ReadSide.AlmostEmpty_S <= AlmostEmptyReg_S;

			if DataInRegEnable_S = '1' then
				Fifo_O.ReadSide.Data_D <= DataInReg_D;
			end if;
		end if;
	end process p_reg;
end architecture Structural;
