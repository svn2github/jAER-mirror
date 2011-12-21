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

entity ADCStateMachine is

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
	FramePeriodxDI		  : in    std_logic_vector(31 downto 0);
    CDVSTestSRRowInxSO    : out   std_logic;
    CDVSTestSRRowClockxSO : out   std_logic;
    CDVSTestSRColInxSO    : out   std_logic;
    CDVSTestSRColClockxSO : out   std_logic;
    CDVSTestColMode0xSO  : out   std_logic;
    CDVSTestColMode1xSO  : out   std_logic);

end ADCStateMachine;

architecture Behavioral of ADCStateMachine is
  type ColState is (stIdle, stFeedReset, stFeedRead ,stFeedRow,stReadColumn, stColumnCount, stFeedNull, stWaitFrame);
  type RowState is (stIdle, stStartup, stLatch, stWriteConfig, stFeedRow, stResetA, stInitA, stTrackA, stStartConversionA, stBusyA, stReadA, stWriteA, stInitB, stTrackB, stStartConversionB, stBusyB, stReadB, stWriteB, stRowDone, stColumnDone);


  -- present and next state
  signal StateColxDP, StateColxDN, StateColxDL : ColState;
  signal StateRowxDP, StateRowxDN : RowState;
  signal ADCconfigWordxS : std_logic_vector(11 downto 0);
  signal ADCwordWritexE : std_logic;
  signal ClockxC : std_logic;

-- clock this circuit with half the
-- input clock frequency: 15 MHz

  signal ADCoutMSBxS : std_logic_vector(3 downto 0);
  signal StartPixelxS : std_logic;
  signal StartColxSN, StartColxSP : std_logic;
  signal StartRowxSN, StartRowxSP : std_logic;
  signal ChannelxD : std_logic_vector(1 downto 0);

  -- timestamp reset register
  signal DividerColxDP, DividerColxDN : std_logic_vector(32 downto 0);
  signal DividerRowxDP, DividerRowxDN : std_logic_vector(16 downto 0);

  constant configword : std_logic_vector(11 downto 0) := "000101100000";--"100101101000";
  signal CountRowxDN, CountRowxDP : std_logic_vector(4 downto 0);
  signal CountColxDN, CountColxDP : std_logic_vector(5 downto 0);
  signal NoBxS, DoReadxS, ReadDonexS : std_logic;
  signal ColModexD : std_logic_vector(1 downto 0); -- "00" Null, "01" Sel A, "10" Sel B, "11" Res A
                                    							

begin

  StartPixelxS <= StartColxSP and StartRowxSP;
  ADCconfigWordxS <= ADCconfigxDI;
  ADCoutxDO <= ADCoutMSBxS(3 downto 2) &  ADCwordxDIO(11 downto 0);
  ADCoutMSBxS <= '1' & StartPixelxS & ChannelxD;
  ChannelxD <= ADCconfigWordxS(6 downto 5);
  
  CDVSTestColMode0xSO <= ColModexD(0);
  CDVSTestColMode1xSO <= ColModexD(1);
  
  with ADCwordWritexE select
    ADCwordxDIO <=
    ADCconfigWordxS when '1',
    (others => 'Z')       when others;
  
                                             
-- calculate col next state and outputs
  p_col : process (StateColxDP, DividerColxDP, ColSettlexDI, ExposurexDI, RunADCxSI, CountColxDP, StartColxSP, ReadDonexS)
  begin  -- process p_memless
    -- default assignements: stay in present state

    StateColxDN   <= StateColxDP;
    DividerColxDN <= DividerColxDP;
    CDVSTestSRColClockxSO <= '0';
    CDVSTestSRColInxSO <= '0';

    StartColxSN <= StartColxSP;
    
    CountColxDN <= CountColxDP;
    
    case StateColxDP is
      when stIdle =>
     	if RunADCxSI = '1' then
          StateColxDN <= stFeedReset;
		  StartColxSN <= '1';
        end if;
        DividerColxDN <= (others => '0');
        CountColxDN <= (others => '0');
		NoBxS <= '1';
      when stFeedReset =>
        if StateColxDL = StateColxDP then
         StateColxDN <= stFeedRead;
        else
         CDVSTestSRColInxSO <= '1';
         CDVSTestSRColClockxSO <= '1';
        end if;
        DividerColxDN <= (others => '0');
      when stFeedRead =>
        if StateColxDL = StateColxDP then
          DividerColxDN <= DividerColxDP + 1;
          if DividerColxDP > ColSettlexDI then
            StateColxDN <= stFeedRow;
          end if;
        else
         CDVSTestSRColInxSO <= '1';
         CDVSTestSRColClockxSO <= '1';
        end if;
      when stFeedRow =>
        DividerColxDN <= (others => '0');
        DoReadxS <= '1';
        if ReadDonexS = '1' then
          StateColxDN <= stColumnCount;
        end if;
      when stColumnCount =>
		  CountColxDN <= CountColxDP + 1;
		  StartColxSN <= '0';
		  DoReadxS <= '0';
        if CountColxDP = (ExposurexDI + 1) then
          StateColxDN <= stFeedRead;
          NoBxS <= '0';
        elsif CountColxDP > (ExposurexDI + 64) then
          StateColxDN <= stWaitFrame;
        else
          StateColxDN <= stFeedNull;
        end if;
      when stFeedNull =>
        if StateColxDL = StateColxDP then
          DividerColxDN <= DividerColxDP + 1;
          if DividerColxDP > ColSettlexDI then
            StateColxDN <= stFeedRow;
          end if;
        else
         CDVSTestSRColClockxSO <= '1';
        end if; 
      when stWaitFrame =>
        DividerColxDN <= DividerColxDP + 1;
        if DividerColxDP > FramePeriodxDI then
          StateColxDN <= stIdle;
        end if;
      when others      => null;
    end case;

  end process p_col;

-- calculate next Row state and outputs
  p_row : process (StateRowxDP, ADCbusyxSI, ClockxC, SRLatchxEI, DividerRowxDP, CountRowxDP, ResSettlexDI, RowSettlexDI, StartRowxSP, NoBxS, DoReadxS)
  begin  -- process p_row
    -- default assignements: stay in present state

    StateRowxDN   <= StateRowxDP;
    DividerRowxDN <= DividerRowxDP;
    CDVSTestSRRowClockxSO <= '0';
    CDVSTestSRRowInxSO <= '0';
    
    CountRowxDN <= CountRowxDP;
    
	ColModexD <= "00";
	
    ADCwritexEBO <= '1';
    ADCreadxEBO <= '1';
    ADCconvstxEBO <= '1';
    RegisterWritexEO <= '0';
    ADCwordWritexE <= '0';
    ADCclockxCO <= ClockxC;
    
    case StateRowxDP is
      when stStartup =>
        ADCwritexEBO <= '0';
        StateRowxDN <= stWriteConfig;
        ADCwordWritexE <= '1';
        ADCconvstxEBO <= '0';
      when stWriteConfig =>
        ADCwordWritexE <= '1';
        StateRowxDN <= stIdle;
        ADCconvstxEBO <= '0';
      when stLatch =>
        if SRLatchxEI = '1' then
          StateRowxDN <= stStartup;
        end if;
        ADCconvstxEBO <= '0';
      when stIdle =>
		ColModexD <= "00";
        ADCclockxCO <= '0';             -- switch off clock in idle state to-- safe power
        if SRLatchxEI = '0' then
          StateRowxDN <= stLatch;
        elsif DoReadxS = '1' then
          StateRowxDN <= stFeedRow;
        end if;
        DividerRowxDN <= (others => '0');
        ADCconvstxEBO <= '0';
		CountRowxDN <= (others => '0');
	  when stFeedRow =>
		ColModexD <= "00";
		CDVSTestSRRowClockxSO <= '1';
		CDVSTestSRRowInxSO <= '1';
		StartRowxSN <= '1';
		StateRowxDN <= stResetA;
	  when stResetA =>
		ColModexD <= "11";
		DividerRowxDN <= DividerRowxDP + 1;
		if DividerRowxDP > ResSettlexDI then
			StateRowxDN <= stInitA;
		end if;
      when stInitA =>
		ColModexD <= "00";
		DividerRowxDN <= (others => '0');
        StateRowxDN <= stTrackA;
        ADCconvstxEBO <= '0';
      when stTrackA =>
		ColModexD <= "01";
        ADCconvstxEBO <= '1';
        DividerRowxDN <= DividerRowxDP + 1;
        if DividerRowxDP > RowSettlexDI then
          StateRowxDN <= stStartConversionA;
          DividerRowxDN <= (others => '0');
        end if;
      when stStartConversionA =>
		ColModexD <= "01";
        ADCconvstxEBO <= '0';
        if ADCbusyxSI = '1' then
          StateRowxDN <= stBusyA;
        end if; 
      when stBusyA =>
		ColModexD <= "01";
        ADCconvstxEBO <= '0';
        if ADCbusyxSI = '0' then
          StateRowxDN <= stReadA;
        end if;
      when stReadA =>
		ColModexD <= "00";
        ADCconvstxEBO <= '0';
        ADCreadxEBO <= '0';
        StateRowxDN <= stWriteA;
      when stWriteA =>
        ADCconvstxEBO <= '0';
        ADCreadxEBO <= '0';
        RegisterWritexEO <= '1';
        DividerRowxDN <= (others => '0');
		if NoBxS = '1' then
			StateRowxDN <= stRowDone;
		else
			StateRowxDN <= stInitB;
		end if;
		
	  when stInitB =>
		ColModexD <= "00";
		DividerRowxDN <= (others => '0');
        StateRowxDN <= stTrackB;
        ADCconvstxEBO <= '0';
      when stTrackB =>
		ColModexD <= "10";
        ADCconvstxEBO <= '1';
        DividerRowxDN <= DividerRowxDP + 1;
        if DividerRowxDP > RowSettlexDI then
          StateRowxDN <= stStartConversionB;
          DividerRowxDN <= (others => '0');
        end if;
      when stStartConversionB =>
		ColModexD <= "10";
        ADCconvstxEBO <= '0';
        if ADCbusyxSI = '1' then
          StateRowxDN <= stBusyB;
        end if; 
      when stBusyB =>
		ColModexD <= "10";
        ADCconvstxEBO <= '0';
        if ADCbusyxSI = '0' then
          StateRowxDN <= stReadB;
        end if;
      when stReadB =>
		ColModexD <= "00";
        ADCconvstxEBO <= '0';
        ADCreadxEBO <= '0';
        StateRowxDN <= stWriteB;
      when stWriteB =>
        ADCconvstxEBO <= '0';
        ADCreadxEBO <= '0';
        RegisterWritexEO <= '1';
        DividerRowxDN <= (others => '0');
		StateRowxDN <= stRowDone;
		
	  when stRowDone =>
		ColModexD <= "00";
        ADCconvstxEBO <= '0';
		CDVSTestSRRowClockxSO <= '1';
		CDVSTestSRRowInxSO <= '0';
		StartRowxSN <= '0';
		if CountRowxDP >= 31 then
			StateRowxDN <= stInitA;
		else
			StateRowxDN <= stColumnDone;
		end if;
		CountRowxDN <= CountRowxDP + 1;
      when stColumnDone =>
        ColModexD <= "00";
		ReadDonexS <= '1';
		StateRowxDN <= stIdle;
       
      when others      => null;
    end case;

  end process p_row;

  -- change state on clock edge
  p_memoryzing : process (ClockxC, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      StateColxDP <= stIdle;
	  StateRowxDP <= stStartup;
      DividerColxDP <= (others => '0');
	  DividerRowxDP <= (others => '0');
      StartColxSP <= '0';
	  StartRowxSP <= '0';
      CountColxDP <= (others => '0');
      CountRowxDP <= (others => '0');
    elsif ClockxC'event and ClockxC = '1' then  -- rising clock edge
      StateColxDL <= StateColxDP;
      StateColxDP <= StateColxDN;
      StateRowxDP <= StateRowxDN;
      DividerColxDP <= DividerColxDN;
	  DividerRowxDP <= DividerRowxDN;
      StartColxSP <= StartColxSN;
	  StartRowxSP <= StartRowxSN;
      CountRowxDP <= CountRowxDN;
      CountColxDP <= CountColxDN;
    end if;
  end process p_memoryzing;

  -- purpose: create clock
  -- type   : sequential
  -- inputs : clockxci,
  -- outputs: 
  p_clock : process (ClockxCI)
  begin  -- process  
    if ClockxCI'event and ClockxCI = '1' then  -- rising clock edge
       ClockxC <= not ClockxC;
    end if;
  end process;
end Behavioral;
