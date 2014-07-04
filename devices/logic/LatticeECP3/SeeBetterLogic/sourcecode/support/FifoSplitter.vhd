library ieee;
use ieee.std_logic_1164.all;
use work.FIFORecords.all;

entity FifoSplitter is
	generic (
		FIFO_WIDTH : integer := 16);
	port (
		Clock_CI : in std_logic;
		Reset_RI : in std_logic;

		FifoIn_I : in  tFromFifoReadSide(Data_D(FIFO_WIDTH-1 downto 0));
		FifoIn_O : out tToFifoReadSide;

		FifoOut1_I : in	 tFromFifoWriteSide;
		FifoOut1_O : out tToFifoWriteSide(Data_D(FIFO_WIDTH-1 downto 0));

		FifoOut2_I : in	 tFromFifoWriteSide;
		FifoOut2_O : out tToFifoWriteSide(Data_D(FIFO_WIDTH-1 downto 0)));
end entity FifoSplitter;

architecture Behavioral of FifoSplitter is
	signal FifoInNotEmpty_S : std_logic;

	signal WriteDelayReg_S : std_logic;

	signal DataFifoOutReg_D : std_logic_vector(FIFO_WIDTH-1 downto 0);
begin
	FifoInNotEmpty_S <= not FifoIn_I.Empty_S;
	FifoIn_O.Read_S	 <= FifoInNotEmpty_S;

	regUpdate : process (Clock_CI, Reset_RI) is
	begin  -- process regUpdate
		if Reset_RI = '1' then			  -- asynchronous reset (active high)
			FifoOut1_O.Write_S <= '0';
			FifoOut2_O.Write_S <= '0';
			WriteDelayReg_S	   <= '0';
			DataFifoOutReg_D   <= (others => '0');
		elsif rising_edge(Clock_CI) then  -- rising clock edge
			FifoOut1_O.Write_S <= WriteDelayReg_S and not FifoOut1_I.Full_S;
			FifoOut2_O.Write_S <= WriteDelayReg_S and not FifoOut2_I.Full_S;
			WriteDelayReg_S	   <= FifoInNotEmpty_S;
			DataFifoOutReg_D   <= FifoIn_I.Data_D;
		end if;
	end process regUpdate;

	FifoOut1_O.Data_D <= DataFifoOutReg_D;
	FifoOut2_O.Data_D <= DataFifoOutReg_D;
end architecture Behavioral;
