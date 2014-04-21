library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity fifoStatemachine is
port (
	Clock_CI               : in std_logic;
	Reset_RBI              : in std_logic;
	Run_SI                 : in std_logic;
	
	-- USB FIFO flags
	USBFifoThread0Full_SI : in  std_logic;
	USBFifoThread0AlmostFull_SI : in std_logic;
	USBFifoThread1Full_SI : in  std_logic;
	USBFifoThread1AlmostFull_SI : in std_logic;
	
	-- Input FIFO flags
	InFifoEmpty_SI         : in std_logic;

	-- Input FIFO control lines
	InFifoRead_SO : out std_logic;
	
	-- USB FIFO control lines
	USBFifoChipSelect_SBO     : out std_logic;
	USBFifoWrite_SBO          : out std_logic;
	USBFifoPktEnd_SBO         : out std_logic;
	USBFifoAddress_DO        : out std_logic_vector(1 downto 0));
end fifoStatemachine;

architecture Behavioral of fifoStatemachine is
  type state is (stIdle, stSetupDelay1, stSetupDelay2, stSetupDelay3, stSetupWrite, stWrite);
  -- present and next state
  signal State_DP, State_DN : state;

  -- FIFO addresse: always write to thread 0, which is the output socket for FPGA->FX3 USB.
  constant EP_FIFO : std_logic_vector := "00";
	begin
	-- calculate next state and outputs
	  p_memless : process (State_DP, USBFifoThread0Full_SI, USBFifoThread0AlmostFull_SI, USBFifoThread1Full_SI, USBFifoThread1AlmostFull_SI, InFifoEmpty_SI, Run_SI)
	  begin  -- process p_memless
		-- default assignements: stay in present state, don't change address in
		-- FifoAddress register, write registers for transfers
		State_DN                     <= State_DP;

		USBFifoChipSelect_SBO        <= '0'; -- Always keep chip selected (active-low).
		USBFifoWrite_SBO             <= '1';
		USBFifoPktEnd_SBO            <= '1';
		USBFifoAddress_DO           <= EP_FIFO;

		InFifoRead_SO <= '0'; -- Don't read from input FIFO until we know we can write.
	
		case State_DP is
		  when stIdle =>
			if InFifoEmpty_SI = '0' and USBFifoThread0Full_SI = '0' and Run_SI = '1' then
			  State_DN <= stSetupDelay1;
			end if;
		 
		 -- Wait three cycles so that the USBFifoFull flag has time to assert itself.
		  when stSetupDelay1 =>
				State_DN <= stSetupDelay2;
			  
		  when stSetupDelay2 =>
				State_DN <= stSetupDelay3;
			  
		  when stSetupDelay3 =>
				State_DN <= stSetupWrite;

		  when stSetupWrite =>
			-- Check now, after delaying, that the FIFO is still free.
			if USBFifoThread0Full_SI = '0' then
			  State_DN <= stWrite;
			  InFifoRead_SO <= '1';
			else
			  State_DN <= stIdle;
			end if;
		  
		  -- Write the data to the USB FIFO continuously, until either the input FIFO is
		  -- empty or the USB one is full.
		  when stWrite =>
			-- Check that there still is data to send.
			if  InFifoEmpty_SI = '1' then
			  State_DN <= stIdle;
			end if;
			
			-- Check that we're reaching the end of the FIFO using the watermark flag (almost full).
			-- This way we know exactly how much space is left and can start to limit the number of
			-- writes, without having to check the FULL flag, which has a 3-cycle delay.
			if USBFifoThread0AlmostFull_SI = '1' then
				State_DN <= stIdle; -- Single cycle access mode.
			end if;

			-- Execute write and continue to read next data chunk.
			USBFifoWrite_SBO <= '0';
			InFifoRead_SO <= '1';
				
		  when others => null;
		end case;

	  end process p_memless;

	  -- Change state on clock edge (synchronous).
	  p_memoryzing : process (Clock_CI, Reset_RBI)
	  begin  -- process p_memoryzing
		if Reset_RBI = '0' then             -- asynchronous reset (active low)
		  State_DP <= stIdle;
		elsif rising_edge(Clock_CI) then
		  State_DP <= State_DN;
		end if;
	  end process p_memoryzing;
	end Behavioral;
