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

		-- PAER side proceeding to next state machine
		PSMreq_ABO 	:	out	std_logic; -- Active low
		PSMack_ABI 	:	in	std_logic; -- Active low
		OMCfire_DO	: 	out	std_logic;
		
		-- Receptive Field
		ReceptiveField_ADI : in receptiveFieldDaughterOMC;
		AllowReset_AI	   : in std_logic; -- Don't reset until allowed

		-- Receive Parameters
		Threshold_SI	:	in unsigned(24 downto 0); -- Threshold Parameter
		TimerLimit_SI	:	in unsigned(24 downto 0)); -- Set timer limit
end ObjectMotionCell;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------  

--------------------------------------------------------------------------------
-- Architecture Declaration ----------------------------------------------------
--------------------------------------------------------------------------------
architecture Behavioural of ObjectMotionCell is
	-- States
    type tst is (Idle, ExcitationCalculate, ExcitationNormalise, InhibitionCalculate, InhibitionNormalise, SubtractionCalculate, MultiplyDT, VmembraneCalculate, Checkfire, Acknowledge);
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
	
	signal	POMCack_S		: std_logic; -- Acknowledge of the OMC

	-- Parameters
	signal 	Threshold_S		:	unsigned(24 downto 0); -- Threshold Parameter
	signal 	TimerLimit_S	:	unsigned(24 downto 0); -- Set timer limit
	
	-- Unconnected
	signal	Unconnected1_S	: std_logic; -- Unused
	signal  vcc1 : std_logic; -- Short to logical 1
begin
--------------------------------------------------------------------------------
	-- Instantiate TimeStampTimer
	vcc1 <= '1';
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
		Enable_SI    => vcc1, -- Always enable
		DataLimit_DI => TimerLimit_S, -- Set the counter's limit (set the maximum counting time)
		Overflow_SO  => Unconnected1_S, -- Get the counter's overflow
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
		State_DP <= Idle;
		PreviousTimeStamp_S <= (others => '0'); -- Assign first timestamp
		Excitation_S <= (others => '0');
		Inhibition_S <= (others => '0');
		TimeBetween2Events_S <= (others => '0');
		MembranePotential_S <= (others => '0');
		Subtraction_S <= (others => '0');
		SubtractionTimesDT_S <= (others => '0');
		CurrentTimeStamp_S <= (others => '0');
		OMCFire_DO <= '0';
		
		-- Reset values before SPIConfig assignment
		Threshold_S <= (others => '0');
	 	TimerLimit_S <= (others => '1');
---------------------------------------------------------------------------------
	-- At every clock cycle
	elsif (Rising_edge(Clock_CI)) then
		State_DP <= State_DN;  -- Assign next state to current state
		
		-- Store SPIConfig
		Threshold_S <= Threshold_SI; 
	 	TimerLimit_S <= TimerLimit_SI;
		
		case State_DP is

			when Idle =>
				POMCack_S <= '1'; -- Don't acknowledge the DVS state machine
				OMCFire_DO <= '0';

			when ExcitationCalculate =>
				CurrentTimeStamp_S <= TimeStamp_S; -- Assign current timestamp
				TemporalVariable1 := (others => '0');
				for i in 1 to 2 loop
					for j in 1 to 2 loop
						TemporalVariable1 := TemporalVariable1 + ("000000000" & ReceptiveField_ADI(i,j)); -- Find the total Excitation
					end loop; -- j
				end loop; -- i
				Excitation_S <= TemporalVariable1;

			when ExcitationNormalise =>
				Excitation_S <=  ("00" & Excitation_S(24 downto 2)) - 1; -- Divide by 4 to normalise (shift by 2 bits)

			when InhibitionCalculate =>
				TemporalVariable2 := (others => '0');
				for i in 0 to 3 loop
					for j in 0 to 3 loop
						if ((i >= 1) and (i <= 2) and (j >= 1) and (j <= 2)) then
							null;
						else
							TemporalVariable2 := TemporalVariable2 + ("000000000" & ReceptiveField_ADI(i,j)); -- Find the left half of Inhibition
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
				
			when CheckFire =>
				if (MembranePotential_S >= Threshold_S) then
					OMCFire_DO <= '1';
				end if;
			
			when Acknowledge =>
				POMCack_S <= '0';
				
			when others => null;

		end case;
	end if;
end process Sequential;
--------------------------------------------------------------------------------
Combinational : process (State_DP, PDVSreq_ABI, ReceptiveField_ADI, Subtraction_S, Threshold_S, AllowReset_AI) -- Combinational Process
begin
	-- Default
	PSMreq_ABO <= '1';
	State_DN <= State_DP; -- Keep the same state

	case State_DP is

		when Idle =>
			if (PDVSreq_ABI = '0') then
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
			State_DN <= CheckFire;

		when CheckFire =>
			State_DN <= Acknowledge;
		
		when Acknowledge =>
			PSMreq_ABO <= '0'; -- Request everytime (even for no fire), change later on if only for fire event
			if ((PDVSreq_ABI = '1') and (AllowReset_AI = '1')) then
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