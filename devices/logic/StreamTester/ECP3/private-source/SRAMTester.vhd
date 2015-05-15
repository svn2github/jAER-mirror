library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Settings.USB_EVENT_WIDTH;
use work.SRAMControllerOperations.all;

-- To test SRAM, a small state machine runs through all addresses in increasing order
-- and writes the lower 16bit of the address as data. It then reads them all out
-- and sends them out via USB to the host to be verified. It then repeats this cycle
-- as long as the SRAM test is kept running.
entity SRAMTester is
	port(
		Clock_CI              : in    std_logic;
		Reset_RI              : in    std_logic;

		EnableSRAMTest_SI     : in    std_logic;
		FIFOFull_SI           : in    std_logic;
		FIFOWrite_SO          : out   std_logic;
		FIFOData_DO           : out   std_logic_vector(USB_EVENT_WIDTH - 1 downto 0);

		-- Hardware I/O connections (SRAM).
		SRAMChipEnable1_SBO   : out   std_logic;
		SRAMOutputEnable1_SBO : out   std_logic;
		SRAMWriteEnable1_SBO  : out   std_logic;
		SRAMChipEnable2_SBO   : out   std_logic;
		SRAMOutputEnable2_SBO : out   std_logic;
		SRAMWriteEnable2_SBO  : out   std_logic;
		SRAMChipEnable3_SBO   : out   std_logic;
		SRAMOutputEnable3_SBO : out   std_logic;
		SRAMWriteEnable3_SBO  : out   std_logic;
		SRAMChipEnable4_SBO   : out   std_logic;
		SRAMOutputEnable4_SBO : out   std_logic;
		SRAMWriteEnable4_SBO  : out   std_logic;
		SRAMAddress_DO        : out   std_logic_vector(20 downto 0);
		SRAMData_DZIO         : inout std_logic_vector(15 downto 0));
end entity SRAMTester;

architecture Behavioral of SRAMTester is
	attribute syn_enum_encoding : string;

	type tState is (stIdle, stClearInit, stClearDone, stWriteInit, stWriteDone, stReadBackInit, stReadBackDone);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : tState;

	signal Operation_S            : std_logic_vector(SRAMCONTROLLER_OPERATIONS_SIZE - 1 downto 0);
	signal Address_DP, Address_DN : unsigned(21 downto 0);
	signal DataFromSRAM_D         : std_logic_vector(15 downto 0);
	signal ControllerReady_S      : std_logic;

	-- Register outputs to FIFO.
	signal FIFOWriteReg_S : std_logic;
	signal FIFODatReg_D   : std_logic_vector(USB_EVENT_WIDTH - 1 downto 0);
begin
	sramController : entity work.SRAMController
		port map(
			Clock_CI              => Clock_CI,
			Reset_RI              => Reset_RI,
			Operation_SI          => Operation_S,
			Address_DI            => Address_DP,
			Data_DI               => std_logic_vector(Address_DP(15 downto 0)),
			Data_DO               => DataFromSRAM_D,
			Ready_SO              => ControllerReady_S,
			SRAMChipEnable1_SBO   => SRAMChipEnable1_SBO,
			SRAMOutputEnable1_SBO => SRAMOutputEnable1_SBO,
			SRAMWriteEnable1_SBO  => SRAMWriteEnable1_SBO,
			SRAMChipEnable2_SBO   => SRAMChipEnable2_SBO,
			SRAMOutputEnable2_SBO => SRAMOutputEnable2_SBO,
			SRAMWriteEnable2_SBO  => SRAMWriteEnable2_SBO,
			SRAMChipEnable3_SBO   => SRAMChipEnable3_SBO,
			SRAMOutputEnable3_SBO => SRAMOutputEnable3_SBO,
			SRAMWriteEnable3_SBO  => SRAMWriteEnable3_SBO,
			SRAMChipEnable4_SBO   => SRAMChipEnable4_SBO,
			SRAMOutputEnable4_SBO => SRAMOutputEnable4_SBO,
			SRAMWriteEnable4_SBO  => SRAMWriteEnable4_SBO,
			SRAMAddress_DO        => SRAMAddress_DO,
			SRAMData_DZIO         => SRAMData_DZIO);

	sramTester : process(State_DP, EnableSRAMTest_SI, Address_DP, ControllerReady_S, DataFromSRAM_D, FIFOFull_SI)
	begin
		-- Keep register state by default.
		State_DN <= State_DP;

		Address_DN <= Address_DP;

		Operation_S <= SRAMCONTROLLER_OPERATIONS_DO_NOTHING;

		-- FIFO output.
		FIFODatReg_D   <= (others => '0');
		FIFOWriteReg_S <= '0';

		case State_DP is
			when stIdle =>
				Address_DN <= (others => '0');

				if EnableSRAMTest_SI = '1' then
					-- Start by clearing all SRAM.
					State_DN <= stClearInit;
				end if;

			when stClearInit =>
				if ControllerReady_S = '1' then
					Operation_S <= SRAMCONTROLLER_OPERATIONS_CLEAR;
					State_DN    <= stClearDone;
				end if;

			when stClearDone =>
				-- Wait for clearing of memory to be done.
				if ControllerReady_S = '1' then
					State_DN <= stWriteInit;
				end if;

			when stWriteInit =>
				if ControllerReady_S = '1' then
					Operation_S <= SRAMCONTROLLER_OPERATIONS_WRITE;
					State_DN    <= stWriteDone;
				end if;

			when stWriteDone =>
				-- Wait for write to memory to be done.
				if ControllerReady_S = '1' then
					if Address_DP = (Address_DP'range => '1') then
						State_DN   <= stReadBackInit;
						Address_DN <= (others => '0');
					else
						State_DN   <= stWriteInit;
						Address_DN <= Address_DP + 1;
					end if;
				end if;

			when stReadBackInit =>
				if ControllerReady_S = '1' then
					Operation_S <= SRAMCONTROLLER_OPERATIONS_READ;
					State_DN    <= stReadBackDone;
				end if;

			when stReadBackDone =>
				-- Wait for read from memory to be done.
				if ControllerReady_S = '1' then
					if Address_DP = (Address_DP'range => '1') then
						State_DN   <= stIdle;
						Address_DN <= (others => '0');
					elsif FIFOFull_SI = '0' then
						-- Write just read value to FIFO output.
						FIFODatReg_D   <= DataFromSRAM_D;
						FIFOWriteReg_S <= '1';

						State_DN   <= stReadBackInit;
						Address_DN <= Address_DP + 1;
					end if;
				end if;

			when others => null;
		end case;
	end process sramTester;

	registerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then
			State_DP <= stIdle;

			Address_DP <= (others => '0');

			FIFOData_DO  <= (others => '0');
			FIFOWrite_SO <= '0';
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			Address_DP <= Address_DN;

			FIFOData_DO  <= FIFODatReg_D;
			FIFOWrite_SO <= FIFOWriteReg_S;
		end if;
	end process registerUpdate;
end architecture Behavioral;
