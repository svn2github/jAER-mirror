library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.Settings.all;
use work.FIFORecords.all;
use work.MultiplexerConfigRecords.all;
use work.DVSAERConfigRecords.all;
use work.APSADCConfigRecords.all;
use work.IMUConfigRecords.all;
use work.ExtTriggerConfigRecords.all;
use work.FX3ConfigRecords.all;

entity TopLevel is
	port(
		USBClock_CI             : in    std_logic;
		Reset_RI                : in    std_logic;

		SPIAlternativeSelect_SI : in    std_logic;
		SPISlaveSelect_ABI      : in    std_logic;
		SPIClock_AI             : in    std_logic;
		SPIMOSI_AI              : in    std_logic;
		SPIMISO_DZO             : out   std_logic;
		BiasDiagSelect_SI       : in    std_logic;

		USBFifoData_DO          : out   std_logic_vector(USB_FIFO_WIDTH - 1 downto 0);
		USBFifoChipSelect_SBO   : out   std_logic;
		USBFifoWrite_SBO        : out   std_logic;
		USBFifoRead_SBO         : out   std_logic;
		USBFifoPktEnd_SBO       : out   std_logic;
		USBFifoAddress_DO       : out   std_logic_vector(1 downto 0);
		USBFifoThr0Ready_SI     : in    std_logic;
		USBFifoThr0Watermark_SI : in    std_logic;
		USBFifoThr1Ready_SI     : in    std_logic;
		USBFifoThr1Watermark_SI : in    std_logic;

		LED1_SO                 : out   std_logic;
		LED2_SO                 : out   std_logic;
		LED3_SO                 : out   std_logic;
		LED4_SO                 : out   std_logic;

		Debug_SO                : out   std_logic_vector(8 downto 0);

		ChipBiasEnable_SO       : out   std_logic;
		ChipBiasDiagSelect_SO   : out   std_logic;
		--ChipBiasBitOut_DI : in std_logic;

		DVSAERData_AI           : in    std_logic_vector(AER_BUS_WIDTH - 1 downto 0);
		DVSAERReq_ABI           : in    std_logic;
		DVSAERAck_SBO           : out   std_logic;
		DVSAERReset_SBO         : out   std_logic;

		APSChipRowSRClock_SO    : out   std_logic;
		APSChipRowSRIn_SO       : out   std_logic;
		APSChipColSRClock_SO    : out   std_logic;
		APSChipColSRIn_SO       : out   std_logic;
		APSChipColMode_DO       : out   std_logic_vector(1 downto 0);
		APSChipTXGate_SBO       : out   std_logic;

		APSADCData_DI           : in    std_logic_vector(ADC_BUS_WIDTH - 1 downto 0);
		APSADCOverflow_SI       : in    std_logic;
		APSADCClock_CO          : out   std_logic;
		APSADCOutputEnable_SBO  : out   std_logic;
		APSADCStandby_SO        : out   std_logic;

		IMUClock_CZO            : out   std_logic;
		IMUData_DZIO            : inout std_logic;
		IMUInterrupt_AI         : in    std_logic;

		SyncOutClock_CO         : out   std_logic;
		SyncOutSwitch_AI        : in    std_logic;
		SyncOutSignal_SO        : out   std_logic;
		SyncInClock_AI          : in    std_logic;
		SyncInSwitch_AI         : in    std_logic;
		SyncInSignal_AI         : in    std_logic);
end TopLevel;

architecture Structural of TopLevel is
	signal USBReset_R   : std_logic;
	signal LogicClock_C : std_logic;
	signal LogicReset_R : std_logic;
	signal ADCClock_C   : std_logic;
	signal ADCReset_R   : std_logic;

	signal USBFifoThr0ReadySync_S, USBFifoThr0WatermarkSync_S, USBFifoThr1ReadySync_S, USBFifoThr1WatermarkSync_S : std_logic;
	signal DVSAERReqSync_SB, IMUInterruptSync_S                                                                   : std_logic;
	signal SyncOutSwitchSync_S, SyncInClockSync_C, SyncInSwitchSync_S, SyncInSignalSync_S                         : std_logic;
	signal SPISlaveSelectSync_SB, SPIClockSync_C, SPIMOSISync_D                                                   : std_logic;

	signal LogicUSBFifoControlIn_S  : tToFifo;
	signal LogicUSBFifoControlOut_S : tFromFifo;
	signal LogicUSBFifoDataIn_D     : std_logic_vector(USB_FIFO_WIDTH - 1 downto 0);
	signal LogicUSBFifoDataOut_D    : std_logic_vector(USB_FIFO_WIDTH - 1 downto 0);

	signal DVSAERFifoControlIn_S  : tToFifo;
	signal DVSAERFifoControlOut_S : tFromFifo;
	signal DVSAERFifoDataIn_D     : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal DVSAERFifoDataOut_D    : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	signal APSADCFifoControlIn_S  : tToFifo;
	signal APSADCFifoControlOut_S : tFromFifo;
	signal APSADCFifoDataIn_D     : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal APSADCFifoDataOut_D    : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	signal IMUFifoControlIn_S  : tToFifo;
	signal IMUFifoControlOut_S : tFromFifo;
	signal IMUFifoDataIn_D     : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal IMUFifoDataOut_D    : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	signal ExtTriggerFifoControlIn_S  : tToFifo;
	signal ExtTriggerFifoControlOut_S : tFromFifo;
	signal ExtTriggerFifoDataIn_D     : std_logic_vector(EVENT_WIDTH - 1 downto 0);
	signal ExtTriggerFifoDataOut_D    : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	signal ConfigModuleAddress_D : unsigned(6 downto 0);
	signal ConfigParamAddress_D  : unsigned(7 downto 0);
	signal ConfigParamInput_D    : std_logic_vector(31 downto 0);
	signal ConfigLatchInput_S    : std_logic;
	signal ConfigParamOutput_D   : std_logic_vector(31 downto 0);

	signal MultiplexerConfigParamOutput_D : std_logic_vector(31 downto 0);
	signal DVSAERConfigParamOutput_D      : std_logic_vector(31 downto 0);
	signal APSADCConfigParamOutput_D      : std_logic_vector(31 downto 0);
	signal IMUConfigParamOutput_D         : std_logic_vector(31 downto 0);
	signal ExtTriggerConfigParamOutput_D  : std_logic_vector(31 downto 0);

	signal MultiplexerConfig_D : tMultiplexerConfig;
	signal DVSAERConfig_D      : tDVSAERConfig;
	signal APSADCConfig_D      : tAPSADCConfig;
	signal IMUConfig_D         : tIMUConfig;
	signal ExtTriggerConfig_D  : tExtTriggerConfig;

	-- Alejandro testing WSAER2CAVIAR and CAVIAR2WSAER
	signal CAVIAR_data, CAVIARo_data, tCAVIARo_data                                                                                                       : std_logic_vector(16 downto 0);
	signal CAVIAR_req, CAVIAR_ack, CAVIAR_ack_aux, CAVIARo_req, CAVIARo_ack, tCAVIARo_req, tCAVIARo_ack, WSAER_req, WSAER_ack, tWSAER_req, tWSAER_ack, kk : std_logic;
	signal WSAER_data, tWSAER_data                                                                                                                        : std_logic_vector(9 downto 0);
	signal timertest                                                                                                                                      : std_logic_vector(15 downto 0);
	signal alex                                                                                                                                           : std_logic_vector(1 downto 0);
	signal spi_wr                                                                                                                                         : std_logic; --nss, sclk, mosi, miso,
	signal spi_data                                                                                                                                       : std_logic_vector(7 downto 0);
	signal spi_address                                                                                                                                    : std_logic_vector(7 downto 0);
	signal led                                                                                                                                            : std_logic_vector(2 downto 0);
	signal ot_active                                                                                                                                      : std_logic_vector(3 downto 0);
	signal WS2CAVIAR_en, BGAFen, AERMonitorACKxSB_kk, DAVIS_en                                                                                            : std_logic;
	signal testcnt                                                                                                                                        : unsigned(7 downto 0);
begin
	-- Alejandro.
	kk1 : process(LogicClock_C, LogicReset_R)
	begin
		if (LogicReset_R = '1') then
			testcnt <= (others => '0');
		elsif rising_edge(LogicClock_C) then
			testcnt <= testcnt + 1;
		end if;
	end process;

	Debug_SO <= DVSAERReqSync_SB & CAVIAR_req & CAVIARo_req & tWSAER_req & WS2CAVIAR_en & led(1 downto 0) & DAVIS_en & '0';

	-- WordSerial to PAER CAVIAR format converter. It joins properly x and y AE into only one event. Row only events are filtered.
	BWSAER2CAVIAR : entity work.WSAER2CAVIAR
		port map(
			WSAER_data  => DVSAERData_AI,
			WSAER_req   => DVSAERReqSync_SB,
			WSAER_ack   => AERMonitorACKxSB_kk,
			-- clock and reset inputs
			CLK         => LogicClock_C,
			RST         => LogicReset_R,
			row_delay   => DVSAERConfig_D.AckDelay_D,
			-- AER monitor interface
			CAVIAR_ack  => CAVIAR_ack,
			CAVIAR_req  => CAVIAR_req,
			CAVIAR_data => CAVIAR_data);

	-- Top entity that gather a Background Activity Filter and x4 object Trackers. The output can be enabled or passthrogh for any component. 
	-- It is not possible to join together both DVS traffic and this filters traffic.
	BFilters : entity work.BGF_OBT_top
		port map(
			aer_in_data   => CAVIAR_data,
			aer_in_req_l  => CAVIAR_req,
			aer_in_ack_l  => CAVIAR_ack_aux,
			aer_out_data  => tCAVIARo_data,
			aer_out_req_l => tCAVIARo_req,
			aer_out_ack_l => tCAVIARo_ack,
			rst_l         => LogicReset_R,
			clk50         => LogicClock_C,
			CLK           => SPIClockSync_C,
			DATA          => SPIMOSISync_D,
			LATCH         => SPIAlternativeSelect_SI,
			spi_data      => spi_data,
			spi_address   => spi_address,
			spi_wr        => spi_wr,
			BGAF_en       => BGAFen,
			WS2CAVIAR_en  => WS2CAVIAR_en,
			DAVIS_en      => DAVIS_en,
			OT_ACTIVE     => ot_active,
			LED           => led);
	CAVIARo_data <= tCAVIARo_data when (BGAFen = '1') else CAVIAR_data;
	CAVIARo_req  <= tCAVIARo_req when (BGAFen = '1') else CAVIAR_req;
	tCAVIARo_ack <= CAVIARo_ack when (BGAFen = '1') else '1';
	CAVIAR_ack   <= CAVIAR_ack_aux when (BGAFen = '1') else CAVIARo_ack;

	-- PAER CAVIAR to WordSerial converter. If two consecutive PAER arrives with the same x address, only a y event is sent.
	BCAVIAR2WSAER : entity work.CAVIAR2WSAER
		port map(
			CAVIAR_ack  => CAVIARo_ack,
			CAVIAR_req  => CAVIARo_req,
			CAVIAR_data => CAVIARo_data,
			-- clock and reset inputs
			CLK         => LogicClock_C,
			RST         => LogicReset_R,
			alex        => alex,
			WSAER_data  => tWSAER_data,
			WSAER_req   => tWSAER_req,
			WSAER_ack   => tWSAER_ack);

	WSAER_data    <= tWSAER_data when (WS2CAVIAR_en = '1') else DVSAERData_AI;
	WSAER_req     <= tWSAER_req when (WS2CAVIAR_en = '1') else DVSAERReqSync_SB;
	DVSAERAck_SBO <= AERMonitorACKxSB_kk when (WS2CAVIAR_en = '1' and DAVIS_en = '1') else WSAER_ack when (DAVIS_en = '1') else 'Z';
	tWSAER_ack    <= WSAER_ack when (WS2CAVIAR_en = '1') else '1';

	-- First: synchronize all USB-related inputs to the USB clock.
	syncInputsToUSBClock : entity work.FX3USBClockSynchronizer
		port map(
			USBClock_CI                 => USBClock_CI,
			Reset_RI                    => Reset_RI,
			ResetSync_RO                => USBReset_R,
			USBFifoThr0Ready_SI         => USBFifoThr0Ready_SI,
			USBFifoThr0ReadySync_SO     => USBFifoThr0ReadySync_S,
			USBFifoThr0Watermark_SI     => USBFifoThr0Watermark_SI,
			USBFifoThr0WatermarkSync_SO => USBFifoThr0WatermarkSync_S,
			USBFifoThr1Ready_SI         => USBFifoThr1Ready_SI,
			USBFifoThr1ReadySync_SO     => USBFifoThr1ReadySync_S,
			USBFifoThr1Watermark_SI     => USBFifoThr1Watermark_SI,
			USBFifoThr1WatermarkSync_SO => USBFifoThr1WatermarkSync_S);

	-- Second: synchronize all logic-related inputs to the logic clock.
	syncInputsToLogicClock : entity work.LogicClockSynchronizer
		port map(
			LogicClock_CI          => LogicClock_C,
			Reset_RI               => Reset_RI,
			ResetSync_RO           => LogicReset_R,
			SPISlaveSelect_SBI     => SPISlaveSelect_ABI,
			SPISlaveSelectSync_SBO => SPISlaveSelectSync_SB,
			SPIClock_CI            => SPIClock_AI,
			SPIClockSync_CO        => SPIClockSync_C,
			SPIMOSI_DI             => SPIMOSI_AI,
			SPIMOSISync_DO         => SPIMOSISync_D,
			DVSAERReq_SBI          => DVSAERReq_ABI,
			DVSAERReqSync_SBO      => DVSAERReqSync_SB,
			IMUInterrupt_SI        => IMUInterrupt_AI,
			IMUInterruptSync_SO    => IMUInterruptSync_S,
			SyncOutSwitch_SI       => SyncOutSwitch_AI,
			SyncOutSwitchSync_SO   => SyncOutSwitchSync_S,
			SyncInClock_CI         => SyncInClock_AI,
			SyncInClockSync_CO     => SyncInClockSync_C,
			SyncInSwitch_SI        => SyncInSwitch_AI,
			SyncInSwitchSync_SO    => SyncInSwitchSync_S,
			SyncInSignal_SI        => SyncInSignal_AI,
			SyncInSignalSync_SO    => SyncInSignalSync_S);

	-- Third: set all constant outputs.
	USBFifoChipSelect_SBO <= '0';       -- Always keep USB chip selected (active-low).
	USBFifoRead_SBO       <= '1';       -- We never read from the USB data path (active-low).
	USBFifoData_DO        <= LogicUSBFifoDataOut_D;
	ChipBiasDiagSelect_SO <= BiasDiagSelect_SI; -- Direct bypass.
	-- Always enable chip if it is needed (for DVS or APS).
	chipBiasEnableBuffer : entity work.SimpleRegister
		port map(
			Clock_CI     => LogicClock_C,
			Reset_RI     => LogicReset_R,
			Enable_SI    => '1',
			Input_SI(0)  => DVSAERConfig_D.Run_S or APSADCConfig_D.Run_S,
			Output_SO(0) => ChipBiasEnable_SO);

	-- Wire all LEDs.
	LED1_SO <= ot_active(0);
	LED2_SO <= ot_active(1);
	LED3_SO <= ot_active(2);
	LED4_SO <= ot_active(3);
	--led1Buffer : entity work.SimpleRegister
	--port map(
	--Clock_CI  => LogicClock_C,
	--Reset_RI  => LogicReset_R,
	--Enable_SI => '1',
	--Input_SI  => MultiplexerConfig_D.Run_S,
	--Output_SO => LED1_SO);

	--led2Buffer : entity work.SimpleRegister
	--port map(
	--Clock_CI  => USBClock_CI,
	--Reset_RI  => USBReset_R,
	--Enable_SI => '1',
	--Input_SI  => LogicUSBFifoControlOut_S.ReadSide.Empty_S,
	--Output_SO => LED2_SO);

	--led3Buffer : entity work.SimpleRegister
	--port map(
	--Clock_CI  => LogicClock_C,
	--Reset_RI  => LogicReset_R,
	--Enable_SI => '1',
	--Input_SI  => not SPISlaveSelectSync_SB,
	--Output_SO => LED3_SO);

	--led4Buffer : entity work.SimpleRegister
	--port map(
	--Clock_CI  => LogicClock_C,
	--Reset_RI  => LogicReset_R,
	--Enable_SI => '1',
	--Input_SI  => LogicUSBFifoControlOut_S.WriteSide.Full_S,
	--Output_SO => LED4_SO);

	-- Generate logic clock using a PLL.
	logicClockPLL : entity work.PLL
		generic map(
			CLOCK_FREQ     => USB_CLOCK_FREQ,
			OUT_CLOCK_FREQ => LOGIC_CLOCK_FREQ)
		port map(
			Clock_CI    => USBClock_CI,
			Reset_RI    => USBReset_R,
			OutClock_CO => LogicClock_C);

	-- Generate ADC clock using a PLL. Must be 30MHz.
	adcClockPLL : entity work.PLL
		generic map(
			CLOCK_FREQ     => USB_CLOCK_FREQ,
			OUT_CLOCK_FREQ => ADC_CLOCK_FREQ)
		port map(
			Clock_CI    => USBClock_CI,
			Reset_RI    => USBReset_R,
			OutClock_CO => ADCClock_C);

	-- Also create synchronized reset signal for ADC.
	adcResetSync : entity work.ResetSynchronizer
		port map(
			ExtClock_CI  => ADCClock_C,
			ExtReset_RI  => Reset_RI,
			SyncReset_RO => ADCReset_R);

	usbFX3SM : entity work.FX3Statemachine
		port map(
			Clock_CI                    => USBClock_CI,
			Reset_RI                    => USBReset_R,
			USBFifoThread0Full_SI       => USBFifoThr0ReadySync_S,
			USBFifoThread0AlmostFull_SI => USBFifoThr0WatermarkSync_S,
			USBFifoThread1Full_SI       => USBFifoThr1ReadySync_S,
			USBFifoThread1AlmostFull_SI => USBFifoThr1WatermarkSync_S,
			USBFifoWrite_SBO            => USBFifoWrite_SBO,
			USBFifoPktEnd_SBO           => USBFifoPktEnd_SBO,
			USBFifoAddress_DO           => USBFifoAddress_DO,
			InFifoControl_SI            => LogicUSBFifoControlOut_S.ReadSide,
			InFifoControl_SO            => LogicUSBFifoControlIn_S.ReadSide,
			FX3Config_DI                => tFX3ConfigDefault);

	-- Instantiate one FIFO to hold all the events coming out of the mixer-producer state machine.
	logicUSBFifo : entity work.FIFODualClock
		generic map(
			DATA_WIDTH        => USB_FIFO_WIDTH,
			DATA_DEPTH        => USBLOGIC_FIFO_SIZE,
			EMPTY_FLAG        => 0,
			ALMOST_EMPTY_FLAG => USBLOGIC_FIFO_ALMOST_EMPTY_SIZE,
			FULL_FLAG         => USBLOGIC_FIFO_SIZE,
			ALMOST_FULL_FLAG  => USBLOGIC_FIFO_SIZE - USBLOGIC_FIFO_ALMOST_FULL_SIZE)
		port map(
			Reset_RI       => LogicReset_R,
			WrClock_CI     => LogicClock_C,
			RdClock_CI     => USBClock_CI,
			FifoControl_SI => LogicUSBFifoControlIn_S,
			FifoControl_SO => LogicUSBFifoControlOut_S,
			FifoData_DI    => LogicUSBFifoDataIn_D,
			FifoData_DO    => LogicUSBFifoDataOut_D);

	multiplexerSM : entity work.MultiplexerStateMachine
		port map(
			Clock_CI                 => LogicClock_C,
			Reset_RI                 => LogicReset_R,
			OutFifoControl_SI        => LogicUSBFifoControlOut_S.WriteSide,
			OutFifoControl_SO        => LogicUSBFifoControlIn_S.WriteSide,
			OutFifoData_DO           => LogicUSBFifoDataIn_D,
			DVSAERFifoControl_SI     => DVSAERFifoControlOut_S.ReadSide,
			DVSAERFifoControl_SO     => DVSAERFifoControlIn_S.ReadSide,
			DVSAERFifoData_DI        => DVSAERFifoDataOut_D,
			APSADCFifoControl_SI     => APSADCFifoControlOut_S.ReadSide,
			APSADCFifoControl_SO     => APSADCFifoControlIn_S.ReadSide,
			APSADCFifoData_DI        => APSADCFifoDataOut_D,
			IMUFifoControl_SI        => IMUFifoControlOut_S.ReadSide,
			IMUFifoControl_SO        => IMUFifoControlIn_S.ReadSide,
			IMUFifoData_DI           => IMUFifoDataOut_D,
			ExtTriggerFifoControl_SI => ExtTriggerFifoControlOut_S.ReadSide,
			ExtTriggerFifoControl_SO => ExtTriggerFifoControlIn_S.ReadSide,
			ExtTriggerFifoData_DI    => ExtTriggerFifoDataOut_D,
			MultiplexerConfig_DI     => MultiplexerConfig_D);

	multiplexerSPIConfig : entity work.MultiplexerSPIConfig
		port map(
			Clock_CI                        => LogicClock_C,
			Reset_RI                        => LogicReset_R,
			MultiplexerConfig_DO            => MultiplexerConfig_D,
			ConfigModuleAddress_DI          => ConfigModuleAddress_D,
			ConfigParamAddress_DI           => ConfigParamAddress_D,
			ConfigParamInput_DI             => ConfigParamInput_D,
			ConfigLatchInput_SI             => ConfigLatchInput_S,
			MultiplexerConfigParamOutput_DO => MultiplexerConfigParamOutput_D);

	dvsAerFifo : entity work.FIFO
		generic map(
			DATA_WIDTH        => EVENT_WIDTH,
			DATA_DEPTH        => DVSAER_FIFO_SIZE,
			EMPTY_FLAG        => 0,
			ALMOST_EMPTY_FLAG => DVSAER_FIFO_ALMOST_EMPTY_SIZE,
			FULL_FLAG         => DVSAER_FIFO_SIZE,
			ALMOST_FULL_FLAG  => DVSAER_FIFO_SIZE - DVSAER_FIFO_ALMOST_FULL_SIZE)
		port map(
			Clock_CI       => LogicClock_C,
			Reset_RI       => LogicReset_R,
			FifoControl_SI => DVSAERFifoControlIn_S,
			FifoControl_SO => DVSAERFifoControlOut_S,
			FifoData_DI    => DVSAERFifoDataIn_D,
			FifoData_DO    => DVSAERFifoDataOut_D);

	dvsAerSM : entity work.DVSAERStateMachine
		generic map(
			AER_BUS_WIDTH => AER_BUS_WIDTH)
		port map(
			Clock_CI          => LogicClock_C,
			Reset_RI          => LogicReset_R,
			OutFifoControl_SI => DVSAERFifoControlOut_S.WriteSide,
			OutFifoControl_SO => DVSAERFifoControlIn_S.WriteSide,
			OutFifoData_DO    => DVSAERFifoDataIn_D,
			DVSAERData_DI     => WSAER_data, --DVSAERData_AI, --
			DVSAERReq_SBI     => WSAER_req, --DVSAERReqSync_SB, --
			DVSAERAck_SBO     => WSAER_ack, --DVSAERAck_SBO, --
			DVSAERReset_SBO   => DVSAERReset_SBO,
			DVSAERConfig_DI   => DVSAERConfig_D);

	dvsaerSPIConfig : entity work.DVSAERSPIConfig
		port map(
			Clock_CI                   => LogicClock_C,
			Reset_RI                   => LogicReset_R,
			DVSAERConfig_DO            => DVSAERConfig_D,
			ConfigModuleAddress_DI     => ConfigModuleAddress_D,
			ConfigParamAddress_DI      => ConfigParamAddress_D,
			ConfigParamInput_DI        => ConfigParamInput_D,
			ConfigLatchInput_SI        => ConfigLatchInput_S,
			DVSAERConfigParamOutput_DO => DVSAERConfigParamOutput_D);

	-- Dual-clock FIFO is needed to bridge from ADC clock (ADCClock_C in this case) to logic clock.
	apsAdcFifo : entity work.FIFODualClock
		generic map(
			DATA_WIDTH        => EVENT_WIDTH,
			DATA_DEPTH        => APSADC_FIFO_SIZE,
			EMPTY_FLAG        => 0,
			ALMOST_EMPTY_FLAG => APSADC_FIFO_ALMOST_EMPTY_SIZE,
			FULL_FLAG         => APSADC_FIFO_SIZE,
			ALMOST_FULL_FLAG  => APSADC_FIFO_SIZE - APSADC_FIFO_ALMOST_FULL_SIZE)
		port map(
			Reset_RI       => ADCReset_R,
			WrClock_CI     => ADCClock_C,
			RdClock_CI     => LogicClock_C,
			FifoControl_SI => APSADCFifoControlIn_S,
			FifoControl_SO => APSADCFifoControlOut_S,
			FifoData_DI    => APSADCFifoDataIn_D,
			FifoData_DO    => APSADCFifoDataOut_D);

	apsAdcSM : entity work.APSADCStateMachine
		generic map(
			ADC_CLOCK_FREQ    => ADC_CLOCK_FREQ,
			ADC_BUS_WIDTH     => ADC_BUS_WIDTH,
			CHIP_SIZE_COLUMNS => CHIP_SIZE_COLUMNS,
			CHIP_SIZE_ROWS    => CHIP_SIZE_ROWS)
		port map(
			Clock_CI               => ADCClock_C,
			Reset_RI               => ADCReset_R,
			OutFifoControl_SI      => APSADCFifoControlOut_S.WriteSide,
			OutFifoControl_SO      => APSADCFifoControlIn_S.WriteSide,
			OutFifoData_DO         => APSADCFifoDataIn_D,
			APSChipRowSRClock_SO   => APSChipRowSRClock_SO,
			APSChipRowSRIn_SO      => APSChipRowSRIn_SO,
			APSChipColSRClock_SO   => APSChipColSRClock_SO,
			APSChipColSRIn_SO      => APSChipColSRIn_SO,
			APSChipColMode_DO      => APSChipColMode_DO,
			APSChipTXGate_SBO      => APSChipTXGate_SBO,
			APSADCData_DI          => APSADCData_DI,
			APSADCOverflow_SI      => APSADCOverflow_SI,
			APSADCClock_CO         => APSADCClock_CO,
			APSADCOutputEnable_SBO => APSADCOutputEnable_SBO,
			APSADCStandby_SO       => APSADCStandby_SO,
			APSADCConfig_DI        => APSADCConfig_D);

	apsadcSPIConfig : entity work.APSADCSPIConfig
		port map(
			Clock_CI                   => LogicClock_C,
			Reset_RI                   => LogicReset_R,
			APSADCConfig_DO            => APSADCConfig_D,
			ConfigModuleAddress_DI     => ConfigModuleAddress_D,
			ConfigParamAddress_DI      => ConfigParamAddress_D,
			ConfigParamInput_DI        => ConfigParamInput_D,
			ConfigLatchInput_SI        => ConfigLatchInput_S,
			APSADCConfigParamOutput_DO => APSADCConfigParamOutput_D);

	imuFifo : entity work.FIFO
		generic map(
			DATA_WIDTH        => EVENT_WIDTH,
			DATA_DEPTH        => IMU_FIFO_SIZE,
			EMPTY_FLAG        => 0,
			ALMOST_EMPTY_FLAG => IMU_FIFO_ALMOST_EMPTY_SIZE,
			FULL_FLAG         => IMU_FIFO_SIZE,
			ALMOST_FULL_FLAG  => IMU_FIFO_SIZE - IMU_FIFO_ALMOST_FULL_SIZE)
		port map(
			Clock_CI       => LogicClock_C,
			Reset_RI       => LogicReset_R,
			FifoControl_SI => IMUFifoControlIn_S,
			FifoControl_SO => IMUFifoControlOut_S,
			FifoData_DI    => IMUFifoDataIn_D,
			FifoData_DO    => IMUFifoDataOut_D);

	imuSM : entity work.IMUStateMachine
		port map(
			Clock_CI          => LogicClock_C,
			Reset_RI          => LogicReset_R,
			OutFifoControl_SI => IMUFifoControlOut_S.WriteSide,
			OutFifoControl_SO => IMUFifoControlIn_S.WriteSide,
			OutFifoData_DO    => IMUFifoDataIn_D,
			IMUClock_CZO      => IMUClock_CZO,
			IMUData_DZIO      => IMUData_DZIO,
			IMUInterrupt_SI   => IMUInterruptSync_S,
			IMUConfig_DI      => IMUConfig_D);

	imuSPIConfig : entity work.IMUSPIConfig
		port map(
			Clock_CI                => LogicClock_C,
			Reset_RI                => LogicReset_R,
			IMUConfig_DO            => IMUConfig_D,
			ConfigModuleAddress_DI  => ConfigModuleAddress_D,
			ConfigParamAddress_DI   => ConfigParamAddress_D,
			ConfigParamInput_DI     => ConfigParamInput_D,
			ConfigLatchInput_SI     => ConfigLatchInput_S,
			IMUConfigParamOutput_DO => IMUConfigParamOutput_D);

	extTriggerFifo : entity work.FIFO
		generic map(
			DATA_WIDTH        => EVENT_WIDTH,
			DATA_DEPTH        => EXT_TRIGGER_FIFO_SIZE,
			EMPTY_FLAG        => 0,
			ALMOST_EMPTY_FLAG => EXT_TRIGGER_FIFO_ALMOST_EMPTY_SIZE,
			FULL_FLAG         => EXT_TRIGGER_FIFO_SIZE,
			ALMOST_FULL_FLAG  => EXT_TRIGGER_FIFO_SIZE - EXT_TRIGGER_FIFO_ALMOST_FULL_SIZE)
		port map(
			Clock_CI       => LogicClock_C,
			Reset_RI       => LogicReset_R,
			FifoControl_SI => ExtTriggerFifoControlIn_S,
			FifoControl_SO => ExtTriggerFifoControlOut_S,
			FifoData_DI    => ExtTriggerFifoDataIn_D,
			FifoData_DO    => ExtTriggerFifoDataOut_D);

	extTriggerSM : entity work.ExtTriggerStateMachine
		port map(
			Clock_CI               => LogicClock_C,
			Reset_RI               => LogicReset_R,
			OutFifoControl_SI      => ExtTriggerFifoControlOut_S.WriteSide,
			OutFifoControl_SO      => ExtTriggerFifoControlIn_S.WriteSide,
			OutFifoData_DO         => ExtTriggerFifoDataIn_D,
			ExtTriggerSignal_SI    => SyncInSignalSync_S,
			CustomTriggerSignal_SI => '1',
			ExtTriggerSignal_SO    => SyncOutSignal_SO,
			ExtTriggerConfig_DI    => ExtTriggerConfig_D);

	extTriggerSPIConfig : entity work.ExtTriggerSPIConfig
		port map(
			Clock_CI                       => LogicClock_C,
			Reset_RI                       => LogicReset_R,
			ExtTriggerConfig_DO            => ExtTriggerConfig_D,
			ConfigModuleAddress_DI         => ConfigModuleAddress_D,
			ConfigParamAddress_DI          => ConfigParamAddress_D,
			ConfigParamInput_DI            => ConfigParamInput_D,
			ConfigLatchInput_SI            => ConfigLatchInput_S,
			ExtTriggerConfigParamOutput_DO => ExtTriggerConfigParamOutput_D);

	spiConfiguration : entity work.SPIConfig
		port map(
			Clock_CI               => LogicClock_C,
			Reset_RI               => LogicReset_R,
			SPISlaveSelect_SBI     => SPISlaveSelectSync_SB,
			SPIClock_CI            => SPIClockSync_C,
			SPIMOSI_DI             => SPIMOSISync_D,
			SPIMISO_DZO            => SPIMISO_DZO,
			ConfigModuleAddress_DO => ConfigModuleAddress_D,
			ConfigParamAddress_DO  => ConfigParamAddress_D,
			ConfigParamInput_DO    => ConfigParamInput_D,
			ConfigLatchInput_SO    => ConfigLatchInput_S,
			ConfigParamOutput_DI   => ConfigParamOutput_D);

	spiConfigurationOutputSelect : process(ConfigModuleAddress_D, MultiplexerConfigParamOutput_D, DVSAERConfigParamOutput_D, APSADCConfigParamOutput_D, IMUConfigParamOutput_D, ExtTriggerConfigParamOutput_D)
	begin
		-- Output side select.
		ConfigParamOutput_D <= (others => '0');

		case ConfigModuleAddress_D is
			when MULTIPLEXERCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= MultiplexerConfigParamOutput_D;

			when DVSAERCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= DVSAERConfigParamOutput_D;

			when APSADCCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= APSADCConfigParamOutput_D;

			when IMUCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= IMUConfigParamOutput_D;

			when EXTTRIGGERCONFIG_MODULE_ADDRESS =>
				ConfigParamOutput_D <= ExtTriggerConfigParamOutput_D;

			when others => null;
		end case;
	end process spiConfigurationOutputSelect;
end Structural;
