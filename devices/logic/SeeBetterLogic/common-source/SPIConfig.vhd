library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ShiftRegisterModes.all;

entity SPIConfig is
	port(
		Clock_CI               : in  std_logic;
		Reset_RI               : in  std_logic;

		-- SPI ports
		SPISlaveSelect_SBI     : in  std_logic;
		SPIClock_CI            : in  std_logic;
		SPIMOSI_DI             : in  std_logic;
		SPIMISO_DZO            : out std_logic;

		-- Configuration inputs and outputs
		ConfigModuleAddress_DO : out unsigned(6 downto 0);
		ConfigParamAddress_DO  : out unsigned(7 downto 0);
		ConfigParamInput_DO    : out std_logic_vector(31 downto 0);
		ConfigLatchInput_SO    : out std_logic;
		ConfigParamOutput_DI   : in  std_logic_vector(31 downto 0));
end entity SPIConfig;

architecture Behavioral of SPIConfig is
	attribute syn_enum_encoding : string;

	type tState is (stIdle, stInput, stInputLatch, stOutput);
	attribute syn_enum_encoding of tState : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : tState;

	signal SPIClockRisingEdges_S, SPIClockFallingEdges_S : std_logic;
	signal SPIReadMOSI_S, SPIWriteMISO_S                 : std_logic;
	signal SPIInputSRegMode_S                            : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0);
	signal SPIInputContent_D                             : std_logic_vector(7 downto 0);
	signal SPIOutputSRegMode_S                           : std_logic_vector(SHIFTREGISTER_MODE_SIZE - 1 downto 0);
	signal SPIOutputContent_D                            : std_logic_vector(31 downto 0);
	signal SPIBitCounterClear_S, SPIBitCounterEnable_S   : std_logic;
	signal SPIBitCount_D                                 : unsigned(5 downto 0);

	signal ReadOperationReg_SP, ReadOperationReg_SN : std_logic;
	signal ModuleAddressReg_DP, ModuleAddressReg_DN : unsigned(6 downto 0);
	signal ParamAddressReg_DP, ParamAddressReg_DN   : unsigned(7 downto 0);

	signal LatchInputReg_SP, LatchInputReg_SN : std_logic;
	signal ParamInput_DP, ParamInput_DN       : std_logic_vector(31 downto 0);

	signal ParamOutput_DP, ParamOutput_DN : std_logic_vector(31 downto 0);

	-- Register outputs (MISO only here).
	signal SPIMISOReg_DZ : std_logic;
begin
	ConfigModuleAddress_DO <= ModuleAddressReg_DP;
	ConfigParamAddress_DO  <= ParamAddressReg_DP;
	ConfigParamInput_DO    <= ParamInput_DP;
	ConfigLatchInput_SO    <= LatchInputReg_SP;
	ParamOutput_DN         <= ConfigParamOutput_DI;

	-- The SPI input lines have already been synchronized to the logic clock at
	-- this point, so we can use and sample them directly.
	spiClockDetector : entity work.EdgeDetector
		port map(
			Clock_CI               => Clock_CI,
			Reset_RI               => Reset_RI,
			InputSignal_SI         => SPIClock_CI,
			RisingEdgeDetected_SO  => SPIClockRisingEdges_S,
			FallingEdgeDetected_SO => SPIClockFallingEdges_S);

	-- We support SPI mode 0 (CPOL=0, CPHA=0). So we sample data on the rising
	-- edge and we output data on the falling one. Of course, only if this
	-- device's slave select line is enabled (active-low).
	SPIReadMOSI_S  <= SPIClockRisingEdges_S and not SPISlaveSelect_SBI;
	SPIWriteMISO_S <= SPIClockFallingEdges_S and not SPISlaveSelect_SBI;

	spiInputShiftRegister : entity work.ShiftRegister
		generic map(
			SIZE => SPIInputContent_D'length)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			Mode_SI          => SPIInputSRegMode_S,
			DataIn_DI        => SPIMOSI_DI,
			ParallelWrite_DI => (others => '0'),
			ParallelRead_DO  => SPIInputContent_D);

	spiOutputShiftRegister : entity work.ShiftRegister
		generic map(
			SIZE => SPIOutputContent_D'length)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			Mode_SI          => SPIOutputSRegMode_S,
			DataIn_DI        => '0',
			ParallelWrite_DI => ParamOutput_DP,
			ParallelRead_DO  => SPIOutputContent_D);

	spiBitCounter : entity work.ContinuousCounter
		generic map(
			SIZE              => SPIBitCount_D'length,
			GENERATE_OVERFLOW => false)
		port map(
			Clock_CI     => Clock_CI,
			Reset_RI     => Reset_RI,
			Clear_SI     => SPIBitCounterClear_S,
			Enable_SI    => SPIBitCounterEnable_S,
			DataLimit_DI => (others => '1'),
			Overflow_SO  => open,
			Data_DO      => SPIBitCount_D);

	spiCommunication : process(State_DP, SPIInputContent_D, SPIOutputContent_D, SPIBitCount_D, SPISlaveSelect_SBI, SPIReadMOSI_S, SPIWriteMISO_S, ReadOperationReg_SP, ModuleAddressReg_DP, ParamAddressReg_DP, ParamInput_DP)
	begin
		-- Keep state by default.
		State_DN <= State_DP;

		-- Keep all registers at current value by default.
		ReadOperationReg_SN <= ReadOperationReg_SP;
		ModuleAddressReg_DN <= ModuleAddressReg_DP;
		ParamAddressReg_DN  <= ParamAddressReg_DP;

		LatchInputReg_SN <= '0';
		ParamInput_DN    <= ParamInput_DP;

		-- SPI output is Hi-Z by default.
		SPIMISOReg_DZ <= 'Z';

		-- Keep the input elements (shift register and counter) fixed.
		SPIInputSRegMode_S    <= SHIFTREGISTER_MODE_DO_NOTHING;
		SPIOutputSRegMode_S   <= SHIFTREGISTER_MODE_DO_NOTHING;
		SPIBitCounterClear_S  <= '0';
		SPIBitCounterEnable_S <= '0';

		case State_DP is
			when stIdle =>
				-- If this SPI slave gets selected, start observing the clock
				-- and input lines.
				if SPISlaveSelect_SBI = '0' then
					State_DN <= stInput;
				end if;

				-- Keep input elements clear while idling.
				SPIInputSRegMode_S   <= SHIFTREGISTER_MODE_PARALLEL_CLEAR;
				SPIOutputSRegMode_S  <= SHIFTREGISTER_MODE_PARALLEL_CLEAR;
				SPIBitCounterClear_S <= '1';

			when stInput =>
				-- Push a zero out on the SPI bus, when there is nothing
				-- concrete to output. We're reading input right now.
				SPIMISOReg_DZ <= '0';

				if SPIReadMOSI_S = '1' then
					SPIInputSRegMode_S <= SHIFTREGISTER_MODE_SHIFT_LEFT;

					SPIBitCounterEnable_S <= '1';
				end if;

				case SPIBitCount_D is
					when to_unsigned(8, 6) =>
						ReadOperationReg_SN <= SPIInputContent_D(7);
						ModuleAddressReg_DN <= unsigned(SPIInputContent_D(6 downto 0));

					when to_unsigned(16, 6) =>
						ParamAddressReg_DN <= unsigned(SPIInputContent_D(7 downto 0));

						if ReadOperationReg_SP = '1' then
							State_DN <= stOutput;
						end if;

					when to_unsigned(24, 6) =>
						ParamInput_DN(31 downto 24) <= SPIInputContent_D(7 downto 0);

					when to_unsigned(32, 6) =>
						ParamInput_DN(23 downto 16) <= SPIInputContent_D(7 downto 0);

					when to_unsigned(40, 6) =>
						ParamInput_DN(15 downto 8) <= SPIInputContent_D(7 downto 0);

					when to_unsigned(48, 6) =>
						ParamInput_DN(7 downto 0) <= SPIInputContent_D(7 downto 0);

						-- And we're done, so copy the input to the config register.
						State_DN <= stInputLatch;

					when others => null;
				end case;

			when stInputLatch =>
				-- This has its own state, because we want to delay it by one cycle,
				-- to give time to the ParamInput to propagate down to the various'
				-- modules input registers.
				LatchInputReg_SN <= '1';

				State_DN <= stIdle;

			when stOutput =>
				-- Push out MSB to MISO.
				SPIMISOReg_DZ <= SPIOutputContent_D(31);

				if SPIWriteMISO_S = '1' then
					if SPIBitCount_D = to_unsigned(16, 6) then
						SPIOutputSRegMode_S <= SHIFTREGISTER_MODE_PARALLEL_LOAD;
					else
						SPIOutputSRegMode_S <= SHIFTREGISTER_MODE_SHIFT_LEFT;
					end if;

					SPIBitCounterEnable_S <= '1';
				end if;

				-- On the 48th falling edge, when we can exit the output state,
				-- the counter will be at 49, because we started counting
				-- rising edges above and then switched to falling ones,
				-- loosing one. Another way to see this, is that when this is
				-- 48, we start outputting the 48th and last bit, and we are on
				-- the 47th falling edge, so we need to keep that stable until
				-- the 48th falling edge, which is when the counter changes to 49.
				if SPIBitCount_D = to_unsigned(49, 6) then
					State_DN <= stIdle;
				end if;

			when others => null;
		end case;
	end process spiCommunication;

	spiUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			State_DP <= stIdle;

			ReadOperationReg_SP <= '0';
			ModuleAddressReg_DP <= (others => '1');
			ParamAddressReg_DP  <= (others => '1');

			LatchInputReg_SP <= '0';
			ParamInput_DP    <= (others => '0');

			ParamOutput_DP <= (others => '0');
			SPIMISO_DZO    <= 'Z';
		elsif rising_edge(Clock_CI) then -- rising clock edge
			State_DP <= State_DN;

			ReadOperationReg_SP <= ReadOperationReg_SN;
			ModuleAddressReg_DP <= ModuleAddressReg_DN;
			ParamAddressReg_DP  <= ParamAddressReg_DN;

			LatchInputReg_SP <= LatchInputReg_SN;
			ParamInput_DP    <= ParamInput_DN;

			ParamOutput_DP <= ParamOutput_DN;
			SPIMISO_DZO    <= SPIMISOReg_DZ;
		end if;
	end process spiUpdate;
end architecture Behavioral;
