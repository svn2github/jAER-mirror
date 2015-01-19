library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.APPROACHSENSITIVITYConfigRecords.all;

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
	
	-- Register outputs to FIFO.
	signal OutFifoWriteReg_S      : std_logic;
	signal OutFifoDataRegEnable_S : std_logic;
	signal OutFifoDataReg_D       : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	
	signal sum 					 : real in the range of -2^(m-1) to 2^(m-1)-2(-f);
	signal result				 : real in the range of -2^(m-1) to 2^(m-1)-2(-f);
	signal OnInhibition, OffExcitation : real in the range of -2^(m-1) to 2^(m-1)-2(-f);
	signal ACVmem				 : real in the range of -2^(m-1) to 2^(m-1)-2(-f);
	signal CounterValue		     : std_logic_vector(Counter_WIDTH - 1 downto 0);
	
	
	-- Register outputs to APPROACHSENSITIVITY.
	APPROACHSENSITIVITYConfig_DI     : in  tAPPROACHSENSITIVITYConfig;
	
	
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
					
			APPROACHSENSITIVITYConfigReg_D <= tAPPROACHSENSITIVITYConfigDefault;
			
			
		elsif rising_edge(Clock_CI) then  
			State_DP <= State_DN;
			VmemOn_O <= VmemOn;
			VmemOff_O <= VmemOff;
			APPROACHSENSITIVITYConfigReg_D <= APPROACHSENSITIVITYConfig_DI;
			
		end if;
	end process ApproachCellStateMachine_memoryzing;
	
	
