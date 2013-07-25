--------------------------------------------------------------------------------
-- Company: INI Zurich
-- Engineer: Christian Brandli
--
-- Create Date:    13:58:57 10/24/05
-- Design Name:    
-- Module Name:    ADCStatemachine - Testbench
-- Project Name:   SeeBetter20
-- Target Device:  
-- Tool versions:  
-- Description: handles the ADC 
--
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity ADCStateMachine_tb is
end ADCStateMachine_tb;

architecture Behavioural of ADCStateMachine_tb is

  component ADCStateMachine
    port (
	ClockxCI              : in    std_logic;
    ADCclockxCO           : out   std_logic;
    ResetxRBI             : in    std_logic;
    ADCwordxDI            : in    std_logic_vector(9 downto 0);
    ADCoutxDO             : out   std_logic_vector(13 downto 0);
    ADCoexEBO          	: out   std_logic;
    ADCstbyxEO           : out   std_logic;
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
  end component;
  
  signal IfClockxC 			: std_logic;
  signal ADCclockxC 		: std_logic;
  signal ResetxRB 			: std_logic;
  signal ADCwordxD          : std_logic_vector(9 downto 0);
  signal ADCdataxD            : std_logic_vector(13 downto 0);
  signal ADCoexEB          :   std_logic;
  signal ADCstbyxE           :   std_logic;
  signal ADCovrxS			  :   std_logic;
  signal RegisterWritexE      :   std_logic;
  signal SRLatchxE            :    std_logic;
  signal RunADCxS             :    std_logic;
  signal ExposurexD          :    std_logic_vector(15 downto 0);
  signal ColSettlexD          :    std_logic_vector(15 downto 0);
  signal RowSettlexD          :    std_logic_vector(15 downto 0);
  signal ResSettlexD          :    std_logic_vector(15 downto 0);
  signal FramePeriodxD		  :    std_logic_vector(15 downto 0);
  signal ExtTriggerxE 	      :    std_logic;
  signal CDVSTestSRRowInxS    :    std_logic;
  signal CDVSTestSRRowClockxS :    std_logic;
  signal CDVSTestSRColInxS    :    std_logic;
  signal CDVSTestSRColClockxS :    std_logic;
  signal CDVSTestColMode0xS  :    std_logic;
  signal CDVSTestColMode1xS  :    std_logic;
  signal CDVSTestApsTxGatexS :    std_logic;
  signal ADCStateOutputLEDxS :    std_logic;
  
  constant Tpw_clk : time := 66.6666 ns;
	
begin
  
  clock_gen : process is
    begin
	  IfClockxC <= '0' after Tpw_clk, '1' after 2*Tpw_clk;
	  Wait for 2*Tpw_clk;
  end process clock_gen;
  
  ADCclockxC <= 'Z';
  ResetxRB <= '0', '1' after 1000 ns;
  ADCwordxD <= "0100110111";
  ADCdataxD <= (others=>'Z');
  ADCoexEB <= 'Z';
  ADCstbyxE <= 'Z';
  RegisterWritexE <= 'Z';
  SRLatchxE <= '1', '0' after 2000 ns, '1' after 2500 ns;
  RunADCxS <= '0', '1' after 5 us;--, '0' after 15 us, '1' after 40005 us, '0' after 40015 us; 
  ExposurexD   <= "0000000000000100";
  ColSettlexD   <= "0000000000000010";
  RowSettlexD   <= "0000000000000010";
  ResSettlexD   <= "0000000000001000";
  FramePeriodxD <= "0000000000001000";
  ExtTriggerxE	<= '0';
  CDVSTestSRRowInxS <= 'Z';
  CDVSTestSRRowClockxS <= 'Z';
  CDVSTestSRColInxS <= 'Z';
  CDVSTestSRColClockxS <= 'Z';
  CDVSTestColMode0xS <= 'Z';
  CDVSTestColMode1xS <= 'Z';
  CDVSTestApsTxGatexS <= 'Z';
  ADCStateOutputLEDxS <= 'Z';

  ADCStateMachine_1: ADCStateMachine
    port map (
      ClockxCI              => IfClockxC,
      ADCclockxCO           => ADCclockxC,
      ResetxRBI             => ResetxRB,
      ADCwordxDI            => ADCwordxD,
      ADCoutxDO             => ADCdataxD,
      ADCoexEBO          	=> ADCoexEB,
      ADCstbyxEO	  		=> ADCstbyxE,
	  ADCovrxSI				=> ADCovrxS,
      RegisterWritexEO      => RegisterWritexE,
      SRLatchxEI            => SRLatchxE,
      RunADCxSI             => RunADCxS,
	  ExposurexDI			=> ExposurexD,
	  ColSettlexDI          => ColSettlexD,
	  RowSettlexDI          => RowSettlexD,
	  ResSettlexDI          => ResSettlexD,
	  FramePeriodxDI		=> FramePeriodxD,
	  ExtTriggerxEI			=> ExtTriggerxE,
      CDVSTestSRRowInxSO    => CDVSTestSRRowInxS,
      CDVSTestSRRowClockxSO => CDVSTestSRRowClockxS,
      CDVSTestSRColInxSO    => CDVSTestSRColInxS,
      CDVSTestSRColClockxSO => CDVSTestSRColClockxS,
	  CDVSTestColMode0xSO   => CDVSTestColMode0xS,
	  CDVSTestColMode1xSO   => CDVSTestColMode1xS,
	  CDVSTestApsTxGatexSO	=> CDVSTestApsTxGatexS,
	  ADCStateOutputLEDxSO	=> ADCStateOutputLEDxS
	  );

end Behavioural;