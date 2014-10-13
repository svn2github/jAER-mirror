--------------------------------------------------------------------------------
-- Company: INI
-- Engineer: Diederik Paul Moeys
--
-- Create Date:    28.08.2014
-- Design Name:    
-- Module Name:    ObjectMotionCell
-- Project Name:   VISUALISE
-- Target Device:  Latticed LFE3-17EA-7ftn256i
-- Tool versions:  Diamond x64 3.0.0.97x
-- Description:	   Module to mimic the processing of the Object Motion Cell RGC
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
entity ObjectMotionCell is
	port (
		-- Clock and reset inputs
		Clock_CI	: in std_logic;
		Reset_RI	: in std_logic;

		-- PAER side coming from DVS state-machine
		PDVSreq_ABI 	:	in	std_logic; -- Active low
		PDVSack_ABO 	:	out	std_logic; -- Active low
		PDVSdata_ADI	: 	in	unsigned(16 downto 0); -- Data in size

		-- PAER side proceeding to next state machine
		PSMreq_ABO 	:	out	std_logic; -- Active low
		PSMack_ABI 	:	in	std_logic; -- Active low
		OMCfire_DO	: 	out	std_logic;

		-- Receive Parameters
		Threshold_SI	:	in unsigned(24 downto 0); -- Threshold Parameter
		DecayTime_SI	: 	in unsigned(24 downto 0); -- Decay time constant
		TimerLimit_SI	:	in unsigned(24 downto 0)); -- Set timer limit
end ObjectMotionCell;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------  

--------------------------------------------------------------------------------
-- Architecture Declaration ----------------------------------------------------
--------------------------------------------------------------------------------
architecture Behavioural of ObjectMotionCell is
	-- States
    type tst is (Idle, ReadAndUpdate, ExcitationCalculate, ExcitationNormalise, InhibitionCalculate, InhibitionNormalise, SubtractionCalculate, MultiplyDT, VmembraneCalculate, Fire, Acknowledge, Decay);
	signal State_DP, State_DN: tst; -- Current state and Next state

	-- Signals
	signal	Excitation_S	: unsigned (24 downto 0); -- Excitation of center
	signal	Inhibition_S	: unsigned (24 downto 0); -- Inhibition	of periphery
	signal	Subtraction_S	: unsigned (24 downto 0); -- Subtraction of inhibition from excitation
	signal	SubtractionTimesDT_S : unsigned (24 downto 0); -- Multiply the DT times the previous subtraction
	signal	MembranePotential_S  : unsigned (24 downto 0); -- Membrane potential 
	
	signal	TimeStamp_S		: unsigned (24 downto 0); -- Timer's output used to get timestamp
	signal	CurrentTimeStamp_S		: unsigned (24 downto 0); -- Current event's timestamp
	signal	PreviousTimeStamp_S		: unsigned (24 downto 0); -- Previous event's timestamp
	signal	TimeBetween2Events_S	: unsigned (24 downto 0); -- Delta T
	
	signal 	OVFack_SO		: std_logic; -- Acknowledge of overflow
	signal	CounterOVF_S	: std_logic; -- Counter overflow for decay
	signal	POMCack_S		: std_logic; -- Acknowledge of the OMC

	-- Parameters
	signal 	Threshold_S		:	unsigned(24 downto 0); -- Threshold Parameter
	signal 	DecayTime_S		: 	unsigned(24 downto 0); -- Decay time constant
	signal 	TimerLimit_S	:	unsigned(24 downto 0); -- Set timer limit
	
	-- Unconnected
	signal	Unconnected1_S	: unsigned (24 downto 0); -- Unused
	signal	Unconnected2_S	: std_logic; -- Unused

	-- Create array of registers
	type subunits is array (15 downto 0, 15 downto 0) of unsigned(15 downto 0);
	signal arrayOfSubunits : subunits;
	signal vcc1 : std_logic; -- Short to logical 1
	signal vcc2 : std_logic; -- Short to logical 1
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
	-- Instantiate TimeStampTimer
	vcc2 <= '1';
	TimeStampTimer: entity work.ContinuousCounter
	generic map(
		SIZE              => 25, -- Maximum possible size
		RESET_ON_OVERFLOW => true, -- Reset when full (independent) 
		GENERATE_OVERFLOW => false, -- Don't generate overflow
		SHORT_OVERFLOW    => false, -- Keep the overflow
		OVERFLOW_AT_ZERO  => false) -- Overflow at "111.." not "000.." (Reset)
	port map(
		Clock_CI     => Clock_CI, -- Share the same clock
		Reset_RI     => Reset_RI, -- Share the same asynchronous reset
		Clear_SI     => Reset_RI, -- Clear with reset as well
		Enable_SI    => vcc2, -- Always enable
		DataLimit_DI => TimerLimit_S, -- Set the counter's limit (set the maximum counting time)
		Overflow_SO  => Unconnected2_S, -- Get the counter's overflow
		Data_DO      => TimeStamp_S); -- Leave unconnected
--------------------------------------------------------------------------------
	-- Instantiate Muller C-Element
	AcknowledgeCElement: entity work.MullerCelement
	port map(
		Ain     => POMCack_S, -- Acknowledge of OMC
		Bin     => PSMack_ABI, -- Next state statem-machine acknowledge
		Cout    => PDVSack_ABO); --Output of C-Element (final acknowledge)
--------------------------------------------------------------------------------
Sequential : process (Clock_CI, Reset_RI) -- Sequential Process
variable TemporalVariable1 : unsigned(24 downto 0);
variable TemporalVariable2 : unsigned(24 downto 0);
variable TemporalVariable4 : unsigned(49 downto 0);
begin
	-- External reset	
	if (Reset_RI = '1') then
		POMCack_S <= '0'; -- Acknowledge the DVS state machine
		OVFack_SO <= '1'; -- Give counter acknowledge
		State_DP <= Idle;
		PreviousTimeStamp_S <= (others => '0'); -- Assign first timestamp
		Excitation_S <= (others => '0');
		Inhibition_S <= (others => '0');
		TimeBetween2Events_S <= (others => '0');
		MembranePotential_S <= (others => '0');
		Subtraction_S <= (others => '0');
		SubtractionTimesDT_S <= (others => '0');
		CurrentTimeStamp_S <= (others => '0');
		
		-- Reset values before SPIConfig assignment
		Threshold_S <= (others => '0'); 
		DecayTime_S <= (others => '1');
	 	TimerLimit_S <= (others => '1');
	
		-- Reset all subunits to 1 (1 is always needed, so that it can be shifted)
		for i in 0 to 15 loop
      		for j in 0 to 15 loop
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
		
		case State_DP is

			when Idle =>
				POMCack_S <= '1'; -- Don't acknowledge the DVS state machine
				OVFack_SO  <= '0'; -- Remove counter acknowledge

			when ReadAndUpdate =>	 
				if (arrayOfSubunits(to_integer(PDVSdata_ADI(16 downto 13)),to_integer(PDVSdata_ADI(8 downto 5))) =  "1000000000000000") then
					null; 
				else
	        		arrayOfSubunits(to_integer(PDVSdata_ADI(16 downto 13)),to_integer(PDVSdata_ADI(8 downto 5))) <= arrayOfSubunits(to_integer(PDVSdata_ADI(16 downto 13)),to_integer(PDVSdata_ADI(8 downto 5)))(14 downto 0) & '0'; -- Multiply by 2
				end if;
				CurrentTimeStamp_S <= TimeStamp_S; -- Assign current timestamp

			when ExcitationCalculate =>
				TemporalVariable1 := (others => '0');
				for i in 8 to 9 loop
					for j in 8 to 9 loop
						TemporalVariable1 := TemporalVariable1 + ("000000000" & arrayOfSubunits(i,j)); -- Find the total Excitation
					end loop; -- j
				end loop; -- i
				Excitation_S <= TemporalVariable1;

			when ExcitationNormalise =>
				Excitation_S <=  ("00" & Excitation_S(24 downto 2)) - 1; -- Divide by 4 to normalise (shift by 2 bits)

			when InhibitionCalculate =>
				TemporalVariable2 := (others => '0');
				for i in 0 to 15 loop
					for j in 0 to 15 loop
						if ((i >= 7) and (i <= 8) and (j >= 7) and (j <= 8)) then
							null;
						else
							TemporalVariable2 := TemporalVariable2 + ("000000000" & arrayOfSubunits(i,j)); -- Find the left half of Inhibition
						end if;
					end loop; -- j
				end loop; -- i
				Inhibition_S <= (TemporalVariable2 + 4);

			when InhibitionNormalise =>
				Inhibition_S <= ("00000000" & Inhibition_S(24 downto 8)) - 1; -- Divide by 256 to normalise approximately (shift by 6 bits)

			when SubtractionCalculate =>
				if (Excitation_S >= Inhibition_S) then
					Subtraction_S <= (Excitation_S - Inhibition_S); -- Net synaptic input
				else
					Subtraction_S <= (others => '0');
				end if;
				TimeBetween2Events_S <= CurrentTimeStamp_S - PreviousTimeStamp_S; -- Delta T (time passed between 2 events)

			when MultiplyDT => 
				TemporalVariable4 := Subtraction_S * TimeBetween2Events_S;
				SubtractionTimesDT_S <= TemporalVariable4(24 downto 0); -- Integration
				PreviousTimeStamp_S <= CurrentTimeStamp_S; -- Reset previous timestamp to current timestamp 
				
			when VmembraneCalculate =>
				MembranePotential_S <= MembranePotential_S + SubtractionTimesDT_S; -- Membrane potential

			when Decay =>
				for i in 0 to 15 loop
					for j in 0 to 15 loop
						if (arrayOfSubunits(i,j) = "0000000000000001") then -- Already at minimum possible
							null;
						else
							arrayOfSubunits(i,j) <= '0' & arrayOfSubunits(i,j)(15 downto 1); -- Decay by dividing by 2
						end if;
					end loop; -- j
				end loop; -- i
				OVFack_SO  <= '1'; -- Give counter acknowledge				

			when Acknowledge =>
				POMCack_S <= '0';
				
			when others => null;

		end case;
	end if;
end process Sequential;
--------------------------------------------------------------------------------
Combinational : process (State_DP, PDVSreq_ABI, CounterOVF_S, arrayOfSubunits, PDVSdata_ADI, Subtraction_S, Threshold_S) -- Combinational Process
begin
	-- Default
	OMCFire_DO <= '0';
	PSMreq_ABO <= '1';
	State_DN <= State_DP; -- Keep the same state

	case State_DP is

		when Idle =>
			if ((PDVSreq_ABI = '0') and (CounterOVF_S = '0')) then
				State_DN <= ReadAndUpdate;
			elsif (CounterOVF_S = '1') then
				State_DN <= Decay;
			else null;
			end if;				

		when ReadAndUpdate =>	
			if (arrayOfSubunits(to_integer(PDVSdata_ADI(16 downto 13)),to_integer(PDVSdata_ADI(8 downto 5))) = "1000000000000000") then
				State_DN <= Acknowledge;
			else
				State_DN <= ExcitationCalculate;
			end if;

		when ExcitationCalculate =>
			State_DN <= ExcitationNormalise;

		when ExcitationNormalise =>
			State_DN <= InhibitionCalculate;

		when InhibitionCalculate =>
			State_DN <= InhibitionNormalise;
			
		when InhibitionNormalise =>
			State_DN <= SubtractionCalculate;

		when SubtractionCalculate =>
			State_DN <= MultiplyDT;
		
		when MultiplyDT => 
			State_DN <= VmembraneCalculate;
				
		when VmembraneCalculate =>
			if (Subtraction_S > Threshold_S) then
				State_DN <= Fire;
			else 
				State_DN <= Acknowledge;
			end if;	

		when Fire =>
			OMCFire_DO <= '1';
			State_DN <= Acknowledge;

		when Acknowledge =>
			PSMreq_ABO <= '0'; -- Request everytime (even for no fire), change later on if only for fire event
			if (PDVSreq_ABI = '1') then
				State_DN <= Idle;
			else 
				null;
			end if;

		when Decay =>	 
			if (CounterOVF_S = '0') then
				State_DN <= Idle;		
			else
				null;
			end if;
			
		when others => null;

	end case;
end process Combinational;
--------------------------------------------------------------------------------
end Behavioural;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------