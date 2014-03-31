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
	FX2FifoChipSelectxEBO     : out std_logic;
    FX2FifoWritexEBO          : out std_logic;
    FX2FifoPktEndxSBO         : out std_logic;
    FX2FifoAddressxDO         : out std_logic_vector(1 downto 0);

    -- short paket stuff
    IncEventCounterxSO         : out std_logic;
    ResetEventCounterxSO       : out std_logic;
    ResetEarlyPaketTimerxSO    : out std_logic;
    
    -- short paket timer overflow
    EarlyPaketTimerOverflowxSI : in  std_logic);
end fifoStatemachine;

architecture Behavioral of fifoStatemachine is
  type state is (stIdle, stEarlyPaket1, stSetupWrite1, stSetupWrite2, stWrite);

  -- present and next state
  signal StatexDP, StatexDN : state;


  -- fifo addresses
  constant EP_FIFO : std_logic_vector := "00";

   -- counter for FULL flag delay
   signal FullCountxDP, FullCountxDN : std_logic_vector(3 downto 0);  
begin

-- calculate next state and outputs
  p_memless : process (StatexDP, FullCountxDP, FX2FifoInFullxSBI,  EarlyPaketTimerOverflowxSI, FifoEmptyxSI, RunxSI)
  begin  -- process p_memless
    -- default assignements: stay in present state, don't change address in
    -- FifoAddress register, no Fifo transaction, write registers, don't reset the counters
    StatexDN                     <= StatexDP;
	FullCountxDN                 <= (others => '0');

	FX2FifoChipSelectxEBO        <= '0'; -- Always keep chip selected (active-low).
    FX2FifoWritexEBO             <= '1';
    FX2FifoPktEndxSBO            <= '1';

    IncEventCounterxSO        <= '0';
    ResetEventCounterxSO      <= '0';
    ResetEarlyPaketTimerxSO   <= '0';
    FX2FifoAddressxDO         <= EP_FIFO;

    FifoReadxEO <= '0';
    
    FifoTransactionxSO <= '1';          -- is zero only in idle state

    case StatexDP is
      when stIdle =>
        if EarlyPaketTimerOverflowxSI = '1' and FX2FifoInFullxSBI = '1' and RunxSI = '1' then
          -- we haven't commited a paket for a long time
          StatexDN <= stEarlyPaket1;
        elsif FifoEmptyxSI = '0' and FX2FifoInFullxSBI = '1' and RunxSI = '1' then
          StatexDN <= stSetupWrite1;
        end if;

        FifoTransactionxSO        <= '0';  -- no fifo transaction running
     
	 when stEarlyPaket1 =>
	   -- ordering the FX2 to send a paket
       -- even if it's not full, need two
       -- states to ensure setup time of
       -- fifoaddress 
        StatexDN                  <= stIdle;
        ResetEarlyPaketTimerxSO   <= '1';
        ResetEventCounterxSO      <= '1';
        FX2FifoPktEndxSBO         <= '0';

      when stSetupWrite1 =>
	    -- Check that we can really write because the FX3 FIFO is not full.
	    -- There is a 3 cycle latency on the flag upating!
		if FullCountxDP = 4 then
		  FullCountxDN <= (others => '0');
		  StatexDN <= stSetupWrite2;
		else
		  FullCountxDN <= FullCountxDP + 1;
		end if;

	  when stSetupWrite2 =>
	    -- Check now, after delaying, that the FIFO is still free.
	    if FX2FifoInFullxSBI = '1' then
          StatexDN <= stWrite;
          FifoReadxEO <= '1';
		else
		  StatexDN <= stIdle;
		end if;
      
	  when stWrite =>             -- write the address to the fifo
        if  FifoEmptyxSI = '1' then
          StatexDN <= stIdle;
        end if;
        FX2FifoWritexEBO <= '0';
        FifoReadxEO <= '1';
        IncEventCounterxSO <= '1';
            
      when others => null;
    end case;

  end process p_memless;

  -- change state on clock edge
  p_memoryzing : process (ClockxCI, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      StatexDP <= stIdle;
	  FullCountxDP <= (others => '0');
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      StatexDP <= StatexDN;
	  FullCountxDP <= FullCountxDN;
    end if;
  end process p_memoryzing;
  
end Behavioral;
