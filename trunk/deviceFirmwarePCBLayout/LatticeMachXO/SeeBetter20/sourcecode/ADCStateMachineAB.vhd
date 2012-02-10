--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    13:58:57 10/24/05
-- Design Name:    
-- Module Name:    ADCStatemachine - Behavioral
-- Project Name:   cDVSTest20
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

entity ADCStateMachineAB is

  port (
    ClockxCI              : in    std_logic;
    ADCclockxCO           : out   std_logic;
    ResetxRBI             : in    std_logic;
    ADCwordxDIO           : inout std_logic_vector(11 downto 0);
    ADCoutxDO             : out   std_logic_vector(13 downto 0);
    ADCwritexEBO          : out   std_logic;
    ADCreadxEBO           : out   std_logic;
    ADCconvstxEBO         : out   std_logic;
    ADCbusyxSI            : in    std_logic;
    RegisterWritexEO      : out   std_logic;
    SRLatchxEI            : in    std_logic;
    RunADCxSI             : in    std_logic;
    ADCconfigxDI          : in    std_logic_vector(11 downto 0);
    ExposurexDI           : in    std_logic_vector(15 downto 0);
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
    ADCStateOutputLEDxSO  : out   std_logic);
end ADCStateMachineAB;

architecture Behavioral of ADCStateMachineAB is
  type ColState is (stIdle, stFeedReset1, stFeedReset2, stFeedRead , stReset, stReleaseReset, stReadA, stSwitch, stReadB, stColumnCount, stFeedNull, stWaitFrame, stResetT, stInitAT, stReadAT, stInitBT, stReadBT, stWaitT);
  type RowState is (stIdle, stStartup, stLatch, stWriteConfig, stFeedRow, stInit, stStartConversion, stBusy, stRead, stWrite, stRowDone, stColumnDone,stColSettle);


  -- present and next state
  signal StateColxDP, StateColxDN : ColState;
  signal StateRowxDP, StateRowxDN : RowState;
  signal ADCconfigWordxS          : std_logic_vector(11 downto 0);
  signal ADCwordWritexE           : std_logic;
  signal ClockxC                  : std_logic;

  -- SR output copies
  signal CDVSTestSRRowInxS, CDVSTestSRRowClockxS, CDVSTestSRColInxS, CDVSTestSRColClockxS : std_logic;

-- clock this circuit with half the
-- input clock frequency: 15 MHz

  signal ADCoutMSBxS              : std_logic_vector(3 downto 0);
  signal StartPixelxS             : std_logic;
  signal StartColxSN, StartColxSP : std_logic;
  signal StartRowxSN, StartRowxSP : std_logic;
  signal ChannelxD                : std_logic_vector(1 downto 0);

  -- timestamp reset register
  signal DividerColxDP, DividerColxDN : std_logic_vector(32 downto 0);
  signal DividerRowxDP, DividerRowxDN : std_logic_vector(16 downto 0);

  constant configword                         : std_logic_vector(11 downto 0) := "000101100000";  --"100101101000";
  signal   CountRowxDN, CountRowxDP           : std_logic_vector(4 downto 0);
  signal   CountColxDN, CountColxDP           : std_logic_vector(17 downto 0);
  signal   IsAxS, NoBxS, DoReadxS, ReadDonexS : std_logic;
  signal   ColModexD                          : std_logic_vector(1 downto 0);  -- "00" Null, "01" Sel A, "10" Sel B, "11" Res A             

--  signal FrameEndxS : std_logic_vector(17 downto 0);

  constant SizeX : integer := 64;

begin
  
  CDVSTestSRRowInxSO <= CDVSTestSRRowInxS;
  CDVSTestSRColInxSO <= CDVSTestSRColInxS;

  StartPixelxS    <= StartColxSP and StartRowxSP;
  ADCconfigWordxS <= ADCconfigxDI;
  ADCoutxDO       <= ADCoutMSBxS(3 downto 1) & ADCwordxDIO(11 downto 1);
  ADCoutMSBxS     <= '1' & StartPixelxS & not IsAxS & '0';
  ChannelxD       <= ADCconfigWordxS(6 downto 5);

  CDVSTestColMode0xSO <= ColModexD(0);
  CDVSTestColMode1xSO <= ColModexD(1) or (ExtTriggerxEI and TestPixelxEI);

  ADCStateOutputLEDxSO <= '1' when StateColxDP = stIdle and StateRowxDP = stIdle else '0';

  with ADCwordWritexE select
    ADCwordxDIO <=
    configword      when '1',
    (others => 'Z') when others;


-- calculate col next state and outputs
  p_col : process (StateColxDP, DividerColxDP, ColSettlexDI, ExposurexDI, RunADCxSI, CountColxDP, StartColxSP, ReadDonexS, StateRowxDP, FramePeriodxDI, ResSettlexDI, RowSettlexDI, TestPixelxEI)
  begin  -- process p_memless
    -- default assignements: stay in present state

    StateColxDN          <= StateColxDP;
    DividerColxDN        <= DividerColxDP;
    CDVSTestSRColClockxS <= '0';
    CDVSTestSRColInxS    <= '0';
    ColModexD            <= "00";

    DoReadxS <= '0';
    StartColxSN <= StartColxSP;

    CountColxDN <= CountColxDP;

    case StateColxDP is
      when stIdle =>
        if StateRowxDP = stIdle then
          if RunADCxSI = '1' and TestPixelxEI = '0' then
            StateColxDN <= stFeedReset1;
            StartColxSN <= '1';
          elsif TestPixelxEI = '1' then
            StateColxDN <= stResetT;
          end if;
        end if;
        DividerColxDN        <= (others => '0');
        CountColxDN          <= (others => '0');
        CDVSTestSRColInxS    <= '1';
        CDVSTestSRColClockxS <= '0';
        DoReadxS             <= '0';
        ColModexD            <= "00";
        NoBxS                <= '1';
      when stFeedReset1 =>
        CDVSTestSRColClockxS <= '1';
        CDVSTestSRColInxS    <= '1';
        StateColxDN          <= stFeedReset2;
        ColModexD            <= "00";
      when stFeedReset2 =>
        CDVSTestSRColClockxS <= '0';
        CDVSTestSRColInxS    <= '1';
        StateColxDN          <= stFeedRead;
        ColModexD            <= "00";
      when stFeedRead =>
        CDVSTestSRColClockxS <= '1';
        CDVSTestSRColInxS    <= '1';
        StateColxDN          <= stReset;
        ColModexD            <= "00";
      when stReset =>
        CDVSTestSRColClockxS <= '0';
        CDVSTestSRColInxS    <= '0';
        if DividerColxDP >= ResSettlexDI then
          StateColxDN   <= stReleaseReset;
          DividerColxDN <= (others => '0');
        else
          DividerColxDN <= DividerColxDP + 1;
        end if;
        if CountColxDP < SizeX then
          ColModexD <= "11";
        else
          ColModexD <= "00";
        end if;
      when stReleaseReset =>
        StateColxDN <= stReadA;
        ColModexD   <= "00";
      when stReadA =>
        CDVSTestSRColClockxS <= '0';
        CDVSTestSRColInxS    <= '0';
        IsAxS                <= '1';
     
        DoReadxS <= '1';
        if ReadDonexS = '1' then
          DoReadxS <= '0';
          StateColxDN   <= stSwitch;
          DividerColxDN <= (others => '0');
        end if;
     
        if CountColxDP < SizeX then
          ColModexD <= "01";
        else
          ColModexD <= "00";
        end if;
      when stSwitch =>
        DoReadxS    <= '0';
        StateColxDN <= stReadB;
        ColModexD   <= "00";
      when stReadB =>
        IsAxS <= '0';
     
        DoReadxS <= '1';
        if ReadDonexS = '1' then
          DoReadxS <= '0';
          StateColxDN   <= stColumnCount;
          DividerColxDN <= (others => '0');
        end if;
     
        if NoBxS = '0' and CountColxDP > ExposurexDI + 1 and CountColxDP < ExposurexDI + 66 then
          ColModexD <= "10";
        else
          ColModexD <= "00";
        end if;
      when stColumnCount =>
        DividerColxDN <= (others => '0');
        CountColxDN   <= CountColxDP + 1;
        StartColxSN   <= '0';
        DoReadxS      <= '0';
        if CountColxDP > SizeX + ExposurexDI then
          StateColxDN <= stWaitFrame;
        elsif CountColxDP = ExposurexDI then
          StateColxDN <= stFeedRead;
          NoBxS       <= '0';
        else
          StateColxDN <= stFeedNull;
        end if;
        ColModexD <= "00";
      when stFeedNull =>
        CDVSTestSRColClockxS <= '1';
        CDVSTestSRColInxS    <= '0';
        StateColxDN          <= stReset;
        ColModexD            <= "00";
      when stWaitFrame =>
        if DividerColxDP >= FramePeriodxDI then
          StateColxDN   <= stIdle;
          DividerColxDN <= (others => '0');
        else
          DividerColxDN <= DividerColxDP + 1;
        end if;
        ColModexD <= "00";

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
        if DividerColxDP >= ExposurexDI then
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
        if TestPixelxEI = '0' then
          StateColxDN   <= stIdle;
          DividerColxDN <= (others => '0');
        elsif DividerColxDP >= FramePeriodxDI then
          StateColxDN   <= stResetT;
          DividerColxDN <= (others => '0');
        else
          DividerColxDN <= DividerColxDP + 1;
        end if;
      when others => null;
    end case;

  end process p_col;

-- calculate next Row state and outputs
  p_row : process (ClockxC, ADCbusyxSI, SRLatchxEI, DividerRowxDP, CountRowxDP, ResSettlexDI, RowSettlexDI, StateRowxDP, IsAxS, DoReadxS, StateColxDP, ExposurexDI, CountColxDP, NoBxS, ColSettlexDI)
  begin  -- process p_row
    -- default assignements: stay in present state

    StateRowxDN          <= StateRowxDP;
    DividerRowxDN        <= DividerRowxDP;
    CDVSTestSRRowClockxS <= '0';
    CDVSTestSRRowInxS    <= '0';

    CountRowxDN <= CountRowxDP;

    ReadDonexS <= '0';
    ADCwritexEBO     <= '1';
    ADCreadxEBO      <= '1';
    ADCconvstxEBO    <= '1';
    RegisterWritexEO <= '0';
    ADCwordWritexE   <= '0';
    ADCclockxCO      <= ClockxC;

    case StateRowxDP is
      when stStartup =>
        StateRowxDN    <= stWriteConfig;
        ADCwordWritexE <= '1';
        ADCwritexEBO   <= '0';
        ADCconvstxEBO  <= '1';
      when stWriteConfig =>
        ADCwordWritexE <= '1';
        StateRowxDN    <= stIdle;
        ADCconvstxEBO  <= '1';
      when stLatch =>
        if SRLatchxEI = '1' then
          StateRowxDN <= stStartup;
        end if;
        ADCwordWritexE <= '1';
        ADCconvstxEBO  <= '1';
      when stIdle =>
        ADCclockxCO <= '1';  -- switch off clock in idle state to-- safe power
        if DoReadxS = '1' and (StateColxDP = stReadA or StateColxDP = stReadB) then
          StateRowxDN <= stFeedRow;
        end if;
        DividerRowxDN <= (others => '0');
        ADCconvstxEBO <= '0';
        CountRowxDN   <= (others => '0');
        ReadDonexS    <= '0';
      when stFeedRow =>
        CDVSTestSRRowClockxS <= '1';
        CDVSTestSRRowInxS    <= '1';
        StateRowxDN          <= stColSettle;
        if IsAxS = '1' then
          StartRowxSN <= '1';
        else
          StartRowxSN <= '0';
        end if;
      when stColSettle =>
        if DividerRowxDP >= ColSettlexDI then
            StateRowxDN   <= stInit;
            DividerRowxDN <= (others => '0');
        else
          DividerRowxDN <= DividerRowxDP + 1;
        end if;
      when stInit =>
        ADCconvstxEBO <= '1';
        if DividerRowxDP >= RowSettlexDI then
          StateRowxDN   <= stStartConversion;
          DividerRowxDN <= (others => '0');
        else
          DividerRowxDN <= DividerRowxDP + 1;
        end if;
      when stStartConversion =>
        ADCconvstxEBO <= '0';
        if ADCbusyxSI = '1' then
          StateRowxDN <= stBusy;
        end if;
      when stBusy =>
        ADCconvstxEBO <= '0';
        if ADCbusyxSI = '0' then
          StateRowxDN <= stRead;
        end if;
      when stRead =>
        ADCconvstxEBO <= '0';
        ADCreadxEBO   <= '0';
        StateRowxDN   <= stWrite;
      when stWrite =>
        ADCconvstxEBO <= '0';
        ADCreadxEBO   <= '0';
        if IsAxS = '1' then
          if CountColxDP < SizeX then
            RegisterWritexEO <= '1';
          else
            RegisterWritexEO <= '0';
          end if;
        else
          if NoBxS = '0' and CountColxDP > ExposurexDI + 1 and CountColxDP < ExposurexDI + 66 then
            RegisterWritexEO <= '1';
          else
            RegisterWritexEO <= '0';
          end if;
        end if;
        DividerRowxDN <= (others => '0');
        StateRowxDN   <= stRowDone;
      when stRowDone =>
        ADCconvstxEBO        <= '1';
        CDVSTestSRRowClockxS <= '1';
        CDVSTestSRRowInxS    <= '0';
        StartRowxSN          <= '0';
        if CountRowxDP >= 31 then
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
  p_memoryzing : process (ClockxC, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      StateColxDP   <= stIdle;
      StateRowxDP   <= stStartup;
      DividerColxDP <= (others => '0');
      DividerRowxDP <= (others => '0');
      StartColxSP   <= '0';
      StartRowxSP   <= '0';
      CountColxDP   <= (others => '0');
      CountRowxDP   <= (others => '0');
    elsif ClockxC'event and ClockxC = '1' then  -- rising clock edge   
      StateColxDP   <= StateColxDN;
      StateRowxDP   <= StateRowxDN;
      DividerColxDP <= DividerColxDN;
      DividerRowxDP <= DividerRowxDN;
      StartColxSP   <= StartColxSN;
      StartRowxSP   <= StartRowxSN;
      CountRowxDP   <= CountRowxDN;
      CountColxDP   <= CountColxDN;
    end if;
  end process p_memoryzing;

  -- purpose: create clock
  -- type   : sequential
  -- inputs : clockxci,
  -- outputs: 
  p_clock : process (ClockxCI, ResetxRBI)
  begin  -- process 
    if ResetxRBI = '0' then
      ClockxC <= '0';
    elsif ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
      ClockxC <= not ClockxC;
    end if;
  end process p_clock;

  -- 90 degree phase shifted clock for shift registers on chip
  p_clock_chip : process (ClockxC, ResetxRBI)
  begin  -- process 
    if ResetxRBI = '0' then
      CDVSTestSRRowClockxSO <= '0';
      CDVSTestSRColClockxSO <= '0';
    elsif ClockxC'event and ClockxC = '0' then  -- falling clock edge
      CDVSTestSRRowClockxSO <= CDVSTestSRRowClockxS;
      CDVSTestSRColClockxSO <= CDVSTestSRColClockxS;
    end if;
  end process p_clock_chip;
  
end Behavioral;
