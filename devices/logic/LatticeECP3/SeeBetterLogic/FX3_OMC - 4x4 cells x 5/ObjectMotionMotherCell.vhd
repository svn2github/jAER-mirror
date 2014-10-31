--------------------------------------------------------------------------------
-- Company: INI
-- Engineer: Diederik Paul Moeys
--
-- Create Date:    28.08.2014
-- Design Name:    
-- Module Name:    ObjectMotionMotherCell
-- Project Name:   VISUALISE
-- Target Device:  Latticed LFE3-17EA-7ftn256i
-- Tool versions:  Diamond x64 3.0.0.97x
-- Description:	   Ensemble of 5 OMC
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Libraries -------------------------------------------------------------------
-------------------------------------------------------------------------------- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ObjectMotionCellConfigRecords.all;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Entity Declaration ----------------------------------------------------------
--------------------------------------------------------------------------------
entity ObjectMotionMotherCell is
	port (
		-- Clock and reset inputs
		Clock_CI	: in std_logic;
		Reset_RI	: in std_logic;

		-- PAER side coming from DVS state-machine
		PDVSMotherOMCreq_ABI 	:	in	std_logic; -- Active low
		PDVSMotherOMCack_ABO 	:	out	std_logic; -- Active low
		PDVSdata_ADI	: 	in	unsigned(16 downto 0); -- Data in size

		-- PAER side proceeding to next state machine
		PSMMotherOMCreq_ABO 	:	out	std_logic; -- Active low
		PSMMotherOMCack_ABI 	:	in	std_logic; -- Active low
		OMCfireMotherOMC_DO		: 	out	unsigned(4 downto 0);

		-- Receive Parameters
		Threshold_SI	:	in unsigned(24 downto 0); -- Threshold Parameter
		DecayTime_SI	: 	in unsigned(24 downto 0); -- Decay time constant
		TimerLimit_SI	:	in unsigned(24 downto 0)); -- Set timer limit
end ObjectMotionMotherCell;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------  

--------------------------------------------------------------------------------
-- Architecture Declaration ----------------------------------------------------
--------------------------------------------------------------------------------
architecture Behavioural of ObjectMotionMotherCell is
	-- States
    type tst is (Idle, ReadAndUpdate, CheckIfDone, Decay);
	signal State_DP, State_DN: tst; -- Current state and Next state

	-- Signals
	signal 	OVFack_SO		: std_logic; -- Acknowledge of overflow
	signal	CounterOVF_S	: std_logic; -- Counter overflow for decay
	
	-- Signals of OMCs
	signal	PDVSreqOMC1_S	: std_logic;
	signal	PDVSackOMC1_S	: std_logic;
	signal	PSMreqOMC1_S	: std_logic;
	signal	OMCfireOMC1_S	: std_logic;

	signal	PDVSreqOMC2_S	: std_logic;
	signal	PDVSackOMC2_S	: std_logic;
	signal	PSMreqOMC2_S	: std_logic;
	signal	OMCfireOMC2_S	: std_logic;
	
	signal	PDVSreqOMC3_S	: std_logic;
	signal	PDVSackOMC3_S	: std_logic;
	signal	PSMreqOMC3_S	: std_logic;
	signal	OMCfireOMC3_S	: std_logic;
	
	signal	PDVSreqOMC4_S	: std_logic;
	signal	PDVSackOMC4_S	: std_logic;
	signal	PSMreqOMC4_S	: std_logic;
	signal	OMCfireOMC4_S	: std_logic;
	
	signal	PDVSreqOMC5_S	: std_logic;
	signal	PDVSackOMC5_S	: std_logic;
	signal	PSMreqOMC5_S	: std_logic;
	signal	OMCfireOMC5_S	: std_logic;

	signal  AllowReset_S	: std_logic;
	
	-- Parameters
	signal 	Threshold_S		:	unsigned(24 downto 0); -- Threshold Parameter
	signal 	DecayTime_S		: 	unsigned(24 downto 0); -- Decay time constant
	signal 	TimerLimit_S	:	unsigned(24 downto 0); -- Set timer limit
	
	-- Unconnected
	signal	Unconnected1_S	: unsigned (24 downto 0); -- Unused

	-- Create array of registers
	signal	arrayOfSubunits		: 	receptiveFieldMotherOMC;
	signal	arrayOfSubunitsOMC1	: 	receptiveFieldDaughterOMC;
	signal	arrayOfSubunitsOMC2	: 	receptiveFieldDaughterOMC;
	signal	arrayOfSubunitsOMC3	: 	receptiveFieldDaughterOMC;
	signal	arrayOfSubunitsOMC4	: 	receptiveFieldDaughterOMC;
	signal	arrayOfSubunitsOMC5	: 	receptiveFieldDaughterOMC;
	signal vcc1 : std_logic; -- Short to logical 1
begin
--------------------------------------------------------------------------------
	-- Instantiate DecayCounter
	vcc1 <= '1';
	DecayCounter: entity work.ContinuousCounter
	generic map(
		SIZE              => 25, -- Maximum possible size
		RESET_ON_OVERFLOW => false, -- Reset only when OVFack_SO is '1' 
		GENERATE_OVERFLOW => true, -- Generate overflow
		SHORT_OVERFLOW    => false, -- Keep the overflow
		OVERFLOW_AT_ZERO  => false) -- Overflow at "111.." not "000.." (Reset)
	port map(
		Clock_CI     => Clock_CI, -- Share the same clock
		Reset_RI     => Reset_RI, -- Share the same asynchronous reset
		Clear_SI     => OVFack_SO, -- Clear with acknowledge of overflow
		Enable_SI    => vcc1, -- Always enable
		DataLimit_DI => DecayTime_S, -- Set the counter's limit (set the decay time)
		Overflow_SO  => CounterOVF_S, -- Get the counter's overflow
		Data_DO      => Unconnected1_S); -- Leave unconnected			
--------------------------------------------------------------------------------
	-- OMC1
	OMC1: entity work.ObjectMotionCell
	port map(
		-- Clock and reset inputs
		Clock_CI     => Clock_CI, -- Share the same clock
		Reset_RI     => Reset_RI, -- Share the same asynchronous reset
		-- PAER side coming from DVS state-machine
		PDVSreq_ABI =>	PDVSreqOMC1_S, -- Active low
		PDVSack_ABO	=>	PDVSackOMC1_S, -- Active low
		-- PAER side proceeding to next state machine
		PSMreq_ABO 	=>	PSMreqOMC1_S, -- Active low
		PSMack_ABI 	=>	PSMMotherOMCack_ABI, -- Active low
		OMCfire_DO	=> 	OMCfireOMC1_S,
		-- Receptive Field
		ReceptiveField_ADI => arrayOfSubunitsOMC1,
		-- Reset permission
		AllowReset_AI	=> AllowReset_S,
		-- Receive Parameters
		Threshold_SI	=> Threshold_SI, -- Threshold Parameter
		TimerLimit_SI	=> TimerLimit_SI); -- Set timer limit
--------------------------------------------------------------------------------
	-- OMC2
	OMC2: entity work.ObjectMotionCell
	port map(
		-- Clock and reset inputs
		Clock_CI     => Clock_CI, -- Share the same clock
		Reset_RI     => Reset_RI, -- Share the same asynchronous reset
		-- PAER side coming from DVS state-machine
		PDVSreq_ABI =>	PDVSreqOMC2_S, -- Active low
		PDVSack_ABO	=>	PDVSackOMC2_S, -- Active low
		-- PAER side proceeding to next state machine
		PSMreq_ABO 	=>	PSMreqOMC2_S, -- Active low
		PSMack_ABI 	=>	PSMMotherOMCack_ABI, -- Active low
		OMCfire_DO	=> 	OMCfireOMC2_S,
		-- Receptive Field
		ReceptiveField_ADI => arrayOfSubunitsOMC2,
		-- Reset permission
		AllowReset_AI	=> AllowReset_S,
		-- Receive Parameters
		Threshold_SI	=> Threshold_SI, -- Threshold Parameter
		TimerLimit_SI	=> TimerLimit_SI); -- Set timer limit
--------------------------------------------------------------------------------
	-- OMC3
	OMC3: entity work.ObjectMotionCell
	port map(
		-- Clock and reset inputs
		Clock_CI     => Clock_CI, -- Share the same clock
		Reset_RI     => Reset_RI, -- Share the same asynchronous reset
		-- PAER side coming from DVS state-machine
		PDVSreq_ABI =>	PDVSreqOMC3_S, -- Active low
		PDVSack_ABO	=>	PDVSackOMC3_S, -- Active low
		-- PAER side proceeding to next state machine
		PSMreq_ABO 	=>	PSMreqOMC3_S, -- Active low
		PSMack_ABI 	=>	PSMMotherOMCack_ABI, -- Active low
		OMCfire_DO	=> 	OMCfireOMC3_S,
		-- Receptive Field
		ReceptiveField_ADI => arrayOfSubunitsOMC3,
		-- Reset permission
		AllowReset_AI	=> AllowReset_S,
		-- Receive Parameters
		Threshold_SI	=> Threshold_SI, -- Threshold Parameter
		TimerLimit_SI	=> TimerLimit_SI); -- Set timer limit
--------------------------------------------------------------------------------
	-- OMC4	
	OMC4: entity work.ObjectMotionCell
	port map(
		-- Clock and reset inputs
		Clock_CI     => Clock_CI, -- Share the same clock
		Reset_RI     => Reset_RI, -- Share the same asynchronous reset
		-- PAER side coming from DVS state-machine
		PDVSreq_ABI =>	PDVSreqOMC4_S, -- Active low
		PDVSack_ABO	=>	PDVSackOMC4_S, -- Active low
		-- PAER side proceeding to next state machine
		PSMreq_ABO 	=>	PSMreqOMC4_S, -- Active low
		PSMack_ABI 	=>	PSMMotherOMCack_ABI, -- Active low
		OMCfire_DO	=> 	OMCfireOMC4_S,
		-- Receptive Field
		ReceptiveField_ADI => arrayOfSubunitsOMC4,
		-- Reset permission
		AllowReset_AI	=> AllowReset_S,
		-- Receive Parameters
		Threshold_SI	=> Threshold_SI, -- Threshold Parameter
		TimerLimit_SI	=> TimerLimit_SI); -- Set timer limit
--------------------------------------------------------------------------------
	-- OMC5
	OMC5: entity work.ObjectMotionCell
	port map(
		-- Clock and reset inputs
		Clock_CI     => Clock_CI, -- Share the same clock
		Reset_RI     => Reset_RI, -- Share the same asynchronous reset
		-- PAER side coming from DVS state-machine
		PDVSreq_ABI =>	PDVSreqOMC5_S, -- Active low
		PDVSack_ABO	=>	PDVSackOMC5_S, -- Active low
		-- PAER side proceeding to next state machine
		PSMreq_ABO 	=>	PSMreqOMC5_S, -- Active low
		PSMack_ABI 	=>	PSMMotherOMCack_ABI, -- Active low
		OMCfire_DO	=> 	OMCfireOMC5_S,
		-- Receptive Field
		ReceptiveField_ADI => arrayOfSubunitsOMC5,
		-- Reset permission
		AllowReset_AI	=> AllowReset_S,
		-- Receive Parameters
		Threshold_SI	=> Threshold_SI, -- Threshold Parameter
		TimerLimit_SI	=> TimerLimit_SI); -- Set timer limit
--------------------------------------------------------------------------------
Sequential : process (Clock_CI, Reset_RI) -- Sequential Process
begin
	-- External reset	
	if (Reset_RI = '1') then
		OVFack_SO <= '1'; -- Give counter acknowledge
		State_DP <= Idle;
		PDVSMotherOMCack_ABO <= '0';
		PSMMotherOMCreq_ABO  <= '1';
		OMCfireMotherOMC_DO  <= (others => '0');

			-- Signals of OMCs
		PDVSreqOMC1_S	<= '1';
		PDVSackOMC1_S	<= '1';
		PSMreqOMC1_S	<= '1';
		OMCfireOMC1_S	<= '0';

		PDVSreqOMC2_S	<= '1';
		PDVSackOMC2_S	<= '1';
		PSMreqOMC2_S	<= '1';
		OMCfireOMC2_S	<= '0';
	
		PDVSreqOMC3_S	<= '1';
		PDVSackOMC3_S	<= '1';
		PSMreqOMC3_S	<= '1';
		OMCfireOMC3_S	<= '0';
	
		PDVSreqOMC4_S	<= '1';
		PDVSackOMC4_S	<= '1';
		PSMreqOMC4_S	<= '1';
		OMCfireOMC4_S	<= '0';
	
		PDVSreqOMC5_S	<= '1';
		PDVSackOMC5_S	<= '1';
		PSMreqOMC5_S	<= '1';
		OMCfireOMC5_S	<= '0';
		
		AllowReset_S <= '0';
	
		-- Reset values before SPIConfig assignment
		Threshold_S  <= (others => '0'); 
		DecayTime_S  <= (others => '1');
	 	TimerLimit_S <= (others => '1');
		
		-- Reset Receptive Fields
		for i in 0 to 3 loop
      		for j in 0 to 3 loop
        		arrayOfSubunitsOMC1(i,j) <= (others => '0');
      		end loop; -- j
    	end loop; -- i
		for i in 0 to 3 loop
      		for j in 0 to 3 loop
        		arrayOfSubunitsOMC2(i,j) <= (others => '0');
      		end loop; -- j
    	end loop; -- i
		for i in 0 to 3 loop
      		for j in 0 to 3 loop
        		arrayOfSubunitsOMC3(i,j) <= (others => '0');
      		end loop; -- j
    	end loop; -- i
		for i in 0 to 3 loop
      		for j in 0 to 3 loop
        		arrayOfSubunitsOMC4(i,j) <= (others => '0');
      		end loop; -- j
    	end loop; -- i
		for i in 0 to 3 loop
      		for j in 0 to 3 loop
        		arrayOfSubunitsOMC5(i,j) <= (others => '0');
      		end loop; -- j
    	end loop; -- i
	
		-- Reset all subunits to 1 (1 is always needed, so that it can be shifted)
		for i in 0 to 7 loop
      		for j in 0 to 7 loop
        		arrayOfSubunits(i,j) <= (0 => '1', others => '0');
      		end loop; -- j
    	end loop; -- i
---------------------------------------------------------------------------------
	-- At every clock cycle
	elsif (Rising_edge(Clock_CI)) then
		State_DP <= State_DN;  -- Assign next state to current state
		
		-- Store SPIConfig
		Threshold_S <= Threshold_SI; 
		DecayTime_S <= DecayTime_SI;
	 	TimerLimit_S <= TimerLimit_SI;
		
		-- Set Receptive Fields
		for i in 0 to 3 loop
      		for j in 0 to 3 loop
        		arrayOfSubunitsOMC1(i,j) <= arrayOfSubunits(i,j);
        		arrayOfSubunitsOMC2(i,j) <= arrayOfSubunits(i+3,j);
        		arrayOfSubunitsOMC3(i,j) <= arrayOfSubunits(i,j+3);
        		arrayOfSubunitsOMC4(i,j) <= arrayOfSubunits(i+3,j+3);
        		arrayOfSubunitsOMC5(i,j) <= arrayOfSubunits(i+2,j+2);
      		end loop; -- j
    	end loop; -- i
		
		-- Next stage request managed by OMCs
		PSMMotherOMCreq_ABO <= not((PSMreqOMC1_S) and (PSMreqOMC2_S) and (PSMreqOMC3_S) and (PSMreqOMC4_S) and (PSMreqOMC5_S));

		case State_DP is

			when Idle =>
				PDVSMotherOMCack_ABO <= '1'; -- Don't acknowledge the DVS state machine
				
				-- Don't request to daughters
				PDVSreqOMC1_S <= '1';
				PDVSreqOMC2_S <= '1';
				PDVSreqOMC3_S <= '1';
				PDVSreqOMC4_S <= '1';
				PDVSreqOMC5_S <= '1';
				
				OVFack_SO  <= '0'; -- Remove counter acknowledge
				
				AllowReset_S <= '1'; -- Allow Daughter OMC to go back to Idle state
				
			when ReadAndUpdate =>	 
				AllowReset_S <= '0';
				if (arrayOfSubunits(to_integer(PDVSdata_ADI(16 downto 14)),to_integer(PDVSdata_ADI(8 downto 6))) =  "1000000000000000") then
					null; 
				else
	        		arrayOfSubunits(to_integer(PDVSdata_ADI(16 downto 14)),to_integer(PDVSdata_ADI(8 downto 6))) <= arrayOfSubunits(to_integer(PDVSdata_ADI(16 downto 14)),to_integer(PDVSdata_ADI(8 downto 6)))(14 downto 0) & '0'; -- Multiply by 2
				end if;
				-- OMC1 req
				if((to_integer(PDVSdata_ADI(16 downto 14)) <= 3) and (to_integer(PDVSdata_ADI(8 downto 6)) <= 3) and (to_integer(PDVSdata_ADI(16 downto 14)) >= 0) and (to_integer(PDVSdata_ADI(8 downto 6)) >= 0)) then
					PDVSreqOMC1_S <= PDVSMotherOMCreq_ABI;
				end if;
				-- OMC2 req
				if((to_integer(PDVSdata_ADI(16 downto 14)) <= 7) and (to_integer(PDVSdata_ADI(8 downto 6)) <= 3) and (to_integer(PDVSdata_ADI(16 downto 14)) >= 4) and (to_integer(PDVSdata_ADI(8 downto 6)) >= 0)) then
					PDVSreqOMC2_S <= PDVSMotherOMCreq_ABI;
				end if;
				-- OMC3 req
				if((to_integer(PDVSdata_ADI(16 downto 14)) <= 3) and (to_integer(PDVSdata_ADI(8 downto 6)) <= 7) and (to_integer(PDVSdata_ADI(16 downto 14)) >= 0) and (to_integer(PDVSdata_ADI(8 downto 6)) >= 4)) then
					PDVSreqOMC3_S <= PDVSMotherOMCreq_ABI;
				end if;
				-- OMC4 req
				if((to_integer(PDVSdata_ADI(16 downto 14)) <= 7) and (to_integer(PDVSdata_ADI(8 downto 6)) <= 7) and (to_integer(PDVSdata_ADI(16 downto 14)) >= 4) and (to_integer(PDVSdata_ADI(8 downto 6)) >= 4)) then
					PDVSreqOMC4_S <= PDVSMotherOMCreq_ABI;
				end if;
				-- OMC5 req
				if((to_integer(PDVSdata_ADI(16 downto 14)) <= 5) and (to_integer(PDVSdata_ADI(8 downto 6)) <= 5) and (to_integer(PDVSdata_ADI(16 downto 14)) >= 2) and (to_integer(PDVSdata_ADI(8 downto 6)) >= 2)) then
					PDVSreqOMC5_S <= PDVSMotherOMCreq_ABI;
				end if;

			when CheckIfDone =>
				if (not((PDVSackOMC5_S) and (PDVSackOMC5_S) and (PDVSackOMC5_S) and (PDVSackOMC5_S) and (PDVSackOMC5_S)) = '0') then
					OMCFireMotherOMC_DO <= (0 => OMCfireOMC1_S, 1 => OMCfireOMC2_S, 2 => OMCfireOMC3_S, 3 => OMCfireOMC4_S, 4 => OMCfireOMC5_S);
				end if;

			when Decay =>
				for i in 0 to 7 loop
					for j in 0 to 7 loop
						if (arrayOfSubunits(i,j) = "0000000000000001") then -- Already at minimum possible
							null;
						else
							arrayOfSubunits(i,j) <= '0' & arrayOfSubunits(i,j)(15 downto 1); -- Decay by dividing by 2
						end if;
					end loop; -- j
				end loop; -- i
				OVFack_SO  <= '1'; -- Give counter acknowledge				
				
			when others => null;

		end case;
	end if;
end process Sequential;
--------------------------------------------------------------------------------
Combinational : process (State_DP, PDVSMotherOMCreq_ABI, arrayOfSubunits, CounterOVF_S, PDVSdata_ADI, PDVSackOMC1_S, PDVSackOMC2_S, PDVSackOMC3_S, PDVSackOMC4_S, PDVSackOMC5_S) -- Combinational Process
begin
	-- Default
	State_DN <= State_DP; -- Keep the same state

	case State_DP is

		when Idle =>
			if ((PDVSMotherOMCreq_ABI = '0') and (CounterOVF_S = '0')) then
				State_DN <= ReadAndUpdate;
			elsif (CounterOVF_S = '1') then
				State_DN <= Decay;
			end if;

		when ReadAndUpdate =>	
			if (arrayOfSubunits(to_integer(PDVSdata_ADI(16 downto 14)),to_integer(PDVSdata_ADI(8 downto 6))) = "1000000000000000") then
				State_DN <= Idle;
			else
				State_DN <= CheckIfDone;
			end if;

		when CheckIfDone =>
			if (not((PDVSackOMC1_S) and (PDVSackOMC2_S) and (PDVSackOMC3_S) and (PDVSackOMC4_S) and (PDVSackOMC5_S)) = '0') then
				State_DN <= Idle;
			end if;

		when Decay =>	 
			if (CounterOVF_S = '0') then
				State_DN <= Idle;		
			end if;
			
		when others => null;

	end case;
end process Combinational;
--------------------------------------------------------------------------------
end Behavioural;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------