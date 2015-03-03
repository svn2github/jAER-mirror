library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.ApproachSensitivityConfigRecords.all;


entity ApproachCellStateMachine is

	generic(
		SubunitXAddr, SubunitYAddr: std_logic_vector(AERAddressBits- SubsamplingBits downto 0);

	port(
		Clock_CI                 : in  std_logic;
		Reset_RI                 : in  std_logic;

		 --output to USB including 	ApproachCell Membrane Potential encoded in data_encode
		OutFifoControl_SI        : in  tFromFifoWriteSide;
		OutFifoControl_SO        : out tToFifoWriteSide;
		OutFifoData_DO           : out std_logic_vector(FULL_EVENT_WIDTH - 1 downto 0);
		
			-- Fifo input (from MULTIPLEXER)
		MULTIPLEXERFifoControl_SI     : in  tFromFifoReadSide;
		MULTIPLEXERFifoControl_SO     : out tToFifoReadSide;
		MULTIPLEXERFifoData_DI        : in  std_logic_vector(FULL_EVENT_WIDTH - 1 downto 0);

		
		ApproachSensitivityConfig_DI     : in  tApproachSensitivityConfig);
		
end entity ApproachCellStateMachine;

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
		DVSAEREvent_Code: 		   in  std_logic_vector( EVENT_WIDTH-1 down to 1);
		
		InputtoAC_O				 : out std_logic_vector( Vmemwidth-1 down to 1);
		VmemOn_O, VmemOff_O		 : out std_logic_vector( Vmemwidth-1 down to 1);
		
		
	
		ApproachSensitivityConfig_DI     : in  tApproachSensitivityConfig);
		
end entity ApproachCellStateMachine;



architecture Behavioral of ApproachCellStateMachine is
	attribute syn_enum_encoding : string

	type state is (stIdle, stResetCounter, stCheckCounter, stDecayALL, stUpdateACVmem, stComparetoRN, stComparetoIFThreshold, Fire);
	
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;
	
	-- Register outputs to FIFO.
	signal OutFifoWriteReg_S      : std_logic;
	signal OutFifoDataRegEnable_S : std_logic;
	signal OutFifoDataReg_D       : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	
	signal sum 					 :
	signal result				 :
	signal OnInhibition, OffExcitation : 
	signal ACVmem				 :
	signal CounterValue		     : std_logic_vector(Counter_WIDTH - 1 downto 0);
	
	
	-- Register outputs to ApproachSensitivity.
	ApproachSensitivityConfig_DI     : in  tApproachSensitivityConfig;
	
	
begin
	p_memoryless : process(State_DP, MULTIPLEXERFifoData_DI)
	begin
		State_DN <= State_DP;           -- Keep current state by default.
		sum <= (others => '0');
		result <= (others => '0');
		CounterValue <= (others => '0');
		
		OutFifoWriteReg_S      <= '0';
		OutFifoDataRegEnable_S <= '0';
		OutFifoDataReg_D       <= (others => '0');
							
		case State_DP is
		
			
					
			when stIdle =>
				 if DVSEvent_I = '1' then 
				    State_DN <= stCheckRF;
					
				 else State_DN <= stIdle; 
				 
            when stCheckRF =>
				 if in RF then
					State_DN <= stComputesynapticInput;
				 else State_DN <= stIdle; 
				 
			when stComputesynapticInput =>
				
					sumACRFOn : = VmemOn1 + VmemOn2 + VmemOn3 + VmemOn4;
					sumACRFOff : = VmemOff1 + VmemOff2 + VmemOff3 + VmemOff4;
					OnnetSynapticInput := sumACRFOn sll OnsynapticWeightbits;
					OffnetSynapticInput := sumACRFOff sll OffsynapticWeightbits;
					netsynapticInput <= OffnetSynapticInput - OnnetSynapticInput;
					State_DN <= stComputeMembraneState;

					
		    when stComputeMembraneState =>
		   
					MS := MembraneState + SynapicInput;
					MembraneState <=MS;
					State_DN <= stComparetoIFThreshold;
					
			
					
			--when stUpadateVmem =>
					--if PossionFiringEnabled=> '1'     then
							--State_DN <= stComparetoRN;	
							
					--else    State_DN <= stComparetoIFThreshold;
					--end if;
					
			--when stComparetoRN =>
					--if  ACVmem >= RN then
						--State_DN <= stFire;
						
					--else State_DN <= stIdle;
					--end if;
		
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
	ApproachCellStateMachine_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
		
			State_DP <= stIdle;	
					
			ApproachSensitivityConfigReg_D <= tApproachSensitivityConfigDefault;
			
			
		elsif rising_edge(Clock_CI) then  
			State_DP <= State_DN;
			VmemOn_O <= VmemOn;
			VmemOff_O <= VmemOff;
			ApproachSensitivityConfigReg_D <= ApproachSensitivityConfig_DI;
			
		end if;
	end process ApproachCellStateMachine_memoryzing;
	



architecture Behavioral of ApproachCellStateMachine is
	attribute syn_enum_encoding : string

	type state is (stIdle, stResetCounter, stCheckCounter, stDecayALL, stUpdateACVmem, stComparetoRN, stComparetoIFThreshold, Fire);
	
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;
	signal InputtoAC_O		:   std_logic_vector( Vmemwidth-1 down to 1);
	signal VmemOn_O, VmemOff_O		:  std_logic_vector( Vmemwidth-1 down to 1);
    
	ApproachSensitivityConfig_DI     : in  tApproachSensitivityConfig;
	
	
begin
	p_memoryless : process(State_DP, )
	
	variable sum, V: std_logic_vector( Vmemwidth-1 down to 1);
	
	begin
		State_DN <= State_DP;           -- Keep current state by default.
										--
			

							
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
	
	
		-- Change state on clock edge (synchronous).
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;
			DVSAERConfigReg_D <= tDVSAERConfigDefault;
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;
			DVSAERConfigReg_D <= DVSAERConfig_DI;
		end if;
	end process p_memoryzing;
end Behavioral;
