library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.Settings.all;

entity MultiplexerStateMachine is
	port (
		Clock_CI : in std_logic;
		Reset_RI : in std_logic;
		FPGARun_SI : in std_logic;

		-- Timestamp input
		TimestampReset_SI : in std_logic;
		TimestampOverflow_SI : in std_logic;
		Timestamp_DI : in std_logic_vector(TIMESTAMP_WIDTH-1 downto 0);

		-- Fifo output (to USB)
		OutFifoFull_SI : in std_logic;
		OutFifoAlmostFull_SI : in std_logic;
		OutFifoWrite_SO : out std_logic;
		OutFifoData_DO : out std_logic_vector(USB_FIFO_WIDTH-1 downto 0);

		-- Fifo input (from DVS AER)
		DVSAERFifoEmpty_SI : in std_logic;
		DVSAERFifoAlmostEmpty_SI : in std_logic;
		DVSAERFifoRead_SO : out std_logic;
		DVSAERFifoData_DI : in std_logic_vector(EVENT_WIDTH-1 downto 0));
end MultiplexerStateMachine;

architecture Behavioral of MultiplexerStateMachine is
	
begin
	
end Behavioral;
