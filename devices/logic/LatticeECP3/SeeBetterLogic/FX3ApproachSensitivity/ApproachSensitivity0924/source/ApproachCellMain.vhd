library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ACConfigRecords.all;


entity ApproachCellMain is
 

	--generic (DecayCounter_Size : Integer := 32;
			 --TimeCounter_Size : Integer := 32;
			 --UpdateUnit:  signed (7 downto 0);
			 --IFThreshold: signed(63 downto 0)
			 --);
	
    port(
		Clock_CI                 : in  std_logic;
		Reset_RI                 : in  std_logic;
		
		SurSupEnable_I : in std_logic; 
		CAVIAR_req    : in std_logic;
		WS_ack        : in std_logic;
		CAVIAR_data   : in  std_logic_vector(16 downto 0);
		
		AC_Ack_O : 		out std_logic;
		AC_Req_O : 		out  std_logic;
		AC_Fire_O :	    out std_logic_vector (5 downto 0);
		ACConfig_DI:    in  tACConfig
		);
		
end entity ApproachCellMain;


architecture Behavioral of ApproachCellMain is

	--attribute syn_enum_encoding : string

	--type state is (stIdle,);
	
	--attribute syn_enum_encoding of state : type is "onehot";
	type tDVSEventR is array ( 7 downto 0, 7 downto 0) of std_logic;
	
	--signal State_DP, State_DN : state;	
	
	----Enable Counter? when----
	signal EnableCounter: std_logic :='1';
	
	----2 Counter Output----
	signal DecayEnable : std_logic;
	signal ACConfigReg_D: tACConfig;
	signal CounterOut: unsigned(ACConfigReg_D.TimeCounter_Size - 1 downto 0);
	 
	----Decoded DVS Address-------
	--signal DVSEventReq,  AC_Ack : tDVSEventR;  --3bits *3bits---
	signal EventPolarity : std_logic;  ---1bit----
	signal EventYAddr, EventXAddr: std_logic_vector( 4 downto 0);  ---3bits *3bits----
	constant  DataLimit: unsigned (ACConfigReg_D.TimeCounter_Size -1 downto 0) := (others=> '1');
	signal AC_Fire,  AC_Ack, DVSEventReq : tDVSEventR;
	

	
			
begin
	
	DecayCounter : entity work.ContinuousCounter
	
		generic map(
			SIZE => ACConfigReg_D.DecayCounter_Size)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => EnableCounter,-----
			DataLimit_DI => DataLimit,
			Overflow_SO  => DecayEnable,  
			Data_DO      => open );
			

	EventTimestampCounter : entity work.ContinuousCounter
	
		generic map(
			SIZE => ACConfigReg_D.TimeCounter_Size)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => '0',
			Enable_SI    => EnableCounter,-----
			DataLimit_DI => DataLimit,
			Overflow_SO  => open,  
			Data_DO      => CounterOut);
		

	ApproachCells : for k in 7 downto 0 generate
			ApproacCellMember : for m in 7 downto 0 generate
						AC: entity work.AC
						
						   generic map (
								CounterSize => ACConfigReg_D.TimeCounter_Size,
								UpdateUnit => ACConfigReg_D.UpdateUnit,
								IFThreshold => ACConfigReg_D.IFThreshold )
								
							port map 
							( 
								Clock_CI     => Clock_CI,
								Reset_RI     => Reset_RI,
								DVSEvent_I     => DVSEventReq(k,m),
								EventXAddr_I    => EventXAddr,
								EventYAddr_I => EventYAddr,
								EventPolarity_I  => EventPolarity, 
								DecayEnable_I =>  DecayEnable,
								CounterOut_I  => CounterOut,
								surroundSuppressionEnabled_I  => SurSupEnable_I,		
								AC_Fire_O    => AC_Fire(k,m),
								AC_Ack_O     => AC_Ack(k,m));
		   end generate;
	   end generate;
	   
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		--if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			--State_DP <= stIdle;	  
			
		if rising_edge(Clock_CI) then
			EventXAddr <= CAVIAR_data ( 5 downto 1 );
			EventYAddr <= CAVIAR_data ( 13 downto 9 );
			
			
			for k in 0 to 7 loop
				for m in 0 to 7 loop
				
					if k= unsigned (CAVIAR_data (16 downto 14)) and m= unsigned (CAVIAR_data (8 downto 6)) then 
					   DVSEventReq(k,m) <= CAVIAR_req; 
					end if;
					
					if  AC_Ack(k,m) = '1' then
						AC_Ack_O <= '1';
						AC_Fire_O (5 downto 3) <= std_logic_vector (to_unsigned (m, 3)); 
						AC_Fire_O (2 downto 0) <= std_logic_vector (to_unsigned (k, 3));
					end if;
							
				end loop;
			end loop;
			ACConfigReg_D <= ACConfig_DI;
		end if;
	end process;
end Behavioral;



			
