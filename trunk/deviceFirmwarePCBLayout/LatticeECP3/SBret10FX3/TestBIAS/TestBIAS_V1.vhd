--------------------------------------------------------------------------------
-- Company: iniLabs
-- Engineer: Vicente Villanueva
--
-- Create Date:    03.04.2014
-- Design Name:    Ports_initialitation
-- Module Name:    Initialitation - Structural
-- Project Name:   TrueNorth
-- Target Device:  DevBoard_USB3.0
-- Tool versions:  Diamond 3.0
-- Description: Initialitation for output ports.

--------------------------------------------------------------------------------
-- This file put all the outputs to high impedance in order to decrease the inrush current
-- when the device is being programmed
--------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity PORTS_INI is
	port (
	X : inout std_logic;
	IfClockxCI	: in std_logic;
	--CONTROL BIAS
	CDVSTestSRRowClockxSO : out std_logic;
	CDVSTestSRColClockxSO : out std_logic;
	CDVSTestSRRowInxSO : out std_logic;
	CDVSTestSRColInxSO : out std_logic;
	CDVSTestBiasEnablexEO : out std_logic;
	CDVSTestChipResetxRBO : out std_logic;
	CDVSTestColMode0xSO : out std_logic; --#ColState0 in the PCB
	CDVSTestColMode1xSO : out std_logic; --#ColState1 in the PCB
	CDVSTestBiasDiagSelxSO : out std_logic;
	CDVSTestBiasBitOutxSI : out std_logic;
	CDVSTestApsTxGatexSO : out std_logic;
		
	--LED SIGNALS FLAGS
	LED1xSO: out std_logic; --#SP_LED1 in the PCB
	LED2xSO: out std_logic; --#SP_LED2 in the PCB
	LED3xSO: out std_logic; --#SP_LED3 in the PCB
	LED4xSO: out std_logic; --#SP_LED4 in the PCB #nAck in the PCB
	LED5xSO: out std_logic; --#SP_LED5 in the PCB #nRequest in the PCB

	--TrueNorth AERinputs
	AERMonAdd0_TN_IN : in std_logic ;
	AERMonAdd1_TN_IN : in std_logic ;
	AERMonAdd2_TN_IN : in std_logic ;
	AERMonAdd3_TN_IN : in std_logic ;
	AERMonAdd4_TN_IN : in std_logic ;
	AERMonAdd5_TN_IN : in std_logic ;
	AERMonAdd6_TN_IN : in std_logic ;
	AERMonAdd7_TN_IN : in std_logic ;
	AERMonAdd8_TN_IN : in std_logic ;
	AERMonAdd9_TN_IN : in std_logic ;
	AERMonAdd10_TN_IN : in std_logic ;
	AERMonAdd11_TN_IN : in std_logic ;
	AERMonAdd12_TN_IN : in std_logic ;
	AERMonAdd13_TN_IN : in std_logic ;
	AERMonAdd14_TN_IN : in std_logic ;
	AERMonAdd15_TN_IN : in std_logic ;
	AERMonAdd16_TN_IN : in std_logic ;
	AERMonAdd17_TN_IN : in std_logic ;
	AERMonAdd18_TN_IN : in std_logic ;
	--TrueNorth AERoutputs
	AERMonAdd0_TN_OUT: out std_logic;	
	AERMonAdd1_TN_OUT: out std_logic;
	AERMonAdd2_TN_OUT: out std_logic;
	AERMonAdd3_TN_OUT: out std_logic;
	AERMonAdd4_TN_OUT: out std_logic;
	AERMonAdd5_TN_OUT: out std_logic;
	AERMonAdd6_TN_OUT: out std_logic;
	AERMonAdd7_TN_OUT: out std_logic;
	AERMonAdd8_TN_OUT: out std_logic;
	AERMonAdd9_TN_OUT: out std_logic;
	AERMonAdd10_TN_OUT: out std_logic;
	AERMonAdd11_TN_OUT: out std_logic;
	AERMonAdd12_TN_OUT: out std_logic;
	AERMonAdd13_TN_OUT: out std_logic;
	AERMonAdd14_TN_OUT: out std_logic;
	AERMonAdd15_TN_OUT: out std_logic;
	AERMonAdd16_TN_OUT: out std_logic;
	AERMonAdd17_TN_OUT: out std_logic;
	AERMonAdd18_TN_OUT: out std_logic;

	--declare all new IO
	TN_clkC0 : in std_logic ;
	TN_reset : in std_logic ;
	TN_int : in std_logic ;

	--TrueNorth SPI
	SDI_TN : out std_logic ;
	SDO_TN : in std_logic ;
	SCK_TN : in std_logic ;

	--TrueNorth special signals
	TN_Req_out : in std_logic ;
	TN_Req_in : out std_logic ;
	TN_Ack_out : in std_logic ;
	TN_Ack_in : out std_logic 
	);
	end PORTS_INI;

architecture TN_parasite of PORTS_INI is


begin

retard : process (X) is
variable ti : integer range 0 to 1000000;

	begin
	ti :=0;
	while (ti<=1000) loop
	ti:=ti+1; 
		LED1xSO <= 'Z'; --#SP_LED1 in the PCB
		LED2xSO  <= 'Z';--#SP_LED2 in the PCB
		LED3xSO  <= 'Z';--#SP_LED3 in the PCB	
		LED4xSO  <= 'Z';--#SP_LED4 in the PCB	
		LED5xSO  <= 'Z';--#SP_LED5 in the PCB	
		CDVSTestSRRowClockxSO <= 'Z';
		CDVSTestSRColClockxSO <= 'Z';
		CDVSTestSRRowInxSO <= 'Z';
		CDVSTestSRColInxSO <= 'Z';
		CDVSTestBiasEnablexEO <= 'Z';
		CDVSTestChipResetxRBO <= 'Z';
		CDVSTestColMode0xSO <= 'Z';
		CDVSTestColMode1xSO <= 'Z';
		CDVSTestBiasDiagSelxSO <= 'Z';
		CDVSTestBiasBitOutxSI <= 'Z';
		CDVSTestApsTxGatexSO <= 'Z';
	
		AERMonAdd0_TN_OUT <= 'Z';--#Q4_P in the PCB		
		AERMonAdd1_TN_OUT <= 'Z';--#Q3_N in the PCB
		AERMonAdd2_TN_OUT <= 'Z';--#Q3_P in the PCB
		AERMonAdd3_TN_OUT <= 'Z';--#Q2_N in the PCB
		AERMonAdd4_TN_OUT <= 'Z';--#Q2_P in the PCB
		AERMonAdd5_TN_OUT <= 'Z';--#Q1_N in the PCB
		AERMonAdd6_TN_OUT <= 'Z';--#Q1_P in the PCB
		AERMonAdd7_TN_OUT <= 'Z';--#Q9_N in the PCB
		AERMonAdd8_TN_OUT <= 'Z';--#Q9_P in the PCB
		AERMonAdd9_TN_OUT <= 'Z';--#Q10_P in the PCB
		AERMonAdd10_TN_OUT <= 'Z';--#Q10_N in the PCB		
		AERMonAdd11_TN_OUT <= 'Z';--#Q11 in the PCB
		AERMonAdd12_TN_OUT <= 'Z';--#Q12_P in the PCB
		AERMonAdd13_TN_OUT <= 'Z';--#Q12_N in the PCB
		AERMonAdd14_TN_OUT <= 'Z';--#Q13_P in the PCB
		AERMonAdd15_TN_OUT <= 'Z';--#Q13_N in the PCB
		AERMonAdd16_TN_OUT <= 'Z';--#Q14_P in the PCB
		AERMonAdd17_TN_OUT <= 'Z';--#Q14_N in the PCB
		
			
		SDI_TN <= 'Z';

		TN_Req_in <= 'Z';
		TN_Ack_in <= 'Z';
		
		--wait;
		end loop;
		end process;

end TN_parasite;
