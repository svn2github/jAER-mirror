library ieee;
use ieee.std_logic_1164.all;
use work.FIFORecords.all;

-- Split a FIFO into two FIFOs. This is accomplished by taking data,
-- when available, from the input FIFO, and forwarding it directly to
-- the output FIFOs, which may accept the data if they do have available
-- space. If not, the data is not copied to that particular output FIFO.
entity FifoMerger is
	generic(
		FIFO_WIDTH : integer);
	port(
		Clock_CI           : in  std_logic;
		Reset_RI           : in  std_logic;

		FifoIn1Control_SI   : in  tFromFifoReadSide;
		FifoIn1Control_SO   : out tToFifoReadSide;
		FifoIn1Data_DI      : in  std_logic_vector(FIFO_WIDTH - 1 downto 0);
		
		FifoIn2Control_SI   : in  tFromFifoReadSide;
		FifoIn2Control_SO   : out tToFifoReadSide;
		FifoIn2Data_DI      : in  std_logic_vector(FIFO_WIDTH - 1 downto 0);

--		FifoOutEnable_SI  : in  std_logic;
		FifoOutControl_SI : in  tFromFifoWriteSide;
		FifoOutControl_SO : out tToFifoWriteSide;
		FifoOutData_DO    : out std_logic_vector(FIFO_WIDTH - 1 downto 0));
end entity FifoMerger;

architecture Behavioral of FifoMerger is
	type tSMmeger is (idle, FIFO1, FIFO2);
	signal cs, ns: tSMmerger;
	signal Arbiter_priority  : integer range 1 to 2;
	
	signal FifoIn1NotEmpty_S : std_logic;
	signal FifoIn2NotEmpty_S : std_logic;

	signal WriteDelayReg_S : std_logic;

	signal DataFifoOutReg_D : std_logic_vector(FIFO_WIDTH - 1 downto 0);
	
begin
	FifoInNotEmpty_S         <= not FifoInControl_SI.Empty_S;
	FifoIn1Control_SO.Read_S <= FifoIn1Read;
	FifoIn2Control_SO.Read_S <= FifoIn2Read;

	SM_comb: process(cs, FifoIn1Control_SI, FifoIn2Control_SI, FifoOutControl_SI, Arbiter_priority)
	begin
	    case cs is
		    when idle =>
			    if (FifoIn1Control_SI.Empty_S='0' and FifoIn2Control_SI.Empty_S='1' and FifoOutControl_SI.Write_S='0') then
				   ns <= FIFO1;
			    elsif (FifoIn1Control_SI.Empty_S='1' and FifoIn2Control_SI.Empty_S='0' and FifoOutControl_SI.Write_S='0') then
				   ns <= FIFO2;
			    elsif (FifoIn1Control_SI.Empty_S='0' and FifoIn2Control_SI.Empty_S='2' and FifoOutControl_SI.Write_S='0') then
				   if (Arbiter_priority = 1) then 
				        ns <= FIFO1;
				   else ns FIFO2;
				else
				   ns <= idle;
				end if;
			when others => 
			    ns <= idle;
		end case;
	end process;
   
	SM_seq : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			FifoOutControl_SO.Write_S <= '0';
			FifoIn1Control_SO.Read_S  <= '0';
			FifoIn2Control_SO.Read_S  <= '0';
			DataFifoOutReg_D           <= (others => '0');
			Arbiter_priority		   <= 1;
		elsif rising_edge(Clock_CI) then -- rising clock edge
		    cs <= ns;
			FifoOutControl_SO.Write_S <= '0';
			FifoIn1Control_SO.Read_S  <= '0';
			FifoIn2Control_SO.Read_S  <= '0';
			case (cs) is
			    when FIFO1 => 
				    Arbiter_priority          <= 2;
					FifoOutcontrol_SO.Write_S <= '1';
					FifoIn1Control_SO.Read_S  <= '1';
					DataFifoOutReg_D          <= FifoIn1Data_DI;
				when FIFO2 => 
				    Arbiter_priority <= 1;
					FifoOutcontrol_SO.Write_S <= '1';
					FifoIn2Control_SO.Read_S  <= '1';
					DataFifoOutReg_D          <= FifoIn2Data_DI;
			end case;
		end if;
	end process;

	FifoOutData_DO <= DataFifoOutReg_D;
end architecture Behavioral;
