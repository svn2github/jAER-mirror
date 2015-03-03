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
					State_DN <= stUpadateVmem;
					if surroundSuppressionEnale=> '1'   then
					
					else 
					end if;
					
			when stUpadateVmem =>
					if PossionFiringEnabled=> '1'     then
							State_DN <= stComparetoRN;	
							
					else    State_DN <= stComparetoIFThreshold;
					end if;
					
			when stComparetoRN =>
					if  ACVmem >= RN then
						State_DN <= stFire;
						
					else State_DN <= stIdle;
					end if;
		
			when stComparetoIFThreshold =>
			
					if  ACVmem >= IFThreshold    then
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
			OutFifoControl_SO.Write_S <= '0';
			OutFifoData_DO            <= (others => '0');
			
			APPROACHSENSITIVITYConfigReg_D <= tAPPROACHSENSITIVITYConfigDefault;
			
			
		elsif rising_edge(Clock_CI) then  
			State_DP <= State_DN;
			
			OutFifoControl_SO.Write_S <= OutFifoWriteReg_S;
			if OutFifoDataRegEnable_S = '1' then
				OutFifoData_DO <= OutFifoDataReg_D;
			end if;
			
			APPROACHSENSITIVITYConfigReg_D <= APPROACHSENSITIVITYConfig_DI;
			
		end if;
	end process ApproachCellStateMachine_memoryzing;
	
	
	DecayAllStateMachine_memoryless
	when stIdle =>
					if MULTIPLEXERFifoData_DI(15 downto 13) => EVENT_CODE_X_ADDR then
						State_DN <= stResetCounter;
						Counter <= (others => '0');
					else State_DN <= stCheckCounter;
					end if;
					
			when stResetCounter =>
				if MULTIPLEXERFifoData_DI(8 downto SubsamplingBits-1)=> SubunitXAddr then
						State_DN <= stUpdateVmem;	
				else State_DN <= stIdle;
				end if;
				
			when stCheckCounter =>
				if  CounterValue >= minUpdateInterval then
					State_DN <= stDecay;
				else State_DN <= stIdle;
				end if;
				          
			when stDecay =>
					if MULTIPLEXERFifoData_DI(15 downto 13) => EVENT_CODE_X_ADDR then
						State_DN <= stCheckCounter;
					else State_DN <= stDecay;
						VmemOn <= VmemOn srl DecayFactor;
					end if;
	DecayAllStateMachine_memoryzing				
	
	
end Behavioral; 