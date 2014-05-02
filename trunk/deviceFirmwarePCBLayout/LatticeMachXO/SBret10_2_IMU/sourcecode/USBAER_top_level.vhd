--------------------------------------------------------------------------------
-- Company: ini
-- Engineer: Raphael Berner
--
-- Create Date:    11:54:08 10/24/05
-- Design Name:    
-- Module Name:    USBAER_top_level - Structural
-- Project Name:   USBAERmini2
-- Target Device:  CoolrunnerII XC2C256
-- Tool versions:  
-- Description: top-level file, connects all blocks
--
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED."+";

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity USBAER_top_level is
  port (
    -- communication ports to FX2 Fifos
    FX2FifoDataxDIO         : out std_logic_vector(15 downto 0);
    FX2FifoInFullxSBI       : in    std_logic;
    FX2FifoWritexEBO        : out   std_logic;
    FX2FifoReadxEBO         : out   std_logic;
  
    FX2FifoPktEndxSBO       : out   std_logic;
    FX2FifoAddressxDO       : out   std_logic_vector(1 downto 0);

    -- clock and reset inputs
    -- ClockxCI  : in std_logic;
    --IfClockxCO : out std_logic;
    IfClockxCI : in std_logic;
    ResetxRBI : in std_logic;
	
	-- ports to synchronize other USBAER boards
    SyncInCLKxABI   : in  std_logic;      -- Pin T2. Input for 10kHz clock. Used when the DVS is slave
	SyncInSIGxSBO   : in  std_logic;	-- Pin T4. Input 2. Used when the DVS is slave
	SyncInSWxEI   : in  std_logic;		-- Pin T3. Says to the host that a cable is attached, so the DVS is a slave.
    SyncOutCLKxCBO : out std_logic;		-- Pin T13. Generates a 10kHz clock when the DVS is Master
	SyncOutSIGxSBI : out std_logic;		-- Pin P12. 
	SyncOutSWxEI : out std_logic;		-- Pin P11. Says to the Host a cable is attached, so the DVS is Master

    -- communication with 8051   
    PC0xSIO  : inout  std_logic;
    PC1xSIO  : inout  std_logic;
    PC2xSIO  : inout  std_logic;
    PC3xSIO  : inout  std_logic;

--    PA0xSIO : inout std_logic;
    PA0xSIO : inout std_logic;
    PA1xSIO : inout std_logic;
    PA3xSIO : inout std_logic;
    PA7xSIO : inout std_logic;

    PE2xSI : in std_logic;
    PE3xSI : in std_logic;

    FXLEDxSI : in std_logic;

    -- ADC
    ADCclockxCO : out std_logic;
    ADCwordxDI : in std_logic_vector(9 downto 0);
   
    ADCoexEBO : out std_logic;
    ADCstbyxEO : out std_logic;	
	ADCovrxSI : in std_logic;
   
	--H IMU I2C Signals
	IMUSDAxSIO : inout std_logic; -- Pin T5. IMU I2C Serial Data Address, used to send configuration bits and recieve IMU data
	IMUSCLxSO  : out std_logic;   -- Pin T6. IMU I2C Serial Clock, *add details*
	--H 
	
	CDVSTestSRRowClockxSO: out std_logic;
    CDVSTestSRColClockxSO: out std_logic;
    CDVSTestSRRowInxSO: out std_logic;
    CDVSTestSRColInxSO: out std_logic;
    
    CDVSTestBiasEnablexEO : out std_logic;
    CDVSTestChipResetxRBO: out std_logic;
	
	CDVSTestColMode0xSO : out std_logic;
	CDVSTestColMode1xSO : out std_logic;
	
	CDVSTestBiasDiagSelxSO : out std_logic;
	CDVSTestBiasBitOutxSI : in std_logic;

	CDVSTestApsTxGatexSO : out std_logic;
    
    -- control LED
    LED1xSO : out std_logic;
    LED2xSO : out std_logic;
    LED3xSO : out std_logic;
 
    DebugxSIO : inout std_logic_vector(15 downto 0);

    -- AER monitor interface
    AERMonitorREQxABI    : in  std_logic;  -- needs synchronization
    AERMonitorACKxSBO    : out std_logic;
    AERMonitorAddressxDI : in  std_logic_vector(9 downto 0));

end USBAER_top_level;

architecture Structural of USBAER_top_level is
  
  component fifoStatemachine
    port (
      ClockxCI                   : in  std_logic;
      ResetxRBI                  : in  std_logic;
	  RunxSI                     : in  std_logic;
      FifoTransactionxSO         : out std_logic;
      FX2FifoInFullxSBI          : in  std_logic;
      FifoEmptyxSI               : in  std_logic;
      FifoReadxEO                : out std_logic;
      FX2FifoWritexEBO           : out std_logic;
      FX2FifoPktEndxSBO          : out std_logic;
      FX2FifoAddressxDO          : out std_logic_vector(1 downto 0);
      IncEventCounterxSO         : out std_logic;
      ResetEventCounterxSO       : out std_logic;
      ResetEarlyPaketTimerxSO    : out std_logic;
      EarlyPaketTimerOverflowxSI : in  std_logic);
  end component;

  component shiftRegister
    generic (
      width : natural);
    port (
      ClockxCI   : in  std_logic;
      ResetxRBI  : in  std_logic;
      LatchxEI   : in  std_logic;
      DxDI       : in  std_logic;
      QxDO       : out std_logic;
      DataOutxDO : out std_logic_vector((width-1) downto 0));
  end component;
  
  component clockgen
    port (
      CLK: in std_logic;
      RESET: in std_logic;
      CLKOP: out std_logic; 
      LOCK: out std_logic);
  end component;

  component cDVSResetStateMachine
    port (
      ClockxCI      : in  std_logic;
      ResetxRBI     : in  std_logic;
      AERackxSBI    : in  std_logic;
      RxcolGxSI     : in  std_logic;
      cDVSresetxRBI : in  std_logic;
      CDVSresetxRBO : out std_logic);
  end component;
  
    component synchronizerStateMachine
     port (
       ClockxCI              : in  std_logic;
       ResetxRBI             : in  std_logic;
       RunxSI                : in  std_logic;
       ConfigxSI             : in  std_logic;
       SyncInCLKxABI			 : in  std_logic;      
--	   SyncInSIGxSBO 		  	: in  std_logic;
--	   SyncInSWxEI  		: in  std_logic;
	   SyncOutCLKxCBO 		: out std_logic;
--	   SyncOutSIGxSBI 		: out std_logic;
--	   SyncOutSWxEI 		: out std_logic;
       TriggerxSO            : out std_logic;
       HostResetTimestampxSI : in  std_logic;
       ResetTimestampxSBO    : out std_logic;
       IncrementCounterxSO   : out std_logic);
   end component;                                                     

  component monitorStateMachine
    port (
    ClockxCI               : in  std_logic;
    ResetxRBI              : in  std_logic;
    AERREQxSBI     : in  std_logic;
    AERACKxSBO     : out std_logic;
    XxDI        : in std_logic;
    UseLongAckxSI        : in std_logic;
    FifoFullxSI         : in  std_logic;
    FifoWritexEO          : out std_logic;
    TimestampRegWritexEO     : out std_logic;
    AddressRegWritexEO       : out std_logic;
	
	--H Change variable name and size
    --AddressTimestampSelectxSO  : out std_logic_vector(1 downto 0);
	DatatypeSelectxSO : out std_logic_vector(2 downto 0); -- Selects type of data being written to the FIFO
	--H 
	
	ADCvalueReadyxSI : in std_logic;
    ReadADCvaluexEO : out std_logic;
    TimestampOverflowxSI : in std_logic;
    TriggerxSI : in std_logic;
    AddressMSBxDO : out std_logic_vector(1 downto 0);
    ResetTimestampxSBI : in std_logic
    );
  end component;

  component ADCStateMachine
    port (
		ClockxCI              : in    std_logic;
		ADCclockxCO           : out   std_logic;
		ResetxRBI             : in    std_logic;
		ADCwordxDI            : in    std_logic_vector(9 downto 0);
		ADCoutxDO             : out   std_logic_vector(13 downto 0);
		ADCoexEBO	          : out   std_logic;
		ADCstbyxEO            : out   std_logic;
		ADCovrxSI			  : in	  std_logic;
		RegisterWritexEO      : out   std_logic;
		SRLatchxEI            : in    std_logic;
		RunADCxSI             : in    std_logic;
		ExposurexDI          : in    std_logic_vector(15 downto 0);
		ColSettlexDI          : in    std_logic_vector(15 downto 0);
		RowSettlexDI          : in    std_logic_vector(15 downto 0);
		ResSettlexDI          : in    std_logic_vector(15 downto 0);
		FramePeriodxDI		  : in    std_logic_vector(15 downto 0);
		ExtTriggerxEI		  : in    std_logic;
		CDVSTestSRRowInxSO    : out   std_logic;
		CDVSTestSRRowClockxSO : out   std_logic;
		CDVSTestSRColInxSO    : out   std_logic;
		CDVSTestSRColClockxSO : out   std_logic;
		CDVSTestColMode0xSO   : out   std_logic;
		CDVSTestColMode1xSO   : out   std_logic;
		CDVSTestApsTxGatexSO  : out   std_logic;
		ADCStateOutputLEDxSO  : out	  std_logic);
  end component;
  
  component ADCvalueReady
    port (
      ClockxCI         : in  std_logic;
      ResetxRBI        : in  std_logic;
      RegisterWritexEI : in  std_logic;
      ReadValuexEI     : in  std_logic;
      ValueReadyxSO    : out std_logic);
  end component;
  
  --H Interface between IMU and I2C Controller
  component IMUStateMachine
    port (
		-- Change signals
        ClockxCI              : in    std_logic;
		ADCclockxCO           : out   std_logic;
		ResetxRBI             : in    std_logic;
		ADCwordxDI            : in    std_logic_vector(9 downto 0);
		ADCoutxDO             : out   std_logic_vector(13 downto 0);
		ADCoexEBO	          : out   std_logic;
		ADCstbyxEO            : out   std_logic;
		ADCovrxSI			  : in	  std_logic;
		RegisterWritexEO      : out   std_logic;
		SRLatchxEI            : in    std_logic;
		RunADCxSI             : in    std_logic;
		ExposurexDI          : in    std_logic_vector(15 downto 0);
		ColSettlexDI          : in    std_logic_vector(15 downto 0);
		RowSettlexDI          : in    std_logic_vector(15 downto 0);
		ResSettlexDI          : in    std_logic_vector(15 downto 0);
		FramePeriodxDI		  : in    std_logic_vector(15 downto 0);
		ExtTriggerxEI		  : in    std_logic;
		CDVSTestSRRowInxSO    : out   std_logic;
		CDVSTestSRRowClockxSO : out   std_logic;
		CDVSTestSRColInxSO    : out   std_logic;
		CDVSTestSRColClockxSO : out   std_logic;
		CDVSTestColMode0xSO   : out   std_logic;
		CDVSTestColMode1xSO   : out   std_logic;
		CDVSTestApsTxGatexSO  : out   std_logic;
		ADCStateOutputLEDxSO  : out	  std_logic);
  end component;
  --H
  
  --H IMU Value Ready Indicator
  component IMUvalueReady
    port (
	  -- Change signals
      ClockxCI         : in  std_logic;
      ResetxRBI        : in  std_logic;
      RegisterWritexEI : in  std_logic;
      ReadValuexEI     : in  std_logic;
      ValueReadyxSO    : out std_logic);
  end component;
  --H 
  
  --H I2C Controller used for to read and write data from the IMU
  component I2C_Top
    port (
	  SDA        : inout std_logic;              -- Serial Data Line of the I2C bus
      SCL        : inout std_logic;              -- Serial Clock Line of the I2C bus
      Clock      : in std_logic;                 -- MP Clock 
      Reset_L    : in std_logic;                 -- Reset, active low
      CS_L       : in std_logic;                 -- Chip select, active low
      A0         : in std_logic;                 -- Address bits for register selection
      A1         : in std_logic;                 -- Address bits for register selection
      A2         : in std_logic;                 -- Address bits for register selection
      RW_L       : in std_logic;                 -- Read/Write, write active low
      INTR_L     : out std_logic;                -- Interupt Request, active low
      DATA       : inout std_logic_vector(7 downto 0)); -- data bus to/from attached device(NOTE: Data(7) is MSB)                         
  end component  
  --H
  
  component wordRegister
    generic (
      width          :     natural := 14);	
	port (
      ClockxCI       : in  std_logic;
      ResetxRBI      : in  std_logic;
      WriteEnablexEI : in  std_logic;
      DataInxDI      : in  std_logic_vector(width-1 downto 0);
      DataOutxDO     : out std_logic_vector(width-1 downto 0));
  end component;

  component eventCounter
    port (
      ClockxCI     : in  std_logic;
      ResetxRBI    : in  std_logic;
      ClearxSI     : in  std_logic;
      IncrementxSI : in  std_logic;
      OverflowxSO  : out std_logic);
  end component;

  component timestampCounter
    port (
      ClockxCI      : in  std_logic;
      ResetxRBI     : in  std_logic;
      IncrementxSI  : in  std_logic;
      OverflowxSO   : out std_logic;
      DataxDO       : out std_logic_vector(13 downto 0));
  end component;

  component earlyPaketTimer
    port (
      ClockxCI        : in  std_logic;
      ResetxRBI       : in  std_logic;
      ClearxSI        : in  std_logic;
      TimerExpiredxSO : out std_logic);
  end component;

  component AERfifo
    port (
      Data: in  std_logic_vector(15 downto 0); 
      WrClock: in  std_logic;
      RdClock: in  std_logic; 
      WrEn: in  std_logic;
      RdEn: in  std_logic;
      Reset: in  std_logic; 
      RPReset: in  std_logic;
      Q: out  std_logic_vector(15 downto 0); 
      Empty: out  std_logic;
      Full: out  std_logic; 
      AlmostEmpty: out  std_logic;
      AlmostFull: out  std_logic);
  end component;

  -- routing
  -- signal CDVSTestBiasDiagSelxS 	: std_logic;

  -- signal declarations
  signal MonitorTimestampxD                          : std_logic_vector(13 downto 0);
  signal ActualTimestampxD                           : std_logic_vector(13 downto 0);

  -- register write enables
  signal TimestampRegWritexE   : std_logic;
  
  signal SyncIn1xAB : std_logic;

  signal AERREQxSB, AERReqSyncxSBN  : std_logic;

  signal AERMonitorACKxSB : std_logic;
  signal UseLongAckxS : std_logic;
  
  -- mux control signals
  --H
  --signal AddressTimestampSelectxS : std_logic_vector(1 downto 0);
  signal DatatypeSelectxS : std_logic_vector(2 downto 0);
  --H
  
  -- communication between state machines
--  signal SetMonitorEventReadyxS    : std_logic;
--  signal ClearMonitorEventxS       : std_logic;
--  signal MonitorEventReadyxS       : std_logic;
  signal IncEventCounterxS         : std_logic;
  signal ResetEventCounterxS       : std_logic;
  signal ResetEarlyPaketTimerxS    : std_logic;
  signal EarlyPaketTimerOverflowxS : std_logic;
  signal SMResetEarlyPaketTimerxS : std_logic;
  signal ECResetEarlyPaketTimerxS : std_logic;

  -- clock, reset
  signal ClockxC, IfClockxC             : std_logic;
  signal ResetxRB, ResetxR              : std_logic;
  signal RunxS : std_logic;
  signal CounterResetxRB               : std_logic;
  signal SynchronizerResetTimestampxSB : std_logic;
  signal CDVSTestChipResetxRB : std_logic; 
  signal CDVSTestPeriodicChipResetxRB : std_logic;
  signal RxcolGxS : std_logic;

  -- signals regarding the timestamp
  signal TimestampOverflowxS   : std_logic;
  signal AddressMSBxD          : std_logic_vector(1 downto 0);
  signal TimestampMasterxS     : std_logic;

  -- various
  signal FifoTransactionxS : std_logic;
  signal FX2FifoWritexEB : std_logic;
  signal FX2FifoPktEndxSB     : std_logic;
  signal SyncOut1xSB        : std_logic;
  signal HostResetTimestampxS : std_logic;

  signal TriggerxS : std_logic;

  signal AddressRegOutxD : std_logic_vector(9 downto 0);
  signal AddressRegWritexE : std_logic;
  signal AddressRegOut8xD : std_logic;

  -- counter increment signal
  signal IncxS : std_logic;

  --H IMU Register control and data signals
  signal ReadIMUValuexE, IMUvalueReadyxS : std_logic;
  signal IMUregInxD : std_logic_vector(15 downto 0);
  signal IMUregOutxD : std_logic_vector(15 downto 0);
  signal IMUregWritexE : std_logic;
  signal IMUdataxD : std_logic_Vector(15 downto 0);
  --H 
  
  --H  
  --signal IMUsmRstxE           : std_logic;
  --signal IMUclockxC           : std_logic;
  --signal IMUoexEB	          : std_logic;
  --signal IMUstbyxE            : std_logic;
  --signal IMUovrxS			  : std_logic;
  --signal IMUConfigurationxD : std_logic_vector(15 downto 0);
  --H

  -- ADC related signals
  signal ReadADCvaluexE, ADCvalueReadyxS : std_logic;
  signal ADCregInxD : std_logic_vector(13 downto 0);
  signal ADCregOutxD : std_logic_vector(13 downto 0);
  signal ADCregWritexE : std_logic;
  signal ADCdataxD : std_logic_vector(13 downto 0);
  
  signal ADCsmRstxE           : std_logic;
  signal ADCclockxC           : std_logic;
  signal ADCoexEB	          : std_logic;
  signal ADCstbyxE            : std_logic;
  signal ADCovrxS			  : std_logic;
  signal CDVSTestSRRowClockxS, CDVSTestSRRowInxS : std_logic;
  signal CDVSTestSRColClockxS, CDVSTestSRColInxS : std_logic;
  signal CDVSTestColMode0xS, CDVSTestColMode1xS : std_logic;
  signal CDVSTestApsTxGatexS  : std_logic;
  signal ExtTriggerxE				: std_logic;
  
  signal SRDataOutxD : std_logic_vector(79 downto 0);
  
  signal ExposurexD, ColSettlexD, RowSettlexD, ResSettlexD : std_logic_vector(15 downto 0); 
  signal FramePeriodxD : std_logic_vector(15 downto 0);
  
  signal SRoutxD, SRinxD, SRLatchxE, SRClockxC : std_logic;
  signal RunADCxS : std_logic;
  
  signal ADCStateOutputLEDxS : std_logic;
  
  -- lock signal from PLL, unused so far
  signal LockxS : std_logic;

  -- fifo signals
  signal FifoDataInxD, FifoDataOutxD : std_logic_vector(15 downto 0);
  signal FifoWritexE, FifoReadxE : std_logic;
  signal FifoEmptyxS, FifoAlmostEmptyxS, FifoFullxS, FifoAlmostFullxS : std_logic;
  
  -- constants used for mux
  constant selectADC : std_logic_vector(2 downto 0) := "011";
  constant selectaddress   : std_logic_vector(2 downto 0) := "001";
  constant selecttimestamp : std_logic_vector(2 downto 0) := "000";
  constant selecttrigger : std_logic_vector(2 downto 0) := "010";
  --H 
  constant selectIMU : std_logic_vector(2 downto 0) := "100";
  --H 
  
  --H 
  --H External event indicator is the 12th bit (if 13th bit is 0), use other bits to specify type
  constant externaleventIMU : std_logic_vector(13 downto 0) := "0100000000001";
  constant externaleventOthers : std_logic_vector(13 downto 0) := "01000000000000";   
  --H 

begin
  IfClockxC <= IfClockxCI;
  ADCclockxCO <= ADCclockxC;
  
  uClockGen : clockgen
    port map (
      CLK  =>  IFClockxCI,
      RESET=> ResetxR,
      CLKOP=> ClockxC,
      LOCK=>  LockxS);

  --ClockxC <= IFClockxCI;
  
  -- routing
  
  CDVSTestBiasDiagSelxSO <= PA0xSIO; 
  
  -- run the state machines either when reset is high or when in slave mode
  ResetxRB <= ResetxRBI;
  ResetxR <= not ResetxRBI;
  CounterResetxRB <= SynchronizerResetTimestampxSB;
  
  FX2FifoReadxEBO <= '1';

  SyncIn1xAB <= SyncInCLKxABI;
  
  --H FIGURE OUT WHAT TO DO HERE ABOUT IMU CONFIG BITS
  
  shiftRegister_1: shiftRegister
    generic map (
      width => 80)
    port map (
      ClockxCI   => SRClockxC,
      ResetxRBI  => ResetxRB,
      LatchxEI   => SRLatchxE,
      DxDI       => SRinxD,
      QxDO       => SRoutxD,
      DataOutxDO => SRDataOutxD);

  ExposurexD <= SRDataOutxD(15 downto 0);
  ColSettlexD <= SRDataOutxD(31 downto 16);
  RowSettlexD <= SRDataOutxD(47 downto 32);
  ResSettlexD <= SRDataOutxD(63 downto 48);
  FramePeriodxD <= SRDataOutxD(79 downto 64);
  
  uFifo : AERfifo
    port map (
      Data(15 downto 0)=> FifoDataInxD,
      WrClock => ClockxC,
      RdClock => IfClockxC,
      WrEn=> FifoWritexE, 
      RdEn=> FifoReadxE,
      Reset => ResetxR,
      RPReset=> ResetxR,
      Q(15 downto 0)=>  FifoDataOutxD,
      Empty=> FifoEmptyxS, 
      Full=> FifoFullxS,
      AlmostEmpty=> FifoAlmostEmptyxS,
      AlmostFull=> FifoAlmostFullxS);

  FX2FifoDataxDIO <= FifoDataOutxD;

  uMonitorAddressRegister : wordRegister
    generic map (
      width          => 10)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => AddressRegWritexE,
      DataInxDI      => AERMonitorAddressxDI,
      DataOutxDO     => AddressRegOutxD);
  
  uMonitorTimestampRegister : wordRegister
    generic map (
      width          => 14)
    port map (
      ClockxCI       => ClockxC,
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => TimestampRegWritexE,
      DataInxDI      => ActualTimestampxD,
      DataOutxDO     => MonitorTimestampxD);

  uADCRegister : wordRegister
    generic map (
      width          => 14)
    port map (
      ClockxCI       => IfClockxC,
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => ADCregWritexE,
      DataInxDI      => ADCregInxD,
      DataOutxDO     => ADCregOutxD);

  ADCregInxD <= ADCdataxD;
  
  --H IMU Word Register used to store data
  uIMURegister : wordRegister
    generic map (
      width          => 16)
    port map (
      ClockxCI       => IfClockxC, -- Check which clock I need to use? What was IfClock again?
      ResetxRBI      => ResetxRB,
      WriteEnablexEI => IMUregWritexE,
      DataInxDI      => IMUregInxD,
      DataOutxDO     => IMUregOutxD);

  IMUregInxD <= IMUdataxD;
  --H
  
  uEarlyPaketTimer : earlyPaketTimer
    port map (
      ClockxCI        => ClockxC,
      ResetxRBI       => ResetxRB,
      ClearxSI        => ResetEarlyPaketTimerxS,
      TimerExpiredxSO => EarlyPaketTimerOverflowxS);

  uEventCounter : eventCounter
    port map (
      ClockxCI     => ClockxC,
      ResetxRBI    => ResetxRB,
      ClearxSI     => ResetEventCounterxS,
      IncrementxSI => IncEventCounterxS,
      OverflowxSO  => ECResetEarlyPaketTimerxS);

  uTimestampCounter : timestampCounter
    port map (
      ClockxCI      => ClockxC,
      ResetxRBI     => CounterResetxRB,
      IncrementxSI  => IncxS,
      OverflowxSO   => TimestampOverflowxS,
      DataxDO       => ActualTimestampxD);

  uSynchronizerStateMachine_1: synchronizerStateMachine
    port map (
      ClockxCI              => ClockxC,
      ResetxRBI             => ResetxRB,
      RunxSI                => RunxS,
      ConfigxSI             => TimestampMasterxS,
      SyncInCLKxABI            => SyncIn1xAB,
      SyncOutCLKxCBO           => SyncOut1xSB,
      TriggerxSO            => TriggerxS,
      HostResetTimestampxSI => HostResetTimestampxS,
      ResetTimestampxSBO    => SynchronizerResetTimestampxSB,
      IncrementCounterxSO   => IncxS);

   TimestampMasterxS <= PA1xSIO;
     
  fifoStatemachine_1: fifoStatemachine
    port map (
      ClockxCI                   => IfClockxC,
      ResetxRBI                  => ResetxRB,
	  RunxSI					 => RunxS,
      FifoTransactionxSO         => FifoTransactionxS,
      FX2FifoInFullxSBI          => FX2FifoInFullxSBI,
      FifoEmptyxSI               => FifoEmptyxS,
      FifoReadxEO                => FifoReadxE,
      FX2FifoWritexEBO           => FX2FifoWritexEB,
      FX2FifoPktEndxSBO          => FX2FifoPktEndxSB,
      FX2FifoAddressxDO          => FX2FifoAddressxDO,
      IncEventCounterxSO         => IncEventCounterxS,
      ResetEventCounterxSO       => ResetEventCounterxS,
      ResetEarlyPaketTimerxSO    => SMResetEarlyPaketTimerxS,
      EarlyPaketTimerOverflowxSI => EarlyPaketTimerOverflowxS);

  monitorStateMachine_1: monitorStateMachine
    port map (
      ClockxCI                  => ClockxC,
      ResetxRBI                 => ResetxRB,
      AERREQxSBI                => AERREQxSB,
      AERACKxSBO                => AERMonitorACKxSB,
      XxDI                      => AERMonitorAddressxDI(9),
      UseLongAckxSI             => UseLongAckxS,
      FifoFullxSI               => FifoFullxS,
      FifoWritexEO              => FifoWritexE,
      TimestampRegWritexEO      => TimestampRegWritexE,
      AddressRegWritexEO => AddressRegWritexE,
      
	  --H Change variable name and size
	  --AddressTimestampSelectxSO => AddressTimestampSelectxS,
	  DatatypeSelectxSO         ==> DatatypeSelectxSO,
	  --H 
	  
	  ADCvalueReadyxSI => ADCvalueReadyxS,
      ReadADCvaluexEO => ReadADCvaluexE,
      TimestampOverflowxSI      => TimestampOverflowxS,
      TriggerxSI => TriggerxS,
      AddressMSBxDO             => AddressMSBxD,
      ResetTimestampxSBI        => SynchronizerResetTimestampxSB);
  
  ADCStateMachine_1: ADCStateMachine
    port map (
      ClockxCI              => IfClockxC,
      ADCclockxCO           => ADCclockxC,
      ResetxRBI             => ADCsmRstxE,
      ADCwordxDI           	=> ADCwordxDI,
      ADCoutxDO             => ADCdataxD,
      ADCoexEBO          	=> ADCoexEB,
      ADCstbyxEO           	=> ADCstbyxE,
	  ADCovrxSI				=> ADCovrxS,
      RegisterWritexEO      => ADCregWritexE,
      SRLatchxEI            => SRLatchxE,
      RunADCxSI             => RunADCxS,
	  ExposurexDI          => ExposurexD,
	  ColSettlexDI          => ColSettlexD,
	  RowSettlexDI          => RowSettlexD,
	  ResSettlexDI          => ResSettlexD,
	  FramePeriodxDI		=> FramePeriodxD,
	  ExtTriggerxEI			=> ExtTriggerxE,
	  CDVSTestSRRowInxSO    => CDVSTestSRRowInxS,
      CDVSTestSRRowClockxSO => CDVSTestSRRowClockxS,
      CDVSTestSRColInxSO    => CDVSTestSRColInxS,
      CDVSTestSRColClockxSO => CDVSTestSRColClockxS,
	  CDVSTestColMode0xSO   => CDVSTestColMode0xS,
	  CDVSTestColMode1xSO   => CDVSTestColMode1xS,
	  CDVSTestApsTxGatexSO   => CDVSTestApsTxGatexS,
	  ADCStateOutputLEDxSO  => ADCStateOutputLEDxS
	  );
  
  ADCovrxS	<= ADCovrxSI;
  ADCsmRstxE <= ResetxRB and RunxS;

  ADCvalueReady_1: ADCvalueReady
    port map (
      ClockxCI         => ClockxC,
      ResetxRBI        => ResetxRB,
      RegisterWritexEI => ADCregWritexE,
      ReadValuexEI     => ReadADCvaluexE,
      ValueReadyxSO    => ADCvalueReadyxS);

  --H Instantiations of IMU Modules
  IMUStateMachine_1: IMUStateMachine
    port map (
	--H Fill in later
  );
  
  --H Control signals?
  
  --H Instantiations of IMU Modules
  IMUvalueReady_1: IMUvalueReady
    port map (
      ClockxCI         => ClockxC,
      ResetxRBI        => ResetxRB,
      RegisterWritexEI => IMUregWritexE,
      ReadValuexEI     => ReadIMUvaluexE,
      ValueReadyxSO    => IMUvalueReadyxS);
  --H 
	  
  cDVSResetStateMachine_1: cDVSResetStateMachine
    port map (
      ClockxCI      => ClockxC,
      ResetxRBI     => ResetxRB,
      AERackxSBI    => AERREQxSB,
      RxcolGxSI => RxcolGxS,
      cDVSresetxRBI => PE3xSI,
      CDVSresetxRBO => CDVSTestPeriodicChipResetxRB);
  
  SyncOutCLKxCBO <= SyncOut1xSB;
  FX2FifoPktEndxSBO <= FX2FifoPktEndxSB;
  FX2FifoWritexEBO <= FX2FifoWritexEB;
  AERMonitorACKxSBO <= AERMonitorACKxSB;

  -- reset early paket timer whenever a paket is sent (short or normal)
  ResetEarlyPaketTimerxS <= (SMResetEarlyPaketTimerxS or ECResetEarlyPaketTimerxS);

  -- mux to select how to drive dataline 8
  
  with AddressRegOutxD(9) select
    AddressRegOut8xD <=
	'0' when '0',
	AddressRegOutxD(8) when '1',
	'0' when others;
	
  --H Sets trigger event type to be written to fifo
  with IMUEventxSI select
    externaleventtype <= 
		externaleventIMU when '1',
		externaleventOthers when others;
  --H
	

  -- mux to select how to drive datalines
  with AddressTimestampSelectxS select
    FifoDataInxD <=
    AddressMSBxD & "00" & AddressRegOutxD(9) & "00" & AddressRegOut8xD & AddressRegOutxD(7 downto 0) when selectaddress, -- hack to put the xbit at bit position 11 (which allows addresses up to 10 bits)
    AddressMSBxD & MonitorTimestampxD when selecttimestamp,
    AddressMSBxD & externaleventtype when selecttrigger, --H used to write IMU event indicator                                     
	AddressMSBxD & ADCregOutxD when selectADC;
	IMUregOutxD when selectIMU; --H writes IMU measurements

  LED1xSO <= CDVSTestChipResetxRB;
  LED2xSO <= RunxS;
  LED3xSO <= ADCStateOutputLEDxS;
  --LED3xSO <= ExtTriggerxE;

  CDVSTestChipResetxRBO <= CDVSTestChipResetxRB;
  CDVSTestChipResetxRB <= PE3xSI;
  
  --CDVSTestChipResetxRBO <= PE3xSI;
  --CDVSTestChipResetxRBO <= CDVSTestChipResetxRB;

  CDVSTestBiasEnablexEO <= not PE2xSI;

  HostResetTimestampxS <= PA7xSIO;
  RunxS <= PA3xSIO;
  ExtTriggerxE <= '0';

  RunADCxS <= PC0xSIO;
  SRClockxC <= PC1xSIO;
  SRLatchxE <= PC2xSIO;
  SRinxD <= PC3xSIO;

  CDVSTestSRColClockxSO <= CDVSTestSRColClockxS;
  CDVSTestSRRowClockxSO <= CDVSTestSRRowClockxS;
  CDVSTestSRColInxSO <= CDVSTestSRColInxS;
  CDVSTestSRRowInxSO <= CDVSTestSRRowInxS;

  CDVSTestColMode0xSO <= CDVSTestColMode0xS;
  CDVSTestColMode1xSO <= CDVSTestColMode1xS;

  CDVSTestApsTxGatexSO <= CDVSTestApsTxGatexS;

  ADCstbyxEO <= ADCstbyxE;
  ADCoexEBO <= ADCoexEB;

  
  RxcolGxS <= '0';
  UseLongAckxS <= '0';

--  DebugxSIO(13) <= '0';
--  UseLongAckxS <= DebugxSIO(14);  
--  DebugxSIO(15) <= '1';
  
  DebugxSIO(0) <= ADCStateOutputLEDxS;
  
    -- purpose: synchronize asynchronous inputs
  -- type   : sequential
  -- inputs : ClockxCI
  -- outputs: 
  synchronizer : process (ClockxC)
  begin
    if ClockxC'event and ClockxC = '1' then 
      AERREQxSB         <= AERReqSyncxSBN;
      AERReqSyncxSBN <= AERMonitorREQxABI;
    end if;
  end process synchronizer;
end Structural;


