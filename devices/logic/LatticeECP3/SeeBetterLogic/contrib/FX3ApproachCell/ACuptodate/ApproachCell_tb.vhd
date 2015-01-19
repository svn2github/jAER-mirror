
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ApproachCell_tb is
end entity ApproachCell_tb;

architecture Testbench of ApproachCell_tb is
	-- component generics
	constant CounterSize    : integer := 32;
	constant UpdateUnit : signed( 1 downto 0) := "01";
	constant IFThreshold    : signed(63 downto 0) := X"0000000000000001";
	
	-- component ports
	--signal Clock_C     : std_logic;
	signal Reset_R     : std_logic;
	signal DVSEvent    : std_logic;
	signal EventXAddr : std_logic_vector( 4 downto 0) ;
	signal EventYAddr  : std_logic_vector( 4 downto 0);
	signal EventPolarity      : std_logic;
	signal DecayEnable :std_logic;
	signal AC_Fire: std_logic;
	signal CounterOut : unsigned(CounterSize - 1 downto 0) := (others=> '0');
	signal surroundSuppressionEnabled : std_logic;
	-- clock
	signal Clk : std_logic := '1';
begin                                   -- architecture Testbench

	-- component instantiation
	DUT : entity work.ApproachCell
	
		generic map(
			CounterSize => CounterSize,
			UpdateUnit => UpdateUnit,
			IFThreshold    => IFThreshold
		     )
		port map(
			Clock_CI     => Clk,
			Reset_RI     => Reset_R,
			DVSEvent_I     => DVSEvent,
			EventXAddr_I    => EventXAddr,
			EventYAddr_I => EventYAddr,
			EventPolarity_I  => EventPolarity,  --Polarity = 0 off event Polarity =1 On event;  Excitation = netOff- net On
			DecayEnable_I      => DecayEnable,
			AC_Fire_O  => AC_Fire,
			CounterOut_I => CounterOut,
			surroundSuppressionEnabled_I => surroundSuppressionEnabled
			);

	-- clock generation
	Clk     <= not Clk after 0.5 ns;
	
	
	
	Counter: process 
	begin
	

	  if rising_edge(Clk) then
	  CounterOut := CounterOut + 1;
		
	end process Counter;

	-- waveform generation
	WaveGen_Proc : process
	begin
		Reset_R     <= '0';
		DVSEvent     <= '0';
		EventXAddr   <= "00000";
		EventYAddr   <= "00000";
		EventPolarity <= '0';
		DecayEnable  <= '0';
		surroundSuppressionEnabled <= '0';
		
		
	
		-- pulse reset
		wait for 2 ns;
		Reset_R <= '1';
		wait for 3 ns;
		Reset_R <= '0';

		-- should remain at zero for 5 cycles
		wait for 5 ns;
		
		

		-- count up for 10 cycles, now it's 10
		DVSEvent <= '1';
		wait for 10 ns;
		DVSEvent <= '0';
		
		-- keep at 10 for 5 cycles
		wait for 5 ns;

		-- count up for 10 cycles (should wrap around), now it's 5
		EventPolarity <= '1';
		wait for 10 ns;
		EventPolarity <= '0';
		
		

		-- keep at 10 for 5 cycles
		wait for 5 ns;

		-- count up for 10 cycles (should wrap around), now it's 5
		EventXAddr <= "11101";
		wait for 10 ns;
		EventXAddr <= "00000";

		-- clear goes back to 0
		wait for 5 ns;
		
		-- count up for 10 cycles (should wrap around), now it's 5
		EventYAddr <= "11101";
		wait for 10 ns;
		EventYAddr <= "00000";
		
		
		-- should remain at zero for 5 cycles
		wait for 5 ns;

		-- count up for 10 cycles, now it's 10
		DVSEvent <= '1';
		wait for 10 ns;
		DVSEvent <= '0';
		
		-- keep at 10 for 5 cycles
		wait for 5 ns;

		-- count up for 10 cycles (should wrap around), now it's 5
		EventPolarity <= '1';
		wait for 10 ns;
		EventPolarity <= '0';
		
		

		-- keep at 10 for 5 cycles
		wait for 5 ns;

		-- count up for 10 cycles (should wrap around), now it's 5
		EventXAddr <= "11100";
		wait for 10 ns;
		EventXAddr <= "00000";

		-- clear goes back to 0
		wait for 5 ns;
		
		-- count up for 10 cycles (should wrap around), now it's 5
		EventYAddr <= "11100";
		wait for 10 ns;
		EventYAddr <= "00000";
		
		wait;
		
	end process WaveGen_Proc;
end architecture Testbench;

