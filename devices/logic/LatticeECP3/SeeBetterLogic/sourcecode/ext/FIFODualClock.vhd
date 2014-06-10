library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.Settings.all;

entity FIFODualClock is
	generic (
		DATA_WIDTH		  : integer := 16;
		DATA_DEPTH		  : integer := 64;
		EMPTY_FLAG		  : integer := 0;
		ALMOST_EMPTY_FLAG : integer := 4;
		FULL_FLAG		  : integer := 64;
		ALMOST_FULL_FLAG  : integer := 60);
	port (
		Reset_RI	   : in	 std_logic;
		DataIn_DI	   : in	 std_logic_vector(DATA_WIDTH-1 downto 0);
		WrClock_CI	   : in	 std_logic;
		WrEnable_SI	   : in	 std_logic;
		DataOut_DO	   : out std_logic_vector(DATA_WIDTH-1 downto 0);
		RdClock_CI	   : in	 std_logic;
		RdEnable_SI	   : in	 std_logic;
		Empty_SO	   : out std_logic;
		AlmostEmpty_SO : out std_logic;
		Full_SO		   : out std_logic;
		AlmostFull_SO  : out std_logic);
end entity FIFODualClock;

architecture Structural of FIFODualClock is
	-- Use double-clock FIFO from the Lattice Portable Module Interfaces.
	-- This is a more portable variation than what you'd get with the other tools,
	-- but slightly less configurable. It has everything we need though, and allows
	-- for easy switching between underlying hardware implementations and tuning.
	component pmi_fifo_dc is
		generic (
			pmi_data_width_w	  : integer := 18;
			pmi_data_width_r	  : integer := 18;
			pmi_data_depth_w	  : integer := 256;
			pmi_data_depth_r	  : integer := 256;
			pmi_full_flag		  : integer := 256;
			pmi_empty_flag		  : integer := 0;
			pmi_almost_full_flag  : integer := 252;
			pmi_almost_empty_flag : integer := 4;
			pmi_regmode			  : string	:= "reg";
			pmi_resetmode		  : string	:= "async";
			pmi_family			  : string	:= "EC";
			module_type			  : string	:= "pmi_fifo_dc";
			pmi_implementation	  : string	:= "EBR");
		port (
			Data		: in  std_logic_vector(pmi_data_width_w-1 downto 0);
			WrClock		: in  std_logic;
			RdClock		: in  std_logic;
			WrEn		: in  std_logic;
			RdEn		: in  std_logic;
			Reset		: in  std_logic;
			RPReset		: in  std_logic;
			Q			: out std_logic_vector(pmi_data_width_r-1 downto 0);
			Empty		: out std_logic;
			Full		: out std_logic;
			AlmostEmpty : out std_logic;
			AlmostFull	: out std_logic);
	end component pmi_fifo_dc;
begin  -- architecture Structural
	fifoDualClock : pmi_fifo_dc
		generic map (
			pmi_data_width_w	  => DATA_WIDTH,
			pmi_data_width_r	  => DATA_WIDTH,
			pmi_data_depth_w	  => DATA_DEPTH,
			pmi_data_depth_r	  => DATA_DEPTH,
			pmi_full_flag		  => FULL_FLAG,
			pmi_empty_flag		  => EMPTY_FLAG,
			pmi_almost_full_flag  => ALMOST_FULL_FLAG,
			pmi_almost_empty_flag => ALMOST_EMPTY_FLAG,
			pmi_regmode			  => "noreg",
			pmi_resetmode		  => "async",
			pmi_family			  => DEVICE_FAMILY,
			pmi_implementation	  => "LUT")
		port map (
			Data		=> DataIn_DI,
			WrClock		=> WrClock_CI,
			RdClock		=> RdClock_CI,
			WrEn		=> WrEnable_SI,
			RdEn		=> RdEnable_SI,
			Reset		=> Reset_RI,
			RPReset		=> Reset_RI,
			Q			=> DataOut_DO,
			Empty		=> Empty_SO,
			Full		=> Full_SO,
			AlmostEmpty => AlmostEmpty_SO,
			AlmostFull	=> AlmostFull_SO);
end architecture Structural;
