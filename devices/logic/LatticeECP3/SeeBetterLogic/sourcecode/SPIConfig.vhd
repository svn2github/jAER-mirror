library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ShiftRegisterModes.all;
use work.MultiplexerConfigRecords.all;
use work.DVSAERConfigRecords.all;

entity SPIConfig is
	port (
		Clock_CI : in std_logic;
		Reset_RI : in std_logic;

		-- SPI ports
		SPISlaveSelect_SBI : in	   std_logic;
		SPIClock_CI		   : in	   std_logic;
		SPIMOSI_DI		   : in	   std_logic;
		SPIMISO_ZO		   : inout std_logic;

		-- Configuration modules outputs
		MultiplexerConfig_DO : out tMultiplexerConfig;
		DVSAERConfig_DO		 : out tDVSAERConfig);
end entity SPIConfig;

architecture Behavioral of SPIConfig is
	component EdgeDetector is
		generic (
			SIGNAL_START_POLARITY : std_logic := '0');
		port (
			Clock_CI			   : in	 std_logic;
			Reset_RI			   : in	 std_logic;
			InputSignal_SI		   : in	 std_logic;
			RisingEdgeDetected_SO  : out std_logic;
			FallingEdgeDetected_SO : out std_logic);
	end component EdgeDetector;

	component ShiftRegister is
		generic (
			SIZE : integer := 8);
		port (
			Clock_CI		 : in  std_logic;
			Reset_RI		 : in  std_logic;
			Mode_SI			 : in  std_logic_vector(1 downto 0);
			DataIn_DI		 : in  std_logic;
			DataOutRight_DO	 : out std_logic;
			DataOutLeft_DO	 : out std_logic;
			ParallelWrite_DI : in  std_logic_vector(SIZE-1 downto 0);
			ParallelRead_DO	 : out std_logic_vector(SIZE-1 downto 0));
	end component ShiftRegister;

	component ContinuousCounter is
		generic (
			COUNTER_WIDTH	  : integer := 16;
			RESET_ON_OVERFLOW : boolean := true;
			SHORT_OVERFLOW	  : boolean := false;
			OVERFLOW_AT_ZERO  : boolean := false);
		port (
			Clock_CI	 : in  std_logic;
			Reset_RI	 : in  std_logic;
			Clear_SI	 : in  std_logic;
			Enable_SI	 : in  std_logic;
			DataLimit_DI : in  unsigned(COUNTER_WIDTH-1 downto 0);
			Overflow_SO	 : out std_logic;
			Data_DO		 : out unsigned(COUNTER_WIDTH-1 downto 0));
	end component ContinuousCounter;

	type state is (stIdle, stInputModuleAddress, stInputParamAddress, stInputByte1, stInputByte2, stInputByte3, stInputByte4, stInputDelay, stOutputByte1, stOutputByte2, stOutputByte3, stOutputByte4);

	attribute syn_enum_encoding			 : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

	signal SPIClockRisingEdges_S, SPIClockFallingEdges_S						: std_logic;
	signal SPIReadMOSI_S, SPIWriteMISO_S										: std_logic;
	signal SPIInputSRegMode_S													: std_logic_vector(1 downto 0);
	signal SPIInputSRegRead_D													: std_logic_vector(7 downto 0);
	signal SPIInputCountClear_S, SPIInputCountEnable_S, SPIInputCountOverflow_S : std_logic;

	signal ReadOperationReg_SP, ReadOperationReg_SN : std_logic;
	signal ModuleAddressReg_DP, ModuleAddressReg_DN : std_logic_vector(6 downto 0);
	signal ParamAddressReg_DP, ParamAddressReg_DN	: std_logic_vector(7 downto 0);
	signal ParamContent_DP, ParamContent_DN			: std_logic_vector(31 downto 0);
	signal TransferDoneReg_SP, TransferDoneReg_SN	: std_logic;

	-- Configuration modules registers
	signal MultiplexerConfigReg_DP, MultiplexerConfigReg_DN : tMultiplexerConfig;
	signal DVSAERConfigReg_DP, DVSAERConfigReg_DN			: tDVSAERConfig;
begin  -- architecture Behavioral
	-- The SPI input lines have already been synchronized to the logic clock at
	-- this point, so we can use and sample them directly.
	spiClockDetector : EdgeDetector
		port map (
			Clock_CI			   => Clock_CI,
			Reset_RI			   => Reset_RI,
			InputSignal_SI		   => SPIClock_CI,
			RisingEdgeDetected_SO  => SPIClockRisingEdges_S,
			FallingEdgeDetected_SO => SPIClockFallingEdges_S);

	-- We support SPI mode 0 (CPOL=0, CPHA=0). So we sample data on the rising
	-- edge and we output data on the falling one. Of course, only if this
	-- device's slave select line is enabled (active-low).
	SPIReadMOSI_S  <= SPIClockRisingEdges_S and not SPISlaveSelect_SBI;
	SPIWriteMISO_S <= SPIClockFallingEdges_S and not SPISlaveSelect_SBI;

	spiInputShiftRegister : ShiftRegister
		port map (
			Clock_CI		 => Clock_CI,
			Reset_RI		 => Reset_RI,
			Mode_SI			 => SPIInputSRegMode_S,
			DataIn_DI		 => SPIMOSI_DI,
			DataOutRight_DO	 => open,
			DataOutLeft_DO	 => open,
			ParallelWrite_DI => (others => '0'),
			ParallelRead_DO	 => SPIInputSRegRead_D);

	spiInputCounter : ContinuousCounter
		generic map (
			COUNTER_WIDTH => 3)
		port map (
			Clock_CI	 => Clock_CI,
			Reset_RI	 => Reset_RI,
			Clear_SI	 => SPIInputCountClear_S,
			Enable_SI	 => SPIInputCountEnable_S,
			DataLimit_DI => (others => '1'),
			Overflow_SO	 => SPIInputCountOverflow_S,
			Data_DO		 => open);

	spiCommunication : process (State_DP, SPIInputSRegRead_D, SPIInputCountOverflow_S, SPISlaveSelect_SBI, SPIReadMOSI_S, ReadOperationReg_SP, ModuleAddressReg_DP, ParamAddressReg_DP, ParamContent_DP, TransferDoneReg_SP)
	begin
		-- Keep state by default.
		State_DN <= State_DP;

		-- Keep all registers at current value by default.
		ReadOperationReg_SN <= ReadOperationReg_SP;
		ModuleAddressReg_DN <= ModuleAddressReg_DP;
		ParamAddressReg_DN	<= ParamAddressReg_DP;
		ParamContent_DN		<= ParamContent_DP;
		TransferDoneReg_SN	<= TransferDoneReg_SP;

		-- SPI output is Hi-Z by default.
		SPIMISO_ZO <= 'Z';

		-- Keep the input elements (shift register and counter) fixed.
		SPIInputSRegMode_S	  <= SHIFTREGISTER_MODE_DO_NOTHING;
		SPIInputCountClear_S  <= '0';
		SPIInputCountEnable_S <= '0';

		case State_DP is
			when stIdle =>
				-- If this SPI slave gets selected, start observing the clock
				-- and input lines.
				if SPISlaveSelect_SBI = '0' then
					State_DN <= stInputModuleAddress;
				end if;

				-- Keep input elements clear while idling.
				SPIInputSRegMode_S	 <= SHIFTREGISTER_MODE_PARALLEL_LOAD;
				SPIInputCountClear_S <= '1';

			when stInputModuleAddress =>
				-- Push a zero out on the SPI bus, when there is nothing
				-- concrete to output. We're reading input right now.
				SPIMISO_ZO <= '0';

				-- Detect SPI slave selection failure.
				if SPISlaveSelect_SBI = '1' then
					State_DN <= stIdle;
				end if;

				if SPIReadMOSI_S = '1' then
					SPIInputSRegMode_S	  <= SHIFTREGISTER_MODE_SHIFT_LEFT;
					SPIInputCountEnable_S <= '1';
				end if;

				if SPIInputCountOverflow_S = '1' then
					-- Copy captured data to the right place.
					ReadOperationReg_SN <= SPIInputSRegRead_D(7);
					ModuleAddressReg_DN <= SPIInputSRegRead_D(6 downto 0);

					-- Capture next byte.
					State_DN <= stInputParamAddress;
				end if;

			when others => null;
		end case;
	end process spiCommunication;

	configUpdate : process (ModuleAddressReg_DP, ParamAddressReg_DP, ParamContent_DP, MultiplexerConfigReg_DP, DVSAERConfigReg_DP)
	begin
		MultiplexerConfigReg_DN <= MultiplexerConfigReg_DP;
		DVSAERConfigReg_DN		<= DVSAERConfigReg_DP;

		case ModuleAddressReg_DP is
			when MULTIPLEXERCONFIG_MODULE_ADDRESS =>
				case ParamAddressReg_DP is
					when MULTIPLEXERCONFIG_PARAM_ADDRESSES.Run_S =>
						MultiplexerConfigReg_DN.Run_S <= ParamContent_DP(0);

					when MULTIPLEXERCONFIG_PARAM_ADDRESSES.TimestampRun_S =>
						MultiplexerConfigReg_DN.TimestampRun_S <= ParamContent_DP(0);

					when MULTIPLEXERCONFIG_PARAM_ADDRESSES.TimestampReset_S =>
						MultiplexerConfigReg_DN.TimestampReset_S <= ParamContent_DP(0);

					when others => null;
				end case;

			when DVSAERCONFIG_MODULE_ADDRESS =>
				case ParamAddressReg_DP is
					when DVSAERCONFIG_PARAM_ADDRESSES.Run_S =>
						DVSAERConfigReg_DN.Run_S <= ParamContent_DP(0);

					when DVSAERCONFIG_PARAM_ADDRESSES.AckDelay_D =>
						DVSAERConfigReg_DN.AckDelay_D <= ParamContent_DP(tDVSAERConfig.AckDelay_D'length-1 downto 0);

					when DVSAERCONFIG_PARAM_ADDRESSES.AckExtension_D =>
						DVSAERConfigReg_DN.AckExtension_D <= ParamContent_DP(tDVSAERConfig.AckExtension_D'length-1 downto 0);

					when others => null;
				end case;

			when others => null;
		end case;
	end process configUpdate;

	regUpdate : process (Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then			-- asynchronous reset (active high)
			State_DP <= stIdle;

			ReadOperationReg_SP <= '0';
			ModuleAddressReg_DP <= (others => '0');
			ParamAddressReg_DP	<= (others => '0');
			ParamContent_DP		<= (others => '0');
			TransferDoneReg_SP	<= '0';

			MultiplexerConfigReg_DP <= tMultiplexerConfigDefault;
			DVSAERConfigReg_DP		<= tDVSAERConfigDefault;
		elsif rising_edge(Clock_CI) then  -- rising clock edge
			State_DP <= State_DN;

			ReadOperationReg_SP <= ReadOperationReg_SN;
			ModuleAddressReg_DP <= ModuleAddressReg_DN;
			ParamAddressReg_DP	<= ParamAddressReg_DN;
			ParamContent_DP		<= ParamContent_DN;
			TransferDoneReg_SP	<= TransferDoneReg_SN;

			if TransferDoneReg_SP = '1' then
				MultiplexerConfigReg_DP <= MultiplexerConfigReg_DN;
				DVSAERConfigReg_DP		<= DVSAERConfigReg_DN;
			end if;
		end if;
	end process regUpdate;

	-- Connect configuration modules outputs
	MultiplexerConfig_DO <= MultiplexerConfigReg_DP;
	DVSAERConfig_DO		 <= DVSAERConfigReg_DP;
end architecture Behavioral;
