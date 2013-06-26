-- VHDL module instantiation generated by SCUBA Diamond_1.0_Production (529)
-- Module  Version: 5.4
-- Tue Nov 16 17:05:21 2010

-- parameterized module component declaration
component AERfifo
    port (Data: in  std_logic_vector(15 downto 0); 
        WrClock: in  std_logic; RdClock: in  std_logic; 
        WrEn: in  std_logic; RdEn: in  std_logic; Reset: in  std_logic; 
        RPReset: in  std_logic; Q: out  std_logic_vector(15 downto 0); 
        Empty: out  std_logic; Full: out  std_logic; 
        AlmostEmpty: out  std_logic; AlmostFull: out  std_logic);
end component;

-- parameterized module component instance
__ : AERfifo
    port map (Data(15 downto 0)=>__, WrClock=>__, RdClock=>__, WrEn=>__, 
        RdEn=>__, Reset=>__, RPReset=>__, Q(15 downto 0)=>__, Empty=>__, 
        Full=>__, AlmostEmpty=>__, AlmostFull=>__);
