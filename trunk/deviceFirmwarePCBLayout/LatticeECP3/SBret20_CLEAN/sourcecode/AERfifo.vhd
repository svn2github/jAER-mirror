library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity AERfifo is
	port (
		Data: in  std_logic_vector(15 downto 0); 
		WrClock: in  std_logic; 
		RdClock: in  std_logic; 
		WrEn: in  std_logic; 
		RdEn: in  std_logic; 
		Reset: in  std_logic; 
		RPReset: in  std_logic; 
		Q: out  std_logic_vector(15 downto 0); 
		Empty: out  std_logic; 
		Full: out  std_logic; 
		AlmostEmpty: out  std_logic; 
		AlmostFull: out  std_logic);
end AERfifo;

architecture Structural of AERfifo is
	-- Use double-clock FIFO from the Lattice Portable Module Interfaces.
	-- This is a more portable variation than what you'd get with the other tools,
	-- but slightly less configurable. It has everything we need though, and allows
	-- for easy switching between underlying hardware implementations and tuning.
	component pmi_fifo_dc is
	generic (
		pmi_data_width_w : integer := 18; 
		pmi_data_width_r : integer := 18; 
		pmi_data_depth_w : integer := 256; 
		pmi_data_depth_r : integer := 256; 
		pmi_full_flag : integer := 256; 
		pmi_empty_flag : integer := 0; 
		pmi_almost_full_flag : integer := 252; 
		pmi_almost_empty_flag : integer := 4; 
		pmi_regmode : string := "reg"; 
		pmi_resetmode : string := "async"; 
		pmi_family : string := "EC" ; 
		module_type : string := "pmi_fifo_dc"; 
		pmi_implementation : string := "EBR");
	port (
		Data : in std_logic_vector(pmi_data_width_w-1 downto 0);
		WrClock: in std_logic;
		RdClock: in std_logic;
		WrEn: in std_logic;
		RdEn: in std_logic;
		Reset: in std_logic;
		RPReset: in std_logic;
		Q : out std_logic_vector(pmi_data_width_r-1 downto 0);
		Empty: out std_logic;
		Full: out std_logic;
		AlmostEmpty: out std_logic;
		AlmostFull: out std_logic);
	end component pmi_fifo_dc;
begin
	-- Instantiate one FIFO to hold all the events coming out of the mixer-producer state machine.
	AERfifo_0: pmi_fifo_dc
	generic map (
		pmi_data_width_w => 16,
		pmi_data_depth_w => 64,
		pmi_data_width_r => 16,
		pmi_data_depth_r => 64,
		pmi_full_flag => 64,
		pmi_empty_flag => 0,
		pmi_almost_full_flag => 56,
		pmi_almost_empty_flag => 8,
		pmi_regmode => "noreg",
		pmi_resetmode => "async",
		pmi_family => "ECP3",
		pmi_implementation => "LUT"
	)
	port map (
		Data => Data,
		WrClock => WrClock,
		RdClock => RdClock,
		WrEn => WrEn,
		RdEn => RdEn,
		Reset => Reset,
		RPReset => RPReset,
		Q => Q,
		Empty => Empty,
		Full => Full,
		AlmostEmpty => AlmostEmpty,
		AlmostFull => AlmostFull
	);
end Structural;
