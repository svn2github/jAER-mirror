--------------------------------------------------------------------------------
-- Company: ini
-- Engineer: Raphael Berner
--
-- Create Date:	   11:54:08 10/24/05
-- Design Name:
-- Module Name:	   USBAER_top_level - Structural
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
		FX2FifoDataxDIO	  : out std_logic_vector(7 downto 0);
		FX2FifoInFullxSBI : in	std_logic;
		FX2FifoWritexEBO  : out std_logic;
		FX2FifoReadxEBO	  : out std_logic;

		FX2FifoPktEndxSBO : out std_logic;
		FX2FifoAddressxDO : out std_logic_vector(1 downto 0);

		-- clock and reset inputs
		-- ClockxCI	 : in std_logic;
		--IfClockxCO : out std_logic;
		IfClockxCI : in std_logic;
		ResetxRBI  : in std_logic;

		-- ports to synchronize other USBAER boards
		SyncInxAI	: in  std_logic;	-- needs synchronization
		SynchOutxSO : out std_logic;

		-- communication with 8051
		PC0xSIO : inout std_logic;
		PC1xSIO : inout std_logic;
		PC2xSIO : inout std_logic;
		PC3xSIO : inout std_logic;

		PDxSIO : inout std_logic_vector(7 downto 0);

		PA0xSIO : inout std_logic;
		PA1xSIO : inout std_logic;
		PA3xSIO : inout std_logic;
		PA7xSIO : inout std_logic;

		PE2xSI : in std_logic;
		PE3xSI : in std_logic;

		FXLEDxSI : in std_logic;

		-- ADC
		ADCclockxCO : out	std_logic;
		ADCwordxDIO : inout std_logic_vector(11 downto 0);

		ADCwritexEBO  : out std_logic;
		ADCreadxEBO	  : out std_logic;
		ADCconvstxEBO : out std_logic;
		ADCbusyxSI	  : in	std_logic;

		-- scanner
		ScanClockxSO  : out std_logic;
		SyncbxSI	  : in	std_logic;
		SyncbpfoutxSI : in	std_logic;

		-- chip control
		PowerdownxEO	 : out std_logic;
		CochleaResetxRBO : out std_logic;

		DataSelxSO	  : out std_logic;
		AddSelxSO	  : out std_logic;
		BiasgenSelxSO : out std_logic;
		YbitxSO		  : out std_logic;

		AERkillBitxSO	: out std_logic;
		VctrlKillBitxSO : out std_logic;
		SelAERxSO		: out std_logic;
		SelInxSO		: out std_logic;

		--DAC
		DACbitInxSO	 : out std_logic;
		DACClkxSO	 : out std_logic;
		DACnSyncxSBO : out std_logic;

		--preamp control
		PreampARxSO	   : out std_logic;
		PreampGainRxSO : out std_logic;
		PreampGainLxSO : out std_logic;
		ResCtrlBit1xSO : out std_logic;
		ResCtrlBit2xSO : out std_logic;

		-- control LED
		LED1xSO : out std_logic;
		LED2xSO : out std_logic;
		LED3xSO : out std_logic;

		DebugxSIO : inout std_logic_vector(7 downto 0);

		-- AER monitor interface
		AERMonitorREQxABI	 : in  std_logic;  -- needs synchronization
		AERMonitorACKxSBO	 : out std_logic;
		AERMonitorAddressxDI : in  std_logic_vector(9 downto 0));

end USBAER_top_level;

architecture Structural of USBAER_top_level is

	component fifoStatemachine
		port (
			ClockxCI				   : in	 std_logic;
			ResetxRBI				   : in	 std_logic;
			FifoTransactionxSO		   : out std_logic;
			FX2FifoInFullxSBI		   : in	 std_logic;
			FifoEmptyxSI			   : in	 std_logic;
			FifoReadxEO				   : out std_logic;
			FX2FifoWritexEBO		   : out std_logic;
			FX2FifoPktEndxSBO		   : out std_logic;
			FX2FifoAddressxDO		   : out std_logic_vector(1 downto 0);
			IncEventCounterxSO		   : out std_logic;
			ResetEventCounterxSO	   : out std_logic;
			ResetEarlyPaketTimerxSO	   : out std_logic;
			EarlyPaketTimerOverflowxSI : in	 std_logic);
	end component;

	component shiftRegister
		generic (
			width : natural);
		port (
			ClockxCI   : in	 std_logic;
			ResetxRBI  : in	 std_logic;
			LatchxEI   : in	 std_logic;
			DxDI	   : in	 std_logic;
			QxDO	   : out std_logic;
			DataOutxDO : out std_logic_vector((width-1) downto 0));
	end component;

	component clockgen
		port (
			CLK	  : in	std_logic;
			RESET : in	std_logic;
			CLKOP : out std_logic;
			LOCK  : out std_logic);
	end component;

  component synchronizerStateMachine
    port (
      ClockxCI              : in  std_logic;
      ResetxRBI             : in  std_logic;
      RunxSI                : in  std_logic;
      HostResetTimestampxSI : in  std_logic;
      SyncInxABI            : in  std_logic;
      SyncOutxSBO           : out std_logic;
      ConfigxSI 			: in std_logic;
      --TriggerxSO            : out std_logic;
      ResetTimestampxSBO    : out std_logic;
      IncrementCounterxSO   : out std_logic);
	end component;
  
	component monitorStateMachine
		port (
			ClockxCI				  : in	std_logic;
			ResetxRBI				  : in	std_logic;
			AERREQxSBI				  : in	std_logic;
			AERACKxSBO				  : out std_logic;
			UseLongAckxSI			  : in	std_logic;
			FifoFullxSI				  : in	std_logic;
			FifoWritexEO			  : out std_logic;
			TimestampRegWritexEO	  : out std_logic;
			AddressTimestampSelectxSO : out std_logic_vector(1 downto 0);
			ADCvalueReadyxSI		  : in	std_logic;
			ReadADCvaluexEO			  : out std_logic;
			TimestampOverflowxSI	  : in	std_logic;
			AddressMSBxDO			  : out std_logic_vector(1 downto 0);
			ResetTimestampxSBI		  : in	std_logic
			);
	end component;

	component ADCStateMachine
		port (
			ClockxCI		 : in	 std_logic;
			ADCclockxCO		 : out	 std_logic;
			ResetxRBI		 : in	 std_logic;
			ADCwordxDIO		 : inout std_logic_vector(11 downto 0);
			ADCoutxDO		 : out	 std_logic_vector(13 downto 0);
			ADCwritexEBO	 : out	 std_logic;
			ADCreadxEBO		 : out	 std_logic;
			ADCconvstxEBO	 : out	 std_logic;
			ADCbusyxSI		 : in	 std_logic;
			RegisterWritexEO : out	 std_logic;
			SRLatchxEI		 : in	 std_logic;
			RunADCxSI		 : in	 std_logic;
			ScanEnablexSI	 : in	 std_logic;
			ScanXxSI		 : in	 std_logic_vector(6 downto 0);
			ADCconfigxDI	 : in	 std_logic_vector(11 downto 0);
			TrackTimexDI	 : in	 std_logic_vector(15 downto 0);
			IdleTimexDI		 : in	 std_logic_vector(15 downto 0);
			ScanClockxSO	 : out	 std_logic;
			ScanSyncxSI		 : in	 std_logic);
	end component;

	component ADCvalueReady
		port (
			ClockxCI		 : in  std_logic;
			ResetxRBI		 : in  std_logic;
			RegisterWritexEI : in  std_logic;
			ReadValuexEI	 : in  std_logic;
			ValueReadyxSO	 : out std_logic);
	end component;

	component wordRegister
		generic (
			width : natural := 14);
		port (
			ClockxCI	   : in	 std_logic;
			ResetxRBI	   : in	 std_logic;
			WriteEnablexEI : in	 std_logic;
			DataInxDI	   : in	 std_logic_vector(width-1 downto 0);
			DataOutxDO	   : out std_logic_vector(width-1 downto 0));
	end component;

	component eventCounter
		port (
			ClockxCI	 : in  std_logic;
			ResetxRBI	 : in  std_logic;
			ClearxSI	 : in  std_logic;
			IncrementxSI : in  std_logic;
			OverflowxSO	 : out std_logic);
	end component;

	component timestampCounter
		port (
			ClockxCI	 : in  std_logic;
			ResetxRBI	 : in  std_logic;
			IncrementxSI : in  std_logic;
			OverflowxSO	 : out std_logic;
			DataxDO		 : out std_logic_vector(13 downto 0));
	end component;

	component earlyPaketTimer
		port (
			ClockxCI		: in  std_logic;
			ResetxRBI		: in  std_logic;
			ClearxSI		: in  std_logic;
			TimerExpiredxSO : out std_logic);
	end component;

	component AER2FIFO is
		port (
			Data		: in  std_logic_vector(15 downto 0);
			WrClock		: in  std_logic;
			RdClock		: in  std_logic;
			WrEn		: in  std_logic;
			RdEn		: in  std_logic;
			Reset		: in  std_logic;
			RPReset		: in  std_logic;
			Q			: out std_logic_vector(7 downto 0);
			Empty		: out std_logic;
			Full		: out std_logic;
			AlmostEmpty : out std_logic;
			AlmostFull	: out std_logic);
	end component AER2FIFO;

	-- signal declarations
	signal MonitorTimestampxD : std_logic_vector(13 downto 0);
	signal ActualTimestampxD  : std_logic_vector(13 downto 0);

	-- register write enables
	signal TimestampRegWritexE : std_logic;

	signal SyncInxA : std_logic;

	signal AERREQxSB, AERReqSyncxSBN : std_logic;

	signal AERMonitorACKxSB : std_logic;
	signal UseLongAckxS		: std_logic;

	-- mux control signals
	signal AddressTimestampSelectxS : std_logic_vector(1 downto 0);

	-- communication between state machines
--	signal SetMonitorEventReadyxS	 : std_logic;
--	signal ClearMonitorEventxS		 : std_logic;
--	signal MonitorEventReadyxS		 : std_logic;
	signal IncEventCounterxS		 : std_logic;
	signal ResetEventCounterxS		 : std_logic;
	signal ResetEarlyPaketTimerxS	 : std_logic;
	signal EarlyPaketTimerOverflowxS : std_logic;
	signal SMResetEarlyPaketTimerxS	 : std_logic;
	signal ECResetEarlyPaketTimerxS	 : std_logic;

	-- clock, reset
	signal ClockxC, IfClockxC			 : std_logic;
	signal ResetxRB, ResetxR			 : std_logic;
	signal RunxS						 : std_logic;
	signal CounterResetxRB				 : std_logic;
	signal SynchronizerResetTimestampxSB : std_logic;

	-- signals regarding the timestamp
	signal TimestampOverflowxS : std_logic;
	signal AddressMSBxD		   : std_logic_vector(1 downto 0);
	signal TimestampMasterxS   : std_logic;

	-- various
	signal FifoTransactionxS	: std_logic;
	signal FX2FifoWritexEB		: std_logic;
	signal FX2FifoPktEndxSB		: std_logic;
	signal SynchOutxS			: std_logic;
	signal HostResetTimestampxS : std_logic;

	-- counter increment signal
	signal IncxS : std_logic;

	-- ADC related signals
	signal ReadADCvaluexE, ADCvalueReadyxS : std_logic;
	signal ADCregInxD					   : std_logic_vector(13 downto 0);
	signal ADCregOutxD					   : std_logic_vector(13 downto 0);
	signal ADCregWritexE				   : std_logic;
	signal ADCdataxD					   : std_logic_vector(13 downto 0);

	signal ADCclockxC	: std_logic;
	signal ADCwritexEB	: std_logic;
	signal ADCreadxEB	: std_logic;
	signal ADCconvstxEB : std_logic;
	signal ADCbusyxS	: std_logic;

	signal SRDataOutxD							 : std_logic_vector(63 downto 0);
	signal IdleTimexD, TrackTimexD				 : std_logic_vector(15 downto 0);  -- ca 3ms (adc state
										-- machine is clocked
										-- at 15MHz)
	signal ADCconfigxD							 : std_logic_vector(11 downto 0);
	signal SRoutxD, SRinxD, SRLatchxE, SRClockxC : std_logic;
	signal RunADCxS								 : std_logic;


	signal ScanEnablexS : std_logic;  -- whether scanner should run continously or we take ADC values from a single pixel
	signal ScanXxS		: std_logic_vector(6 downto 0);	 -- 128 channels
	signal ScanSelectxS : std_logic;	-- selects which sync signal the adc
										-- state machine should look at
	signal ScanSyncxS	: std_logic;
	signal ScanClockxS	: std_logic;

	-- control signals for external preamp gain
	signal PreampARxS, PreampARTristateEnablexE						: std_logic;
	signal PreampGainRxS, PreampGainLxS								: std_logic;
	signal PreampGainRTristateEnablexE, PreampGainLTristateEnablexE : std_logic;

	-- lock signal from PLL, unused so far
	signal LockxS : std_logic;

	-- fifo signals
	signal FifoDataInxD													: std_logic_vector(15 downto 0);
	signal FifoDataOutxD												: std_logic_vector(7 downto 0);
	signal FifoWritexE, FifoReadxE										: std_logic;
	signal FifoEmptyxS, FifoAlmostEmptyxS, FifoFullxS, FifoAlmostFullxS : std_logic;

	-- constants used for mux
	constant selectADC		 : std_logic_vector(1 downto 0) := "11";
	constant selectaddress	 : std_logic_vector(1 downto 0) := "01";
	constant selecttimestamp : std_logic_vector(1 downto 0) := "00";

begin
	IfClockxC	<= IfClockxCI;
	ADCclockxCO <= ADCclockxC;

	DACnSyncxSBO	<= PDxSIO(0);
	DACClkxSO		<= PDxSIO(1);
	DACbitInxSO		<= PDxSIO(2);
	DataSelxSO		<= PDxSIO(3);
	AddSelxSO		<= PDxSIO(4);
	BiasgenSelxSO	<= PDxSIO(5);
	VctrlKillBitxSO <= PDxSIO(6);
	AERkillBitxSO	<= PDxSIO(7);

	PowerdownxEO	 <= PE2xSI;
	CochleaResetxRBO <= PE3xSI;

--	  CDVSTestChipResetxRB;
--	with UseCDVSperiodicResetxS select
--	  CDVSTestChipResetxRB <=
--	  PE3xSI when '0',
--	  CDVSTestPeriodicChipResetxRB when others;


	HostResetTimestampxS <= PA7xSIO;
	--H RunxS				 <= PA3xSIO or not TimestampMasterxS;
	RunxS				 <= PA3xSIO;
	--H PA1xSIO				 <= TimestampMasterxS;
	TimestampMasterxS 	<= PA1xSIO;
	
	RunADCxS  <= PC0xSIO;
	SRClockxC <= PC1xSIO;
	SRLatchxE <= PC2xSIO;
	SRinxD	  <= PC3xSIO;

	uClockGen : clockgen
		port map (
			CLK	  => IFClockxCI,
			RESET => ResetxR,
			CLKOP => ClockxC,
			LOCK  => LockxS);

	--ClockxC <= IFClockxCI;

	-- run the state machines either when reset is high or when in slave mode
	ResetxRB		<= ResetxRBI;
	ResetxR			<= not ResetxRBI;
	CounterResetxRB <= SynchronizerResetTimestampxSB;

	FX2FifoReadxEBO <= '1';

	--H SyncInxA <= not SyncInxAI;
	SyncInxA <= SyncInxAI;

	shiftRegister_1 : shiftRegister
		generic map (
			width => 64)
		port map (
			ClockxCI   => SRClockxC,
			ResetxRBI  => ResetxRB,
			LatchxEI   => SRLatchxE,
			DxDI	   => SRinxD,
			QxDO	   => SRoutxD,
			DataOutxDO => SRDataOutxD);

	YbitxSO						<= SRDataOutxD(0);
	ResCtrlBit1xSO				<= SRDataOutxD(1);
	ResCtrlBit2xSO				<= SRDataOutxD(2);
	SelAERxSO					<= SRDataOutxD(3);
	SelInxSO					<= SRDataOutxD(4);
	PreampARxS					<= SRDataOutxD(5);
	PreampARTristateEnablexE	<= SRDataOutxD(6);
	PreampGainLxS				<= SRDataOutxD(7);
	PreampGainLTristateEnablexE <= SRDataOutxD(8);
	PreampGainRxS				<= SRDataOutxD(9);
	PreampGainRTristateEnablexE <= SRDataOutxD(10);
	ADCconfigxD					<= SRDataOutxD(22 downto 11);
	TrackTimexD					<= SRDataOutxD(38 downto 23);
	IdleTimexD					<= SRDataOutxD(54 downto 39);
	ScanXxS						<= SRDataOutxD(61 downto 55);
	ScanSelectxS				<= SRDataOutxD(62);
	ScanEnablexS				<= SRDataOutxD(63);

	with ScanSelectxS select
		ScanSyncxS <=
		SyncbpfoutxSI when '1',
		SyncbxSI	  when others;

	ScanClockxSO <= ScanClockxS;

	with PreampARTristateEnablexE select
		PreampARxSO <=
		PreampARxS when '0',
		'Z'		   when others;

	with PreampGainRTristateEnablexE select
		PreampGainRxSO <=
		PreampGainRxS when '0',
		'Z'			  when others;

	with PreampGainLTristateEnablexE select
		PreampGainLxSO <=
		PreampGainLxS when '0',
		'Z'			  when others;

	uFifo : AER2FIFO
		port map (
			Data		=> FifoDataInxD,
			WrClock		=> ClockxC,
			RdClock		=> IfClockxC,
			WrEn		=> FifoWritexE,
			RdEn		=> FifoReadxE,
			Reset		=> ResetxR,
			RPReset		=> ResetxR,
			Q			=> FifoDataOutxD,
			Empty		=> FifoEmptyxS,
			Full		=> FifoFullxS,
			AlmostEmpty => FifoAlmostEmptyxS,
			AlmostFull	=> FifoAlmostFullxS);

	FX2FifoDataxDIO <= FifoDataOutxD;

	uMonitorTimestampRegister : wordRegister
		generic map (
			width => 14)
		port map (
			ClockxCI	   => ClockxC,
			ResetxRBI	   => ResetxRB,
			WriteEnablexEI => TimestampRegWritexE,
			DataInxDI	   => ActualTimestampxD,
			DataOutxDO	   => MonitorTimestampxD);

	uADCRegister : wordRegister
		generic map (
			width => 14)
		port map (
			ClockxCI	   => IfClockxC,
			ResetxRBI	   => ResetxRB,
			WriteEnablexEI => ADCregWritexE,
			DataInxDI	   => ADCregInxD,
			DataOutxDO	   => ADCregOutxD);

	ADCregInxD <= ADCdataxD;

	uEarlyPaketTimer : earlyPaketTimer
		port map (
			ClockxCI		=> ClockxC,
			ResetxRBI		=> ResetxRB,
			ClearxSI		=> ResetEarlyPaketTimerxS,
			TimerExpiredxSO => EarlyPaketTimerOverflowxS);

	uEventCounter : eventCounter
		port map (
			ClockxCI	 => ClockxC,
			ResetxRBI	 => ResetxRB,
			ClearxSI	 => ResetEventCounterxS,
			IncrementxSI => IncEventCounterxS,
			OverflowxSO	 => ECResetEarlyPaketTimerxS);

	uTimestampCounter : timestampCounter
		port map (
			ClockxCI	 => ClockxC,
			ResetxRBI	 => CounterResetxRB,
			IncrementxSI => IncxS,
			OverflowxSO	 => TimestampOverflowxS,
			DataxDO		 => ActualTimestampxD);

  uSyncStateMachine : synchronizerStateMachine
    port map (
      ClockxCI              => ClockxC,
      ResetxRBI             => ResetxRB,
      RunxSI                => RunxS,
      HostResetTimestampxSI => HostResetTimestampxS,
      SyncInxABI            =>  SyncInxA, 
      SyncOutxSBO            => SynchOutxS, 
	  ConfigxSI				=> TimestampMasterxS,
	  ResetTimestampxSBO    => SynchronizerResetTimestampxSB,
      IncrementCounterxSO   => IncxS);

	fifoStatemachine_1 : fifoStatemachine
		port map (
			ClockxCI				   => IfClockxC,
			ResetxRBI				   => ResetxRB,
			FifoTransactionxSO		   => FifoTransactionxS,
			FX2FifoInFullxSBI		   => FX2FifoInFullxSBI,
			FifoEmptyxSI			   => FifoEmptyxS,
			FifoReadxEO				   => FifoReadxE,
			FX2FifoWritexEBO		   => FX2FifoWritexEB,
			FX2FifoPktEndxSBO		   => FX2FifoPktEndxSB,
			FX2FifoAddressxDO		   => FX2FifoAddressxDO,
			IncEventCounterxSO		   => IncEventCounterxS,
			ResetEventCounterxSO	   => ResetEventCounterxS,
			ResetEarlyPaketTimerxSO	   => SMResetEarlyPaketTimerxS,
			EarlyPaketTimerOverflowxSI => EarlyPaketTimerOverflowxS);

	monitorStateMachine_1 : monitorStateMachine
		port map (
			ClockxCI				  => ClockxC,
			ResetxRBI				  => ResetxRB,
			AERREQxSBI				  => AERREQxSB,
			AERACKxSBO				  => AERMonitorACKxSB,
			UseLongAckxSI			  => UseLongAckxS,
			FifoFullxSI				  => FifoFullxS,
			FifoWritexEO			  => FifoWritexE,
			TimestampRegWritexEO	  => TimestampRegWritexE,
			AddressTimestampSelectxSO => AddressTimestampSelectxS,
			ADCvalueReadyxSI		  => ADCvalueReadyxS,
			ReadADCvaluexEO			  => ReadADCvaluexE,
			TimestampOverflowxSI	  => TimestampOverflowxS,
			AddressMSBxDO			  => AddressMSBxD,
			ResetTimestampxSBI		  => SynchronizerResetTimestampxSB);

	ADCStateMachine_1 : ADCStateMachine
		port map (
			ClockxCI		 => IfClockxC,
			ADCclockxCO		 => ADCclockxC,
			ResetxRBI		 => ResetxRB,
			ADCwordxDIO		 => ADCwordxDIO,
			ADCoutxDO		 => ADCdataxD,
			ADCwritexEBO	 => ADCwritexEB,
			ADCreadxEBO		 => ADCreadxEB,
			ADCconvstxEBO	 => ADCconvstxEB,
			ADCbusyxSI		 => ADCbusyxS,
			RegisterWritexEO => ADCregWritexE,
			SRLatchxEI		 => SRLatchxE,
			RunADCxSI		 => RunADCxS,
			ScanEnablexSI	 => ScanEnablexS,
			ScanXxSI		 => ScanXxS,
			ADCconfigxDI	 => ADCconfigxD,
			TrackTimexDI	 => TrackTimexD,
			IdleTimexDI		 => IdleTimexD,
			ScanClockxSO	 => ScanClockxS,
			ScanSyncxSI		 => ScanSyncxS);


	ADCbusyxS <= ADCbusyxSI;

	ADCvalueReady_1 : ADCvalueReady
		port map (
			ClockxCI		 => ClockxC,
			ResetxRBI		 => ResetxRB,
			RegisterWritexEI => ADCregWritexE,
			ReadValuexEI	 => ReadADCvaluexE,
			ValueReadyxSO	 => ADCvalueReadyxS);


	SynchOutxSO		  <= SynchOutxS;
	FX2FifoPktEndxSBO <= FX2FifoPktEndxSB;
	FX2FifoWritexEBO  <= FX2FifoWritexEB;
	AERMonitorACKxSBO <= AERMonitorACKxSB;

	-- reset early paket timer whenever a paket is sent (short or normal)
	ResetEarlyPaketTimerxS <= (SMResetEarlyPaketTimerxS or ECResetEarlyPaketTimerxS);

	-- mux to select how to drive datalines
	with AddressTimestampSelectxS select
		FifoDataInxD <=
		AddressMSBxD & "0000" & AERMonitorAddressxDI when selectaddress,
		AddressMSBxD & MonitorTimestampxD			 when selecttimestamp,
		AddressMSBxD & ADCregOutxD					 when others;

	LED1xSO <= ScanSelectxS;
	LED2xSO <= RunxS;
	LED3xSO <= FXLEDxSI;


	ADCconvstxEBO <= ADCconvstxEB;
	ADCreadxEBO	  <= ADCreadxEB;
	ADCwritexEBO  <= ADCwritexEB;



	--DebugxSIO(3) <= ADCconvstxEB;
	DebugxSIO(0)		  <= ScanEnablexS;
	DebugxSIO(1)		  <= ScanSyncxS;
	DebugxSIO(7 downto 2) <= ScanXxS(5 downto 0);
	--DebugxSIO(2) <= '1';
	-- DebugxSIO(4) <= ADCbusyxS;
--	DebugxSIO(7 downto 0) <= ActualTimestampxD(7 downto 0);
--	DebugxSIO(7) <= FX2FifoWritexEB;
--	DebugxSIO(6) <= FX2FifoPktEndxSB;
	-- DebugxSIO(5) <= SRLatchxE;
	UseLongAckxS		  <= '0';

	-- DebugxSIO(7) <= UseCalibrationxS;
	-- DebugxSIO(6) <= ;
	-- DebugxSIO(4) <= AERMonitorAddressxDI(8);

	-- purpose: synchronize asynchronous inputs
	-- type	  : sequential
	-- inputs : ClockxCI
	-- outputs:
	synchronizer : process (ClockxC)
	begin
		if ClockxC'event and ClockxC = '1' then
			AERREQxSB	   <= AERReqSyncxSBN;
			AERReqSyncxSBN <= AERMonitorREQxABI;
		end if;
	end process synchronizer;
end Structural;
