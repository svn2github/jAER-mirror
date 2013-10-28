--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    13:58:57 10/24/05
-- Design Name:    
-- Module Name:    ADCStatemachine - Behavioral
-- Project Name:   SBRet10
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

entity ADCStateMachineTest is

  port (
    ClockxCI              : in    std_logic;
    ADCclockxCO           : out   std_logic;
    ResetxRBI             : in    std_logic;
    ADCwordxDI            : in    std_logic_vector(9 downto 0);
    ADCoutxDO             : out   std_logic_vector(13 downto 0);
    ADCstbyxEO            : out   std_logic;
    ADCoexEBO             : out   std_logic;
	ADCovrxSI			  : in	  std_logic;
    RegisterWritexEO      : out   std_logic;
    SRLatchxEI            : in    std_logic;
    RunADCxSI             : in    std_logic;
    ExposurexDI          : in    std_logic_vector(15 downto 0);
    ColSettlexDI          : in    std_logic_vector(15 downto 0);
    RowSettlexDI          : in    std_logic_vector(15 downto 0);
    ResSettlexDI          : in    std_logic_vector(15 downto 0);
    FramePeriodxDI        : in    std_logic_vector(15 downto 0);
    TestPixelxEI          : in    std_logic;
    ExtTriggerxEI         : in    std_logic;
    CDVSTestSRRowInxSO    : out   std_logic;
    CDVSTestSRRowClockxSO : out   std_logic;
    CDVSTestSRColInxSO    : out   std_logic;
    CDVSTestSRColClockxSO : out   std_logic;
    CDVSTestColMode0xSO   : out   std_logic;
    CDVSTestColMode1xSO   : out   std_logic;
	CDVSTestApsTxGatexSO   : out   std_logic;
    ADCStateOutputLEDxSO  : out   std_logic);
end ADCStateMachineTest;

architecture Behavioral of ADCStateMachineTest is
  type ColState is (stIdle, stResetT, stInitAT, stReadAT, stInitBT, stReadBT, stWaitT);

  signal ResetxRB	: std_logic;

  -- present and next state
  signal StateColxDP, StateColxDN : ColState;
  signal ADCwordWritexE           : std_logic;
  signal ClockxC                  : std_logic;
  signal StateClockxC 			  : std_logic;

  -- SR output copies
  signal CDVSTestSRRowInxS, CDVSTestSRRowClockxS, CDVSTestSRColInxS, CDVSTestSRColClockxS : std_logic;

-- clock this circuit with half the
-- input clock frequency: 15 MHz

  signal ADCoutMSBxS              : std_logic_vector(3 downto 0);
  signal StartPixelxS             : std_logic;
  signal StartColxSN, StartColxSP : std_logic;
  signal StartRowxSN, StartRowxSP : std_logic;

  -- timestamp reset register
  signal DividerColxDP, DividerColxDN : std_logic_vector(32 downto 0);
  signal ExposureTxD : std_logic_vector(25 downto 0);
  signal FramePeriodxD : std_logic_vector(25 downto 0);

  signal   NoBxS, DoReadxS, ReadDonexS 		  : std_logic;
  signal   ReadCyclexS						  : std_logic_vector(1 downto 0); -- "00" A, "01" B, "10" C
  signal   ColModexD                          : std_logic_vector(1 downto 0);  -- "00" Null, "01" Sel A, "10" Sel B, "11" Res A             

--  signal FrameEndxS : std_logic_vector(17 downto 0);

  constant SizeX : integer := 240;
  constant SizeY : integer := 180;

begin
  
  ResetxRB <= ResetxRBI and not ExtTriggerxEI;
  
  ClockxC <= ClockxCI;  
  StateClockxC <= ClockxC;
  ADCclockxCO  <= not ClockxC;
  
  CDVSTestSRRowInxSO <= CDVSTestSRRowInxS;
  CDVSTestSRColInxSO <= CDVSTestSRColInxS;
  CDVSTestApsTxGatexSO <= '0';

  StartPixelxS    <= StartColxSP and StartRowxSP;
  ADCoutxDO       <= ADCoutMSBxS(3 downto 0) & ADCwordxDI(9 downto 0);
  ADCoutMSBxS     <= '1' & StartPixelxS & ReadCyclexS;
  ADCstbyxEO	<= '0';
  ADCoexEBO		<= '0';

  CDVSTestColMode0xSO <= ColModexD(0);
  CDVSTestColMode1xSO <= ColModexD(1) or ExtTriggerxEI;

  ADCStateOutputLEDxSO <= StartPixelxS;
  --ADCStateOutputLEDxSO <= '1' when StateColxDP = stIdle and StateRowxDP = stIdle else '0';
  
  FramePeriodxD <= FramePeriodxDI & "0000000001";
  ExposureTxD <= ExposurexDI & "0000000001";

-- calculate col next state and outputs
  p_col : process (StateColxDP, DividerColxDP, ExposurexDI, RunADCxSI, StartColxSP, ReadDonexS, FramePeriodxD, ResSettlexDI)
  begin  -- process p_memless
    -- default assignements: stay in present state

    StateColxDN          <= StateColxDP;
    DividerColxDN        <= DividerColxDP;
    CDVSTestSRColClockxS <= '0';
    CDVSTestSRColInxS    <= '0';
    ColModexD            <= "00";
	ReadCyclexS			 <= "11";

    DoReadxS <= '0';
    StartColxSN <= StartColxSP;

    case StateColxDP is
      when stIdle =>
        if RunADCxSI = '1' then
            StateColxDN <= stResetT;
        end if;
        DividerColxDN        <= (others => '0');
        CDVSTestSRColInxS    <= '1';
        CDVSTestSRColClockxS <= '0';
        DoReadxS             <= '0';
        ColModexD            <= "00";
        NoBxS                <= '1';	
	  when stResetT =>
        ColModexD <= "10";
        if DividerColxDP >= ResSettlexDI then
          StateColxDN   <= stInitAT;
          DividerColxDN <= (others => '0');
        else
          DividerColxDN <= DividerColxDP + 1;
        end if;
      when stInitAT =>
        ColModexD <= "00";
        if DividerColxDP >= ColSettlexDI then
          StateColxDN   <= stReadAT;
          DividerColxDN <= (others => '0');
        else
          DividerColxDN <= DividerColxDP + 1;
        end if;
      when stReadAT =>
        ColModexD <= "01";
        if DividerColxDP >= RowSettlexDI then
          StateColxDN   <= stInitBT;
          DividerColxDN <= (others => '0');
        else
          DividerColxDN <= DividerColxDP + 1;
        end if;
      when stInitBT =>
        ColModexD <= "00";
        if DividerColxDP >= ExposureTxD then
          StateColxDN   <= stReadBT;
          DividerColxDN <= (others => '0');
        else
          DividerColxDN <= DividerColxDP + 1;
        end if;
      when stReadBT =>
        ColModexD <= "01";
        if DividerColxDP >= RowSettlexDI then
          StateColxDN   <= stWaitT;
          DividerColxDN <= (others => '0');
	    else
          DividerColxDN <= DividerColxDP + 1;
        end if;
      when stWaitT =>
        ColModexD <= "00";
        if DividerColxDP >= FramePeriodxD then
          StateColxDN   <= stIdle;
          DividerColxDN <= (others => '0');
        else
          DividerColxDN <= DividerColxDP + 1;
        end if;
		
      when others => null;
    end case;

  end process p_col;

  -- change state on clock edge
  p_memoryzing : process (StateClockxC, ResetxRB)
  begin  -- process p_memoryzing
    if ResetxRB = '0' then             -- asynchronous reset (active low)
      StateColxDP   <= stIdle;
      DividerColxDP <= (others => '0');
      StartColxSP   <= '0';
      StartRowxSP   <= '0';
    elsif StateClockxC'event and StateClockxC = '1' then  -- rising clock edge   
      StateColxDP   <= StateColxDN;
      DividerColxDP <= DividerColxDN;
      StartColxSP   <= StartColxSN;
      StartRowxSP   <= StartRowxSN;
    end if;
  end process p_memoryzing;

  -- purpose: create clock
  -- type   : sequential
  -- inputs : clockxci,
  -- outputs: 
--  p_clock : process (ClockxCI, ResetxRBI)
--  begin  -- process 
--    if ResetxRBI = '0' then
--      ClockxC <= '0';
--    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
--      ClockxC <= not ClockxC;
--   end if;
--  end process p_clock;

  -- 90 degree phase shifted clock for shift registers on chip
  p_clock_chip : process (ClockxC, ResetxRB)
  begin  -- process 
    if ResetxRB = '0' then
      CDVSTestSRRowClockxSO <= '0';
      CDVSTestSRColClockxSO <= '0';
    elsif ClockxC'event and ClockxC = '0' then  -- falling clock edge
      CDVSTestSRRowClockxSO <= CDVSTestSRRowClockxS;
      CDVSTestSRColClockxSO <= CDVSTestSRColClockxS;
    end if;
  end process p_clock_chip;
  
end Behavioral;
