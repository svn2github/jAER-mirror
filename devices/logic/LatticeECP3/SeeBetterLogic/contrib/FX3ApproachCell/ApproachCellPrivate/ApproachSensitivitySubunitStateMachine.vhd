library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.APPROACHSENSITIVITYConfigRecords.all;

entity ApproachCellStateMachine is

	generic(
		UpdateUnit              : integer;
		ACnumber 				: 
		);
	
		
	port(
		Clock_CI                 : in  std_logic;
		Reset_RI                 : in  std_logic;
		
		DVSEvent_I				 : in  std_logic;
		--EventPolarity_I          : in  std_logic;
		
		Vs1_I,Vs2_I,Vs3_I,Vs4_I  : in  std_logic_vector( Vmemwidth-1 down to 1);
		DVSAEREvent_Code: 			   in  std_logic_vector( EVENT_WIDTH-1 down to 1);
		
		InputtoAC_O				 : out std_logic_vector( Vmemwidth-1 down to 1);
		VmemOn_O, VmemOff_O		 : out std_logic_vector( Vmemwidth-1 down to 1);
		
		
	
		--VmemOn, VmemOff		 : out real in the range of -2^(m-1) to 2^(m-1)-2(-f);  Instantiate SubunitStatemachine inside AC stateMachine
		-- Configuration input
		APPROACHSENSITIVITYConfig_DI     : in  tAPPROACHSENSITIVITYConfig);
		
end entity ApproachCellStateMachine;

architecture Behavioral of ApproachCellStateMachine is
	attribute syn_enum_encoding : string

	type state is (stIdle, stResetCounter, stCheckCounter, stDecayALL, stUpdateACVmem, stComparetoRN, stComparetoIFThreshold, Fire);
	
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;
	signal InputtoAC_O		:   std_logic_vector( Vmemwidth-1 down to 1);
	signal VmemOn_O, VmemOff_O		:  std_logic_vector( Vmemwidth-1 down to 1);
    
	APPROACHSENSITIVITYConfig_DI     : in  tAPPROACHSENSITIVITYConfig;
	
	
begin
	p_memoryless : process(State_DP, MULTIPLEXERFifoData_DI)
	
	variable sum, V: std_logic_vector( Vmemwidth-1 down to 1);
	
	begin
		State_DN <= State_DP;           -- Keep current state by default.
		InputtoAC <= (others => '0');
		CounterOverFlows<= (others => '0');
			

							
		case State_DP is
		
			when stIdle =>
				 if DVSEvent_I = '1' then 
				    State_DN <= stCheckRF;
				 elsif CounterOverFlows_I => '1' then 
						State_DN <= stDecay;
				 else State_DN <= stIdle;
					
			when stCheckRF =>
					
					if DVSEvent_I=> '1'  then 
					   State_DN <= stUpdateSubunitVmem;
					else State_DN <= stIdle;
					end if;	
			
			
			when stUpadateSubunitVmem =>
					
				    State_DN <= stIdle;	
					
					if EventPolarity_I  => '1' then
					
					   VOn := VmemOn + UpdateUnit; 
					   VmemOn <= VOn;
					   
					   if  surroundSuppressionEnabled => '1'	then
					   
						sumOn := Vs1On_I + Vs2On_I+ Vs3Ov_I + Vs4On_I;
						sumOn := sumOn srl 2;
						InputtoACOn <= VOn - sumOn;	
						else InputtoACOn <=VOn;

					   end if;
					   
					else VOff := VmemOff + UpdateUnit; 
						 VmemOff <= VOff;
						 
						 if  surroundSuppressionEnabled => '1'	then 
						 
							sumOff := Vs1Off_I + Vs2Off_I+ Vs3Off_I + Vs4Off_I;
							sumOff := sumOff srl 2;
							InputtoACOff <= VOff - sumOff;
							
						 else InputtoACOff <=VOff;
						 
						 end if;
						 
					end if;
							
			when stDecay => 
				 Vmem := Vmem srl 1;
				 State_DN <= stIdle;				
			
			when others => null;
			
		end case;
	
	end process SubunitStateMachine_memoryless;

	
	
	
	