
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ApproachCell_tb is
end entity ApproachCell_tb;

architecture Testbench of ApproachCell_tb is
	-- component generics
	constant CounterSize    : integer := 32;
	constant UpdateUnit : signed( 1 downto 0) := "01";
	constant IFThreshold    : signed(63 downto 0) := x"0000000000000011";
	
	-- component ports
	signal Clock_C     : std_logic;
	signal Reset_R     : std_logic;
	signal Req    : std_logic;
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
			DVSEvent_I    => Req,
			EventXAddr_I    => EventXAddr,
			EventYAddr_I => EventYAddr,
			EventPolarity_I  => EventPolarity,
			DecayEnable_I      => DecayEnable,
			AC_Fire_O  => AC_Fire,
			CounterOut_I => CounterOut,
			surroundSuppressionEnabled_I => surroundSuppressionEnabled
			);
-- clock generation
	Clk     <= not Clk after 0.5 ns;
	
	
	
	Counter: process 
	begin
	

	  wait until  rising_edge(Clk);
	  CounterOut <= CounterOut + 1;
		
	end process Counter;

	-- waveform generation
	WaveGen_Proc : process
	begin
		Reset_R     <= '0';
		Req     <= '0';
		EventXAddr   <= "00000";
		EventYAddr   <= "00000";
		EventPolarity <= '0';  ---Polarity = 0 off event Polarity =1 On event;
		DecayEnable  <= '0';
		surroundSuppressionEnabled <= '0';
		
		
	
		-- pulse reset
		wait for 2 ns;
		Reset_R <= '1';
		wait for 3 ns;---5ns
		Reset_R <= '0';

		-- should remain at zero for 5 cycles
		wait for 5 ns;---10
		
		wait for 5 ns; --15
		Req <= '1';
		EventPolarity <= '0';
		EventXAddr <= "00001";
		EventYAddr <= "00000";
		wait for 5 ns; --15
		Req <= '0';
	
		wait for 5 ns; --15
		Req <= '1';
		EventPolarity <= '0';
		EventXAddr <= "00001";
		EventYAddr <= "00000";
		wait for 5 ns; --15
		Req <= '0';
		
		
		
		wait for 5 ns; --15
		Req <= '1';
		EventPolarity <= '0';
		EventXAddr <= "00001";
		EventYAddr <= "00000";
		wait for 5 ns; --15
		Req <= '0';
	
		wait for 5 ns; --15
		Req <= '1';
		EventPolarity <= '0';
		EventXAddr <= "00001";
		EventYAddr <= "00000";
		wait for 5 ns; --15
		Req <= '0';
		
		wait for 5 ns; --15
		Req <= '1';
		EventPolarity <= '0';
		EventXAddr <= "00101";
		EventYAddr <= "00000";
		wait for 5 ns; --15
		Req <= '0';
		
		
		wait for 5 ns; --15
		Req <= '1';
		EventPolarity <= '0';
		EventXAddr <= "00101";
		EventYAddr <= "00000";
		wait for 5 ns; --15
		Req <= '0';
		
		
		wait for 10 ns;---185
		DecayEnable  <= '1';
		wait for 1 ns;---195
		DecayEnable  <= '0';
		
		
		
		
		wait;
		
	end process WaveGen_Proc;
end architecture Testbench;

