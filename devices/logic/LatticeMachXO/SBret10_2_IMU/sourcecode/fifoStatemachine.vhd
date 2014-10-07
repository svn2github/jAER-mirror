--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    13:58:57 10/24/05
-- Design Name:    
-- Module Name:    fifoStatemachine - Behavioral
-- Project Name:   USBAERmini2
-- Target Device:  
-- Tool versions:  
-- Description: handles the fifo transactions with the FX2
--
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fifoStatemachine is
	port (
		ClockxCI               : in  std_logic;
		ResetxRBI              : in  std_logic;
		RunxSI              : in  std_logic;

		-- signal if transaction is going on
		FifoTransactionxSO         : out std_logic;

		-- fifo flags
		FX2FifoInFullxSBI         : in  std_logic;
		FifoEmptyxSI              : in std_logic;

		-- fifo control lines
		FifoReadxEO : out std_logic;
		--H
		FifoWritexEI : in std_logic;
		FifoCountxDO : out std_logic_vector(9 downto 0); 
		--H
		
		FX2FifoWritexEBO          : out std_logic;
		FX2FifoPktEndxSBO         : out std_logic;
		FX2FifoAddressxDO         : out std_logic_vector(1 downto 0);

		-- short paket stuff
		IncEventCounterxSO         : out std_logic;
		ResetEventCounterxSO       : out std_logic;
		ResetEarlyPaketTimerxSO    : out std_logic;
		
		-- short paket timer overflow
		EarlyPaketTimerOverflowxSI : in  std_logic
	);
end fifoStatemachine;

architecture Behavioral of fifoStatemachine is
	type state is (stIdle, stEarlyPaket1, stEarlyPaket2, stSetupWrite1, stWrite);

	-- present and next state
	signal StatexDP, StatexDN : state;
	--H
	signal FifoCountxDN, FifoCountxDP : std_logic_vector(9 downto 0); -- Fifo Word Counter
	constant fifo_depth : std_logic_vector(9 downto 0) := "1111111111"; -- Fifo Depth --CHECK! THIS MIGHT BE WRONG!
	--H 

	-- fifo addresses
	constant EP2             : std_logic_vector := "00";
	constant EP6             : std_logic_vector := "10";

begin

	-- calculate next state and outputs
	p_memless : process (StatexDP, FX2FifoInFullxSBI,  EarlyPaketTimerOverflowxSI, FifoEmptyxSI, RunxSI, FifoWritexEI, FifoCountxDP) --H
	begin  -- process p_memless
		-- default assignements: stay in present state, don't change address in
		-- FifoAddress register, no Fifo transaction, write registers, don't reset the counters
		StatexDN			<= StatexDP;
		FX2FifoWritexEBO    <= '1';
		FX2FifoPktEndxSBO   <= '1';

		IncEventCounterxSO		<= '0';
		ResetEventCounterxSO	<= '0';
		ResetEarlyPaketTimerxSO <= '0';
		FX2FifoAddressxDO		<= EP6;

		FifoReadxEO <= '0';
		
		FifoTransactionxSO <= '1'; -- is zero only in idle state

		
		--H CHECK WHAT DO DO WITH EARLY PACKET!!!!!
		--H Fifo Default Assignemtn
		FifoCountxDO <= FifoCountxDP;
		FifoCountxDN <= FifoCountxDP;  
		
		--H Fifo Counter Increment
		if FifoWritexEI = '1' and FifoCountxDP /= fifo_depth then
			FifoCountxDN <= FifoCountxDP+1;  
		end if;
		--H	

		case StatexDP is
			when stIdle =>
				if EarlyPaketTimerOverflowxSI = '1' and FX2FifoInFullxSBI = '1' and RunxSI = '1' then
					-- we haven't commited a paket for a long time
					StatexDN <= stEarlyPaket1;
				elsif FifoEmptyxSI = '0' and FX2FifoInFullxSBI = '1' and RunxSI = '1' then
					  StatexDN <= stSetupWrite1;
				end if;
				FifoTransactionxSO <= '0'; -- no fifo transaction running
		
			when stEarlyPaket1 => -- ordering the FX2 to send a paket even if it's not full, need two
                                  -- states to ensure setup time of fifoaddress 
				StatexDN                  <= stEarlyPaket2;
				ResetEarlyPaketTimerxSO   <= '1';
				ResetEventCounterxSO      <= '1';
				FX2FifoPktEndxSBO         <= '0';
			when stEarlyPaket2 => -- added by Alejandro. Not 100% sure if needed.
				StatexDN                  <= stIdle;
				ResetEarlyPaketTimerxSO   <= '1';
				ResetEventCounterxSO      <= '1';
				FX2FifoPktEndxSBO         <= '0';

			when stSetupWrite1 =>
				StatexDN <= stWrite;
				FifoReadxEO <= '1';
				--H Decrement FifoCount if it's not empty 
				if FifoCountxDP = "0000000000" then
					FifoCountxDN <= FifoCountxDP-1; 
				end if;
				--H 

			-- when stSetupWrite2 =>
			-- 		StatexDN <= stWrite;
			--    	FifoReadxEO <= '1';
			
			when stWrite => -- write the address to the fifo
				if  FifoEmptyxSI = '1' then
					StatexDN <= stIdle;
				end if;
				FX2FifoWritexEBO <= '0';
				FifoReadxEO <= '1';
				--H Decrement FifoCount if it's not empty 
				if FifoCountxDP = "0000000000" then
					FifoCountxDN <= FifoCountxDP-1; 
				end if;
				--H 

				IncEventCounterxSO <= '1';
            
			when others => null;
		
		end case;

	end process p_memless;

	-- change state on clock edge
	p_memoryzing : process (ClockxCI, ResetxRBI)
	begin  -- process p_memoryzing
		if ResetxRBI = '0' then             -- asynchronous reset (active low)
			StatexDP <= stIdle;
			FifoCountxDP <= (others => '0'); --H
		elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
			StatexDP <= StatexDN;
			FifoCountxDP <= FifoCountxDN; --H
		end if;
	end process p_memoryzing;
  
end Behavioral;
