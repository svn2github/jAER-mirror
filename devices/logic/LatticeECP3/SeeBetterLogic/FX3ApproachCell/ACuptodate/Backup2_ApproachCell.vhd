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
		
		DVSAEREvent_Code		 		 : in  std_logic_vector( EVENT_WIDTH-1 downto 1); 
		
		AC_Fire_O    					 : out std_logic_vector;
		
		Decay_Enable 					 : in  std_logic;
		);
		
		
end entity ApproachCellStateMachine;


architecture Behavioral of ApproachCellStateMachine is

	attribute syn_enum_encoding : string

	type state is (stIdle, stDecayALL, stDifferentiateXY, stUpdateSubunites, stComputeInputtoAC, stComputeOnInOffExci, stUpdateACVmem, stComparetoIFThreshold, stCheckRF, Fire);
	
	attribute syn_enum_encoding of state : type is "onehot";
	
	type Subunit is array (5 downto 0 , 5 downto 0) of tSubunitParameter;
	type ApproachCell is array (2 downto 0 , 2 downto 0) of tApproachCellParameter;
	
	type tSubunitParameter.VmemOn is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0) ;
	type tSubunitParameter.VmemOff is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0) ;
	type tSubunitParameter.InputtoACOn is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0)  ;
	type tSubunitParameter.InputtoACOff is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0)  ;
	type tApproachCellParameter.OnInhibition is array (2 downto 0 , 2 downto 0) of signed( 31 downto 0)  ;
	type tApproachCellParameter.OffExcitation is array (2 downto 0 , 2 downto 0) of signed( 31 downto 0) ;
	type tApproachCellParameter.Vmem is array (2 downto 0 , 2 downto 0) of signed( 31 downto 0)  ;  ----ref O?  AC_fire_O_Reg?

	-- present and next state
	signal State_DP, State_DN : state;			 
	signal LastTimestamp, Timestamp : std_logic_vector(Counter_Size - 1 downto 0);
	signal EnableCounter std_logic;
	signal OverflowAlert std_logic;
	signal CounterOut std_logic;
	signal EventYAddress, EventXAddress: std_logic_vector(7 downto 0);
			
begin
	
	
	EventTimestampCounter : entity work.ContinuousCounter
	
		generic map(
			SIZE => Counter_Size)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => EnableCounter,
			DataLimit_DI => unsigned (Counter_Size - 1 downto 0),
			Overflow_SO  => OverflowAlert,  --- what to do with the Overflow Alert? 
			Data_DO      => CounterOut);

	p_memoryless : process(State_DP, CounterOut, DVSEvent_I, DVSAEREvent_Code, tSubunitParameter, tApproachCellParameter)---should they be here?
		
		begin
			
			State_DN <= State_DP;           
			Vmem <= (others => '0');   ----for array, use for loop to initiate?
			result <= (others => '0');
			CounterValue <= (others => '0');  ---what should I put here?  those who are saved in reg e.g. SubunitVmem, SubunitSum not?
			AC_Fire <= '0';

			variable sum, V: sum, V is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0) 
		
			case State_DP is
			
				when stIdle =>
					 if DVSEvent_I = '1' then 
						State_DN <= stDifferentiateXY;
				        EnableCounter <= '1';     -----EnableCounter keep 1 afterwards? Do I need to use reg?
					 elsif Decay_Enable = '1' then 
							State_DN <= stDecay;
					 else State_DN <= stIdle;

				when stDecay => 
					 Vmem := Vmem srl 1;
					 State_DN <= stIdle;	
					 
				when stDifferentiateXY =>		
					 if DVSAEREvent_Code[14 downto 12] = '001' then 
						State_DN <= stWaitforXaddress; 
						EventYAddress <= DVSAEREvent_Code[7 downto 0];   ---Do I need to say save this? 
					 else State_DN <= stIdle;
					 
				when stWaitforXaddress =>
					  if DVSAEREvent_Code[14 downto 12] = '010' then 
						 State_DN <= stOffEvent; 
						 LastTimeStamp <= TimeStamp;    -----I am not sure whether to put it here or not.
						 TimeStamp <=CounterOut;
						 EventXAddress <= DVSAEREvent_Code[7 downto 0];  ---Do I need to say save this? 
					  elsif DVSAEREvent_Code[14 downto 12] = '011' then 
						 State_DN <= stOnEvent;
						 LastTimeStamp <= TimeStamp;
						 TimeStamp <=CounterOut;
						 EventXAddress <= DVSAEREvent_Code[7 downto 0];
					  else State_DN <= stWaitforXaddress;
					  
					  
				when stOnEvent =>
					 State_DN <= stComputeInputtoAC;
					 Subunit( EventXAddress [7 downto 2] , EventXAddress [7 downto 2]).VmemOff + = UpdateUnit ;
							 VOff := VmemOff + UpdateUnit; 
							 VmemOff <= VOff;	

											
				when stOffEvent =>
					 State_DN <= stComputeInputtoAC;
					 Subunit( EventXAddress [7 downto 2] , EventXAddress [7 downto 2]).VmemOff + = UpdateUnit ;
							 VOff := VmemOff + UpdateUnit; 
							 VmemOff <= VOff;	
							 
				when stComputeInputtoAC =>	
					State_DN <= stComputesynapticInput
							 if  surroundSuppressionEnabled => '1'	then 
							 
								sumOff := Vs1Off_I + Vs2Off_I+ Vs3Off_I + Vs4Off_I;
								sumOff := sumOff srl 2;
								result := VOff - sumOff;
								if result < 0 then InputtoACOff <= 0;
								else InputtoACOff <= result;
								end if;
								
								sumOff := Vs1Off_I + Vs2Off_I+ Vs3Off_I + Vs4Off_I;
								sumOff := sumOff srl 2;
								result := VOff - sumOff;
								if result < 0 then InputtoACOff <= 0;
								else InputtoACOff <= result;
								end if;
								
							 else InputtoACOff <=VmemOff;
							 
							 end if;
								
							 else InputtoACOff <=VmemOff;
							 
							 end if;	
				
							
							
				----do I sum all together or I just add the difference of the active subunits? for now add up together...
					 
			
					 
				when stComputesynapticInput =>
						for i in  loop
						for j in  loop
					
						sumACRFOn : = sum of ComputeInputtoACon
						sumACRFOff : = 
						netsynapticInput <= OffnetSynapticInput - OnnetSynapticInput;
						State_DN <= stComputeMembraneState;

						
				when stComputeMembraneState =>
			   
						MS := MembraneState + SynapicInput;
						MembraneState <=MS;
						State_DN <= stComparetoIFThreshold;
						
				when stComparetoIFThreshold =>
				
						if  ACVmem > IFThreshold    then
							State_DN <= stFire;
							
						else State_DN <= stIdle;
						end if;
						
				when stFire =>
						State_DN <= stIdle;

				when others => null;
			end case;
		end process SubunitStateMachine_memoryless;
		

		-- Change state on clock edge (synchronous).
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;
			
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;
		end if;
	end process p_memoryzing;
end Behavioral;
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
		
		DVSAEREvent_Code		 		 : in  std_logic_vector( EVENT_WIDTH-1 downto 1); 
		
		AC_Fire_O    					 : out std_logic_vector;
		
		Decay_Enable 					 : in  std_logic;
		);
		
		
end entity ApproachCellStateMachine;


architecture Behavioral of ApproachCellStateMachine is

	attribute syn_enum_encoding : string

	type state is (stIdle, stDecayALL, stDifferentiateXY, stUpdateSubunites, stComputeInputtoAC, stComputeOnInOffExci, stUpdateACVmem, stComparetoIFThreshold, stCheckRF, Fire);
	
	attribute syn_enum_encoding of state : type is "onehot";
	
	type Subunit is array (5 downto 0 , 5 downto 0) of tSubunitParameter;
	
	
	type tSubunitParameter.VmemOn is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0) ;
	type tSubunitParameter.VmemOff is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0) ;
	type tSubunitParameter.InputtoACOn is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0)  ;
	type tSubunitParameter.InputtoACOff is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0)  ;
	type tApproachCellParameter.OnInhibition is array (2 downto 0 , 2 downto 0) of signed( 31 downto 0) ;
	type tApproachCellParameter.OffExcitation is array (2 downto 0 , 2 downto 0) of signed( 31 downto 0) ;
	type tApproachCellParameter.Vmem is array (2 downto 0 , 2 downto 0) of signed( 31 downto 0)  ;  ----ref O?  AC_fire_O_Reg?
	

	-- present and next state
	signal State_DP, State_DN : state;			 
	signal LastTimestamp, Timestamp : std_logic_vector(Counter_Size - 1 downto 0);
	signal EnableCounter std_logic;
	signal OverflowAlert std_logic;
	signal CounterOut std_logic;
	signal EventYAddress, EventXAddress: std_logic_vector(7 downto 0);
			
begin
	
	
	EventTimestampCounter : entity work.ContinuousCounter
	
		generic map(
			SIZE => Counter_Size)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => EnableCounter,
			DataLimit_DI => unsigned (Counter_Size - 1 downto 0),
			Overflow_SO  => OverflowAlert,  --- what to do with the Overflow Alert? 
			Data_DO      => CounterOut);

	p_memoryless : process(State_DP, CounterOut, DVSEvent_I, DVSAEREvent_Code, tSubunitParameter, tApproachCellParameter)---should they be here?
		
		begin
			
			State_DN <= State_DP;           
			Vmem <= (others => '0');   ----for array, use for loop to initiate?
			result <= (others => '0');
			CounterValue <= (others => '0');  ---what should I put here?  those who are saved in reg e.g. SubunitVmem, SubunitSum not?
			AC_Fire <= '0';

			variable sum, V: sum, V is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0) 
			variable i, j : integer range 0 to 63
			variable k, m : integer range 0 to 7  ----- is this neccessary?
			variable n:     integer range 0 to 4
			
		
			case State_DP is
			
				when stIdle =>
					 if DVSEvent_I = '1' then 
						State_DN <= stDifferentiateXY;
				        EnableCounter <= '1';     -----EnableCounter keep 1 afterwards? Do I need to use reg?
					 elsif Decay_Enable = '1' then 
							State_DN <= stDecay;
					 else State_DN <= stIdle;

				when stDecay => 
					 Vmem := Vmem srl 1;
					 State_DN <= stIdle;	
					 
				when stDifferentiateXY =>		
					 if DVSAEREvent_Code[14 downto 12] = '001' then 
						State_DN <= stWaitforXaddress; 
						EventYAddress <= DVSAEREvent_Code[7 downto 0];   ---Do I need to say save this? 
					 else State_DN <= stIdle;
					 
				when stWaitforXaddress =>
					  if DVSAEREvent_Code[14 downto 12] = '010' then 
						 State_DN <= stOffEvent; 
						 LastTimeStamp <= TimeStamp;    -----I am not sure whether to put it here or not.
						 TimeStamp <=CounterOut;
						 EventXAddress <= DVSAEREvent_Code[7 downto 0];  ---Do I need to say save this? 
					  elsif DVSAEREvent_Code[14 downto 12] = '011' then 
						 State_DN <= stOnEvent;
						 LastTimeStamp <= TimeStamp;
						 TimeStamp <=CounterOut;
						 EventXAddress <= DVSAEREvent_Code[7 downto 0];
					  else State_DN <= stWaitforXaddress;
					  
					  
				when stOnEvent =>
					 State_DN <= stComputeInputtoAC;
					 --i := tSubunit.Xaddr; 
					 --j := tSubunit.Yaddr;
							if i= unsigned (EventXAddress [7 downto 2]) & j = unsigned (EventYAddress [7 downto 2]) then 
								VOn :=  Subunit(i,j).VmemOn + UpdateUnit; 
								Subunit(i,j).VmemOn <= VOn;	 
								--or can I use Subunit(i,j).VmemOn + = UpdateUnit;
			    when stOffEvent =>
					 State_DN <= stComputeInputtoAC;
					 --i := tSubunit.Xaddr; 
					 --j := tSubunit.Yaddr;
							if i= unsigned (EventXAddress [7 downto 2]) & j = unsigned (EventYAddress [7 downto 2]) then 
								VOff :=  Subunit(i,j).VmemOff + UpdateUnit; 
								Subunit(i,j).VmemOff <= VOff;	 
								--or can I use Subunit(i,j).VmemOn + = UpdateUnit;

											
					
							 
				 when stComputeInputtoAC =>	
					State_DN <= stComputesynapticInput
					
							 if  surroundSuppressionEnabled => '1'	then 
								n :=0  ---????
								--i := tSubunit.Xaddr; 
								--j := tSubunit.Yaddr;
								for i in 0 to 63
									for j in 0 to 63
										if i< 63 then
											
											sumOff(i,j) := sumOff(i,j) + Subunit(i+1,j).VmemOff;
											n : = n + 1 ;
										if i > 0 then 
											sumOff(i,j) := sumOff(i,j) + Subunit(i-1,j).VmemOff;
											n : = n + 1 ;
											
										if j > 0 then 
											sumOff(i,j) := sumOff(i,j) + Subunit(i,j-1).VmemOff;
											n : = n + 1 ;
											
										if j< 63 then								
											sumOff(i,j) := sumOff(i,j) + Subunit(i,j+1).VmemOff;
											n : = n + 1 ;	
			
											sumOff(i,j) := sumOff(i,j) / n;
											result(i,j) := VOff(i,j) - sumOff(i,j);
											if result(i,j) < 0 then InputtoACOff(i,j) <= 0;
											else InputtoACOff(i,j) <= result(i,j);
											end if;
											
							  for i in 0 to 63
									for j in 0 to 63
										if i< 63 then
											
											sumOn(i,j) := sumOn(i,j) + Subunit(i+1,j).VmemOn;
											n : = n + 1 ;
										if i > 0 then 
											sumOn(i,j) := sumOn(i,j) + Subunit(i-1,j).VmemOn;
											n : = n + 1 ;
											
										if j > 0 then 
											sumOn(i,j) := sumOn(i,j) + Subunit(i,j-1).VmemOn;
											n : = n + 1 ;
											
										if j< 63 then								
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
				
							
							
				----do I sum all together or I just add the difference of the active subunits? for now add up together...
					 
			
					 
				when stComputesynapticInput =>
						for k in 0 to 7  
							for j in 0 to 7 
					
								sumACRFOn : = sum of ComputeInputtoACon
								sumACRFOff : = 
								netsynapticInput <= OffnetSynapticInput - OnnetSynapticInput;
								State_DN <= stComputeMembraneState;

						
				when stComputeMembraneState =>
						dT := Timestamp - LastTimestamp;-------put it into the synchronized logic 
						MS := MembraneState + SynapicInput * dT;
						MembraneState <=MS;
						State_DN <= stComparetoIFThreshold;
						
				when stComparetoIFThreshold =>
				
						if  ACVmem > IFThreshold    then
							State_DN <= stFire;
							MembraneState <= 0 ;
						elsif ACVmem < -10  then 
							ACVmem = 0;
						else State_DN <= stIdle;
						end if;
						
				when stFire =>
						State_DN <= stIdle;

				when others => null;
			end case;
		end process SubunitStateMachine_memoryless;
		

		-- Change state on clock edge (synchronous).
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;
			
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;
		end if;
	end process p_memoryzing;
end Behavioral;


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
		
		DVSAEREvent_Code		 		 : in  std_logic_vector( EVENT_WIDTH-1 downto 1); 
		
		AC_Fire_O    					 : out std_logic_vector;
		
		
		);
		
		
end entity ApproachCellStateMachine;


architecture Behavioral of ApproachCellStateMachine is

	attribute syn_enum_encoding : string

	type state is (stIdle, stDecayALL, stDifferentiateXY, stUpdateSubunites, stComputeInputtoAC, stComputeOnInOffExci, stUpdateACVmem, stComparetoIFThreshold, stCheckRF, Fire);
	
	attribute syn_enum_encoding of state : type is "onehot";
	
	type Subunit is array (5 downto 0 , 5 downto 0) of tSubunitParameter;
	
	
	type tSubunitParameter.VmemOn is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0) ;
	type tSubunitParameter.VmemOff is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0) ;
	type tSubunitParameter.InputtoACOn is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0)  ;
	type tSubunitParameter.InputtoACOff is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0)  ;
	type tApproachCellParameter.OnInhibition is array (2 downto 0 , 2 downto 0) of signed( 31 downto 0) ;
	type tApproachCellParameter.OffExcitation is array (2 downto 0 , 2 downto 0) of signed( 31 downto 0) ;
	type tApproachCellParameter.Vmem is array (2 downto 0 , 2 downto 0) of signed( 31 downto 0)  ;  ----ref O?  AC_fire_O_Reg?
	

	-- present and next state
	signal State_DP, State_DN : state;			 
	signal LastTimestamp, Timestamp : std_logic_vector(Counter_Size - 1 downto 0);
	signal EnableCounter std_logic;
	signal OverflowAlert std_logic;
	signal CounterOut std_logic;
	signal EventYAddress, EventXAddress: std_logic_vector(7 downto 0);
	signal Decay_Enable 					 : in  std_logic;
			
begin
	
	
	EventTimestampCounter : entity work.ContinuousCounter
	
		generic map(
			SIZE => EventTimestampCounter_Size)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => EnableCounter,
			DataLimit_DI => unsigned (Counter_Size - 1 downto 0),
			Overflow_SO  => OverflowAlert,  --- what to do with the Overflow Alert? 
			Data_DO      => CounterOut);
			
	DecayCounter : entity work.ContinuousCounter
	
		generic map(
			SIZE => DecayCounter_Size)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => '1',
			DataLimit_DI => unsigned (DecayCounter_Size - 1 downto 0),
			Overflow_SO  => Decay_Enable,  --- what to do with the Overflow Alert? 
			Data_DO      => open );
			
	p_memoryless : process(State_DP, CounterOut, DVSEvent_I, DVSAEREvent_Code, tSubunitParameter, tApproachCellParameter)---should they be here?
		
		begin
			
			State_DN <= State_DP;           
			Vmem <= (others => '0');   ----for array, use for loop to initiate?
			result <= (others => '0');
			CounterValue <= (others => '0');  ---what should I put here?  those who are saved in reg e.g. SubunitVmem, SubunitSum not?
			AC_Fire <= '0';

			variable sum, V: sum, V is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0) 
			variable i, j : integer range 0 to 63
			variable k, m : integer range 0 to 7  ----- is this neccessary?
			variable n:     integer range 0 to 4
			
		
			case State_DP is
			
				when stIdle =>
					 if DVSEvent_I = '1' then 
						State_DN <= stDifferentiateXY;
				        EnableCounter <= '1';     -----EnableCounter keep 1 afterwards? Do I need to use reg?
					 elsif Decay_Enable = '1' then 
							State_DN <= stDecay;
					 else State_DN <= stIdle;

				when stDecay => 
					 Vmem := Vmem srl 1;
					 State_DN <= stIdle;	
					 
				when stDifferentiateXY =>		
					 if DVSAEREvent_Code[14 downto 12] = '001' then 
						State_DN <= stWaitforXaddress; 
						EventYAddress <= DVSAEREvent_Code[7 downto 0];   ---Do I need to say save this? 
					 else State_DN <= stIdle;
					 
				when stWaitforXaddress =>
					  if DVSAEREvent_Code[14 downto 12] = '010' then 
						 State_DN <= stOffEvent; 
						 if k= unsigned (EventXAddress [7 downto 5]) & m= unsigned (EventYAddress [7 downto 5]) then 
						 LastTimeStamp(k,m) <= TimeStamp (k,m);  						 -----I am not sure whether to put it here or not.
						 dT(k,m)  := Timestamp(k,m)  - LastTimestamp(k,m);
						 TimeStamp(k,m)  <=CounterOut(k,m) ;
						 EventXAddress <= DVSAEREvent_Code[7 downto 0];  ---Do I need to say save this? 
					  elsif DVSAEREvent_Code[14 downto 12] = '011' then 
						 State_DN <= stOnEvent;
						 LastTimeStamp <= TimeStamp;
						 TimeStamp <=CounterOut;
						 EventXAddress <= DVSAEREvent_Code[7 downto 0];
					  else State_DN <= stWaitforXaddress;
					  
					  
				when stOnEvent =>
					 State_DN <= stComputeInputtoAC;
					 --i := tSubunit.Xaddr; 
					 --j := tSubunit.Yaddr;
							if i= unsigned (EventXAddress [7 downto 2]) & j = unsigned (EventYAddress [7 downto 2]) then 
								VOn(i,j) :=  VmemOn(i,j) + UpdateUnit; 
								VmemOn(i,j) <= VOn;	 
								--or can I use Subunit(i,j).VmemOn + = UpdateUnit;
			    when stOffEvent =>
					 State_DN <= stComputeInputtoAC;
					 --i := tSubunit.Xaddr; 
					 --j := tSubunit.Yaddr;
							if i= unsigned (EventXAddress [7 downto 2]) & j = unsigned (EventYAddress [7 downto 2]) then 
								VOff(i,j) :=  VmemOff(i,j) + UpdateUnit; 
								VmemOff(i,j)  <= VOff(i,j);	 
								--or can I use Subunit(i,j).VmemOn + = UpdateUnit;

											
					
							 
				 when stComputeInputtoAC =>	
					State_DN <= stComputesynapticInput
					
							 if  surroundSuppressionEnabled => '1'	then 
								n :=0  ---????
								--i := tSubunit.Xaddr; 
								--j := tSubunit.Yaddr;
								for i in 0 to 63
									for j in 0 to 63
										if i < 63 then
											
											sumOff(i,j) := sumOff(i,j) + Subunit(i+1,j).VmemOff;
											n : = n + 1 ;
										if i > 0 then 
											sumOff(i,j) := sumOff(i,j) + Subunit(i-1,j).VmemOff;
											n : = n + 1 ;
											
										if j > 0 then 
											sumOff(i,j) := sumOff(i,j) + Subunit(i,j-1).VmemOff;
											n : = n + 1 ;
											
										if j< 63 then								
											sumOff(i,j) := sumOff(i,j) + Subunit(i,j+1).VmemOff;
											n : = n + 1 ;	
			
											sumOff(i,j) := sumOff(i,j) / n;
											result(i,j) := VOff(i,j) - sumOff(i,j);
											if result(i,j) < 0 then InputtoACOff(i,j) <= 0;
											else InputtoACOff(i,j) <= result(i,j);
											end if;
											
							  for i in 0 to 63
									for j in 0 to 63
										if i< 63 then
											
											sumOn(i,j) := sumOn(i,j) + Subunit(i+1,j).VmemOn;
											n : = n + 1 ;
										if i > 0 then 
											sumOn(i,j) := sumOn(i,j) + Subunit(i-1,j).VmemOn;
											n : = n + 1 ;
											
										if j > 0 then 
											sumOn(i,j) := sumOn(i,j) + Subunit(i,j-1).VmemOn;
											n : = n + 1 ;
											
										if j< 63 then								
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
				
							
							
				----do I sum all together or I just add the difference of the active subunits? for now add up together...
					 
			
					 
				when stComputesynapticInput =>
						for k in 0 to 7 
							for m in 0 to 7 
							    if to_unsigned (i, 6) (5 downto 3) = to_unsigned (k, 3)  & to_unsigned (j, 6) (5 downto 3) = to_unsigned (m, 3) then
									for to_unsigned (i, 6) (5 downto 3) in '000' to '111' loop
										for to_unsigned (j, 6) (5 downto 3) in '000' to '111' loop
										sumACRFOn(k, m) : = sumACRFOn(k, m) + InputtoACOn(i,j) ;
										sumACRFOff(k, m) : = sumACRFOff(k, m) + InputtoACOff(i,j) ;
										
										netsynapticInput <= sumACRFOff(k, m) - sumACRFOn(k, m);
										State_DN <= stComputeMembraneState;

						
				when stComputeMembraneState =>
						              -------put it into the synchronized logic  dT should be within the approach cell???!
						MS(k,m) := MembraneState(k,m) + netsynapicInput(k,m) * dT(k,m);
						MembraneState(k,m)  <= MS (k,m) ;
						State_DN <= stComparetoIFThreshold; 
						
				when stComparetoIFThreshold =>
				
						if MembraneState(k,m) > IFThreshold    then
							State_DN <= stFire (k,m);
							MembraneState <= 0 ;
						elsif MembraneState < -10  then 
							MembraneState = 0;
						else State_DN <= stIdle;
						end if;
						
				when stFire =>
						State_DN <= stIdle;

				when others => null;
			end case;
		end process SubunitStateMachine_memoryless;
		

		-- Change state on clock edge (synchronous).
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;
			
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;
		end if;
	end process p_memoryzing;
end Behavioral;

