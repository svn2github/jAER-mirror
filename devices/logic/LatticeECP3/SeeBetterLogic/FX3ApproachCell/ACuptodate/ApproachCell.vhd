library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.ApproachSensitivityConfigRecords.all;


entity ApproachCellStateMachine is

	generic (Counter_Size : Integer;
			 UpdateUnit:  Integer);
	
    port(
		Clock_CI                 : in  std_logic;
		Reset_RI                 : in  std_logic;
		
		DVSEvent_I				 : in  std_logic;
		
		EventXAddr_I, EventYAddr_I	 : in  std_logic_vector( 4 downto 0); 
		
		EventPolarity_I					 : in std_logic;
		
		Decay_Enable				     : in std_logic;
		
		AC_Fire_O    					 : out std_logic_vector;
		
		);
		
		
end entity ApproachCellStateMachine;


architecture Behavioral of ApproachCellStateMachine is

	attribute syn_enum_encoding : string

	type state is (stIdle, stDecay, stOnEvent, stOffEvent, stComputeInputtoAC, stComputeSynapticInput, stComputeMembraneState, stComparetoIFThreshold);
	
	attribute syn_enum_encoding of state : type is "onehot";
	
	--type Subunit is array (2 downto 0 , 2 downto 0) of tSubunitParameter;
	type tVmem is array (integer range, integer range) of signed(31 downto 0) ;
	
	signal VmemOn, VmemOff, InputtoACOn, InputtoACOff :  tVmem(2 downto 0 ,2 downto 0); 
	
	--type  is array (2 downto 0 , 2 downto 0) of signed( 31 downto 0) ;
	--type  is array (2 downto 0 , 2 downto 0) of signed( 31 downto 0) ;
	--type  is array (2 downto 0 , 2 downto 0) of signed( 31 downto 0) ;
	
	

	-- present and next state
	signal State_DP, State_DN : state;			 
	signal LastTimestamp, Timestamp : std_logic_vector(Counter_Size - 1 downto 0);
	signal EnableCounter std_logic;
	signal OverflowAlert std_logic;
	signal CounterOut std_logic;
	signal EventYAddress, EventXAddress: std_logic_vector(7 downto 0);
	signal Decay_Enable 					 : in  std_logic;
	signal MembraneState   : std_logic_vector(63 downto 0);
	signal netSynapicInput  : std_logic_vector(31 downto 0);
			
begin
	
	
	EventTimestampCounter : entity work.ContinuousCounter
	
		generic map(
			SIZE => Counter_Size)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => '1',
			DataLimit_DI => unsigned (Counter_Size - 1 downto 0),
			Overflow_SO  => OverflowAlert,  --- what to do with the Overflow Alert? 
			Data_DO      => CounterOut);
			
			
	p_memoryless : process(State_DP, CounterOut, DVSEvent_I, EventXAddr_I, EventYAddr_I, Decay_Enable, EventPolarity_I, VmemOn, VmemOff)---should they be here?
			variable sum, V: sum, V is array (2 downto 0 , 2 downto 0) of signed( 31 downto 0) 
			variable i, j : integer range 0 to 7
			 ----- is this neccessary?
			variable n:     integer range 0 to 4
		
		begin
			
			State_DN <= State_DP;           
			VmemOn <= (others => '0');   ----for array, use for loop to initiate?
			result <= (others => '0');
			CounterValue <= (others => '0');  ---what should I put here?  those who are saved in reg e.g. SubunitVmem, SubunitSum not?
			AC_Fire <= '0';

			
		
			case State_DP is
			
				when stIdle =>
					 if DVSEvent_I = '1' then 
						LastTimeStamp <= TimeStamp ;  						 -----I am not sure whether to put it here or not.
						dT := Timestamp  - LastTimestamp ;
						TimeStamp  <=CounterOut ;
						if EventPolarity_I= '0' then 
						   State_DN <= stOffEvent; 
					    elsif EventPolarity_I= '1' then 
						   State_DN <= stOnEvent;
					 elsif Decay_Enable = '1' then 
							State_DN <= stDecay;
					 else State_DN <= stIdle;
					 end if;

				when stDecay => 
					 VOn(i,j) :=  '0' && VmemOn(i,j)(30 downto 0);
					 VmemOn(i,j) <= VOn(i,j);
					 VOff(i,j) :=  '0' & VmemOff(i,j)(30 downto 0);
					 VmemOff(i,j) <= VOff(i,j);
					 State_DN <= stIdle;

				 when stOnEvent =>
					 State_DN <= stComputeInputtoAC;
					 
							if i= unsigned (EventXAddr_I (4 downto 2)) & j = unsigned (EventXAddr_I (4 downto 2)) then ----else? end if?
								VOn(i,j) :=  VmemOn(i,j) + UpdateUnit; 
								VmemOn(i,j) <= VOn(i,j);
							end if;
								--or can I use Subunit(i,j).VmemOn + = UpdateUnit;
			     when stOffEvent =>
					 State_DN <= stComputeInputtoAC;
					 
							if i= unsigned (EventXAddr_I (4 downto 2)) and j = unsigned (EventXAddr_I (4 downto 2)) then 
								VOff(i,j) :=  VmemOff(i,j) + UpdateUnit; 
								VmemOff(i,j)  <= VOff(i,j);	 
								--or can I use Subunit(i,j).VmemOn + = UpdateUnit;
							end if;
							 
				 when stComputeInputtoAC =>	
						State_DN <= stComputesynapticInput;
					
							 if  surroundSuppressionEnabled => '1'	then 
								n :=0  ---????
								--i := tSubunit.Xaddr; 
								--j := tSubunit.Yaddr;
							    	for i in 0 to 7 loop
   									   for j in 0 to 7 loop----??right?
								
										if i < 7 then
											
											sumOff(i,j) := sumOff(i,j) + Subunit(i+1,j).VmemOff;
											n : = n + 1 ;
										end if;
										if i > 0 then 
											sumOff(i,j) := sumOff(i,j) + Subunit(i-1,j).VmemOff;
											n : = n + 1 ;
											
										if j > 0 then 
											sumOff(i,j) := sumOff(i,j) + Subunit(i,j-1).VmemOff;
											n : = n + 1 ;
											
										if j< 7  then								
											sumOff(i,j) := sumOff(i,j) + Subunit(i,j+1).VmemOff;
											n : = n + 1 ;	
			
											sumOff(i,j) := sumOff(i,j) / n;
											result(i,j) := VOff(i,j) - sumOff(i,j);
											if result(i,j) < 0 then InputtoACOff(i,j) <= 0;
											else InputtoACOff(i,j) <= result(i,j);
											end if;
										end if;
							
											
						    	   for i in 0 to 7  for j in 0 to 7
							  
										if i< 7 then
											
											sumOn(i,j) := sumOn(i,j) + Subunit(i+1,j).VmemOn;
											n : = n + 1 ;
										if i > 0 then 
											sumOn(i,j) := sumOn(i,j) + Subunit(i-1,j).VmemOn;
											n : = n + 1 ;
											
										if j > 0 then 
											sumOn(i,j) := sumOn(i,j) + Subunit(i,j-1).VmemOn;
											n : = n + 1 ;
											
										if j< 7 then								
											sumOn(i,j) := sumOn(i,j) + Subunit(i,j+1).VmemOn;
											n : = n + 1 ;	
			
											sumOn(i,j) := sumOn(i,j) / n;
											result(i,j) := VOn(i,j) - sumOn(i,j);
											if result(i,j) < 0 then InputtoACOn(i,j) <= 0;
											else InputtoACOn(i,j) <= result(i,j);
											end if;										
								
							 else InputtoACOff(i,j) <=VmemOff(i,j);	
								  InputtoACOn(i,j)  <=VmemOn(i,j);
							 
							 end if;	
					
			 
				when stComputeSynapticInput =>
						State_DN <= stComputeMembraneState;
							
								for i in 0 to 7 loop
									for j in 0 to 7 loop
									sumACRFOn : = sumACRFOn + InputtoACOn(i,j) ;
									sumACRFOff : = sumACRFOff + InputtoACOff(i,j) ;
									
						netSynapticInput <= sumACRFOff - sumACRFOn;
										

						
				when stComputeMembraneState =>
						              
						MS := MembraneState + netSynapicInput * dT;
						MembraneState <= MS ;
						State_DN <= stComparetoIFThreshold; 
						
				when stComparetoIFThreshold =>
						State_DN <= stIdle;
						if MembraneState > IFThreshold    then
							AC_Fire_O  <= 1
							MembraneState <= 0 ;
						elsif MembraneState < -10  then 
							MembraneState = 0;
						end if;

				when others => null;
			end case;
		end process SubunitStateMachine_memoryless;
		

		-- Change state on clock edge (synchronous).
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;
			iREQ_decay <= '0';
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;
			if OVF='1' then 
			   iREQ_decay <='1';
			elsif State_DP = stDecay then
			   iREQ_decay <= '0';
			end if;
			
		end if;
	end process p_memoryzing;
end Behavioral;
