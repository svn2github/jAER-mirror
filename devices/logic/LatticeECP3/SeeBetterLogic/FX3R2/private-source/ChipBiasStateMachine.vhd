library ieee;
use ieee.std_logic_1164.all;
use work.ChipBiasConfigRecords.all;

entity ChipBiasStateMachine is
	port(
		Clock_CI      : in std_logic;
		Reset_RI      : in std_logic;

		-- Configuration inputs
		BiasConfig_DI : in tBiasConfig;
		ChipConfig_DI : in tChipConfig
	);
end entity ChipBiasStateMachine;

architecture Behavioral of ChipBiasStateMachine is
begin
end architecture Behavioral;
