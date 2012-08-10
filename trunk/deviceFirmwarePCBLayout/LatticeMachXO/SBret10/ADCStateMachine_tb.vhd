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

  component ADCStateMachineAB
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
		TestPixelxEI		  : in	  std_logic;
		CDVSTestSRRowInxSO    : out   std_logic;
		CDVSTestSRRowClockxSO : out   std_logic;
		CDVSTestSRColInxSO    : out   std_logic;
		CDVSTestSRColClockxSO : out   std_logic;
		CDVSTestColMode0xSO  : out   std_logic;
		CDVSTestColMode1xSO  : out   std_logic; 
		ADCStateOutputLEDxSO  : out   std_logic);
  end component;
  
  signal IfClockxC 			: std_logic;
  signal ADCclockxC 		: std_logic;
  signal ResetxRB 			: std_logic;
  signal ADCwordxD          : std_logic_vector(11 downto 0);
  signal ADCdataxD             : std_logic_vector(13 downto 0);
  signal ADCwritexEB          :   std_logic;
  signal ADCreadxEB           :   std_logic;
  signal ADCconvstxEB         :   std_logic;
  signal ADCbusyxS            :    std_logic;
  signal RegisterWritexE      :   std_logic;
  signal SRLatchxE            :    std_logic;
  signal RunADCxS             :    std_logic;
  signal RunADConxS             :    std_logic;
  signal RunADCoffxS             :    std_logic;
  signal ADCconfigxD          :    std_logic_vector(11 downto 0);
  signal ExposurexD           :    std_logic_vector(15 downto 0);
  signal ColSettlexD          :    std_logic_vector(15 downto 0);
  signal RowSettlexD          :    std_logic_vector(15 downto 0);
  signal ResSettlexD          :    std_logic_vector(15 downto 0);
  signal FramePeriodxD		  :    std_logic_vector(31 downto 0);
  signal TestPixelxE		  :    std_logic;
  signal CDVSTestSRRowInxS    :    std_logic;
  signal CDVSTestSRRowClockxS :    std_logic;
  signal CDVSTestSRColInxS    :    std_logic;
  signal CDVSTestSRColClockxS :    std_logic;
  signal CDVSTestColMode0xS  :    std_logic;
  signal CDVSTestColMode1xS  :    std_logic;
  signal ADCStateOutputLEDxS :		std_logic;
  
  constant Tpw_clk : time := 66.6666 ns;
	
begin
  
  clock_gen : process is
    begin
	  IfClockxC <= '0' after Tpw_clk, '1' after 2*Tpw_clk;
	  Wait for 2*Tpw_clk;
  end process clock_gen;
  
  ADCclockxC <= 'Z';
  ResetxRB <= '0', '1' after 1000 ns;
  ADCwordxD <= "011000111100" when ADCwritexEB = '1' else (others=>'Z');
  ADCdataxD <= (others=>'Z');
  ADCwritexEB <= 'Z';
  ADCreadxEB <= 'Z';
  ADCconvstxEB <= 'Z';
  RunADConxS <= RunADCoffxS nor ADCconvstxEB ;
  ADCbusyxS <= RunADConxS after 50 ns;
  RunADCoffxS <= ADCbusyxS after 1000 ns;
  RegisterWritexE <= 'Z';
  SRLatchxE <= '1', '0' after 2000 ns, '1' after 2500 ns;
  RunADCxS <= '0', '1' after 5 us;--, '0' after 15 us, '1' after 40005 us, '0' after 40015 us; 
  ADCConfigxD   <= "000101100000";
  ExposurexD    <= "0000000000000100";
  ColSettlexD   <= "0000000000000010";
  RowSettlexD   <= "0000000000000010";
  ResSettlexD   <= "0000000000001000";
  FramePeriodxD <= "00000000000000000000000000001000";
  TestPixelxE	<= '0';
  CDVSTestSRRowInxS <= 'Z';
  CDVSTestSRRowClockxS <= 'Z';
  CDVSTestSRColInxS <= 'Z';
  CDVSTestSRColClockxS <= 'Z';
  CDVSTestColMode0xS <= 'Z';
  CDVSTestColMode1xS <= 'Z';
  ADCStateOutputLEDxS <= 'Z';

  ADCStateMachine_1: ADCStateMachineAB
    port map (
      ClockxCI              => IfClockxC,
      ADCclockxCO           => ADCclockxC,
      ResetxRBI             => ResetxRB,
      ADCwordxDIO           => ADCwordxD,
      ADCoutxDO             => ADCdataxD,
      ADCwritexEBO          => ADCwritexEB,
      ADCreadxEBO           => ADCreadxEB,
      ADCconvstxEBO         => ADCconvstxEB,
      ADCbusyxSI            => ADCbusyxS,
      RegisterWritexEO      => RegisterWritexE,
      SRLatchxEI            => SRLatchxE,
      RunADCxSI             => RunADCxS,
	  ExposurexDI           => ExposurexD,
	  ColSettlexDI          => ColSettlexD,
	  RowSettlexDI          => RowSettlexD,
	  ResSettlexDI          => ResSettlexD,
	  FramePeriodxDI		=> FramePeriodxD,
	  TestpixelxEI			=> TestpixelxE,
	  ADCconfigxDI          => ADCconfigxD,
      CDVSTestSRRowInxSO    => CDVSTestSRRowInxS,
      CDVSTestSRRowClockxSO => CDVSTestSRRowClockxS,
      CDVSTestSRColInxSO    => CDVSTestSRColInxS,
      CDVSTestSRColClockxSO => CDVSTestSRColClockxS,
	  CDVSTestColMode0xSO   => CDVSTestColMode0xS,
	  CDVSTestColMode1xSO   => CDVSTestColMode1xS, 
	  ADCStateOutputLEDxSO	=> ADCStateOutputLEDxS
	  );

end Behavioural;