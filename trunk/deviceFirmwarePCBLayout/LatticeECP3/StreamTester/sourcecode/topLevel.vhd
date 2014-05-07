library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity topLevel is
  port (
    USBClock_CI : in std_logic;
    Reset_RBI : in std_logic;
	FPGARun_SI : in std_logic;
	
	USBFifoData_DO : out std_logic_vector(15 downto 0);
	USBFifoChipSelect_SBO : out std_logic;
	USBFifoWrite_SBO : out std_logic;
	USBFifoRead_SBO : out std_logic;
	USBFifoPktEnd_SBO : out std_logic;
	USBFifoAddress_DO : out std_logic_vector(1 downto 0);
	USBFifoThr0Ready_SI : in std_logic;
	USBFifoThr0Watermark_SI : in std_logic;
	USBFifoThr1Ready_SI : in std_logic;
	USBFifoThr1Watermark_SI : in std_logic;
	
	LED1_SO : out std_logic;
	LED2_SO : out std_logic;
	LED3_SO : out std_logic;
	LED4_SO : out std_logic);
end topLevel;

architecture Structural of topLevel is
  component fifoStatemachine
    port (
    Clock_CI : in std_logic;
	Reset_RBI : in std_logic;
	Run_SI : in std_logic;
	USBFifoThread0Full_SI : in std_logic;
	USBFifoThread0AlmostFull_SI : in std_logic;
	USBFifoThread1Full_SI : in std_logic;
	USBFifoThread1AlmostFull_SI : in std_logic;
	USBFifoChipSelect_SBO : out std_logic;
	USBFifoWrite_SBO : out std_logic;
	USBFifoPktEnd_SBO : out std_logic;
	USBFifoAddress_DO : out std_logic_vector(1 downto 0);
	InFifoEmpty_SI : in std_logic;
	InFifoAlmostEmpty_SI : in std_logic;
    InFifoRead_SO : out std_logic);
  end component;

  component AERfifo
    port (
    Data: in std_logic_vector(15 downto 0); 
    WrClock: in std_logic; 
    RdClock: in std_logic; 
    WrEn: in std_logic; 
    RdEn: in std_logic; 
    Reset: in std_logic; 
    RPReset: in std_logic; 
    Q: out std_logic_vector(15 downto 0); 
    Empty: out std_logic; 
    Full: out std_logic; 
    AlmostEmpty: out std_logic; 
    AlmostFull: out std_logic);
  end component;
  
  component continuousCounter
    port (
    Clock_CI : in  std_logic;
    Reset_RBI : in  std_logic;
    Data_DO : out std_logic_vector(15 downto 0));
  end component;
  
  component pmi_pll is
     generic (
       pmi_freq_clki : integer := 100; 
       pmi_freq_clkfb : integer := 100; 
       pmi_freq_clkop : integer := 100; 
       pmi_freq_clkos : integer := 100; 
       pmi_freq_clkok : integer := 50; 
       pmi_family : string := "EC"; 
       pmi_phase_adj : integer := 0; 
       pmi_duty_cycle : integer := 50; 
       pmi_clkfb_source : string := "CLKOP"; 
       pmi_fdel : string := "off"; 
       pmi_fdel_val : integer := 0; 
       module_type : string := "pmi_pll" 
    );
    port (
     CLKI: in std_logic;
     CLKFB: in std_logic;
     RESET: in std_logic;
     CLKOP: out std_logic;
     CLKOS: out std_logic;
     CLKOK: out std_logic;
     CLKOK2: out std_logic;
     LOCK: out std_logic
   );
  end component pmi_pll;
  
  signal Reset_RI: std_logic;
  signal AERFifoDataIn_D : std_logic_vector(15 downto 0);
  signal AERFifoWrite_S, AERFifoRead_S : std_logic;
  signal AERFifoEmpty_S, AERFifoFull_S, AERFifoAlmostEmpty_S : std_logic;
  signal SlowClock_C : std_logic;
begin
  Reset_RI <= not Reset_RBI;
  AERFifoWrite_S <= FPGARun_SI and (not AERFifoFull_S);
  USBFifoRead_SBO <= '1';
  LED1_SO <= AERFifoEmpty_S;
  LED2_SO <= AERFifoFull_S;
  LED3_SO <= '0';
  LED4_SO <= '0';

uFifoStatemachine: fifoStatemachine
    port map (
    Clock_CI => USBClock_CI,
	Reset_RBI => Reset_RBI,
	Run_SI => FPGARun_SI,
	USBFifoThread0Full_SI => USBFifoThr0Ready_SI,
	USBFifoThread0AlmostFull_SI => USBFifoThr0Watermark_SI,
	USBFifoThread1Full_SI => USBFifoThr1Ready_SI,
	USBFifoThread1AlmostFull_SI => USBFifoThr1Watermark_SI,
	USBFifoChipSelect_SBO => USBFifoChipSelect_SBO,
	USBFifoWrite_SBO => USBFifoWrite_SBO,
	USBFifoPktEnd_SBO => USBFifoPktEnd_SBO,
	USBFifoAddress_DO => USBFifoAddress_DO,
	InFifoEmpty_SI => AERFifoEmpty_S,
	InFifoAlmostEmpty_SI => AERFifoAlmostEmpty_S,
    InFifoRead_SO => AERFifoRead_S);
	  
  uFifo : AERfifo
    port map (
      Data => AERFifoDataIn_D,
      WrClock => SlowClock_C,
      RdClock => USBClock_CI,
      WrEn => AERFifoWrite_S, 
      RdEn => AERFifoRead_S,
      Reset => Reset_RI,
      RPReset => Reset_RI,
      Q =>  USBFifoData_DO,
      Empty => AERFifoEmpty_S, 
      Full => AERFifoFull_S,
      AlmostEmpty => AERFifoAlmostEmpty_S,
      AlmostFull => open);
	  
  uPLLSlowDown: pmi_pll
    generic map(
       pmi_freq_clki => 25,
       pmi_freq_clkfb => 10,
       pmi_freq_clkop => 10,
       pmi_freq_clkos => 10,
       pmi_freq_clkok => 10,
       pmi_family => "ECP3",
       pmi_phase_adj => 0,
       pmi_duty_cycle => 25,
       pmi_clkfb_source => "CLKOP",
       pmi_fdel => "off",
       pmi_fdel_val => 0
    )
    port map (
     CLKI => USBClock_CI,
     CLKFB => SlowClock_C,
     RESET => Reset_RI,
     CLKOP => SlowClock_C,
     CLKOS => open,
     CLKOK => open,
     CLKOK2 => open,
     LOCK => open
   );

  uContinuousCounter : continuousCounter
    port map (
    Clock_CI => SlowClock_C,
    Reset_RBI => Reset_RBI,
    Data_DO => AERFifoDataIn_D);

end Structural;