library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity fifoStatemachine is
	port (
		Clock_CI : in std_logic;
		Reset_RBI : in std_logic;
		Run_SI : in std_logic;

		-- USB FIFO flags
		USBFifoThread0Full_SI : in std_logic;
		USBFifoThread0AlmostFull_SI : in std_logic;
		USBFifoThread1Full_SI : in std_logic;
		USBFifoThread1AlmostFull_SI : in std_logic;

		-- USB FIFO control lines
		USBFifoChipSelect_SBO : out std_logic;
		USBFifoWrite_SBO : out std_logic;
		USBFifoPktEnd_SBO : out std_logic;
		USBFifoAddress_DO : out std_logic_vector(1 downto 0);

		-- Input FIFO flags
		InFifoEmpty_SI : in std_logic;
		InFifoAlmostEmpty_SI : in std_logic;

		-- Input FIFO control lines
		InFifoRead_SO : out std_logic);
end fifoStatemachine;

architecture Behavioral of fifoStatemachine is
	type state is (stIdle0, stPrepareWrite0, stWriteFirst0, stWriteSecond0, stSwitch0,
	               stIdle1, stPrepareWrite1, stWriteFirst1, stWriteSecond1, stSwitch1);

	-- present and next state
	signal State_DP, State_DN: state;
begin
	p_memoryless : process (State_DP, USBFifoThread0Full_SI, USBFifoThread0AlmostFull_SI, USBFifoThread1Full_SI, USBFifoThread1AlmostFull_SI, InFifoEmpty_SI, Run_SI)
	begin
		State_DN <= State_DP; -- Keep current state by default.

		USBFifoChipSelect_SBO <= '0'; -- Always keep chip selected (active-low).
		USBFifoWrite_SBO <= '1';
		USBFifoPktEnd_SBO <= '1';
		USBFifoAddress_DO(1) <= '0';
		USBFifoAddress_DO(0) <= '0';
		InFifoRead_SO <= '0'; -- Don't read from input FIFO until we know we can write.

		case State_DP is
			when stIdle0 =>
				if Run_SI = '1' and InFifoEmpty_SI = '0' and USBFifoThread0Full_SI = '0' then
					State_DN <= stPrepareWrite0;
				end if;

			when stPrepareWrite0 =>
				State_DN <= stWriteFirst0;
				InFifoRead_SO <= '1';

			when stWriteFirst0 =>
				if USBFifoThread0AlmostFull_SI = '1' then
					State_DN <= stSwitch0;
				else
					State_DN <= stWriteSecond0;
				end if;

				InFifoRead_SO <= '1';
				USBFifoWrite_SBO <= '0';

			when stWriteSecond0 =>
				if InFifoEmpty_SI = '1' then
					State_DN <= stIdle0;
				else
					State_DN <= stWriteFirst0;
					InFifoRead_SO <= '1';
				end if;

				USBFifoWrite_SBO <= '0';

			when stSwitch0 =>
				if InFifoEmpty_SI = '1' or USBFifoThread1Full_SI = '1' then
					State_DN <= stIdle1;
				else
					State_DN <= stWriteFirst1;
					InFifoRead_SO <= '1';
				end if;

				USBFifoWrite_SBO <= '0';

			when stIdle1 =>
				USBFifoAddress_DO(0) <= '1'; -- Access Thread 1.

				if Run_SI = '1' and InFifoEmpty_SI = '0' and USBFifoThread1Full_SI = '0' then
					State_DN <= stPrepareWrite1;
				end if;

			when stPrepareWrite1 =>
				USBFifoAddress_DO(0) <= '1'; -- Access Thread 1.

				State_DN <= stWriteFirst1;
				InFifoRead_SO <= '1';

			when stWriteFirst1 =>
				USBFifoAddress_DO(0) <= '1'; -- Access Thread 1.

				if USBFifoThread1AlmostFull_SI = '1' then
					State_DN <= stSwitch1;
				else
					State_DN <= stWriteSecond1;
				end if;

				InFifoRead_SO <= '1';
				USBFifoWrite_SBO <= '0';

			when stWriteSecond1 =>
				USBFifoAddress_DO(0) <= '1'; -- Access Thread 1.

				if InFifoEmpty_SI = '1' then
					State_DN <= stIdle1;
				else
					State_DN <= stWriteFirst1;
					InFifoRead_SO <= '1';
				end if;

				USBFifoWrite_SBO <= '0';

			when stSwitch1 =>
				USBFifoAddress_DO(0) <= '1'; -- Access Thread 1.

				if InFifoEmpty_SI = '1' or USBFifoThread0Full_SI = '1' then
					State_DN <= stIdle0;
				else
					State_DN <= stWriteFirst0;
					InFifoRead_SO <= '1';
				end if;

				USBFifoWrite_SBO <= '0';

			when others => null;
		end case;
	end process p_memoryless;
	
	-- Change state on clock edge (synchronous).
	p_memoryzing : process (Clock_CI, Reset_RBI)
	begin
		if Reset_RBI = '0' then -- asynchronous reset (active-low)
			State_DP <= stIdle0;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;
		end if;
	end process p_memoryzing;
end Behavioral;
