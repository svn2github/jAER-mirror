-- VHDL module instantiation generated by SCUBA Diamond (64-bit) 3.2.0.134
-- Module  Version: 5.6
-- Mon Oct 06 19:04:15 2014

-- parameterized module component declaration
component clockgen
    port (CLK: in std_logic; RESET: in std_logic; CLKOP: out std_logic; 
        LOCK: out std_logic);
end component;

-- parameterized module component instance
__ : clockgen
    port map (CLK=>__, RESET=>__, CLKOP=>__, LOCK=>__);
