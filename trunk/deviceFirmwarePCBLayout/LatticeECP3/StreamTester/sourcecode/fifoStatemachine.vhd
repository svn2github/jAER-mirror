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
	type state is (stIdle0, stPrepareWrite0, stWrite0, stSwitch0,
	               stIdle1, stPrepareWrite1, stWrite1, stSwitch1);

	-- present and next state
	signal State_DP: state;

	begin
		-- Change state on clock edge (synchronous).
		process (Clock_CI, Reset_RBI)
		begin
		if Reset_RBI = '0' then -- asynchronous reset (active-low)
			State_DP <= stIdle0;
		elsif rising_edge(Clock_CI) then
			USBFifoChipSelect_SBO <= '0'; -- Always keep chip selected (active-low).
			USBFifoWrite_SBO <= '1';
			USBFifoPktEnd_SBO <= '1';
			USBFifoAddress_DO(1) <= '0';
			USBFifoAddress_DO(0) <= '0';
			InFifoRead_SO <= '0'; -- Don't read from input FIFO until we know we can write.

			case State_DP is
			when stIdle0 =>
				if Run_SI = '1' and InFifoAlmostEmpty_SI = '0' and USBFifoThread0Full_SI = '0' then
					State_DP <= stPrepareWrite0;
				end if;

			when stPrepareWrite0 =>
				State_DP <= stWrite0;
				InFifoRead_SO <= '1'; -- Signal we want to read from the FIFO on next cycle.

			when stWrite0 =>
				-- Check that we're reaching the end of the FIFO using the watermark flag (almost full).
				-- This way we know exactly how much space is left (2 cycles) and can enter the right path
				-- to switch to the next thread.
				if USBFifoThread0AlmostFull_SI = '1' then
					State_DP <= stSwitch0;
					USBFifoWrite_SBO <= '0';
					InFifoRead_SO <= '1';
				-- Check that there still is data to send.
				elsif InFifoAlmostEmpty_SI = '1' then
					State_DP <= stIdle0;
					-- Last piece of data is sampled when the empty flag goes high.
					-- So we still write it out here.
					USBFifoWrite_SBO <= '0';
				else
					-- Execute write and continue to read from FIFO on next cycle.
					USBFifoWrite_SBO <= '0';
					InFifoRead_SO <= '1';
				end if;

			when stSwitch0 =>
				if USBFifoThread1Full_SI = '1' or InFifoEmpty_SI = '1' then
					State_DP <= stIdle1;
				else
					State_DP <= stWrite1;
					InFifoRead_SO <= '1';
				end if;

				USBFifoWrite_SBO <= '0';

			when stIdle1 =>
				USBFifoAddress_DO(0) <= '1'; -- Access Thread 1.

				if Run_SI = '1' and InFifoAlmostEmpty_SI = '0' and USBFifoThread1Full_SI = '0' then
					State_DP <= stPrepareWrite1;
				end if;

			when stPrepareWrite1 =>
				USBFifoAddress_DO(0) <= '1'; -- Access Thread 1.

				State_DP <= stWrite1;
				InFifoRead_SO <= '1'; -- Signal we want to read from the FIFO on next cycle.

			when stWrite1 =>
				USBFifoAddress_DO(0) <= '1'; -- Access Thread 1.

				-- Check that we're reaching the end of the FIFO using the watermark flag (almost full).
				-- This way we know exactly how much space is left (2 cycles) and can enter the right path
				-- to switch to the next thread.
				if USBFifoThread1AlmostFull_SI = '1' then
					State_DP <= stSwitch1;
					USBFifoWrite_SBO <= '0';
					InFifoRead_SO <= '1';
				-- Check that there still is data to send.
				elsif InFifoAlmostEmpty_SI = '1' then
					State_DP <= stIdle1;
					-- Last piece of data is sampled when the empty flag goes high.
					-- So we still write it out here.
					USBFifoWrite_SBO <= '0';
				else
					-- Execute write and continue to read from FIFO on next cycle.
					USBFifoWrite_SBO <= '0';
					InFifoRead_SO <= '1';
				end if;

			when stSwitch1 =>
				USBFifoAddress_DO(0) <= '1'; -- Access Thread 1.

				if USBFifoThread0Full_SI = '1' or InFifoEmpty_SI = '1' then
					State_DP <= stIdle0;
				else
					State_DP <= stWrite0;
					InFifoRead_SO <= '1';
				end if;

				USBFifoWrite_SBO <= '0';

			when others => null;
			end case;
		end if;
	end process;
end Behavioral;
