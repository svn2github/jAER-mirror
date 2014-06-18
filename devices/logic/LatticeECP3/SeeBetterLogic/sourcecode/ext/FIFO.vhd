library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.Settings.all;

entity FIFO is
	generic (
		DATA_WIDTH		  : integer := 16;
		DATA_DEPTH		  : integer := 64;
		EMPTY_FLAG		  : integer := 0;
		ALMOST_EMPTY_FLAG : integer := 4;
		FULL_FLAG		  : integer := 64;
		ALMOST_FULL_FLAG  : integer := 60);
	port (
		Clock_CI	   : in	 std_logic;
		Reset_RI	   : in	 std_logic;
		DataIn_DI	   : in	 std_logic_vector(DATA_WIDTH-1 downto 0);
		WrEnable_SI	   : in	 std_logic;
		DataOut_DO	   : out std_logic_vector(DATA_WIDTH-1 downto 0);
		RdEnable_SI	   : in	 std_logic;
		Empty_SO	   : out std_logic;
		AlmostEmpty_SO : out std_logic;
		Full_SO		   : out std_logic;
		AlmostFull_SO  : out std_logic);
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
	fifo : pmi_fifo
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
			Data		=> DataIn_DI,
			Clock		=> Clock_CI,
			WrEn		=> WrEnable_SI,
			RdEn		=> FIFORead_S,
			Reset		=> Reset_RI,
			Q			=> DataInReg_D,
			Empty		=> FIFOEmpty_S,
			Full		=> Full_SO,
			AlmostEmpty => FIFOAlmostEmpty_S,
			AlmostFull	=> AlmostFull_SO);

	p_comb : process (State_DP, FIFOEmpty_S, FIFOAlmostEmpty_S, RdEnable_SI)
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

				if RdEnable_SI = '1' then
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
				if RdEnable_SI = '1' then
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

			Empty_SO	   <= '1';
			AlmostEmpty_SO <= '1';

			DataOut_DO <= (others => '0');
		elsif rising_edge(Clock_CI) then  -- rising clock edge
			State_DP <= State_DN;

			Empty_SO	   <= EmptyReg_S;
			AlmostEmpty_SO <= AlmostEmptyReg_S;

			if DataInRegEnable_S = '1' then
				DataOut_DO <= DataInReg_D;
			end if;
		end if;
	end process p_reg;
end architecture Structural;
