library ieee;
use ieee.std_logic_1164.all;
use work.FIFORecords.all;

entity FifoSplitter is
	generic(
		FIFO_WIDTH : integer := 16);
	port(
		Clock_CI           : in  std_logic;
		Reset_RI           : in  std_logic;

		FifoInControl_SI   : in  tFromFifoReadSide;
		FifoInControl_SO   : out tToFifoReadSide;
		FifoInData_DI      : in  std_logic_vector(FIFO_WIDTH - 1 downto 0);

		FifoOut1Enable_SI  : in  std_logic;
		FifoOut1Control_SI : in  tFromFifoWriteSide;
		FifoOut1Control_SO : out tToFifoWriteSide;
		FifoOut1Data_DO    : out std_logic_vector(FIFO_WIDTH - 1 downto 0);

		FifoOut2Enable_SI  : in  std_logic;
		FifoOut2Control_SI : in  tFromFifoWriteSide;
		FifoOut2Control_SO : out tToFifoWriteSide;
		FifoOut2Data_DO    : out std_logic_vector(FIFO_WIDTH - 1 downto 0));
end entity FifoSplitter;

architecture Behavioral of FifoSplitter is
	signal FifoInNotEmpty_S : std_logic;

	signal WriteDelayReg_S : std_logic;

	signal DataFifoOutReg_D : std_logic_vector(FIFO_WIDTH - 1 downto 0);
begin
	FifoInNotEmpty_S        <= not FifoInControl_SI.Empty_S;
	FifoInControl_SO.Read_S <= FifoInNotEmpty_S;

	regUpdate : process(Clock_CI, Reset_RI) is
	begin                               -- process regUpdate
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			FifoOut1Control_SO.Write_S <= '0';
			FifoOut2Control_SO.Write_S <= '0';
			WriteDelayReg_S            <= '0';
			DataFifoOutReg_D           <= (others => '0');
		elsif rising_edge(Clock_CI) then -- rising clock edge
			FifoOut1Control_SO.Write_S <= WriteDelayReg_S and not FifoOut1Control_SI.Full_S and FifoOut1Enable_SI;
			FifoOut2Control_SO.Write_S <= WriteDelayReg_S and not FifoOut2Control_SI.Full_S and FifoOut2Enable_SI;
			WriteDelayReg_S            <= FifoInNotEmpty_S;
			DataFifoOutReg_D           <= FifoInData_DI;
		end if;
	end process regUpdate;

	FifoOut1Data_DO <= DataFifoOutReg_D;
	FifoOut2Data_DO <= DataFifoOutReg_D;
end architecture Behavioral;
