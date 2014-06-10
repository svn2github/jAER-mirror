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
			RdEn		=> RdEnable_SI,
			Reset		=> Reset_RI,
			Q			=> DataOut_DO,
			Empty		=> Empty_SO,
			Full		=> Full_SO,
			AlmostEmpty => AlmostEmpty_SO,
			AlmostFull	=> AlmostFull_SO);
end architecture Structural;
