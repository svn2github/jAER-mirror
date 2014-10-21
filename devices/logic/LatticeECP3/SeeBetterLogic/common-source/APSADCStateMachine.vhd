library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.EventCodes.all;
use work.FIFORecords.all;
use work.APSADCConfigRecords.all;
use work.Settings.CHIP_SIZE_COLUMNS;
use work.Settings.CHIP_SIZE_ROWS;

entity APSADCStateMachine is
	generic(
		ADC_BUS_WIDTH : integer);
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

	type tState is (stIdle, stWriteEvent);
	attribute syn_enum_encoding of tState : type is "onehot";

	constant CHIP_REG_SIZE_COLUMNS : integer := 1 + CHIP_SIZE_COLUMNS + 1; -- One bit more on each side, for three-bit code.
	constant CHIP_REG_SIZE_ROWS    : integer := CHIP_SIZE_ROWS;

	constant COLMODE_NULL   : std_logic_vector(1 downto 0) := "00";
	constant COLMODE_READA  : std_logic_vector(1 downto 0) := "01";
	constant COLMODE_READB  : std_logic_vector(1 downto 0) := "10";
	constant COLMODE_RESETA : std_logic_vector(1 downto 0) := "11";

	-- present and next state
	signal State_DP, State_DN : tState;

	-- Register all outputs for clean transitions.
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

	columnMainStateMachine : process(State_DP, OutFifoControl_SI)
	begin
		State_DN <= State_DP;           -- Keep current state by default.

		APSChipColSRClockReg_S <= '0';
		APSChipColSRInReg_S    <= '0';
		APSChipColModeReg_D    <= COLMODE_NULL;
		APSChipTXGateReg_SB    <= '1';

		APSADCOutputEnableReg_SB <= '1';
		APSADCStandbyReg_S       <= '1';

		OutFifoControl_SO.Write_S <= '0';
		OutFifoData_DO            <= (others => '0');

		case State_DP is
			when stIdle =>
			-- Only exit idle state if APS data producer is active.
			--if APSRun_SI = '1' then
			--if OutFifo_I.Full_S = '0' then
			-- If output fifo full, just wait for it to be empty.
			--State_DN <= stWriteEvent;
			--end if;
			--end if;

			when stWriteEvent =>
				OutFifoData_DO            <= (others => '0');
				OutFifoControl_SO.Write_S <= '1';
				State_DN                  <= stIdle;

			when others => null;
		end case;
	end process columnMainStateMachine;

	rowReadStateMachine : process is
	begin
		APSChipRowSRClockReg_S <= '0';
		APSChipRowSRInReg_S    <= '0';
	end process rowReadStateMachine;

	-- Change state on clock edge (synchronous).
	p_memoryzing : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active-high for FPGAs)
			State_DP <= stIdle;

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
			State_DP <= State_DN;

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
