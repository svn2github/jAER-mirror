library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;
use work.Settings.LOGIC_CLOCK_FREQ;

entity TimestampSynchronizer is
	port(
		Clock_CI          : in  std_logic;
		Reset_RI          : in  std_logic;

		SyncInClock_CI    : in  std_logic;
		SyncOutClock_CO   : out std_logic;

		DeviceIsMaster_SO : out std_logic;

		TimestampRun_SI   : in  std_logic;
		TimestampReset_SI : in  std_logic;

		TimestampInc_SO   : out std_logic;
		TimestampReset_SO : out std_logic);
end entity TimestampSynchronizer;

architecture Behavioral of TimestampSynchronizer is
	attribute syn_enum_encoding : string;

	type tState is (stRunMaster, stResetSlaves, stRunSlave, stSlaveWaitEdge, stStlaveWaitReset);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- Present and next states.
	signal State_DP, State_DN : tState;

	-- Time constants for synchronization.
	constant SYNC_SQUARE_WAVE_HIGH_TIME     : integer := 50; -- in microseconds (50% duty cycle)
	constant SYNC_SQUARE_WAVE_PERIOD        : integer := 100; -- in microseconds (10 KHz clock)
	constant TS_COUNTER_INCREASE_CYCLES     : integer := LOGIC_CLOCK_FREQ * 1; -- corresponds to 1 microsecond
	constant SYNC_SLAVE_TIMEOUT_CYCLES      : integer := LOGIC_CLOCK_FREQ * 10; -- corresponds to 10 microseconds
	constant SYNC_SLAVE_RESET_CYCLES        : integer := LOGIC_CLOCK_FREQ * 200; -- corresponds to 200 microseconds
	constant SYNC_SLAVE_CONFIRMATION_CYCLES : integer := LOGIC_CLOCK_FREQ * 49; -- corresponds to 49 microseconds

	-- Counters used to produce different timestamp ticks and to remain in a certain state
	-- for a certain amount of time. Divider keeps track of local timestamp increases,
	-- while Counter keeps track of everything else.
	constant DIVIDER_SIZE : integer := integer(ceil(log2(real(TS_COUNTER_INCREASE_CYCLES))));
	constant COUNTER_SIZE : integer := integer(ceil(log2(real(SYNC_SLAVE_RESET_CYCLES))));
	constant CONFIRM_SIZE : integer := integer(ceil(log2(real(SYNC_SLAVE_CONFIRMATION_CYCLES))));

	signal Divider_DP, Divider_DN : unsigned(DIVIDER_SIZE - 1 downto 0);
	signal Counter_DP, Counter_DN : unsigned(COUNTER_SIZE - 1 downto 0);
	signal Confirm_DP, Confirm_DN : unsigned(CONFIRM_SIZE - 1 downto 0);

	-- Register outputs.
	signal SyncOutClockReg_C   : std_logic;
	signal DeviceIsMasterReg_S : std_logic;
begin
	tsSynchronizer : process(State_DP, Divider_DP, Counter_DP, Confirm_DP, SyncInClock_CI, TimestampRun_SI, TimestampReset_SI)
	begin
		State_DN <= State_DP;

		Divider_DN <= Divider_DP;
		Counter_DN <= Counter_DP;
		Confirm_DN <= (others => '0');

		SyncOutClockReg_C <= '0';

		DeviceIsMasterReg_S <= '1';

		TimestampReset_SO <= '0';
		TimestampInc_SO   <= '0';

		case State_DP is
			when stRunMaster =>
				Divider_DN <= Divider_DP + 1;

				if Divider_DP = (TS_COUNTER_INCREASE_CYCLES - 1) then
					Divider_DN <= (others => '0');
					Counter_DN <= Counter_DP + 1;

					if Counter_DP = (SYNC_SQUARE_WAVE_PERIOD - 1) then
						Counter_DN <= (others => '0');
					end if;

					TimestampInc_SO <= TimestampRun_SI; -- increment local timestamp, if running
				end if;

				if Counter_DP < SYNC_SQUARE_WAVE_HIGH_TIME then
					SyncOutClockReg_C <= '0';
				else
					SyncOutClockReg_C <= '1';
				end if;

				if TimestampReset_SI = '1' then
					Counter_DN <= (others => '0');

					State_DN <= stResetSlaves;
				elsif SyncInClock_CI = '0' then
					if Confirm_DP = (SYNC_SLAVE_CONFIRMATION_CYCLES - 1) then
						Divider_DN <= (others => '0');
						Counter_DN <= (others => '0');

						-- Not a master if getting 0 on its input, so a slave.
						State_DN <= stRunSlave;

						TimestampReset_SO <= '1';
					else
						Confirm_DN <= Confirm_DP + 1;
					end if;
				end if;

			when stResetSlaves =>
				-- Reset slaves by generating at least a 200 microsecond high on output, which slaves should detect.
				SyncOutClockReg_C <= '1';

				Counter_DN <= Counter_DP + 1;

				if Counter_DP = (SYNC_SLAVE_RESET_CYCLES - 1) then
					Divider_DN <= (others => '0');
					Counter_DN <= (others => '0');

					State_DN <= stRunMaster;

					TimestampReset_SO <= '1';
				end if;

			when stRunSlave =>
				DeviceIsMasterReg_S <= '0';

				SyncOutClockReg_C <= SyncInClock_CI;
				TimestampReset_SO <= TimestampReset_SI;

				Divider_DN <= Divider_DP + 1;

				if Divider_DP = (TS_COUNTER_INCREASE_CYCLES - 1) then
					Divider_DN <= (others => '0');
					Counter_DN <= Counter_DP + 1;

					TimestampInc_SO <= TimestampRun_SI; -- increment local timestamp, if running
				end if;

				if Counter_DP = (SYNC_SQUARE_WAVE_PERIOD - 1) then
					Counter_DN <= (others => '0');

					State_DN <= stSlaveWaitEdge;
				end if;

			when stSlaveWaitEdge =>
				DeviceIsMasterReg_S <= '0';

				SyncOutClockReg_C <= SyncInClock_CI;
				TimestampReset_SO <= TimestampReset_SI;

				Counter_DN <= Counter_DP + 1;

				if Counter_DP = (SYNC_SLAVE_TIMEOUT_CYCLES - 1) then
					Counter_DN <= (others => '0');

					-- No acknowledgement from master. Either resetting timestamps or
					-- lost connection, in which case, become master.
					State_DN <= stStlaveWaitReset;
				elsif SyncInClock_CI = '0' then
					Divider_DN <= (others => '0');
					Counter_DN <= (others => '0');

					State_DN <= stRunSlave;

					TimestampInc_SO <= TimestampRun_SI; -- increment local timestamp, if running
				end if;

			when stStlaveWaitReset =>
				DeviceIsMasterReg_S <= '0';

				SyncOutClockReg_C <= SyncInClock_CI;

				Counter_DN <= Counter_DP + 1;

				if SyncInClock_CI = '0' then
					-- Slave TS reset from master.
					Divider_DN <= (others => '0');
					Counter_DN <= (others => '0');

					State_DN <= stRunSlave;

					TimestampReset_SO <= '1';
				elsif Counter_DP = (SYNC_SLAVE_RESET_CYCLES - 1) then
					-- Lost connection, become master (after making sure that it's not just a reset).
					Divider_DN <= (others => '0');
					Counter_DN <= (others => '0');

					State_DN <= stRunMaster;

					TimestampReset_SO <= '1';
				end if;
		end case;
	end process tsSynchronizer;

	registerUpdate : process(Clock_CI, Reset_RI)
	begin
		if Reset_RI = '1' then
			State_DP <= stRunMaster;

			Divider_DP <= (others => '0');
			Counter_DP <= (others => '0');
			Confirm_DP <= (others => '0');

			SyncOutClock_CO <= '0';

			DeviceIsMaster_SO <= '1';
		elsif rising_edge(Clock_CI) then -- rising clock edge
			State_DP <= State_DN;

			Divider_DP <= Divider_DN;
			Counter_DP <= Counter_DN;
			Confirm_DP <= Confirm_DN;

			SyncOutClock_CO <= SyncOutClockReg_C;

			DeviceIsMaster_SO <= DeviceIsMasterReg_S;
		end if;
	end process registerUpdate;
end architecture Behavioral;
