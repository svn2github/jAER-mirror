library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.Settings.all;

entity DVSAERStateMachine is
	port (
		Clock_CI  : in std_logic;
		Reset_RI  : in std_logic;
		DVSRun_SI : in std_logic;

		-- Fifo output (to Multiplexer)
		OutFifoFull_SI		 : in  std_logic;
		OutFifoAlmostFull_SI : in  std_logic;
		OutFifoWrite_SO		 : out std_logic;
		OutFifoData_DO		 : out std_logic_vector(EVENT_WIDTH-1 downto 0);

		DVSAERData_DI	: in  std_logic_vector(AER_BUS_WIDTH-1 downto 0);
		DVSAERReq_SBI	: in  std_logic;
		DVSAERAck_SBO	: out std_logic;
		DVSAERReset_SBO : out std_logic);
end DVSAERStateMachine;

architecture Behavioral of DVSAERStateMachine is

begin

end Behavioral;
