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
		
		AC_Fire_O     					 : out  array (2 downto 0 , 2 downto 0) of std_logic;
		
		
		);
		
		
end entity ApproachCellStateMachine;


architecture Behavioral of ApproachCellStateMachine is

	attribute syn_enum_encoding : string

	type state is (stIdle, stDecayALL, stDifferentiateXY, stUpdateSubunites, stComputeInputtoAC, stComputeOnInOffExci, stUpdateACVmem, stComparetoIFThreshold, stCheckRF, Fire);
	
	attribute syn_enum_encoding of state : type is "onehot";
	
	type Subunit is array (5 downto 0 , 5 downto 0) of tSubunitParameter;
	
	
	type VmemOn is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0) ;
	type VmemOff is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0) ;
	type InputtoACOn is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0)  ;
	type InputtoACOff is array (5 downto 0 , 5 downto 0) of signed( 31 downto 0)  ;
	
	

	-- present and next state
	signal State_DP, State_DN : state;			 
	signal LastTimestamp, Timestamp : std_logic_vector(Counter_Size - 1 downto 0);
	signal EnableCounter std_logic;
	signal OverflowAlert std_logic;
	signal CounterOut std_logic;
	signal EventYAddress, EventXAddress: std_logic_vector(7 downto 0);
	signal Decay_Enable 			   : in  std_logic;
			
begin
	
	
	EventDecoder : entity work.EventDecoder
	
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
			
			
	Generate_ApproachCells :
		for k in 0 to 2 
			for m in 0 to 2 Generate
				AC: AC port map 
				( 
					Clock_CI     => Clock_CI,
					Reset_RI     => Reset_RI,
					DVSEventInthisAC_I     => DVSEvent_I(k,m),
					EventXAddrInthisAC_I    => EventXAddr(k,m),
					EventYAddrInthisAC_I => EventYAddr(k,m),
					EventPolarity_I  => EventPolarity,  --- what to do with the Overflow Alert? 
					thisAC_Fire_O    => AC_Fire_O(k,m));
