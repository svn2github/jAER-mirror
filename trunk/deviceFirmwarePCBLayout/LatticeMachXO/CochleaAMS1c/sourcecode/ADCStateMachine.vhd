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
    ScanEnablexSI         : in    std_logic;
    ScanXxSI              : in    std_logic_vector(6 downto 0);
    ADCconfigxDI          : in    std_logic_vector(11 downto 0);
    TrackTimexDI          : in    std_logic_vector(15 downto 0);  
    IdleTimexDI           : in    std_logic_vector(15 downto 0);
    ScanClockxSO          : out   std_logic;
    ScanSyncxSI          : in   std_logic);

end ADCStateMachine;

architecture Behavioral of ADCStateMachine is
  type state is (stIdle,  stStartup, stLatch, stWriteConfig, stInit, stTrack , stStartConversion, stBusy, stRead, stWriteReg, stWait,stSinglePixelClockLow,stSinglePixelClockHigh);


  -- present and next state
  signal StatexDP, StatexDN : state;
  signal ADCconfigWordxS : std_logic_vector(11 downto 0);
  signal ADCwordWritexE : std_logic;
  signal ClockxC : std_logic;           -- clock this circuit with half the
                                        -- input clock frequency: 15 MHz

  signal ADCoutMSBxS : std_logic_vector(3 downto 0);
  signal ChannelxDN, ChannelxDP, ChannelxD, ConfigChannelxD : std_logic_vector(1 downto 0);
  signal SeqxD : std_logic;

  signal ScanPixelxS : std_logic_vector(7 downto 0);
  -- timestamp reset register
  signal DividerxDP, DividerxDN : std_logic_vector(16 downto 0);

  constant configword : std_logic_vector(11 downto 0) := "000101100000";--"100101101000";
  signal CountxDN, CountxDP : std_logic_vector(7 downto 0);


begin

  
  ADCconfigWordxS <= ADCconfigxDI;
  ADCoutxDO <= ADCoutMSBxS(3 downto 0) &  ADCwordxDIO(11 downto 2);
  ADCoutMSBxS <= '1' & ScanSyncxSI & ChannelxD;
  ConfigChannelxD <= ADCconfigWordxS(6 downto 5);
  SeqxD <= ADCconfigWordxS(2);

  with SeqxD select
    ChannelxD <=
    ConfigChannelxD when '0',
    ChannelxDP      when others;

  ScanPixelxS <= '0' & ScanXxSI;
  
  with ADCwordWritexE select
    ADCwordxDIO <=
    ADCconfigWordxS when '1',
    (others => 'Z')       when others;
  
-- calculate next state and outputs
  p_memless : process (StatexDP, DividerxDP, ADCbusyxSI, ClockxC, SRLatchxEI, IdleTimexDI,  TrackTimexDI, RunADCxSI, CountxDP,ScanEnablexSI, ScanPixelxS, ScanSyncxSI, ChannelxDP, ConfigChannelxD, SeqxD)
  begin  -- process p_memless
    -- default assignements: stay in present state

    StatexDN   <= StatexDP;
    DividerxDN <= DividerxDP;
    ScanClockxSO <= '0';
   
    ChannelxDN <= ChannelxDP;
    CountxDN <= CountxDP;
    
    ADCwritexEBO <= '1';
    ADCreadxEBO <= '1';
    ADCconvstxEBO <= '1';
    RegisterWritexEO <= '0';
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
          end if;
        end if;
        DividerxDN <= (others => '0');
        CountxDN <= (others => '0');
        ADCconvstxEBO <= '0';
      when stInit =>
 
        StatexDN <= stTrack;
        ADCconvstxEBO <= '0';
        DividerxDN <= (others => '0');
      when stTrack =>
        ADCconvstxEBO <= '1';
        DividerxDN <= DividerxDP + 1;

        if ScanEnablexSI='1' and SeqxD='0' then
          ScanClockxSO <= '1';
        elsif ScanEnablexSI='1' and SeqxD='1' and ChannelxDP="00" then
          ScanClockxSO <= '1';
        end if;

        if DividerxDP > TrackTimexDI then
    
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
          ChannelxDN <= ChannelxDP +1;
          if ChannelxDP = ConfigChannelxD then
            ChannelxDN <= (others => '0');
          end if;
        end if;
      when stSinglePixelClockLow =>
        if CountxDP > ScanPixelxS then
          StatexDN <= stTrack;
        else
          StatexDN <= stSinglePixelClockHigh;
        end if;

        if ScanSyncxSI = '0' then
          DividerxDN(0) <= '1';            -- divider >0 indicates that we
                                        -- received sync, now count up to the
                                        -- desired channel
        end if;
      when stSinglePixelClockHigh =>
        StatexDN <= stSinglePixelClockLow;

        ScanClockxSO <= '1';
        if DividerxDP(0)='1' then
          CountxDN <= CountxDP +1;
        else
          CountxDN <= (others => '0');
        end if;

        if ScanSyncxSI = '0' then
          DividerxDN(0) <= '1';            -- divider >0 indicates that we
          CountxDN <= CountxDP +1;          -- received sync, now count up to the
                                        -- desired channel
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
      ChannelxDP <= (others => '0');
      CountxDP <= (others => '0');      
    elsif ClockxC'event and ClockxC = '1' then  -- rising clock edge
      StatexDP <= StatexDN;
      DividerxDP <= DividerxDN;  
      ChannelxDP <= ChannelxDN;
      CountxDP <= CountxDN;
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
