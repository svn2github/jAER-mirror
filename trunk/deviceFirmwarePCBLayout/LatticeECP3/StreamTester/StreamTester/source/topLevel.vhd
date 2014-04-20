library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED."+";

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
	USBFifoFull_SBI : in std_logic;
	USBFifoAlmostFull_SBI : in std_logic;
	
	LED1_SO : out std_logic;
	LED2_SO : out std_logic);
end topLevel;

architecture Structural of topLevel is
  component fifoStatemachine
    port (
    Clock_CI : in  std_logic;
	Reset_RBI : in  std_logic;
	Run_SI : in  std_logic;
	USBFifoFull_SBI : in  std_logic;
	USBFifoAlmostFull_SBI : in std_logic;
	InFifoEmpty_SI : in std_logic;
    InFifoRead_SO : out std_logic;
	USBFifoChipSelect_SBO : out std_logic;
	USBFifoWrite_SBO : out std_logic;
	USBFifoPktEnd_SBO : out std_logic;
	USBFifoAddress_DO : out std_logic_vector(1 downto 0));
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
  
  signal Reset_RI: std_logic;
  signal AERFifoDataIn_D : std_logic_vector(15 downto 0);
  signal AERFifoWrite_S, AERFifoRead_S : std_logic;
  signal AERFifoEmpty_S, AERFifoFull_S : std_logic;
begin
  Reset_RI <= not Reset_RBI;
  AERFifoWrite_S <= '1';
  USBFifoRead_SBO <= '1';
  LED1_SO <= FPGARun_SI;
  LED2_SO <= '0';

uFifoStatemachine: fifoStatemachine
    port map (
    Clock_CI => USBClock_CI,
	Reset_RBI => Reset_RBI,
	Run_SI => FPGARun_SI,
	USBFifoFull_SBI => USBFifoFull_SBI,
	USBFifoAlmostFull_SBI => USBFifoAlmostFull_SBI,
	InFifoEmpty_SI => AERFifoEmpty_S,
    InFifoRead_SO => AERFifoRead_S,
	USBFifoChipSelect_SBO => USBFifoChipSelect_SBO,
	USBFifoWrite_SBO => USBFifoWrite_SBO,
	USBFifoPktEnd_SBO => USBFifoPktEnd_SBO,
	USBFifoAddress_DO => USBFifoAddress_DO);
	  
  uFifo : AERfifo
    port map (
      Data => AERFifoDataIn_D,
      WrClock => USBClock_CI,
      RdClock => USBClock_CI,
      WrEn => AERFifoWrite_S, 
      RdEn => AERFifoRead_S,
      Reset => Reset_RI,
      RPReset => Reset_RI,
      Q =>  USBFifoData_DO,
      Empty => AERFifoEmpty_S, 
      Full => AERFifoFull_S,
      AlmostEmpty => open,
      AlmostFull => open);

  uContinuousCounter : continuousCounter
    port map (
    Clock_CI => USBClock_CI,
    Reset_RBI => Reset_RBI,
    Data_DO => AERFifoDataIn_D);

end Structural;