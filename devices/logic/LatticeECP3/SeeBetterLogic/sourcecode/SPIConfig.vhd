library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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
		DVSAERConfig_DO : out tDVSAERConfig);
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

	signal SPIClockRisingEdges_S, SPIClockFallingEdges_S : std_logic;
	signal SPIReadMOSI_S, SPIWriteMISO_S				 : std_logic;

	signal ReadOperationReg_SP, ReadOperationReg_SN : std_logic;
	signal ModuleAddressReg_DP, ModuleAddressReg_DN : std_logic_vector(6 downto 0);
	signal ParamAddressReg_DP, ParamAddressReg_DN	: std_logic_vector(7 downto 0);
	signal ParamContent_DP, ParamContent_DN			: std_logic_vector(31 downto 0);
	signal TransferDoneReg_SP, TransferDoneReg_SN	: std_logic;

	-- Configuration modules registers
	signal DVSAERConfigReg_DP, DVSAERConfigReg_DN : tDVSAERConfig;
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

	spiCommunication : process (ReadOperationReg_SP, ModuleAddressReg_DP, ParamAddressReg_DP, ParamContent_DP, TransferDoneReg_SP)
	begin
		ReadOperationReg_SN <= ReadOperationReg_SP;
		ModuleAddressReg_DN <= ModuleAddressReg_DP;
		ParamAddressReg_DN	<= ParamAddressReg_DP;
		ParamContent_DN		<= ParamContent_DP;
		TransferDoneReg_SN	<= TransferDoneReg_SP;

		SPIMISO_ZO <= 'Z';
	end process spiCommunication;

	configUpdate : process (ModuleAddressReg_DP, ParamAddressReg_DP, ParamContent_DP, DVSAERConfigReg_DP)
	begin
		DVSAERConfigReg_DN <= DVSAERConfigReg_DP;

		case ModuleAddressReg_DP is
			when DVSAERCONFIG_MODULE_ADDRESS =>
				case ParamAddressReg_DP is
					when DVSAERCONFIG_PARAM_ADDRESSES.ackDelay =>
						DVSAERConfigReg_DN.ackDelay <= ParamContent_DP(tDVSAERConfig.ackDelay'length-1 downto 0);

					when DVSAERCONFIG_PARAM_ADDRESSES.ackExtension =>
						DVSAERConfigReg_DN.ackExtension <= ParamContent_DP(tDVSAERConfig.ackExtension'length-1 downto 0);

					when others => null;
				end case;

			when others => null;
		end case;
	end process configUpdate;

	regUpdate : process (Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then			-- asynchronous reset (active high)
			ReadOperationReg_SP <= '0';
			ModuleAddressReg_DP <= (others => '0');
			ParamAddressReg_DP	<= (others => '0');
			ParamContent_DP		<= (others => '0');
			TransferDoneReg_SP	<= '0';

			DVSAERConfigReg_DP <= tDVSAERConfigDefault;
		elsif rising_edge(Clock_CI) then  -- rising clock edge
			ReadOperationReg_SP <= ReadOperationReg_SN;
			ModuleAddressReg_DP <= ModuleAddressReg_DN;
			ParamAddressReg_DP	<= ParamAddressReg_DN;
			ParamContent_DP		<= ParamContent_DN;
			TransferDoneReg_SP	<= TransferDoneReg_SN;

			if TransferDoneReg_SP = '1' then
				DVSAERConfigReg_DP <= DVSAERConfigReg_DN;
			end if;
		end if;
	end process regUpdate;

	-- Connect configuration modules outputs
	DVSAERConfig_DO <= DVSAERConfigReg_DP;
end architecture Behavioral;
