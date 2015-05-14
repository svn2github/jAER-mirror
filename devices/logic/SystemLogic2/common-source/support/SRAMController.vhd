library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SRAMControllerOperations.all;

entity SRAMController is
	port(
		Clock_CI              : in    std_logic;
		Reset_RI              : in    std_logic;

		-- Control interface.
		Operation_SI          : in    std_logic_vector(SRAMCONTROLLER_OPERATIONS_SIZE - 1 downto 0); -- Operation to execute.
		Address_DI            : in    unsigned(21 downto 0); -- Address to operate on, out of 8MByte of SRAM (address 0x000000-0x3FFFFF).
		Data_DI               : in    std_logic_vector(15 downto 0); -- Input data for write operations.
		Data_DO               : out   std_logic_vector(15 downto 0); -- Output data from read operations.
		Ready_SO              : out   std_logic; -- Controller ready for memory operation.

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
end entity SRAMController;

architecture Behavioral of SRAMController is
	attribute syn_enum_encoding : string;

	type tState is (stIdle, stRead1, stWrite1, stRead2, stWrite2, stClear1, stClear2, stClear3);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : tState;

	-- Register all outputs.
	signal SRAMChipEnable12Reg_SP, SRAMChipEnable12Reg_SN     : std_logic;
	signal SRAMChipEnable34Reg_SP, SRAMChipEnable34Reg_SN     : std_logic;
	signal SRAMOutputEnable12Reg_SP, SRAMOutputEnable12Reg_SN : std_logic;
	signal SRAMOutputEnable34Reg_SP, SRAMOutputEnable34Reg_SN : std_logic;
	signal SRAMWriteEnable12Reg_SP, SRAMWriteEnable12Reg_SN   : std_logic;
	signal SRAMWriteEnable34Reg_SP, SRAMWriteEnable34Reg_SN   : std_logic;
	signal SRAMAddressReg_DP, SRAMAddressReg_DN               : unsigned(20 downto 0);
	signal SRAMDataOutReg_DP, SRAMDataOutReg_DN               : std_logic_vector(15 downto 0);
	signal SRAMDataInReg_DP, SRAMDataInReg_DN                 : std_logic_vector(15 downto 0);
	signal ControllerReady_SP, ControllerReady_SN             : std_logic;
begin
	sramControl : process(State_DP, Operation_SI, Address_DI, Data_DI, ControllerReady_SP, SRAMAddressReg_DP, SRAMChipEnable12Reg_SP, SRAMChipEnable34Reg_SP, SRAMDataInReg_DP, SRAMDataOutReg_DP, SRAMOutputEnable12Reg_SP, SRAMOutputEnable34Reg_SP, SRAMWriteEnable12Reg_SP, SRAMWriteEnable34Reg_SP, SRAMData_DZIO)
	begin
		-- All registers keep their state by default.
		State_DN <= State_DP;

		SRAMChipEnable12Reg_SN <= SRAMChipEnable12Reg_SP;
		SRAMChipEnable34Reg_SN <= SRAMChipEnable34Reg_SP;

		SRAMOutputEnable12Reg_SN <= SRAMOutputEnable12Reg_SP;
		SRAMOutputEnable34Reg_SN <= SRAMOutputEnable34Reg_SP;

		SRAMWriteEnable12Reg_SN <= SRAMWriteEnable12Reg_SP;
		SRAMWriteEnable34Reg_SN <= SRAMWriteEnable34Reg_SP;

		SRAMAddressReg_DN <= SRAMAddressReg_DP;

		SRAMDataOutReg_DN <= SRAMDataOutReg_DP;
		SRAMDataInReg_DN  <= SRAMDataInReg_DP;

		ControllerReady_SN <= ControllerReady_SP;

		case State_DP is
			when stIdle =>
				-- Ensure everything is disabled to conserve power,
				-- unless we exit this state (code below).
				SRAMChipEnable12Reg_SN   <= '0';
				SRAMChipEnable34Reg_SN   <= '0';
				SRAMOutputEnable12Reg_SN <= '0';
				SRAMOutputEnable34Reg_SN <= '0';
				SRAMWriteEnable12Reg_SN  <= '0';
				SRAMWriteEnable34Reg_SN  <= '0';
				SRAMAddressReg_DN        <= (others => '0');
				SRAMDataOutReg_DN        <= (others => 'Z');

				if Operation_SI = SRAMCONTROLLER_OPERATIONS_READ or Operation_SI = SRAMCONTROLLER_OPERATIONS_WRITE then
					-- On next cycle, we'll start a new memory operation, so
					-- we're not ready for a new one. Also invalidate the content
					-- of the register containing the result of the last read at
					-- this point, since it may only be considered valid when the
					-- ControllerReady flag is set.
					ControllerReady_SN <= '0';
					SRAMDataInReg_DN   <= (others => '0');

					-- Record address on which to operate (lower 21 bits).
					SRAMAddressReg_DN <= Address_DI(20 downto 0);

					-- Highest address bit decides which SRAM chips are selected.
					SRAMChipEnable12Reg_SN <= not Address_DI(21);
					SRAMChipEnable34Reg_SN <= Address_DI(21);

					if Operation_SI = SRAMCONTROLLER_OPERATIONS_READ then
						-- Read operation.
						SRAMOutputEnable12Reg_SN <= not Address_DI(21);
						SRAMOutputEnable34Reg_SN <= Address_DI(21);

						State_DN <= stRead1;
					else
						-- Write operation. Also set data output.
						SRAMWriteEnable12Reg_SN <= not Address_DI(21);
						SRAMWriteEnable34Reg_SN <= Address_DI(21);

						SRAMDataOutReg_DN <= Data_DI;

						State_DN <= stWrite1;
					end if;
				elsif Operation_SI = SRAMCONTROLLER_OPERATIONS_CLEAR then
					ControllerReady_SN <= '0';
					SRAMDataInReg_DN   <= (others => '0');

					-- Start clearing at address 0x000000.
					SRAMAddressReg_DN <= (others => '0');

					-- Always write zeros.
					SRAMDataOutReg_DN <= (others => '0');

					-- Access both chip pairs at the same time, so we clear four bytes
					-- per write cycle, halving the time needed to complete the operation.
					SRAMChipEnable12Reg_SN <= '1';
					SRAMChipEnable34Reg_SN <= '1';

					-- Control of WriteEnable is left to the clear states.
					State_DN <= stClear1;
				end if;

			when stRead1 =>
				-- Wait one full cycle without changing anything.
				State_DN <= stRead2;

			when stRead2 =>
				State_DN <= stIdle;

				-- We are ready again on the next cycle.
				ControllerReady_SN <= '1';

				-- In this state we get the data (register updated on next
				-- clock cycle).
				SRAMDataInReg_DN <= SRAMData_DZIO;

				-- Reset common signals to default.
				SRAMChipEnable12Reg_SN   <= '0';
				SRAMChipEnable34Reg_SN   <= '0';
				SRAMOutputEnable12Reg_SN <= '0';
				SRAMOutputEnable34Reg_SN <= '0';
				SRAMAddressReg_DN        <= (others => '0');

			when stWrite1 =>
				-- Wait one full cycle without changing anything.
				State_DN <= stWrite2;

			when stWrite2 =>
				State_DN <= stIdle;

				-- We are ready again on the next cycle.
				ControllerReady_SN <= '1';

				-- Reset data out to tri-state (default state) for next cycle.
				SRAMDataOutReg_DN <= (others => 'Z');

				-- Reset common signals to default.
				SRAMChipEnable12Reg_SN  <= '0';
				SRAMChipEnable34Reg_SN  <= '0';
				SRAMWriteEnable12Reg_SN <= '0';
				SRAMWriteEnable34Reg_SN <= '0';
				SRAMAddressReg_DN       <= (others => '0');

			when stClear1 =>
				-- WriteEnable has to be toggled for each address, since SRAM
				-- doesn't support burst-writes. So we control it here.
				SRAMWriteEnable12Reg_SN <= '1';
				SRAMWriteEnable34Reg_SN <= '1';

				State_DN <= stClear2;

			when stClear2 =>
				-- Wait one full cycle without changing anything.
				State_DN <= stClear3;

			when stClear3 =>
				SRAMWriteEnable12Reg_SN <= '0';
				SRAMWriteEnable34Reg_SN <= '0';

				-- Check if we're done clearing or if we still have to loop.
				if SRAMAddressReg_DP = (SRAMAddressReg_DP'range => '1') then
					-- Highest address cleared, exit.
					State_DN <= stIdle;

					-- We are ready again on the next cycle.
					ControllerReady_SN <= '1';

					-- Reset data out to tri-state (default state) for next cycle.
					SRAMDataOutReg_DN <= (others => 'Z');

					-- Reset common signals to default.
					SRAMChipEnable12Reg_SN <= '0';
					SRAMChipEnable34Reg_SN <= '0';
					SRAMAddressReg_DN      <= (others => '0');
				else
					-- Not finished with clearing, continue looping.
					State_DN <= stClear1;

					-- Increment address by one (next address).
					SRAMAddressReg_DN <= SRAMAddressReg_DP + 1;
				end if;

			when others => null;
		end case;
	end process sramControl;

	registerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then
			State_DP <= stIdle;

			SRAMChipEnable12Reg_SP <= '0';
			SRAMChipEnable34Reg_SP <= '0';

			SRAMOutputEnable12Reg_SP <= '0';
			SRAMOutputEnable34Reg_SP <= '0';

			SRAMWriteEnable12Reg_SP <= '0';
			SRAMWriteEnable34Reg_SP <= '0';

			SRAMAddressReg_DP <= (others => '0');

			SRAMDataOutReg_DP <= (others => 'Z');
			SRAMDataInReg_DP  <= (others => '0');

			ControllerReady_SP <= '1';
		elsif rising_edge(Clock_CI) then
			State_DP <= State_DN;

			SRAMChipEnable12Reg_SP <= SRAMChipEnable12Reg_SN;
			SRAMChipEnable34Reg_SP <= SRAMChipEnable34Reg_SN;

			SRAMOutputEnable12Reg_SP <= SRAMOutputEnable12Reg_SN;
			SRAMOutputEnable34Reg_SP <= SRAMOutputEnable34Reg_SN;

			SRAMWriteEnable12Reg_SP <= SRAMWriteEnable12Reg_SN;
			SRAMWriteEnable34Reg_SP <= SRAMWriteEnable34Reg_SN;

			SRAMAddressReg_DP <= SRAMAddressReg_DN;

			SRAMDataOutReg_DP <= SRAMDataOutReg_DN;
			SRAMDataInReg_DP  <= SRAMDataInReg_DN;

			ControllerReady_SP <= ControllerReady_SN;
		end if;
	end process registerUpdate;

	-- Link outputs to registers.
	SRAMChipEnable1_SBO <= not SRAMChipEnable12Reg_SP;
	SRAMChipEnable2_SBO <= not SRAMChipEnable12Reg_SP;
	SRAMChipEnable3_SBO <= not SRAMChipEnable34Reg_SP;
	SRAMChipEnable4_SBO <= not SRAMChipEnable34Reg_SP;

	SRAMOutputEnable1_SBO <= not SRAMOutputEnable12Reg_SP;
	SRAMOutputEnable2_SBO <= not SRAMOutputEnable12Reg_SP;
	SRAMOutputEnable3_SBO <= not SRAMOutputEnable34Reg_SP;
	SRAMOutputEnable4_SBO <= not SRAMOutputEnable34Reg_SP;

	SRAMWriteEnable1_SBO <= not SRAMWriteEnable12Reg_SP;
	SRAMWriteEnable2_SBO <= not SRAMWriteEnable12Reg_SP;
	SRAMWriteEnable3_SBO <= not SRAMWriteEnable34Reg_SP;
	SRAMWriteEnable4_SBO <= not SRAMWriteEnable34Reg_SP;

	SRAMAddress_DO <= std_logic_vector(SRAMAddressReg_DP);

	SRAMData_DZIO <= SRAMDataOutReg_DP;
	Data_DO       <= SRAMDataInReg_DP;

	Ready_SO <= ControllerReady_SP;
end architecture Behavioral;
