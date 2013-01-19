-- VHDL netlist generated by SCUBA Diamond_2.0_Production (151)
-- Module  Version: 5.4
--E:\LatticeDiamond\diamond\2.0\ispfpga\bin\nt64\scuba.exe -w -n AERfifo -lang vhdl -synth synplify -bus_exp 7 -bb -arch mj5g00 -type ebfifo -depth 2048 -width 10 -rwidth 10 -no_enable -pe 10 -pf 1900 -e 

-- Thu Jan 17 13:42:36 2013

library IEEE;
use IEEE.std_logic_1164.all;
-- synopsys translate_off
library MACHXO;
use MACHXO.components.all;
-- synopsys translate_on

entity AERfifo is
    port (
        Data: in  std_logic_vector(9 downto 0); 
        WrClock: in  std_logic; 
        RdClock: in  std_logic; 
        WrEn: in  std_logic; 
        RdEn: in  std_logic; 
        Reset: in  std_logic; 
        RPReset: in  std_logic; 
        Q: out  std_logic_vector(9 downto 0); 
        Empty: out  std_logic; 
        Full: out  std_logic; 
        AlmostEmpty: out  std_logic; 
        AlmostFull: out  std_logic);
end AERfifo;

architecture Structure of AERfifo is

    -- internal signal declarations
    signal scuba_vhi: std_logic;
    signal Empty_int: std_logic;
    signal Full_int: std_logic;
    signal scuba_vlo: std_logic;

    -- local component declarations
    component VHI
        port (Z: out  std_logic);
    end component;
    component VLO
        port (Z: out  std_logic);
    end component;
    component FIFO8KA
    -- synopsys translate_off
        generic (FULLPOINTER1 : in std_logic_vector(13 downto 0); 
                FULLPOINTER : in std_logic_vector(13 downto 0); 
                AFPOINTER1 : in std_logic_vector(13 downto 0); 
                AEPOINTER1 : in std_logic_vector(13 downto 0); 
                AFPOINTER : in std_logic_vector(13 downto 0); 
                AEPOINTER : in std_logic_vector(13 downto 0); 
                CSDECODE_R : in std_logic_vector(1 downto 0); 
                CSDECODE_W : in std_logic_vector(1 downto 0); 
                RESETMODE : in String; REGMODE : in String; 
                DATA_WIDTH_R : in Integer; DATA_WIDTH_W : in Integer);
    -- synopsys translate_on
        port (DI0: in  std_logic; DI1: in  std_logic; DI2: in  std_logic; 
            DI3: in  std_logic; DI4: in  std_logic; DI5: in  std_logic; 
            DI6: in  std_logic; DI7: in  std_logic; DI8: in  std_logic; 
            DI9: in  std_logic; DI10: in  std_logic; DI11: in  std_logic; 
            DI12: in  std_logic; DI13: in  std_logic; 
            DI14: in  std_logic; DI15: in  std_logic; 
            DI16: in  std_logic; DI17: in  std_logic; 
            DI18: in  std_logic; DI19: in  std_logic; 
            DI20: in  std_logic; DI21: in  std_logic; 
            DI22: in  std_logic; DI23: in  std_logic; 
            DI24: in  std_logic; DI25: in  std_logic; 
            DI26: in  std_logic; DI27: in  std_logic; 
            DI28: in  std_logic; DI29: in  std_logic; 
            DI30: in  std_logic; DI31: in  std_logic; 
            DI32: in  std_logic; DI33: in  std_logic; 
            DI34: in  std_logic; DI35: in  std_logic; 
            FULLI: in  std_logic; CSW0: in  std_logic; 
            CSW1: in  std_logic; EMPTYI: in  std_logic; 
            CSR0: in  std_logic; CSR1: in  std_logic; WE: in  std_logic; 
            RE: in  std_logic; CLKW: in  std_logic; CLKR: in  std_logic; 
            RST: in  std_logic; RPRST: in  std_logic; 
            DO0: out  std_logic; DO1: out  std_logic; 
            DO2: out  std_logic; DO3: out  std_logic; 
            DO4: out  std_logic; DO5: out  std_logic; 
            DO6: out  std_logic; DO7: out  std_logic; 
            DO8: out  std_logic; DO9: out  std_logic; 
            DO10: out  std_logic; DO11: out  std_logic; 
            DO12: out  std_logic; DO13: out  std_logic; 
            DO14: out  std_logic; DO15: out  std_logic; 
            DO16: out  std_logic; DO17: out  std_logic; 
            DO18: out  std_logic; DO19: out  std_logic; 
            DO20: out  std_logic; DO21: out  std_logic; 
            DO22: out  std_logic; DO23: out  std_logic; 
            DO24: out  std_logic; DO25: out  std_logic; 
            DO26: out  std_logic; DO27: out  std_logic; 
            DO28: out  std_logic; DO29: out  std_logic; 
            DO30: out  std_logic; DO31: out  std_logic; 
            DO32: out  std_logic; DO33: out  std_logic; 
            DO34: out  std_logic; DO35: out  std_logic; 
            EF: out  std_logic; AEF: out  std_logic; AFF: out  std_logic; 
            FF: out  std_logic);
    end component;
    attribute FULLPOINTER1 : string; 
    attribute FULLPOINTER : string; 
    attribute AFPOINTER1 : string; 
    attribute AFPOINTER : string; 
    attribute AEPOINTER1 : string; 
    attribute AEPOINTER : string; 
    attribute RESETMODE : string; 
    attribute REGMODE : string; 
    attribute CSDECODE_R : string; 
    attribute CSDECODE_W : string; 
    attribute DATA_WIDTH_R : string; 
    attribute DATA_WIDTH_W : string; 
    attribute FULLPOINTER1 of AERfifo_0_2 : label is "0b01111111111001";
    attribute FULLPOINTER of AERfifo_0_2 : label is "0b01111111111101";
    attribute AFPOINTER1 of AERfifo_0_2 : label is "0b01110110101001";
    attribute AFPOINTER of AERfifo_0_2 : label is "0b01110110101101";
    attribute AEPOINTER1 of AERfifo_0_2 : label is "0b00000000101111";
    attribute AEPOINTER of AERfifo_0_2 : label is "0b00000000101011";
    attribute RESETMODE of AERfifo_0_2 : label is "ASYNC";
    attribute REGMODE of AERfifo_0_2 : label is "NOREG";
    attribute CSDECODE_R of AERfifo_0_2 : label is "0b11";
    attribute CSDECODE_W of AERfifo_0_2 : label is "0b11";
    attribute DATA_WIDTH_R of AERfifo_0_2 : label is "4";
    attribute DATA_WIDTH_W of AERfifo_0_2 : label is "4";
    attribute FULLPOINTER1 of AERfifo_1_1 : label is "0b00000000000000";
    attribute FULLPOINTER of AERfifo_1_1 : label is "0b11111111111111";
    attribute AFPOINTER1 of AERfifo_1_1 : label is "0b00000000000000";
    attribute AFPOINTER of AERfifo_1_1 : label is "0b11111111111111";
    attribute AEPOINTER1 of AERfifo_1_1 : label is "0b00000000000000";
    attribute AEPOINTER of AERfifo_1_1 : label is "0b11111111111111";
    attribute RESETMODE of AERfifo_1_1 : label is "ASYNC";
    attribute REGMODE of AERfifo_1_1 : label is "NOREG";
    attribute CSDECODE_R of AERfifo_1_1 : label is "0b11";
    attribute CSDECODE_W of AERfifo_1_1 : label is "0b11";
    attribute DATA_WIDTH_R of AERfifo_1_1 : label is "4";
    attribute DATA_WIDTH_W of AERfifo_1_1 : label is "4";
    attribute FULLPOINTER1 of AERfifo_2_0 : label is "0b00000000000000";
    attribute FULLPOINTER of AERfifo_2_0 : label is "0b11111111111111";
    attribute AFPOINTER1 of AERfifo_2_0 : label is "0b00000000000000";
    attribute AFPOINTER of AERfifo_2_0 : label is "0b11111111111111";
    attribute AEPOINTER1 of AERfifo_2_0 : label is "0b00000000000000";
    attribute AEPOINTER of AERfifo_2_0 : label is "0b11111111111111";
    attribute RESETMODE of AERfifo_2_0 : label is "ASYNC";
    attribute REGMODE of AERfifo_2_0 : label is "NOREG";
    attribute CSDECODE_R of AERfifo_2_0 : label is "0b11";
    attribute CSDECODE_W of AERfifo_2_0 : label is "0b11";
    attribute DATA_WIDTH_R of AERfifo_2_0 : label is "4";
    attribute DATA_WIDTH_W of AERfifo_2_0 : label is "4";
    attribute syn_keep : boolean;

begin
    -- component instantiation statements
    AERfifo_0_2: FIFO8KA
        -- synopsys translate_off
        generic map (FULLPOINTER1=> "01111111111001", FULLPOINTER=> "01111111111101", 
        AFPOINTER1=> "01110110101001", AFPOINTER=> "01110110101101", 
        AEPOINTER1=> "00000000101111", AEPOINTER=> "00000000101011", 
        RESETMODE=> "ASYNC", REGMODE=> "NOREG", CSDECODE_R=> "11", 
        CSDECODE_W=> "11", DATA_WIDTH_R=>  4, DATA_WIDTH_W=>  4)
        -- synopsys translate_on
        port map (DI0=>Data(0), DI1=>Data(1), DI2=>Data(2), DI3=>Data(3), 
            DI4=>scuba_vlo, DI5=>scuba_vlo, DI6=>scuba_vlo, 
            DI7=>scuba_vlo, DI8=>scuba_vlo, DI9=>scuba_vlo, 
            DI10=>scuba_vlo, DI11=>scuba_vlo, DI12=>scuba_vlo, 
            DI13=>scuba_vlo, DI14=>scuba_vlo, DI15=>scuba_vlo, 
            DI16=>scuba_vlo, DI17=>scuba_vlo, DI18=>scuba_vlo, 
            DI19=>scuba_vlo, DI20=>scuba_vlo, DI21=>scuba_vlo, 
            DI22=>scuba_vlo, DI23=>scuba_vlo, DI24=>scuba_vlo, 
            DI25=>scuba_vlo, DI26=>scuba_vlo, DI27=>scuba_vlo, 
            DI28=>scuba_vlo, DI29=>scuba_vlo, DI30=>scuba_vlo, 
            DI31=>scuba_vlo, DI32=>scuba_vlo, DI33=>scuba_vlo, 
            DI34=>scuba_vlo, DI35=>scuba_vlo, FULLI=>Full_int, 
            CSW0=>scuba_vhi, CSW1=>scuba_vhi, EMPTYI=>Empty_int, 
            CSR0=>scuba_vhi, CSR1=>scuba_vhi, WE=>WrEn, RE=>RdEn, 
            CLKW=>WrClock, CLKR=>RdClock, RST=>Reset, RPRST=>RPReset, 
            DO0=>Q(0), DO1=>Q(1), DO2=>Q(2), DO3=>Q(3), DO4=>open, 
            DO5=>open, DO6=>open, DO7=>open, DO8=>open, DO9=>open, 
            DO10=>open, DO11=>open, DO12=>open, DO13=>open, DO14=>open, 
            DO15=>open, DO16=>open, DO17=>open, DO18=>open, DO19=>open, 
            DO20=>open, DO21=>open, DO22=>open, DO23=>open, DO24=>open, 
            DO25=>open, DO26=>open, DO27=>open, DO28=>open, DO29=>open, 
            DO30=>open, DO31=>open, DO32=>open, DO33=>open, DO34=>open, 
            DO35=>open, EF=>Empty_int, AEF=>AlmostEmpty, AFF=>AlmostFull, 
            FF=>Full_int);

    AERfifo_1_1: FIFO8KA
        -- synopsys translate_off
        generic map (FULLPOINTER1=> "00000000000000", FULLPOINTER=> "11111111111111", 
        AFPOINTER1=> "00000000000000", AFPOINTER=> "11111111111111", 
        AEPOINTER1=> "00000000000000", AEPOINTER=> "11111111111111", 
        RESETMODE=> "ASYNC", REGMODE=> "NOREG", CSDECODE_R=> "11", 
        CSDECODE_W=> "11", DATA_WIDTH_R=>  4, DATA_WIDTH_W=>  4)
        -- synopsys translate_on
        port map (DI0=>Data(4), DI1=>Data(5), DI2=>Data(6), DI3=>Data(7), 
            DI4=>scuba_vlo, DI5=>scuba_vlo, DI6=>scuba_vlo, 
            DI7=>scuba_vlo, DI8=>scuba_vlo, DI9=>scuba_vlo, 
            DI10=>scuba_vlo, DI11=>scuba_vlo, DI12=>scuba_vlo, 
            DI13=>scuba_vlo, DI14=>scuba_vlo, DI15=>scuba_vlo, 
            DI16=>scuba_vlo, DI17=>scuba_vlo, DI18=>scuba_vlo, 
            DI19=>scuba_vlo, DI20=>scuba_vlo, DI21=>scuba_vlo, 
            DI22=>scuba_vlo, DI23=>scuba_vlo, DI24=>scuba_vlo, 
            DI25=>scuba_vlo, DI26=>scuba_vlo, DI27=>scuba_vlo, 
            DI28=>scuba_vlo, DI29=>scuba_vlo, DI30=>scuba_vlo, 
            DI31=>scuba_vlo, DI32=>scuba_vlo, DI33=>scuba_vlo, 
            DI34=>scuba_vlo, DI35=>scuba_vlo, FULLI=>Full_int, 
            CSW0=>scuba_vhi, CSW1=>scuba_vhi, EMPTYI=>Empty_int, 
            CSR0=>scuba_vhi, CSR1=>scuba_vhi, WE=>WrEn, RE=>RdEn, 
            CLKW=>WrClock, CLKR=>RdClock, RST=>Reset, RPRST=>RPReset, 
            DO0=>Q(4), DO1=>Q(5), DO2=>Q(6), DO3=>Q(7), DO4=>open, 
            DO5=>open, DO6=>open, DO7=>open, DO8=>open, DO9=>open, 
            DO10=>open, DO11=>open, DO12=>open, DO13=>open, DO14=>open, 
            DO15=>open, DO16=>open, DO17=>open, DO18=>open, DO19=>open, 
            DO20=>open, DO21=>open, DO22=>open, DO23=>open, DO24=>open, 
            DO25=>open, DO26=>open, DO27=>open, DO28=>open, DO29=>open, 
            DO30=>open, DO31=>open, DO32=>open, DO33=>open, DO34=>open, 
            DO35=>open, EF=>open, AEF=>open, AFF=>open, FF=>open);

    scuba_vhi_inst: VHI
        port map (Z=>scuba_vhi);

    scuba_vlo_inst: VLO
        port map (Z=>scuba_vlo);

    AERfifo_2_0: FIFO8KA
        -- synopsys translate_off
        generic map (FULLPOINTER1=> "00000000000000", FULLPOINTER=> "11111111111111", 
        AFPOINTER1=> "00000000000000", AFPOINTER=> "11111111111111", 
        AEPOINTER1=> "00000000000000", AEPOINTER=> "11111111111111", 
        RESETMODE=> "ASYNC", REGMODE=> "NOREG", CSDECODE_R=> "11", 
        CSDECODE_W=> "11", DATA_WIDTH_R=>  4, DATA_WIDTH_W=>  4)
        -- synopsys translate_on
        port map (DI0=>Data(8), DI1=>Data(9), DI2=>scuba_vlo, 
            DI3=>scuba_vlo, DI4=>scuba_vlo, DI5=>scuba_vlo, 
            DI6=>scuba_vlo, DI7=>scuba_vlo, DI8=>scuba_vlo, 
            DI9=>scuba_vlo, DI10=>scuba_vlo, DI11=>scuba_vlo, 
            DI12=>scuba_vlo, DI13=>scuba_vlo, DI14=>scuba_vlo, 
            DI15=>scuba_vlo, DI16=>scuba_vlo, DI17=>scuba_vlo, 
            DI18=>scuba_vlo, DI19=>scuba_vlo, DI20=>scuba_vlo, 
            DI21=>scuba_vlo, DI22=>scuba_vlo, DI23=>scuba_vlo, 
            DI24=>scuba_vlo, DI25=>scuba_vlo, DI26=>scuba_vlo, 
            DI27=>scuba_vlo, DI28=>scuba_vlo, DI29=>scuba_vlo, 
            DI30=>scuba_vlo, DI31=>scuba_vlo, DI32=>scuba_vlo, 
            DI33=>scuba_vlo, DI34=>scuba_vlo, DI35=>scuba_vlo, 
            FULLI=>Full_int, CSW0=>scuba_vhi, CSW1=>scuba_vhi, 
            EMPTYI=>Empty_int, CSR0=>scuba_vhi, CSR1=>scuba_vhi, 
            WE=>WrEn, RE=>RdEn, CLKW=>WrClock, CLKR=>RdClock, RST=>Reset, 
            RPRST=>RPReset, DO0=>Q(8), DO1=>Q(9), DO2=>open, DO3=>open, 
            DO4=>open, DO5=>open, DO6=>open, DO7=>open, DO8=>open, 
            DO9=>open, DO10=>open, DO11=>open, DO12=>open, DO13=>open, 
            DO14=>open, DO15=>open, DO16=>open, DO17=>open, DO18=>open, 
            DO19=>open, DO20=>open, DO21=>open, DO22=>open, DO23=>open, 
            DO24=>open, DO25=>open, DO26=>open, DO27=>open, DO28=>open, 
            DO29=>open, DO30=>open, DO31=>open, DO32=>open, DO33=>open, 
            DO34=>open, DO35=>open, EF=>open, AEF=>open, AFF=>open, 
            FF=>open);

    Empty <= Empty_int;
    Full <= Full_int;
end Structure;

-- synopsys translate_off
library MACHXO;
configuration Structure_CON of AERfifo is
    for Structure
        for all:VHI use entity MACHXO.VHI(V); end for;
        for all:VLO use entity MACHXO.VLO(V); end for;
        for all:FIFO8KA use entity MACHXO.FIFO8KA(V); end for;
    end for;
end Structure_CON;

-- synopsys translate_on
