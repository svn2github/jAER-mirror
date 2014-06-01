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

entity ADCStateMachine is

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
    ExtTriggerxEI         : in    std_logic;
    CDVSTestSRRowInxSO    : out   std_logic;
    CDVSTestSRRowClockxSO : out   std_logic;
    CDVSTestSRColInxSO    : out   std_logic;
    CDVSTestSRColClockxSO : out   std_logic;
    CDVSTestColMode0xSO   : out   std_logic;
    CDVSTestColMode1xSO   : out   std_logic;
	CDVSTestApsTxGatexSO   : out   std_logic;
    ADCStateOutputLEDxSO  : out   std_logic);
end ADCStateMachine;

architecture Behavioral of ADCStateMachine is
  type ColState is (stIdle, stReset, stReleaseReset, stReadReset, stCountReset, stNextReset, stIntegrate, stStopIntegrate, stReadSignal, stCountSignal, stNextSignal, stWaitFrame);
  type RowState is (stIdle, stFeedRow, stInit, stRead, stWrite, stRowDone, stColumnDone,stColSettle);

  signal ResetxRB	: std_logic;

  -- present and next state
  signal StateColxDP, StateColxDN : ColState;
  signal StateRowxDP, StateRowxDN : RowState;
  signal ADCwordWritexE           : std_logic;
  signal ClockxC                  : std_logic;
  signal StateClockxC 			  : std_logic;

  -- SR output copies
  signal CDVSTestSRRowInxS, CDVSTestSRRowClockxS, CDVSTestSRColInxS, CDVSTestSRColClockxS : std_logic;

-- clock this circuit with half the
-- input clock frequency: 15 MHz

  signal ADCoutMSBxS              : std_logic_vector(3 downto 0);
  signal StartPixelxS             : std_logic;
  signal StartColxS : std_logic;
  signal StartRowxSN, StartRowxSP : std_logic;

  -- timestamp reset register
  signal DividerColxDP, DividerColxDN : std_logic_vector(32 downto 0);
  signal DividerRowxDP, DividerRowxDN : std_logic_vector(16 downto 0);
  signal ExposureTxD : std_logic_vector(25 downto 0);
  signal ExposurexD : std_logic_vector(25 downto 0);
  signal FramePeriodxD : std_logic_vector(25 downto 0);

  signal   CountRowxDN, CountRowxDP           : std_logic_vector(7 downto 0);
  signal   CountColxDN, CountColxDP           : std_logic_vector(17 downto 0);
  signal   DoReadxS, ReadDonexS 		  : std_logic;
  signal   ReadCyclexS						  : std_logic_vector(1 downto 0); -- "00" A, "01" B, "10" C
  signal   ColModexD                          : std_logic_vector(1 downto 0);  -- "00" Null, "01" Sel A, "10" Sel B, "11" Res A    
  signal   TxGatexE							  : std_logic;

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
  
  StartColxS <= '1' when CountColxDP <= 1 else '0';
  StartPixelxS    <= StartRowxSP and StartColxS;
  ADCoutxDO       <= ADCoutMSBxS(3 downto 0) & ADCwordxDI(9 downto 0);
  ADCoutMSBxS     <= '1' & StartPixelxS & ReadCyclexS;
  ADCstbyxEO	<= '0';
  ADCoexEBO		<= '0';

  CDVSTestColMode0xSO <= ColModexD(0);
  CDVSTestColMode1xSO <= ColModexD(1) or ExtTriggerxEI;

  ADCStateOutputLEDxSO <= StartPixelxS;
  --ADCStateOutputLEDxSO <= '1' when StateColxDP = stIdle and StateRowxDP = stIdle else '0'
  
  FramePeriodxD <= FramePeriodxDI & "0000000001";
  ExposureTxD <= ExposurexDI & "0000000001";
  ExposurexD <= "0000000" & ExposurexDI & "000";

  CDVSTestApsTxGatexSO <= not TxGatexE;

-- calculate col next state and outputs
  p_col : process (StateColxDP, DividerColxDP, ExposurexDI, RunADCxSI, CountColxDP, ReadDonexS, FramePeriodxD, ResSettlexDI, RowSettlexDI, ColSettlexDI, ExposureTxD)
  begin  -- process p_memless
    -- default assignements: stay in present state

    StateColxDN          <= StateColxDP;
    DividerColxDN        <= DividerColxDP;
    CDVSTestSRColClockxS <= '0';
    CDVSTestSRColInxS    <= '0';
    ColModexD            <= "00";
	ReadCyclexS			 <= "11";

    DoReadxS 	<= '0';
	TxGatexE	<= '1';
    CountColxDN <= CountColxDP;

    case StateColxDP is
      when stIdle =>
        if RunADCxSI = '1' then
            StateColxDN <= stReset;
        end if;
        DividerColxDN        <= (others => '0');
        CountColxDN          <= (others => '0');
        CDVSTestSRColInxS    <= '0';
        CDVSTestSRColClockxS <= '0';
        DoReadxS             <= '0';
        ColModexD            <= "11";
		TxGatexE			 <= '0';
      when stReset =>
        CDVSTestSRColClockxS <= '0';
        CDVSTestSRColInxS    <= '0';
        if DividerColxDP >= ResSettlexDI then
          StateColxDN   <= stReleaseReset;
          DividerColxDN <= (others => '0');
        else
          DividerColxDN <= DividerColxDP + 1;
        end if;
        ColModexD 			 <= "11";
		TxGatexE			 <= '1';
      when stReleaseReset =>
        StateColxDN <= stReadReset;
		CDVSTestSRColClockxS <= '1';
        CDVSTestSRColInxS    <= '1';
		ColModexD            <= "00";
		TxGatexE			 <= '0';
      when stReadReset =>
	    --if CountColxDP = 0 then
		  --StateColxDN   <= stCountReset;
		  --DoReadxS 			 <= '0';
		--elsif ReadDonexS = '1' then
		if ReadDonexS = '1' then
          StateColxDN   <= stCountReset;
          DividerColxDN <= (others => '0');
		  DoReadxS 			 <= '0';
		else
		  DoReadxS 			 <= '1';
        end if;
        CDVSTestSRColClockxS <= '0';
        CDVSTestSRColInxS    <= '0';
        ReadCyclexS          <= "00";
		ColModexD            <= "10";
		TxGatexE			 <= '0';
	  when stCountReset =>
        DividerColxDN <= (others => '0');
        CountColxDN   <= CountColxDP + 1;
        DoReadxS      <= '0';
        if CountColxDP >= SizeX+2 then
          StateColxDN <= stIntegrate;
        else
          StateColxDN <= stNextReset;
        end if;
        ColModexD            <= "11";
		TxGatexE			 <= '0';
      when stNextReset =>
		CDVSTestSRColClockxS <= '1';
        CDVSTestSRColInxS    <= '0';
        DoReadxS    		 <= '0';
        StateColxDN 		 <= stReadReset;
        ColModexD            <= "00";
		TxGatexE			 <= '0';
	  when stIntegrate =>
		if DividerColxDP >= ExposurexD then
          StateColxDN   <= stStopIntegrate;
          DividerColxDN <= (others => '0');
        else
          DividerColxDN <= DividerColxDP + 1;
        end if;
		CountColxDN          <= (others => '0');
		ColModexD            <= "00";
		TxGatexE			 <= '1';
	  when stStopIntegrate =>
	    CDVSTestSRColClockxS <= '1';
        CDVSTestSRColInxS    <= '1';
		StateColxDN   <= stReadSignal;
		ColModexD            <= "00";
		TxGatexE			 <= '0';
      when stReadSignal =>
        --if CountColxDP = 0 then
		  --StateColxDN   	<= stCountSignal;
		  --DoReadxS 		<= '0';
		--elsif ReadDonexS = '1' then
		if ReadDonexS = '1' then
          DoReadxS <= '0';
          StateColxDN   <= stCountSignal;
          DividerColxDN <= (others => '0');
        else
		  DoReadxS 			 <= '1';
        end if;
        CDVSTestSRColClockxS <= '0';
        CDVSTestSRColInxS    <= '0';
        ReadCyclexS          <= "01";
		ColModexD            <= "10";
		TxGatexE			 <= '0';
	  when stCountSignal =>
        DividerColxDN <= (others => '0');
        CountColxDN   <= CountColxDP + 1;
        DoReadxS      <= '0';
        if CountColxDP >= SizeX+2 then
          StateColxDN <= stWaitFrame;
        else
          StateColxDN <= stNextSignal;
        end if;
        ColModexD            <= "00";
		TxGatexE			 <= '0';
      when stNextSignal =>
	    CDVSTestSRColClockxS <= '1';
        CDVSTestSRColInxS    <= '0';
        DoReadxS    		 <= '0';
        StateColxDN 		 <= stReadSignal;
        ColModexD            <= "00";
		TxGatexE			 <= '0';
      when stWaitFrame =>
        if DividerColxDP >= FramePeriodxD then
          StateColxDN   <= stIdle;
          DividerColxDN <= (others => '0');
        else
          DividerColxDN <= DividerColxDP + 1;
        end if;
		--StateColxDN   <= stIdle;
        ColModexD <= "11";
		
      when others => null;
    end case;

  end process p_col;

-- calculate next Row state and outputs
  p_row : process (DividerRowxDP, CountRowxDP, RowSettlexDI, StateRowxDP, DoReadxS, StateColxDP, ReadCyclexS, ColSettlexDI)
  begin  -- process p_row
    -- default assignements: stay in present state

    StateRowxDN          <= StateRowxDP;
    DividerRowxDN        <= DividerRowxDP;
    CDVSTestSRRowClockxS <= '0';
    CDVSTestSRRowInxS    <= '0';
	ReadDonexS 			<= '0';
    RegisterWritexEO 	<= '0';
    ADCwordWritexE   	<= '0';
	StartRowxSN 		<= '0';

    CountRowxDN <= CountRowxDP;

    case StateRowxDP is
      when stIdle =>
        if DoReadxS = '1' and (StateColxDP = stReadReset or StateColxDP = stReadSignal) then
          StateRowxDN <= stFeedRow;
        end if;
        DividerRowxDN <= (others => '0');
        CountRowxDN   <= (others => '0');
        ReadDonexS    <= '0';
      when stFeedRow =>
        CDVSTestSRRowClockxS <= '1';
        CDVSTestSRRowInxS    <= '1';
        StateRowxDN          <= stColSettle;
        if ReadCyclexS = "00" then
          StartRowxSN <= '1';
        end if;
      when stColSettle =>
        if DividerRowxDP >= ColSettlexDI then
            StateRowxDN   <= stInit;
            DividerRowxDN <= (others => '0');
        else
          DividerRowxDN <= DividerRowxDP + 1;
        end if;
		if StartRowxSP = '1' then
			StartRowxSN <= '1';
		end if;
      when stInit =>
        if DividerRowxDP >= RowSettlexDI then
          StateRowxDN   <= stWrite;
          DividerRowxDN <= (others => '0');
        else
          DividerRowxDN <= DividerRowxDP + 1;
        end if;
		if StartRowxSP = '1' then
			StartRowxSN <= '1';
		end if;
      when stWrite =>
		if CountColxDP > 0 and CountColxDP <= sizeX and CountRowxDP < sizeY then
			RegisterWritexEO <= '1';
		else
			RegisterWritexEO <= '0';
		end if;
        DividerRowxDN <= (others => '0');
        StateRowxDN   <= stRowDone;
      when stRowDone =>
        CDVSTestSRRowClockxS <= '1';
        CDVSTestSRRowInxS    <= '0';
        StartRowxSN          <= '0';
        if CountRowxDP >= SizeY-1 then
          StateRowxDN <= stColumnDone;
        else
          StateRowxDN <= stInit;
          CountRowxDN <= CountRowxDP + 1;
        end if;
        DividerRowxDN <= (others => '0');
      when stColumnDone =>
        readDonexS  <= '1';
        if DoReadxS = '0' then
          StateRowxDN <= stIdle;
        end if;   
        
      when others => null;
    end case;

  end process p_row;

  -- change state on clock edge
  p_memoryzing : process (StateClockxC, ResetxRB)
  begin  -- process p_memoryzing
    if ResetxRB = '0' then             -- asynchronous reset (active low)
      StateColxDP   <= stIdle;
      StateRowxDP   <= stIdle;
      DividerColxDP <= (others => '0');
      DividerRowxDP <= (others => '0');
      StartRowxSP   <= '0';
      CountColxDP   <= (others => '0');
      CountRowxDP   <= (others => '0');
    elsif StateClockxC'event and StateClockxC = '1' then  -- rising clock edge   
      StateColxDP   <= StateColxDN;
      StateRowxDP   <= StateRowxDN;
      DividerColxDP <= DividerColxDN;
      DividerRowxDP <= DividerRowxDN;
      StartRowxSP   <= StartRowxSN;
      CountRowxDP   <= CountRowxDN;
      CountColxDP   <= CountColxDN;
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
