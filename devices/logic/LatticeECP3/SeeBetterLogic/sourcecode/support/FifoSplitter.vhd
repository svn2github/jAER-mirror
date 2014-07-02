library ieee;
use ieee.std_logic_1164.all;

entity FifoSplitter is
	generic (
		FIFO_WIDTH : integer := 16);
	port (
		Clock_CI : in std_logic;
		Reset_RI : in std_logic;

		FifoInEmpty_SI : in	 std_logic;
		FifoInRead_SO  : out std_logic;
		FifoInData_DI  : in	 std_logic_vector(FIFO_WIDTH-1 downto 0);

		FifoOut1Full_SI	 : in  std_logic;
		FifoOut1Write_SO : out std_logic;
		FifoOut1Data_DO	 : out std_logic_vector(FIFO_WIDTH-1 downto 0);

		FifoOut2Full_SI	 : in  std_logic;
		FifoOut2Write_SO : out std_logic;
		FifoOut2Data_DO	 : out std_logic_vector(FIFO_WIDTH-1 downto 0));
end entity FifoSplitter;

architecture Behavioral of FifoSplitter is
	signal FifoInNotEmpty_S : std_logic;

	signal WriteDelayReg_S : std_logic;

	signal WriteFifoOut1Reg_S : std_logic;
	signal WriteFifoOut2Reg_S : std_logic;

	signal DataFifoOutReg_D : std_logic_vector(FIFO_WIDTH-1 downto 0);
begin
	FifoInNotEmpty_S <= not FifoInEmpty_SI;
	FifoInRead_SO	 <= FifoInNotEmpty_S;

	regUpdate : process (Clock_CI, Reset_RI) is
	begin  -- process regUpdate
		if Reset_RI = '1' then			  -- asynchronous reset (active high)
			WriteDelayReg_S	 <= '0';
			FifoOut1Write_SO <= '0';
			FifoOut2Write_SO <= '0';
			DataFifoOutReg_D <= (others => '0');
		elsif rising_edge(Clock_CI) then  -- rising clock edge
			WriteDelayReg_S	 <= FifoInNotEmpty_S;
			FifoOut1Write_SO <= WriteDelayReg_S and not FifoOut1Full_SI;
			FifoOut2Write_SO <= WriteDelayReg_S and not FifoOut2Full_SI;
			DataFifoOutReg_D <= FifoInData_DI;
		end if;
	end process regUpdate;

	FifoOut1Data_DO <= DataFifoOutReg_D;
	FifoOut2Data_DO <= DataFifoOutReg_D;
end architecture Behavioral;
