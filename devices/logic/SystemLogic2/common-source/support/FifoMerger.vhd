library ieee;
use ieee.std_logic_1164.all;
use work.FIFORecords.all;
-- Alejandro Linares-Barranco. August-2014
-- Merge two FIFOs into one FIFO. This is accomplished by taking data,
-- when available, from the input FIFOs, and forwarding it directly to
-- the output FIFO, which may accept the data if it does have available
-- space. If not, it will wait until available space in output FIFO.
entity FifoMerger is
	generic(
		FIFO_WIDTH : integer);
	port(
		Clock_CI          : in  std_logic;
		Reset_RI          : in  std_logic;

		FifoIn1Control_SI : in  tFromFifoReadSide;
		FifoIn1Control_SO : out tToFifoReadSide;
		FifoIn1Data_DI    : in  std_logic_vector(FIFO_WIDTH - 1 downto 0);

		FifoIn2Control_SI : in  tFromFifoReadSide;
		FifoIn2Control_SO : out tToFifoReadSide;
		FifoIn2Data_DI    : in  std_logic_vector(FIFO_WIDTH - 1 downto 0);

		FifoOutControl_SI : in  tFromFifoWriteSide;
		FifoOutControl_SO : out tToFifoWriteSide;
		FifoOutData_DO    : out std_logic_vector(FIFO_WIDTH - 1 downto 0));
end entity FifoMerger;

architecture Behavioral of FifoMerger is
	attribute syn_enum_encoding : string;

	type tState is (idle, FIFO1, FIFO2);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : tState;

	signal ArbiterPriority_S : integer range 1 to 2;

	signal DataFifoOutReg_D : std_logic_vector(FIFO_WIDTH - 1 downto 0);
begin
	SM_comb : process(State_DP, FifoIn1Control_SI, FifoIn2Control_SI, FifoOutControl_SI, ArbiterPriority_S)
	begin
		case State_DP is
			when idle =>
				if (FifoIn1Control_SI.Empty_S = '0' and FifoIn2Control_SI.Empty_S = '1' and FifoOutControl_SI.Full_S = '0') then
					State_DN <= FIFO1;
				elsif (FifoIn1Control_SI.Empty_S = '1' and FifoIn2Control_SI.Empty_S = '0' and FifoOutControl_SI.Full_S = '0') then
					State_DN <= FIFO2;
				elsif (FifoIn1Control_SI.Empty_S = '0' and FifoIn2Control_SI.Empty_S = '0' and FifoOutControl_SI.Full_S = '0') then
					if (ArbiterPriority_S = 1) then
						State_DN <= FIFO1;
					else
						State_DN <= FIFO2;
					end if;
				else
					State_DN <= idle;
				end if;

			when others =>
				State_DN <= idle;
		end case;
	end process;

	SM_seq : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			FifoOutControl_SO.Write_S <= '0';
			FifoIn1Control_SO.Read_S  <= '0';
			FifoIn2Control_SO.Read_S  <= '0';
			DataFifoOutReg_D          <= (others => '0');
			ArbiterPriority_S         <= 1;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			State_DP                  <= State_DN;
			FifoOutControl_SO.Write_S <= '0';
			FifoIn1Control_SO.Read_S  <= '0';
			FifoIn2Control_SO.Read_S  <= '0';

			case (State_DP) is
				when FIFO1 =>
					ArbiterPriority_S         <= 2;
					FifoOutcontrol_SO.Write_S <= '1';
					FifoIn1Control_SO.Read_S  <= '1';
					DataFifoOutReg_D          <= FifoIn1Data_DI;

				when FIFO2 =>
					ArbiterPriority_S         <= 1;
					FifoOutcontrol_SO.Write_S <= '1';
					FifoIn2Control_SO.Read_S  <= '1';
					DataFifoOutReg_D          <= FifoIn2Data_DI;

				when others => null;
			end case;
		end if;
	end process;

	FifoOutData_DO <= DataFifoOutReg_D;
end architecture Behavioral;