--------------------------------------------------------------------------------
-- Company: INI
-- Engineer: Diederik Paul Moeys
--
-- Create Date:    28.08.2014
-- Design Name:    
-- Module Name:    ObjectMotionMotherCell_tb
-- Project Name:   VISUALISE
-- Target Device:  Latticed LFE3-17EA-7ftn256i
-- Tool versions:  Diamond x64 3.0.0.97x
-- Description:	   TestBench for ObjectMotionCell
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Libraries -------------------------------------------------------------------
-------------------------------------------------------------------------------- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Entity Declaration ----------------------------------------------------------
--------------------------------------------------------------------------------
entity ObjectMotionMotherCell_tb is
end ObjectMotionMotherCell_tb;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------  

--------------------------------------------------------------------------------
-- Architecture Declaration ----------------------------------------------------
--------------------------------------------------------------------------------
architecture TestBench of ObjectMotionMotherCell_tb is
	-- Component generics
	constant Threshold_K     : unsigned (24 downto 0) := (5 => '1', others => '0');
	constant DecayTime_K     : unsigned (24 downto 0) := (10 => '1', others => '0');
	constant TimerLimit_K    : unsigned (24 downto 0) := (24 => '1', others => '0');
	
	-- Component ports
	-- Clock and reset inputs
	signal	Clock_C	: std_logic;
	signal	Reset_R	: std_logic;
	-- PAER side coming from DVS state-machine
	signal	PDVSMotherOMCreq_AB 	:	std_logic; -- Active low
	signal	PDVSMotherOMCack_AB 	:	std_logic; -- Active low
	signal	PDVSMotherOMCdata_AD	: 	unsigned (16 downto 0); -- Data in size
	-- PAER side proceeding to next state machine
	signal	PSMMotherOMCack_AB 	:	std_logic; -- Active low
	signal  PSMMotherOMCreq_AB   :	std_logic; -- Active low
	signal	OMCfireMotherOMC_D	: 	unsigned(4 downto 0);
	-- Receive Parameters
	signal	Threshold_S	:	unsigned (24 downto 0); -- Threshold Parameter
	signal	DecayTime_S	: 	unsigned (24 downto 0); -- Decay time constant
	signal	TimerLimit_S	:	unsigned (24 downto 0); -- Set timer limit

	-- Clock
	signal Clk	:	std_logic := '1'; -- Set clock
begin
--------------------------------------------------------------------------------
	-- Instantiate component ObjectMotionCell
	DUT : entity work.ObjectMotionMotherCell
	port map(
		Clock_CI		=>	Clock_C,
		Reset_RI		=>	Reset_R,
		PDVSMotherOMCreq_ABI 	=>	PDVSMotherOMCreq_AB,
		PDVSMotherOMCack_ABO 	=>	PDVSMotherOMCack_AB,
		PDVSdata_ADI	=>	PDVSMotherOMCdata_AD,
		PSMMotherOMCreq_ABO		=>  PSMMotherOMCreq_AB,
		PSMMotherOMCack_ABI 	=>	PSMMotherOMCack_AB,
		OMCfireMotherOMC_DO	 	=>	OMCfireMotherOMC_D,
		Threshold_SI	=>	Threshold_S,
		DecayTime_SI	=> 	DecayTime_S,
		TimerLimit_SI	=>	TimerLimit_S);
--------------------------------------------------------------------------------
	-- Clock Generation
	Clk     <= not Clk after 0.5 ns;
	Clock_C <= Clk;
--------------------------------------------------------------------------------
WaveGen_Proc : process -- Generate Waweforms
variable cnt1 : integer :=0;
variable cnt2 : integer :=0;
begin
	-- Initial conditions	
	Reset_R			<=	'0'; -- No reset
	PDVSMotherOMCreq_AB 		<=	'1'; -- No request
	PDVSMotherOMCdata_AD		<=	(others => '0'); -- Initial data
	PSMMotherOMCack_AB 		<=	'1'; -- No acknowledge from next State Machine received
	Threshold_S		<=	Threshold_K; -- Fixed threshold
	DecayTime_S		<= 	DecayTime_K; -- Fixed decay time
	TimerLimit_S	<=  TimerLimit_K; -- Fixed timer limit
	report  "Initial conditions set";
	
	-- Reset
	wait for 2 ns;
	Reset_R			<=	'1'; -- No Reset
	wait for 2 ns; -- Wait
	Reset_R			<=	'0'; -- No reset
	wait for 5 ns;
	report  "Reset done";
--------------------------------------------------------------------------------
	-- Case 1: request of DVS arrives (event 1)
	PDVSMotherOMCreq_AB 		<=	'0'; -- DVS request active
	wait for 2 ns;
	report  "Case 1: Request received, check if in Acknowledge state";

	-- Case 2: acknowledge received to go back to Idle state (event 1)
	if (PSMMotherOMCreq_AB = '1') then
		wait until PSMMotherOMCreq_AB = '0';
	end if;
	PSMMotherOMCack_AB 		<=	'0'; -- Acknowledge from next block received
	wait until PDVSMotherOMCack_AB = '0';							   
	wait for 2 ns;
	PDVSMotherOMCreq_AB 		<=	'1'; -- No more request
	wait for 2 ns;
	PSMMotherOMCack_AB 		<=	'1'; -- No more acknowledge from next State Machine
	report  "Case 2: Acknowledge from next State Machine received, DVS request removed and SM acknowledge removed";
	
	-- Case 3: wait to see if the decay takes place
	wait for 20 ns;
	report  "Case 3: Decay checked?";
--------------------------------------------------------------------------------
	-- Try to loop 20 times to see result with data all zero
	while (cnt1 <= 19) loop
		-- Case 4: request of DVS arrives (event 2 = same)
		PDVSMotherOMCreq_AB 		<=	'0'; -- DVS request active
		wait for 2 ns;
		report  "Case 4: Request received, check if in Acknowledge state";

		-- Case 5: acknowledge received to go back to Idle state (event 2 = same)
		if (PSMMotherOMCreq_AB = '1') then
			wait until PSMMotherOMCreq_AB = '0';
		end if;
		PSMMotherOMCack_AB 		<=	'0'; -- Acknowledge from next block received	  
		wait for 2 ns;
		if (PDVSMotherOMCack_AB = '1') then
			wait until PDVSMotherOMCack_AB = '0';
		end if;
		PDVSMotherOMCreq_AB 		<=	'1'; -- No more request
		wait for 2 ns;
		PSMMotherOMCack_AB 		<=	'1'; -- No more acknowledge from next State Machine
		report  "Case 5: Acknowledge from next State Machine received, DVS request removed and SM acknowledge removed";
		cnt1 := cnt1 + 1;
	end loop;
--------------------------------------------------------------------------------
	-- Try to loop 20 times with center subunits active
	while (cnt2 <= 19) loop
		-- Case 6: request of DVS arrives (event 3)
		PDVSMotherOMCdata_AD		<=	(16 => '1', 8 => '1', others => '0'); -- New data
		wait for 2 ns;
		PDVSMotherOMCreq_AB 		<=	'0'; -- DVS request active
		wait for 2 ns;
		report  "Case 6: Request received, check if in Acknowledge state";

		-- Case 7: acknowledge received to go back to Idle state (event 3)
		if (PSMMotherOMCreq_AB = '1') then
			wait until PSMMotherOMCreq_AB = '0';
		end if;
		PSMMotherOMCack_AB 		<=	'0'; -- Acknowledge from next block received
		if (PDVSMotherOMCack_AB = '1') then
			wait until PDVSMotherOMCack_AB = '0';
		end if;
		wait for 2 ns;
		PDVSMotherOMCreq_AB 		<=	'1'; -- No more request
		wait for 2 ns;
		PSMMotherOMCack_AB 		<=	'1'; -- No more acknowledge from next State Machine
		report  "Case 7: Acknowledge from next State Machine received, DVS request removed and SM acknowledge removed";
		cnt2 := cnt2 + 1;
	end loop;
--------------------------------------------------------------------------------	
	wait; -- Wait forever
end process WaveGen_Proc;
--------------------------------------------------------------------------------
end TestBench;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------