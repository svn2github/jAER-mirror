library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;
--use ieee.std_logic_signed.all;




entity ApproachCell is

	generic (CounterSize : Integer:= 8;
			 UpdateUnit: signed :=to_signed(1, 2);
			 IFThreshold: signed(24 downto 0):= (others=> '0') );

	--generic (CounterSize : Integer;
			 --UpdateUnit: signed ( 1 downto 0) ;
			 --IFThreshold: signed(24 downto 0) );


    port(
		Clock_CI                 : in  std_logic;
		Reset_RI                 : in  std_logic;

		DVSEvent_I				 : in  std_logic;

		EventXAddr_I, EventYAddr_I	 : in  std_logic_vector( 4 downto 0);

		EventPolarity_I					 : in std_logic;

		DecayEnable_I				     : in std_logic;

		AC_Fire_O    					 : out std_logic;

		CounterOut_I						 : in  unsigned(CounterSize - 1 downto 0);

		surroundSuppressionEnabled_I	 : in std_logic

		);

end entity ApproachCell;


architecture Behavioral of ApproachCell is

	attribute syn_enum_encoding : string;

	type state is (stIdle, stDecay, stCheckPolarity, stOnEvent, stOffEvent, stComputeInputtoAC, stComputeSynapticInput, stComputeMembraneState, stComparetoIFThreshold);

	attribute syn_enum_encoding of state : type is "onehot";

	type tVmem is array ( 7 downto 0, 7 downto 0) of signed(15 downto 0);
	type n_neighbor is array ( 7 downto 0, 7 downto 0) of integer range 0 to 4;

	signal VmemOn, VmemOff, InputtoACOn, InputtoACOff :  tVmem := ((others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')));



	-- present and next state
	signal State_DP, State_DN : state;
	signal Timestamp: unsigned(7 downto 0) := (others => '0');
	signal Decay_active:  std_logic;
	signal MembraneState   : signed(24 downto 0) := (others => '0');
	signal netSynapticInput  : signed(15 downto 0):= (others => '0');
	signal dT: unsigned(7 downto 0) := (others => '0');
	constant CounterMax: unsigned(7 downto 0):=(others => '1');
	constant weightOn: signed(2 downto 0) := "011";
	constant weightOff: signed(1 downto 0) := "01";
	signal Voff, Von, resultOn, resultOff : tVmem := ((others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')));

	signal sumACRFOn: signed(15 downto 0):= (others => '0');
	signal sumACRFOff : signed(15 downto 0):= (others => '0');
	--variable n_on, n_off:     n_neighbor;
	signal MS:   signed(24 downto 0);


begin

-----[to improve speed, need to pre assign default values of variables to zeros.]


p_memoryless : process(State_DP, CounterOut_I, DVSEvent_I, EventXAddr_I, EventYAddr_I, DecayEnable_I, EventPolarity_I)

	variable sumOff, sumOn : tVmem := ((others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')));
	variable n_on, n_off:     n_neighbor;
			begin

			State_DN <= State_DP;
			AC_Fire_O  <= '0';
			for i in 0 to 7 loop
			   for j in 0 to 7 loop
				   sumOff(i,j) := (others =>'0');
				   sumOn(i,j) := (others => '0');
				   Voff(i,j) <= (others =>'0');
					Von(i,j) <= (others => '0');
					resultOn(i,j) <= (others => '0');
					resultOff(i,j) <= (others => '0');
					n_off(i,j) := 0;
					n_on(i,j) := 0;
				end loop;
			end loop;
			sumACRFOn <= (others =>'0');
			sumACRFOff<= (others =>'0');
			MS <=  MembraneState;
			case State_DP is

				when stIdle =>
					 if DVSEvent_I = '1' then
						State_DN <= stCheckPolarity;
					 elsif Decay_active = '1' then
							State_DN <= stDecay;
					 else State_DN <= stIdle;
					 end if;

				when stCheckPolarity =>
						if EventPolarity_I= '0' then  --------Polarity = 0 off event Polarity =1 On event; should be changed couterwise
						   State_DN <= stOffEvent;
					    elsif EventPolarity_I= '1' then
						   State_DN <= stOnEvent;
						end if;

				when stDecay =>
					State_DN <= stIdle;
					for i in 0 to 7 loop
						for j in 0 to 7 loop
							 VOn(i,j) <=  '0' & VmemOn(i,j)(15 downto 1);
							 VOff(i,j) <=  '0' & VmemOff(i,j)(15 downto 1);
						end loop;
					end loop;


				when stOnEvent =>
					 State_DN <= stComputeInputtoAC;

					   for i in 0 to 7 loop
						 for j in 0 to 7 loop
							if i= unsigned (EventXAddr_I (4 downto 2)) and j = unsigned (EventYAddr_I (4 downto 2)) then
								VOn(i,j) <=  VmemOn(i,j) + UpdateUnit;
							end if;
						 end loop;
					  end loop;


			    when stOffEvent =>
					 State_DN <= stComputeInputtoAC;
					 for i in 0 to 7 loop
						 for j in 0 to 7 loop
							if (i= unsigned (EventXAddr_I (4 downto 2)) and j = unsigned (EventYAddr_I (4 downto 2))) then
								VOff(i,j) <=  VmemOff(i,j) + UpdateUnit;
							end if;
						 end loop;
					  end loop;


				 when stComputeInputtoAC =>
						State_DN <= stComputesynapticInput;
								for i in 0 to 7 loop
									   for j in 0 to 7 loop

										n_off(i,j) := 0;

										if  i< 7 then

											sumOff(i,j) := sumOff(i,j) + VmemOff(i+1,j);
											n_off(i,j) := n_off(i,j) + 1 ;
										end if;

										if i> 0 then
											sumOff(i,j) := sumOff(i,j) + VmemOff(i-1,j);
											n_off(i,j) := n_off(i,j) + 1 ;
										end if;


										if  j> 0 then
											sumOff(i,j) := sumOff(i,j) + VmemOff(i,j-1);
											n_off(i,j) := n_off(i,j) + 1 ;
										end if;


										if j< 7  then
											sumOff(i,j) := sumOff(i,j) + VmemOff(i,j+1);
											n_off(i,j) := n_off(i,j) + 1 ;
										end if;


										--sumOff(i,j) := to_signed(to_integer(sumOff(i,j))/n_off(i,j), 25); 
										sumOff(i,j) := "00"& sumOff(i,j)(15 downto 2); -- shifting bits to get mean of sum-surroundings
										resultOff(i,j) <= VOff(i,j) - sumOff(i,j);
									end loop;
								end loop;
							for i in 0 to 7 loop
									 for j in 0 to 7 loop
										n_on(i,j) := 0;
										if i< 7 then

											sumOn(i,j) := sumOn(i,j) + VmemOn(i+1,j);
											n_on(i,j) := n_on(i,j) + 1 ;
										end if;

										if i > 0 then
											sumOn(i,j) := sumOn(i,j) + VmemOn(i-1,j);
											n_on(i,j) := n_on(i,j) + 1 ;
										end if;

										if j > 0 then
											sumOn(i,j) := sumOn(i,j) + VmemOn(i,j-1);
											n_on(i,j) := n_on(i,j) + 1 ;
										end if;

										if j< 7 then
											sumOn(i,j) := sumOn(i,j) + VmemOn(i,j+1);
											n_on(i,j) := n_on(i,j) + 1 ;
										end if;

										--sumOn(i,j) := to_signed(to_integer(sumOn(i,j))/n_on(i,j), 25);   ---change later to shift bits// changed to get mean of sum-surroundings
										sumOn(i,j) := "00"&sumOn(i,j)(15 downto 2);
										resultOn(i,j) <= VOn(i,j) - sumOn(i,j);
-- resulton(i,j) resultoff(i,j)
									end loop;
								end loop;
				when stComputeSynapticInput =>
						State_DN <= stComputeMembraneState;
						sumACRFOn <= (others => '0');
						sumACRFOff <= (others => '0');
						for i in 0 to 7 loop
							for j in 0 to 7 loop
							sumACRFOn <= sumACRFOn + InputtoACOn(i,j) ;
							sumACRFOff <= sumACRFOff + InputtoACOff(i,j) ;
							end loop;
						end loop;

				when stComputeMembraneState =>

						State_DN <= stComparetoIFThreshold; 
						MS <= MembraneState + netSynapticInput * ( signed (dT));						-----MembraneState  multiplication 
						--MS <= MembraneState + netSynapticInput;
				when stComparetoIFThreshold =>
						State_DN <= stIdle;
						if (MembraneState > IFThreshold)    then                             -------[possion firing to be done later]
							AC_Fire_O  <= '1';
						end if;

				when others => null;
			end case;
		end process p_memoryless;



	p_states_change: process(Clock_CI, Reset_RI)

	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;


		elsif rising_edge(Clock_CI) then

	     	State_DP <= State_DN;
		end if;
	end process;


	p_memoryzing : process(Clock_CI, Reset_RI)

	begin
		if Reset_RI = '1' then
			Decay_active <= '0';


		elsif rising_edge(Clock_CI) then

			if DecayEnable_I ='1' then
			   Decay_active <='1';

			elsif State_DP = stDecay then
			   Decay_active <= '0';
			end if;

			case State_DP is
				when stIdle =>
						 if DVSEvent_I = '1' then
							TimeStamp  <= CounterOut_I;

							if (CounterOut_I > Timestamp) then
							   dT <= CounterOut_I - Timestamp ;
							else
							   dT <= CounterOut_I + CounterMax  - Timestamp ;
							end if;
						 end if;

				when stDecay =>

					for i in 0 to 7 loop
					 for j in 0 to 7 loop
						 VmemOn(i,j) <= VOn(i,j);
						 VmemOff(i,j) <= VOff(i,j);
					 end loop;
					end loop;
					Decay_active <= '0';

				when stOnEvent =>

						   for i in 0 to 7 loop
							 for j in 0 to 7 loop
									VmemOn(i,j) <= VOn(i,j);
							 end loop;
						  end loop;

				when stOffEvent =>

					  for i in 0 to 7 loop
						 for j in 0 to 7 loop
								VmemOff(i,j)  <= VOff(i,j);	 ----VmemOn Off
						 end loop;
					  end loop;

				 when stComputeInputtoAC =>

							 if  surroundSuppressionEnabled_I = '1'	then

									for i in 0 to 7 loop
									   for j in 0 to 7 loop


										if 	(resultOff(i,j) < 0) then
											InputtoACOff(i,j) <= (others =>'0');
										else InputtoACOff(i,j) <= resultOff(i,j);
										end if;

									 end loop;
									end loop;
							  --end if;


								  for i in 0 to 7 loop
									 for j in 0 to 7 loop

										if (resultOn(i,j) < 0)then
											InputtoACOn(i,j) <= ( others=>'0');
										else InputtoACOn(i,j) <= resultOn(i,j);    ----non linearity in the case with surround suppression is implemented. /////
										end if;
									 end loop;
								 end loop;

							 else  for i in 0 to 7 loop
									 for j in 0 to 7 loop
										if (VmemOn(i,j) < 0)then
											InputtoACOn(i,j) <= ( others=>'0');
										else InputtoACOn(i,j) <= VmemOn(i,j);    ----non linearity in the case without surround suppression is implemented. /////
										end if;
										if (VmemOff(i,j) < 0)then
											InputtoACOff(i,j) <= ( others=>'0');
										else InputtoACOff(i,j) <= VmemOff(i,j);    ----non linearity in the case without surround suppression is implemented. /////
										end if;
										
									 end loop; ----[actually I can take all the if else conditional clause inside the for loop]. 
								   end loop;
							 end if;

				when stComputeSynapticInput =>

						netSynapticInput<= sumACRFOff - sumACRFOn;                  -------  signed value netSynapticInput
						-- weight need to be added here   why did Tobi make here 1.2 instead of Won=Woff, it would be no need to implement this multiplification but I can implement by shifting bits anyway


				when stComputeMembraneState =>
						MembraneState <= MS ;
												-----MembraneState
				when stComparetoIFThreshold =>
						if  MembraneState > IFThreshold then
							MembraneState <= (others=>'0') ;
						elsif MembraneState < to_signed(-10, 64)  then
							MembraneState <= (others=>'0');
						end if;
				when others => null;
			end case;

		end if;
	end process p_memoryzing;
end Behavioral;
