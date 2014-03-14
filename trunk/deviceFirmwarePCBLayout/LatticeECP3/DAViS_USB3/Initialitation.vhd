--------------------------------------------------------------------------------
-- Company: iniLabs
-- Engineer: Vicente Villanueva
--
-- Create Date:    03/11/14
-- Design Name:    
-- Module Name:    Initialitation
-- Project Name:   DevBoardUSB3
-- Target Device:  Lattice ECP3 LFE3-17EA
-- Tool versions:  
-- Description: Initialize the ports putting them to High impedance to allow
--	a correct programmation process
-- 
--------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;

use ieee.numeric_std.all;


entity InitZ is
  port (
	IfClockxCI	: in std_logic;
	X : inout std_logic;
	
AERMonitorREQxABI : out std_logic;
AERMonitorACKxSBO  : out std_logic;

---CONTROL
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
	LED1xSO : out std_ulogic; --#SP_LED1 in the PCB
	LED2xSO : out std_logic; --#SP_LED2 in the PCB
	LED3xSO : out std_logic; --#SP_LED3 in the PCB
	LED4xSO : out std_logic; --#SP_LED2 in the PCB
	LED5xSO : out std_logic; --#SP_LED3 in the PCB
	
	ADCclockxCO : out std_logic;
	ADCoexEBO : out std_logic;
	ADCstbyxEO : out std_logic;
	
--TrueNorth AER inputs
	--AERMonAdd0_TN_IN : out std_logic;
	--AERMonAdd1_TN_IN : out std_logic;
	--AERMonAdd2_TN_IN : out std_logic;
	--AERMonAdd3_TN_IN : out std_logic;
	--AERMonAdd4_TN_IN : out std_logic;
	--AERMonAdd5_TN_IN : out std_logic;
	--AERMonAdd6_TN_IN : out std_logic;
	--AERMonAdd7_TN_IN : out std_logic;
	--AERMonAdd8_TN_IN : out std_logic;
	--AERMonAdd9_TN_IN : out std_logic;
	--AERMonAdd10_TN_IN : out std_logic;--#Q16_N in the PCB		
	--AERMonAdd11_TN_IN : out std_logic;--#Q16_P in the PCB
	--AERMonAdd12_TN_IN : out std_logic;--#VREF1_7 in the PCB
	--AERMonAdd13_TN_IN : out std_logic;--#VREF2_7 in the PCB
	--AERMonAdd14_TN_IN : out std_logic;--#CLKT0 in the PCB
	--AERMonAdd15_TN_IN : out std_logic;--#Spare1 (sig0) in the PCB 
	--AERMonAdd16_TN_IN : out std_logic;--#Spare2 (sig1) in the PCB
	--AERMonAdd17_TN_IN : out std_logic;--#Spare3 (sig2) in the PCB
	--AERMonAdd18_TN_IN : out std_logic;--#Spare4 (sig3) in the PCB
--TrueNorth AER outputs
	--AERMonAdd0_TN_OUT : out std_logic;--#Q4_P in the PCB		
	--AERMonAdd1_TN_OUT : out std_logic;--#Q3_N in the PCB
	--AERMonAdd2_TN_OUT : out std_logic;--#Q3_P in the PCB
	--AERMonAdd3_TN_OUT : out std_logic;--#Q2_N in the PCB
	--AERMonAdd4_TN_OUT : out std_logic;--#Q2_P in the PCB
	--AERMonAdd5_TN_OUT : out std_logic;--#Q1_N in the PCB
	--AERMonAdd6_TN_OUT : out std_logic;--#Q1_P in the PCB
	--AERMonAdd7_TN_OUT : out std_logic;--#Q9_N in the PCB
	--AERMonAdd8_TN_OUT : out std_logic;--#Q9_P in the PCB
	--AERMonAdd9_TN_OUT : out std_logic;--#Q10_P in the PCB
	--AERMonAdd10_TN_OUT : out std_logic;--#Q10_N in the PCB		
	--AERMonAdd11_TN_OUT : out std_logic;--#Q11 in the PCB
	--AERMonAdd12_TN_OUT : out std_logic;--#Q12_P in the PCB
	--AERMonAdd13_TN_OUT : out std_logic;--#Q12_N in the PCB
	--AERMonAdd14_TN_OUT : out std_logic;--#Q13_P in the PCB
	--AERMonAdd15_TN_OUT : out std_logic;--#Q13_N in the PCB
	--AERMonAdd16_TN_OUT : out std_logic;--#Q14_P in the PCB
	--AERMonAdd17_TN_OUT : out std_logic;--#Q14_N in the PCB
	--AERMonAdd18_TN_OUT : out std_logic;--#Q15 in the PCB
	--sinals
	ResetxRBI: out std_logic;
	biasAddrSel: out std_logic;		--#BiasAddrSel
	--PxPORT
	
	Vref2_2xDIO : out std_logic;
	Vref1_2xDIO : out std_logic;
	CLKC1_DIO : out std_logic;
	CLKT1_DIO : out std_logic;
	
	FX3FifoDataxDIO_15 : out std_logic;
	FX3FifoDataxDIO_14 : out std_logic;
	FX3FifoDataxDIO_13 : out std_logic;
	FX3FifoDataxDIO_12 : out std_logic;
	FX3FifoDataxDIO_11 : out std_logic;
	FX3FifoDataxDIO_10 : out std_logic;
	FX3FifoDataxDIO_9 : out std_logic;
	FX3FifoDataxDIO_8 : out std_logic;
	FX3FifoDataxDIO_7 : out std_logic;
	FX3FifoDataxDIO_6 : out std_logic;
	FX3FifoDataxDIO_5 : out std_logic;
	FX3FifoDataxDIO_4 : out std_logic;
	FX3FifoDataxDIO_3 : out std_logic;
	FX3FifoDataxDIO_2 : out std_logic;
	FX3FifoDataxDIO_1 : out std_logic;
	FX3FifoDataxDIO_0 : out std_logic;
	FX3FifoWritexEBO : out std_logic;--SLWR signal in the PCB
	FX3FifoReadxEBO : out std_logic;--SLOESLRD signal in the PCB
	FX3FifoPktEndxSBO : out std_logic;--PktEnd
	FX3FifoAddressxDO_0 : out std_logic;--FifoAddr0
	FX3FifoAddressxDO_1 : out std_logic;--FifoAddr1
	FX3FifoInFullxSBI : out std_logic;--fULL
	FX3FifoInAlmFullxSBI : out std_logic; --new signal in FX3 #almFULL
	FX3FifoInEmptyxSBI : out std_logic;--EMPTY
	FX3FifoInAlmEmptyxSBI : out std_logic;--new signal in FX3 #almEMPTY
	FX3FifoSLCSxEBO : out std_logic --SLCS
	);
end InitZ;

	architecture HighZ of InitZ is
	
			
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
		
		ADCclockxCO <= 'Z';
		ADCoexEBO <= 'Z';
		ADCstbyxEO <= 'Z';
	
		FX3FifoWritexEBO <= 'Z';
		FX3FifoReadxEBO <= 'Z';
		FX3FifoPktEndxSBO <= 'Z';
		FX3FifoAddressxDO_0 <= 'Z';
		FX3FifoAddressxDO_1 <= 'Z';
		FX3FifoInFullxSBI <= 'Z';
		FX3FifoInAlmFullxSBI <= 'Z';
		FX3FifoInEmptyxSBI <= 'Z';
		FX3FifoInAlmEmptyxSBI <= 'Z';
		FX3FifoSLCSxEBO <= 'Z';
		ResetxRBI <= 'Z';

		--AERMonAdd0_TN_OUT <= 'Z';--#Q4_P in the PCB		
		--AERMonAdd1_TN_OUT <= 'Z';--#Q3_N in the PCB
		--AERMonAdd2_TN_OUT <= 'Z';--#Q3_P in the PCB
		--AERMonAdd3_TN_OUT <= 'Z';--#Q2_N in the PCB
		--AERMonAdd4_TN_OUT <= 'Z';--#Q2_P in the PCB
		--AERMonAdd5_TN_OUT <= 'Z';--#Q1_N in the PCB
		--AERMonAdd6_TN_OUT <= 'Z';--#Q1_P in the PCB
		--AERMonAdd7_TN_OUT <= 'Z';--#Q9_N in the PCB
		--AERMonAdd8_TN_OUT <= 'Z';--#Q9_P in the PCB
		--AERMonAdd9_TN_OUT <= 'Z';--#Q10_P in the PCB
		--AERMonAdd10_TN_OUT <= 'Z';--#Q10_N in the PCB		
		--AERMonAdd11_TN_OUT <= 'Z';--#Q11 in the PCB
		--AERMonAdd12_TN_OUT <= 'Z';--#Q12_P in the PCB
		--AERMonAdd13_TN_OUT <= 'Z';--#Q12_N in the PCB
		--AERMonAdd14_TN_OUT <= 'Z';--#Q13_P in the PCB
		--AERMonAdd15_TN_OUT <= 'Z';--#Q13_N in the PCB
		--AERMonAdd16_TN_OUT <= 'Z';--#Q14_P in the PCB
		--AERMonAdd17_TN_OUT <= 'Z';--#Q14_N in the PCB
		--AERMonAdd18_TN_OUT <= 'Z';--#Q15 in the PCB
		biasAddrSel <= 'Z';
		Vref2_2xDIO <= 'Z';
		Vref1_2xDIO <= 'Z';
		CLKC1_DIO <= 'Z';
		CLKT1_DIO <= 'Z';
		FX3FifoDataxDIO_15 <= 'Z';
		FX3FifoDataxDIO_14 <= 'Z';
		FX3FifoDataxDIO_13 <= 'Z';
		FX3FifoDataxDIO_12 <= 'Z';
		FX3FifoDataxDIO_11 <= 'Z';
		FX3FifoDataxDIO_10  <= 'Z';
		FX3FifoDataxDIO_9  <= 'Z';
		FX3FifoDataxDIO_8  <= 'Z';
		FX3FifoDataxDIO_7  <= 'Z';
		FX3FifoDataxDIO_6  <= 'Z';
		FX3FifoDataxDIO_5 <= 'Z';
		FX3FifoDataxDIO_4 <= 'Z';
		FX3FifoDataxDIO_3 <= 'Z';
		FX3FifoDataxDIO_2 <= 'Z';
		FX3FifoDataxDIO_1 <= 'Z';
		FX3FifoDataxDIO_0 <= 'Z';
		FX3FifoWritexEBO <= 'Z';
		FX3FifoReadxEBO <= 'Z';
		FX3FifoPktEndxSBO <= 'Z';
		FX3FifoAddressxDO_0 <= 'Z';
		FX3FifoAddressxDO_1 <= 'Z';
		FX3FifoInFullxSBI <= 'Z';
		FX3FifoInAlmFullxSBI <= 'Z';
		FX3FifoInEmptyxSBI <= 'Z';
		FX3FifoInAlmEmptyxSBI <= 'Z';
		FX3FifoSLCSxEBO <= 'Z';
		--wait;
		end loop;
		end process;
end HighZ;