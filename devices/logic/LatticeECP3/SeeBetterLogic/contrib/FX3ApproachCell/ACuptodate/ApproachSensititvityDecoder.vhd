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
		
		DVSAEREvent_Code		 		 : in  std_logic_vector( EVENT_WIDTH-1 downto 0); 
		
		DVSEventInthisAC				 : out  array (2 downto 0 , 2 downto 0) of std_logic;
		
		EventXAddr, EventYAddr			 : out  array (2 downto 0 , 2 downto 0) of std_logic_vector( 4 downto 0); 
		
		EventPolarity					 : out array (2 downto 0 , 2 downto 0) of std_logic;
		
		Decay							 : out array (2 downto 0 , 2 downto 0) of std_logic;
		
		);
		
		
end entity ApproachCellStateMachine;


architecture Behavioral of ApproachCellStateMachine is

	attribute syn_enum_encoding : string

	type state is (stIdle, stDecayALL, stDifferentiateXY, stWaitforXaddress, stDifferentiatePolarity, stDecodeAddresses);
	
	attribute syn_enum_encoding of state : type is "onehot";
	

	type DVSEventInthisAC is array (2 downto 0 , 2 downto 0) of std_logic;
	
	type EventXAddrInthisAC, EventYAddrInthisAC	is  array (2 downto 0 , 2 downto 0) of std_logic_vector( 4 downto 0); 
	
	type EventPolarity	is array (2 downto 0 , 2 downto 0) of std_logic;
	
	type Decay is array (2 downto 0 , 2 downto 0) of std_logic;

	

	-- present and next state
	signal State_DP, State_DN : state;			 
	signal LastTimestamp, Timestamp : std_logic_vector(Counter_Size - 1 downto 0);
	signal EnableCounter std_logic;
	signal OverflowAlert std_logic;
	signal CounterOut std_logic;
	signal EventYAddress, EventXAddress: std_logic_vector(7 downto 0);
	signal Decay_Enable 			   : in  std_logic;
			
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
	
			case State_DP is
			
				when stIdle =>
					 if DVSEvent_I = '1' then 
						State_DN <= stDifferentiateXY;
				        EnableCounter <= '1';     -----put into memoryzing
					 elsif Decay_Enable = '1' then 
							State_DN <= stDecay;
					 else State_DN <= stIdle;

				when stDecay => 
					 Vmem := Vmem srl 1;
					 State_DN <= stIdle;	
					 
				when stDifferentiateXY =>		
					 if DVSAEREvent_Code[14 downto 12] = '001' then 
						State_DN <= stWaitforXaddress; 
						EventYAddress <= DVSAEREvent_Code[7 downto 0];   ---put into memoryzing? 
					 else State_DN <= stIdle;
					 
				when stWaitforXaddress =>
					  if DVSAEREvent_Code[14 downto 12] = '010' then 
						 State_DN <= stIdle; 
						 
					  elsif DVSAEREvent_Code[14 downto 12] = '011' then 
						 
					  else State_DN <= stWaitforXaddress;
					  
		

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