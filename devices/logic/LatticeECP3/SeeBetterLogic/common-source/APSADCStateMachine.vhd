library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.APSADCConfigRecords.all;

entity APSADCStateMachine is
	generic(
		ADC_CLOCK_FREQ    : integer;
		ADC_BUS_WIDTH     : integer;
		CHIP_SIZE_COLUMNS : integer;
		CHIP_SIZE_ROWS    : integer);
	port(
		Clock_CI               : in  std_logic; -- This clock must be 30MHz, use PLL to generate.
		Reset_RI               : in  std_logic; -- This reset must be synchronized to the above clock.

		-- Fifo output (to Multiplexer, must be a dual-clock FIFO)
		OutFifoControl_SI      : in  tFromFifoWriteSide;
		OutFifoControl_SO      : out tToFifoWriteSide;
		OutFifoData_DO         : out std_logic_vector(EVENT_WIDTH - 1 downto 0);

		APSChipRowSRClock_SO   : out std_logic;
		APSChipRowSRIn_SO      : out std_logic;
		APSChipColSRClock_SO   : out std_logic;
		APSChipColSRIn_SO      : out std_logic;
		APSChipColMode_DO      : out std_logic_vector(1 downto 0);
		APSChipTXGate_SBO      : out std_logic;

		APSADCData_DI          : in  std_logic_vector(ADC_BUS_WIDTH - 1 downto 0);
		APSADCOverflow_SI      : in  std_logic;
		APSADCClock_CO         : out std_logic;
		APSADCOutputEnable_SBO : out std_logic;
		APSADCStandby_SO       : out std_logic;

		-- Configuration input
		APSADCConfig_DI        : in  tAPSADCConfig);
end entity APSADCStateMachine;

architecture Behavioral of APSADCStateMachine is
	attribute syn_enum_encoding : string;

	type tColumnState is (stIdle, stWriteEvent);
	attribute syn_enum_encoding of tColumnState : type is "onehot";

	-- present and next state
	signal ColState_DP, ColState_DN : tColumnState;

	type tRowState is (stIdle, stWriteEvent);
	attribute syn_enum_encoding of tRowState : type is "onehot";

	-- present and next state
	signal RowState_DP, RowState_DN : tRowState;

	constant CHIP_REG_SIZE_COLUMNS : integer := 1 + CHIP_SIZE_COLUMNS + 1; -- One bit more on each side, for three-bit code.
	constant CHIP_REG_SIZE_ROWS    : integer := CHIP_SIZE_ROWS;

	constant COLMODE_NULL   : std_logic_vector(1 downto 0) := "00";
	constant COLMODE_READA  : std_logic_vector(1 downto 0) := "01";
	constant COLMODE_READB  : std_logic_vector(1 downto 0) := "10";
	constant COLMODE_RESETA : std_logic_vector(1 downto 0) := "11";

	-- Register outputs to FIFO.
	signal OutFifoWriteReg_S, OutFifoWriteRegCol_S, OutFifoWriteRegRow_S                : std_logic;
	signal OutFifoDataRegEnable_S, OutFifoDataRegColEnable_S, OutFifoDataRegRowEnable_S : std_logic;
	signal OutFifoDataReg_D, OutFifoDataRegCol_D, OutFifoDataRegRow_D                   : std_logic_vector(EVENT_WIDTH - 1 downto 0);

	-- Register all outputs to ADC and chip for clean transitions.
	signal APSChipRowSRClockReg_S, APSChipRowSRInReg_S  : std_logic;
	signal APSChipColSRClockReg_S, APSChipColSRInReg_S  : std_logic;
	signal APSChipColModeReg_D                          : std_logic_vector(1 downto 0);
	signal APSChipTXGateReg_SB                          : std_logic;
	signal APSADCOutputEnableReg_SB, APSADCStandbyReg_S : std_logic;

	-- Double register configuration input, since it comes from a different clock domain (LogicClock), it
	-- needs to go through a double-flip-flop synchronizer to guarantee correctness.
	signal APSADCConfigSyncReg_D, APSADCConfigReg_D : tAPSADCConfig;
begin
	-- Forward 30MHz clock directly to external ADC.
	APSADCClock_CO <= Clock_CI;

	columnMainStateMachine : process(ColState_DP)
	begin
		ColState_DN <= ColState_DP;     -- Keep current state by default.

		OutFifoWriteRegCol_S      <= '0';
		OutFifoDataRegColEnable_S <= '0';
		OutFifoDataRegCol_D       <= (others => '0');

		APSChipColSRClockReg_S <= '0';
		APSChipColSRInReg_S    <= '0';

		APSChipColModeReg_D <= COLMODE_NULL;
		APSChipTXGateReg_SB <= '1';

		APSADCOutputEnableReg_SB <= '1';
		APSADCStandbyReg_S       <= '1';

		case ColState_DP is
			when stIdle =>
			when others => null;
		end case;
	end process columnMainStateMachine;

	rowReadStateMachine : process(RowState_DP)
	begin
		RowState_DN <= RowState_DP;

		OutFifoWriteRegRow_S      <= '0';
		OutFifoDataRegRowEnable_S <= '0';
		OutFifoDataRegRow_D       <= (others => '0');

		APSChipRowSRClockReg_S <= '0';
		APSChipRowSRInReg_S    <= '0';

		case RowState_DP is
			when stIdle =>
			when others => null;
		end case;
	end process rowReadStateMachine;

	OutFifoWriteReg_S      <= OutFifoWriteRegCol_S or OutFifoWriteRegRow_S;
	OutFifoDataRegEnable_S <= OutFifoDataRegColEnable_S or OutFifoDataRegRowEnable_S;
	OutFifoDataReg_D       <= OutFifoDataRegCol_D or OutFifoDataRegRow_D;

	outputDataRegister : entity work.SimpleRegister
		generic map(
			SIZE => EVENT_WIDTH)
		port map(
			Clock_CI  => Clock_CI,
			Reset_RI  => Reset_RI,
			Enable_SI => OutFifoDataRegEnable_S,
			Input_SI  => OutFifoDataReg_D,
			Output_SO => OutFifoData_DO);

	-- Change state on clock edge (synchronous).
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			ColState_DP <= stIdle;
			RowState_DP <= stIdle;

			OutFifoControl_SO.Write_S <= '0';

			APSChipRowSRClock_SO <= '0';
			APSChipRowSRIn_SO    <= '0';
			APSChipColSRClock_SO <= '0';
			APSChipColSRIn_SO    <= '0';
			APSChipColMode_DO    <= COLMODE_NULL;
			APSChipTXGate_SBO    <= '1';

			APSADCOutputEnable_SBO <= '1';
			APSADCStandby_SO       <= '1';

			-- APS ADC config from another clock domain.
			APSADCConfigReg_D     <= tAPSADCConfigDefault;
			APSADCConfigSyncReg_D <= tAPSADCConfigDefault;
		elsif rising_edge(Clock_CI) then
			ColState_DP <= ColState_DN;
			RowState_DP <= RowState_DN;

			OutFifoControl_SO.Write_S <= OutFifoWriteReg_S;

			APSChipRowSRClock_SO <= APSChipRowSRClockReg_S;
			APSChipRowSRIn_SO    <= APSChipRowSRInReg_S;
			APSChipColSRClock_SO <= APSChipColSRClockReg_S;
			APSChipColSRIn_SO    <= APSChipColSRInReg_S;
			APSChipColMode_DO    <= APSChipColModeReg_D;
			APSChipTXGate_SBO    <= APSChipTXGateReg_SB;

			APSADCOutputEnable_SBO <= APSADCOutputEnableReg_SB;
			APSADCStandby_SO       <= APSADCStandbyReg_S;

			-- APS ADC config from another clock domain.
			APSADCConfigReg_D     <= APSADCConfigSyncReg_D;
			APSADCConfigSyncReg_D <= APSADCConfig_DI;
		end if;
	end process p_memoryzing;
end architecture Behavioral;
