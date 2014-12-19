library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.DEVICE_FAMILY;

entity BlockRAM is
	generic(
		ADDRESS_DEPTH : integer;
		ADDRESS_WIDTH : integer;
		DATA_WIDTH    : integer);
	port(
		Clock_CI       : in  std_logic;
		Reset_RI       : in  std_logic;

		Address_DI     : in  unsigned(ADDRESS_WIDTH - 1 downto 0);
		Enable_SI      : in  std_logic;
		WriteEnable_SI : in  std_logic;
		Data_DI        : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
		Data_DO        : out std_logic_vector(DATA_WIDTH - 1 downto 0));
end entity BlockRAM;

architecture Structural of BlockRAM is
begin
	blockRAM : component work.pmi_components.pmi_distributed_spram
		generic map(
			pmi_addr_depth => ADDRESS_DEPTH,
			pmi_addr_width => ADDRESS_WIDTH,
			pmi_data_width => DATA_WIDTH,
			pmi_regmode    => "noreg",
			--pmi_gsr          => "disable",
			--pmi_resetmode    => "async",
			--pmi_optimization => "speed",
			--pmi_write_mode   => "normal",
			pmi_family     => DEVICE_FAMILY)
		port map(
			Data    => Data_DI,
			Address => std_logic_vector(Address_DI),
			Clock   => Clock_CI,
			ClockEn => Enable_SI,
			WE      => WriteEnable_SI,
			Reset   => Reset_RI,
			Q       => Data_DO);
end architecture Structural;
