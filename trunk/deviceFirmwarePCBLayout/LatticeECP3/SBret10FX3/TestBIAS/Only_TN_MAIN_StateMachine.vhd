--------------------------------------------------------------------------------
-- Company: iniLabs
-- Engineer: Vicente Villanueva
--
-- Create Date:    03.04.2014
-- Design Name:    Ports_initialitation
-- Module Name:    Main State Machine - Structural
-- Project Name:   TrueNorth
-- Target Device:  DevBoard_USB3.0
-- Tool versions:  Diamond 3.0
-- Description: Main State Machine that connects all the pieces of the programm

--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED."+";

entity Main_TrueNorth is
	port(
		IfClockxCI	: in std_logic;
			CDVSTestSRRowClockxSO : out std_logic;
			CDVSTestSRColClockxSO : out std_logic;
			CDVSTestSRRowInxSO : out std_logic;
			CDVSTestSRColInxSO : out std_logic;
			CDVSTestBiasEnablexEO : out std_logic;
			CDVSTestChipResetxRBO : out std_logic;
			CDVSTestColMode0xSO : out std_logic; 
			CDVSTestColMode1xSO : out std_logic; 
			CDVSTestBiasDiagSelxSO : out std_logic;
			CDVSTestBiasBitOutxSI : out std_logic;
			CDVSTestApsTxGatexSO : out std_logic;
			LED1xSO: out std_logic; 
			LED2xSO: out std_logic; 
			LED3xSO: out std_logic; 
			LED4xSO: out std_logic; 
			LED5xSO: out std_logic; 
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
			TN_clkC0 : in std_logic ;
			TN_reset : in std_logic ;
			TN_int : in std_logic ;
			SDI_TN : out std_logic ;
			SDO_TN : in std_logic ;
			SCK_TN : in std_logic ;
			TN_Req_out : in std_logic ;
			TN_Req_in : out std_logic ;
			TN_Ack_out : in std_logic ;
			TN_Ack_in : out std_logic 
	);
end Main_TrueNorth;

architecture Structural of Main_TrueNorth is

	component PORTS_INI is
		port (
			--X : inout std_logic;//
			IfClockxCI	: in std_logic;
			CDVSTestSRRowClockxSO : out std_logic;
			CDVSTestSRColClockxSO : out std_logic;
			CDVSTestSRRowInxSO : out std_logic;
			CDVSTestSRColInxSO : out std_logic;
			CDVSTestBiasEnablexEO : out std_logic;
			CDVSTestChipResetxRBO : out std_logic;
			CDVSTestColMode0xSO : out std_logic; 
			CDVSTestColMode1xSO : out std_logic; 
			CDVSTestBiasDiagSelxSO : out std_logic;
			CDVSTestBiasBitOutxSI : out std_logic;
			CDVSTestApsTxGatexSO : out std_logic;
			LED1xSO: out std_logic; 
			LED2xSO: out std_logic; 
			LED3xSO: out std_logic; 
			LED4xSO: out std_logic; 
			LED5xSO: out std_logic; 
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
			TN_clkC0 : in std_logic ;
			TN_reset : in std_logic ;
			TN_int : in std_logic ;
			SDI_TN : out std_logic ;
			SDO_TN : in std_logic ;
			SCK_TN : in std_logic ;
			TN_Req_out : in std_logic ;
			TN_Req_in : out std_logic ;
			TN_Ack_out : in std_logic ;
			TN_Ack_in : out std_logic 
		
		
		);
	end component;
end Structural;