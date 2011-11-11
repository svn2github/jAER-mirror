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
    UseCalibrationxSI     : in    std_logic;
    ScanEnablexSI         : in    std_logic;
    ScanXxSI              : in    std_logic_vector(4 downto 0);
    ScanYxSI              : in    std_logic_vector(4 downto 0);
    ADCconfigxDI          : in    std_logic_vector(11 downto 0);
    TrackTimexDI          : in    std_logic_vector(15 downto 0);
    RefOnTimexDI          : in    std_logic_vector(15 downto 0);
    RefOffTimexDI         : in    std_logic_vector(15 downto 0);
    IdleTimexDI           : in    std_logic_vector(15 downto 0);
    CDVSTestSRRowInxSO    : out   std_logic;
    CDVSTestSRRowClockxSO : out   std_logic;
    CDVSTestSRColInxSO    : out   std_logic;
    CDVSTestSRColClockxSO : out   std_logic;
    CDVSTestRefEnablexEO  : out   std_logic);

end ADCStateMachine;

architecture Behavioral of ADCStateMachine is
  type state is (stIdle,  stStartup, stLatch, stWriteConfig, stInit, stTrack ,stRefHigh,stRefLow, stStartConversion, stBusy, stRead, stWriteReg, stWait,stSinglePixelClockLow,stSinglePixelClockHigh);


  -- present and next state
  signal StatexDP, StatexDN : state;
  signal ADCconfigWordxS : std_logic_vector(11 downto 0);
  signal ADCwordWritexE : std_logic;
  signal ClockxC : std_logic;           -- clock this circuit with half the
                                        -- input clock frequency: 15 MHz

  signal ADCoutMSBxS : std_logic_vector(3 downto 0);
  signal StartPixelxSN, StartPixelxSP : std_logic;
  signal ChannelxD : std_logic_vector(1 downto 0);

  -- timestamp reset register
  signal DividerxDP, DividerxDN : std_logic_vector(16 downto 0);

  constant configword : std_logic_vector(11 downto 0) := "000101100000";--"100101101000";
  signal CountRowxDN, CountRowxDP : std_logic_vector(4 downto 0);
  signal CountColxDN, CountColxDP : std_logic_vector(3 downto 0);

begin

  
  ADCconfigWordxS <= ADCconfigxDI;
  ADCoutxDO <= ADCoutMSBxS(3 downto 2) &  ADCwordxDIO(11 downto 0);
  ADCoutMSBxS <= '1' & StartPixelxSP & ChannelxD;
  ChannelxD <= ADCconfigWordxS(6 downto 5);
  
  with ADCwordWritexE select
    ADCwordxDIO <=
    ADCconfigWordxS when '1',
    (others => 'Z')       when others;
  
-- calculate next state and outputs
  p_memless : process (StatexDP, DividerxDP, ADCbusyxSI, ClockxC, SRLatchxEI, UseCalibrationxSI, IdleTimexDI, RefOnTimexDI, RefOffTimexDI, TrackTimexDI, RunADCxSI, CountColxDP, CountRowxDP, StartPixelxSP,ScanEnablexSI, ScanYxSI, ScanXxSI)
  begin  -- process p_memless
    -- default assignements: stay in present state

    StatexDN   <= StatexDP;
    DividerxDN <= DividerxDP;
    CDVSTestSRColClockxSO <= '0';
    CDVSTestSRRowClockxSO <= '0';
    CDVSTestSRColInxSO <= '0';
    CDVSTestSRRowInxSO <= '0';

    StartPixelxSN <= StartPixelxSP;
    
    CountRowxDN <= CountRowxDP;
    CountColxDN <= CountColxDP;
    
    ADCwritexEBO <= '1';
    ADCreadxEBO <= '1';
    ADCconvstxEBO <= '1';
    RegisterWritexEO <= '0';
    CDVSTestRefEnablexEO <= '0';
    ADCwordWritexE <= '0';
    ADCclockxCO <= ClockxC;
    
    case StatexDP is
      when stStartup =>
        ADCwritexEBO <= '0';
        StatexDN <= stWriteConfig;
        ADCwordWritexE <= '1';
        ADCconvstxEBO <= '0';
      when stWriteConfig =>
        ADCwordWritexE <= '1';
        StatexDN <= stIdle;
        ADCconvstxEBO <= '0';
      when stLatch =>
        if SRLatchxEI = '1' then
          StatexDN <= stStartup;
        end if;
        ADCconvstxEBO <= '0';
      when stIdle =>
        ADCclockxCO <= '0';             -- switch off clock in idle state to-- safe power

        if SRLatchxEI = '0' then
          StatexDN <= stLatch;
        elsif RunADCxSI = '1' then
          if ScanEnablexSI='1' then
            StatexDN <= stInit;
          else
            StatexDN <= stSinglePixelClockLow;
            CountRowxDN <= (others => '0');
            CountColxDN <= (others => '0');
          end if;
        end if;
        DividerxDN <= (others => '0');
        ADCconvstxEBO <= '0';
      when stInit =>
        if CountRowxDP = 0 and CountColxDP = 0 then
          StartPixelxSN <= '1';
          CDVSTestSRRowInxSO <= '1';
          CDVSTestSRColInxSO <= '1';
        elsif CountRowxDP = 0 then
          StartPixelxSN <= '0';
          CDVSTestSRRowInxSO <= '1';
        else
          StartPixelxSN <= '0';
        end if;
        StatexDN <= stTrack;
        ADCconvstxEBO <= '0';
        DividerxDN <= (others => '0');
      when stTrack =>
        ADCconvstxEBO <= '1';
        DividerxDN <= DividerxDP + 1;

        if ScanEnablexSI='1' then
          if CountRowxDP = 0 and CountColxDP = 0 then
            CDVSTestSRRowInxSO <= '1';
            CDVSTestSRColInxSO <= '1';
            CDVSTestSRColClockxSO <= '1';
          elsif CountRowxDP = 0 then
            CDVSTestSRColClockxSO <= '1';
            CDVSTestSRRowInxSO <= '1';
          end if;
          CDVSTestSRRowClockxSO <= '1';
        end if;

        if DividerxDP > TrackTimexDI then
          if UseCalibrationxSI = '1' and ScanEnablexSI='1'  then
            StatexDN <= stRefHigh;
          else
            StatexDN <= stStartConversion;
          end if;
          
          DividerxDN <= (others => '0');
          
          if ScanEnablexSI='1' then
            if CountRowxDP = 0 then
              CountColxDN <= CountColxDP + 1;
            end if;
            CountRowxDN <= CountRowxDP + 1;
          end if;
        end if;
      when stRefHigh =>
        ADCconvstxEBO <= '1';
        DividerxDN <= DividerxDP + 1;

        CDVSTestRefEnablexEO <= '1';
        if DividerxDP > RefOnTimexDI then
          StatexDN <= stRefLow;
          DividerxDN <= (others => '0');
        end if;
      when stRefLow =>
        ADCconvstxEBO <= '1';
        DividerxDN <= DividerxDP + 1;

        CDVSTestRefEnablexEO <= '0';
        if DividerxDP > RefOffTimexDI then
          StatexDN <= stStartConversion;
          DividerxDN <= (others => '0');
        end if;
      when stStartConversion =>
        ADCconvstxEBO <= '0';
        if ADCbusyxSI = '1' then
          StatexDN <= stBusy;
        end if;
       
      when stBusy =>
        ADCconvstxEBO <= '0';
        if ADCbusyxSI = '0' then
          StatexDN <= stRead;
        end if;
      when stRead =>
        ADCconvstxEBO <= '0';
        ADCreadxEBO <= '0';
        StatexDN <= stWriteReg;
      when stWriteReg =>
        ADCconvstxEBO <= '0';
        ADCreadxEBO <= '0';
        StatexDN <= stWait;
        RegisterWritexEO <= '1';
        DividerxDN <= (others => '0');
      when stWait =>
        ADCconvstxEBO <= '0';
        DividerxDN <= DividerxDP+1;
        if RunADCxSI = '0' then
          StatexDN <= stIdle;
        elsif DividerxDP > IdleTimexDI then
          if ScanEnablexSI='1' then    
            StatexDN <= stInit;
          else
            StatexDN <= stTrack;
          end if;
        end if;
      when stSinglePixelClockLow =>
        if DividerxDP >31 and CountColxDP = ScanXxSI(3 downto 0) and CountRowxDP = ScanYxSI(4 downto 0) then
          StatexDN <= stTrack;
        else
          StatexDN <= stSinglePixelClockHigh;
        end if;
        
        if DividerxDP = 31 then
          CDVSTestSRColInxSO <= '1';
          CDVSTestSRRowInxSO <= '1';
        end if;
      when stSinglePixelClockHigh =>
        StatexDN <= stSinglePixelClockLow;
        
        if DividerxDP = 31 then         -- load bit into shift register after
                                        -- 32 clocks
          CDVSTestSRColInxSO <= '1';
          CDVSTestSRRowInxSO <= '1';
        end if;
        
        if DividerxDP <32 then
          DividerxDN <= DividerxDP+1;
          CDVSTestSRRowClockxSO <= '1';
          CDVSTestSRColClockxSO <= '1';
        else
          if CountRowxDP < ScanYxSI(4 downto 0) then
            CDVSTestSRRowClockxSO <= '1';
            CountRowxDN <= CountRowxDP +1;
          end if;
          if CountColxDP < ScanXxSI(3 downto 0) then
            CDVSTestSRColClockxSO <= '1';
            CountColxDN <= CountColxDP +1;
          end if; 
        end if;
       
      when others      => null;
    end case;

  end process p_memless;

  -- change state on clock edge
  p_memoryzing : process (ClockxC, ResetxRBI)
  begin  -- process p_memoryzing
    if ResetxRBI = '0' then             -- asynchronous reset (active low)
      StatexDP <= stStartup;
      DividerxDP <= (others => '0');
      StartPixelxSP <= '0';
      CountColxDP <= (others => '0');
      CountRowxDP <= (others => '0');
    elsif ClockxC'event and ClockxC = '1' then  -- rising clock edge
      StatexDP <= StatexDN;
      DividerxDP <= DividerxDN;
      StartPixelxSP <= StartPixelxSN;
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
