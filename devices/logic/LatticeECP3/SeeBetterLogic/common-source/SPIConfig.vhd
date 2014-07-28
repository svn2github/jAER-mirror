library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ShiftRegisterModes.all;
use work.MultiplexerConfigRecords.all;
use work.DVSAERConfigRecords.all;
use work.ChipBiasConfigRecords.all;

entity SPIConfig is
	port(
		Clock_CI             : in  std_logic;
		Reset_RI             : in  std_logic;

		-- SPI ports
		SPISlaveSelect_SBI   : in  std_logic;
		SPIClock_CI          : in  std_logic;
		SPIMOSI_DI           : in  std_logic;
		SPIMISO_ZO           : out std_logic;

		-- Configuration modules outputs
		MultiplexerConfig_DO : out tMultiplexerConfig;
		DVSAERConfig_DO      : out tDVSAERConfig;
		BiasConfig_DO        : out tBiasConfig;
		ChipConfig_DO        : out tChipConfig);
end entity SPIConfig;

architecture Behavioral of SPIConfig is
	type state is (stIdle, stInput, stInputLatch, stOutput);

	attribute syn_enum_encoding : string;
	attribute syn_enum_encoding of state : type is "onehot";

	-- present and next state
	signal State_DP, State_DN : state;

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
	signal SPIMISOReg_Z : std_logic;

	-- Configuration modules registers
	signal LatchMultiplexerReg_SP, LatchMultiplexerReg_SN   : std_logic;
	signal MultiplexerInput_DP, MultiplexerInput_DN         : std_logic_vector(31 downto 0);
	signal MultiplexerOutput_DP, MultiplexerOutput_DN       : std_logic_vector(31 downto 0);
	signal MultiplexerConfigReg_DP, MultiplexerConfigReg_DN : tMultiplexerConfig;

	signal LatchDVSAERReg_SP, LatchDVSAERReg_SN   : std_logic;
	signal DVSAERInput_DP, DVSAERInput_DN         : std_logic_vector(31 downto 0);
	signal DVSAEROutput_DP, DVSAEROutput_DN       : std_logic_vector(31 downto 0);
	signal DVSAERConfigReg_DP, DVSAERConfigReg_DN : tDVSAERConfig;

	signal LatchBiasReg_SP, LatchBiasReg_SN   : std_logic;
	signal BiasInput_DP, BiasInput_DN         : std_logic_vector(31 downto 0);
	signal BiasOutput_DP, BiasOutput_DN       : std_logic_vector(31 downto 0);
	signal BiasConfigReg_DP, BiasConfigReg_DN : tBiasConfig;

	signal LatchChipReg_SP, LatchChipReg_SN   : std_logic;
	signal ChipInput_DP, ChipInput_DN         : std_logic_vector(31 downto 0);
	signal ChipOutput_DP, ChipOutput_DN       : std_logic_vector(31 downto 0);
	signal ChipConfigReg_DP, ChipConfigReg_DN : tChipConfig;
begin                                   -- architecture Behavioral
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
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			Mode_SI          => SPIInputSRegMode_S,
			DataIn_DI        => SPIMOSI_DI,
			ParallelWrite_DI => (others => '0'),
			ParallelRead_DO  => SPIInputContent_D);

	spiOutputShiftRegister : entity work.ShiftRegister
		generic map(
			SIZE => 32)
		port map(
			Clock_CI         => Clock_CI,
			Reset_RI         => Reset_RI,
			Mode_SI          => SPIOutputSRegMode_S,
			DataIn_DI        => '0',
			ParallelWrite_DI => ParamOutput_DP,
			ParallelRead_DO  => SPIOutputContent_D);

	spiBitCounter : entity work.ContinuousCounter
		generic map(
			COUNTER_WIDTH  => 6,
			SHORT_OVERFLOW => true)
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
		SPIMISOReg_Z <= 'Z';

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
				SPIMISOReg_Z <= '0';

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
				SPIMISOReg_Z <= SPIOutputContent_D(31);

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
			SPIMISO_ZO     <= 'Z';
		elsif rising_edge(Clock_CI) then -- rising clock edge
			State_DP <= State_DN;

			ReadOperationReg_SP <= ReadOperationReg_SN;
			ModuleAddressReg_DP <= ModuleAddressReg_DN;
			ParamAddressReg_DP  <= ParamAddressReg_DN;

			LatchInputReg_SP <= LatchInputReg_SN;
			ParamInput_DP    <= ParamInput_DN;

			ParamOutput_DP <= ParamOutput_DN;
			SPIMISO_ZO     <= SPIMISOReg_Z;
		end if;
	end process spiUpdate;

	configReadWrite : process(ModuleAddressReg_DP, ParamAddressReg_DP, DVSAEROutput_DP, MultiplexerOutput_DP, BiasOutput_DP, ChipOutput_DP)
	begin
		-- Input side select.
		LatchMultiplexerReg_SN <= '0';
		LatchDVSAERReg_SN      <= '0';
		LatchBiasReg_SN        <= '0';
		LatchChipReg_SN        <= '0';

		case ModuleAddressReg_DP is
			when MULTIPLEXERCONFIG_MODULE_ADDRESS =>
				LatchMultiplexerReg_SN <= '1';

			when DVSAERCONFIG_MODULE_ADDRESS =>
				LatchDVSAERReg_SN <= '1';

			when CHIPBIASCONFIG_MODULE_ADDRESS =>
				if ParamAddressReg_DP(7) = '0' then
					LatchBiasReg_SN <= '1';
				else
					LatchChipReg_SN <= '1';
				end if;

			when others => null;
		end case;

		-- Output side select.
		ParamOutput_DN <= (others => '0');

		case ModuleAddressReg_DP is
			when MULTIPLEXERCONFIG_MODULE_ADDRESS =>
				ParamOutput_DN <= MultiplexerOutput_DP;

			when DVSAERCONFIG_MODULE_ADDRESS =>
				ParamOutput_DN <= DVSAEROutput_DP;

			when CHIPBIASCONFIG_MODULE_ADDRESS =>
				if ParamAddressReg_DP(7) = '0' then
					ParamOutput_DN <= BiasOutput_DP;
				else
					ParamOutput_DN <= ChipOutput_DP;
				end if;

			when others => null;
		end case;
	end process configReadWrite;

	multiplexerIO : process(ParamAddressReg_DP, ParamInput_DP, MultiplexerInput_DP, MultiplexerConfigReg_DP)
	begin
		MultiplexerConfigReg_DN <= MultiplexerConfigReg_DP;
		MultiplexerInput_DN     <= ParamInput_DP;
		MultiplexerOutput_DN    <= (others => '0');

		case ParamAddressReg_DP is
			when MULTIPLEXERCONFIG_PARAM_ADDRESSES.Run_S =>
				MultiplexerConfigReg_DN.Run_S <= MultiplexerInput_DP(0);
				MultiplexerOutput_DN(0)       <= MultiplexerConfigReg_DP.Run_S;

			when MULTIPLEXERCONFIG_PARAM_ADDRESSES.TimestampRun_S =>
				MultiplexerConfigReg_DN.TimestampRun_S <= MultiplexerInput_DP(0);
				MultiplexerOutput_DN(0)                <= MultiplexerConfigReg_DP.TimestampRun_S;

			when MULTIPLEXERCONFIG_PARAM_ADDRESSES.TimestampReset_S =>
				MultiplexerConfigReg_DN.TimestampReset_S <= MultiplexerInput_DP(0);
				MultiplexerOutput_DN(0)                  <= MultiplexerConfigReg_DP.TimestampReset_S;

			when others => null;
		end case;
	end process multiplexerIO;

	multiplexerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			LatchMultiplexerReg_SP <= '0';
			MultiplexerInput_DP    <= (others => '0');
			MultiplexerOutput_DP   <= (others => '0');

			MultiplexerConfigReg_DP <= tMultiplexerConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			LatchMultiplexerReg_SP <= LatchMultiplexerReg_SN;
			MultiplexerInput_DP    <= MultiplexerInput_DN;
			MultiplexerOutput_DP   <= MultiplexerOutput_DN;

			if LatchMultiplexerReg_SP = '1' and LatchInputReg_SP = '1' then
				MultiplexerConfigReg_DP <= MultiplexerConfigReg_DN;
			end if;
		end if;
	end process multiplexerUpdate;

	dvsaerIO : process(ParamAddressReg_DP, ParamInput_DP, DVSAERInput_DP, DVSAERConfigReg_DP)
	begin
		DVSAERConfigReg_DN <= DVSAERConfigReg_DP;
		DVSAERInput_DN     <= ParamInput_DP;
		DVSAEROutput_DN    <= (others => '0');

		case ParamAddressReg_DP is
			when DVSAERCONFIG_PARAM_ADDRESSES.Run_S =>
				DVSAERConfigReg_DN.Run_S <= DVSAERInput_DP(0);
				DVSAEROutput_DN(0)       <= DVSAERConfigReg_DP.Run_S;

			when DVSAERCONFIG_PARAM_ADDRESSES.AckDelay_D =>
				DVSAERConfigReg_DN.AckDelay_D                                 <= unsigned(DVSAERInput_DP(tDVSAERConfig.AckDelay_D'length - 1 downto 0));
				DVSAEROutput_DN(tDVSAERConfig.AckDelay_D'length - 1 downto 0) <= std_logic_vector(DVSAERConfigReg_DP.AckDelay_D);

			when DVSAERCONFIG_PARAM_ADDRESSES.AckExtension_D =>
				DVSAERConfigReg_DN.AckExtension_D                                 <= unsigned(DVSAERInput_DP(tDVSAERConfig.AckExtension_D'length - 1 downto 0));
				DVSAEROutput_DN(tDVSAERConfig.AckExtension_D'length - 1 downto 0) <= std_logic_vector(DVSAERConfigReg_DP.AckExtension_D);

			when others => null;
		end case;
	end process dvsaerIO;

	dvsaerUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			LatchDVSAERReg_SP <= '0';
			DVSAERInput_DP    <= (others => '0');
			DVSAEROutput_DP   <= (others => '0');

			DVSAERConfigReg_DP <= tDVSAERConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			LatchDVSAERReg_SP <= LatchDVSAERReg_SN;
			DVSAERInput_DP    <= DVSAERInput_DN;
			DVSAEROutput_DP   <= DVSAEROutput_DN;

			if LatchDVSAERReg_SP = '1' and LatchInputReg_SP = '1' then
				DVSAERConfigReg_DP <= DVSAERConfigReg_DN;
			end if;
		end if;
	end process dvsaerUpdate;

	biasIO : process(ParamAddressReg_DP, ParamInput_DP, BiasInput_DP, BiasConfigReg_DP)
	begin
		BiasConfigReg_DN <= BiasConfigReg_DP;
		BiasInput_DN     <= ParamInput_DP;
		BiasOutput_DN    <= (others => '0');

		case ParamAddressReg_DP is
			when BIASCONFIG_PARAM_ADDRESSES.DiffBn_D =>
				BiasConfigReg_DN.DiffBn_D                               <= BiasInput_DP(tBiasConfig.DiffBn_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.DiffBn_D'length - 1 downto 0) <= BiasConfigReg_DP.DiffBn_D;

			when BIASCONFIG_PARAM_ADDRESSES.OnBn_D =>
				BiasConfigReg_DN.OnBn_D                               <= BiasInput_DP(tBiasConfig.OnBn_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.OnBn_D'length - 1 downto 0) <= BiasConfigReg_DP.OnBn_D;

			when BIASCONFIG_PARAM_ADDRESSES.OffBn_D =>
				BiasConfigReg_DN.OffBn_D                               <= BiasInput_DP(tBiasConfig.OffBn_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.OffBn_D'length - 1 downto 0) <= BiasConfigReg_DP.OffBn_D;

			when BIASCONFIG_PARAM_ADDRESSES.ApsCasEpc_D =>
				BiasConfigReg_DN.ApsCasEpc_D                               <= BiasInput_DP(tBiasConfig.ApsCasEpc_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.ApsCasEpc_D'length - 1 downto 0) <= BiasConfigReg_DP.ApsCasEpc_D;

			when BIASCONFIG_PARAM_ADDRESSES.DiffCasBnc_D =>
				BiasConfigReg_DN.DiffCasBnc_D                               <= BiasInput_DP(tBiasConfig.DiffCasBnc_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.DiffCasBnc_D'length - 1 downto 0) <= BiasConfigReg_DP.DiffCasBnc_D;

			when BIASCONFIG_PARAM_ADDRESSES.ApsROSFBn_D =>
				BiasConfigReg_DN.ApsROSFBn_D                               <= BiasInput_DP(tBiasConfig.ApsROSFBn_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.ApsROSFBn_D'length - 1 downto 0) <= BiasConfigReg_DP.ApsROSFBn_D;

			when BIASCONFIG_PARAM_ADDRESSES.LocalBufBn_D =>
				BiasConfigReg_DN.LocalBufBn_D                               <= BiasInput_DP(tBiasConfig.LocalBufBn_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.LocalBufBn_D'length - 1 downto 0) <= BiasConfigReg_DP.LocalBufBn_D;

			when BIASCONFIG_PARAM_ADDRESSES.PixInvBn_D =>
				BiasConfigReg_DN.PixInvBn_D                               <= BiasInput_DP(tBiasConfig.PixInvBn_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.PixInvBn_D'length - 1 downto 0) <= BiasConfigReg_DP.PixInvBn_D;

			when BIASCONFIG_PARAM_ADDRESSES.PrBp_D =>
				BiasConfigReg_DN.PrBp_D                               <= BiasInput_DP(tBiasConfig.PrBp_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.PrBp_D'length - 1 downto 0) <= BiasConfigReg_DP.PrBp_D;

			when BIASCONFIG_PARAM_ADDRESSES.PrSFBp_D =>
				BiasConfigReg_DN.PrSFBp_D                               <= BiasInput_DP(tBiasConfig.PrSFBp_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.PrSFBp_D'length - 1 downto 0) <= BiasConfigReg_DP.PrSFBp_D;

			when BIASCONFIG_PARAM_ADDRESSES.RefrBp_D =>
				BiasConfigReg_DN.RefrBp_D                               <= BiasInput_DP(tBiasConfig.RefrBp_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.RefrBp_D'length - 1 downto 0) <= BiasConfigReg_DP.RefrBp_D;

			when BIASCONFIG_PARAM_ADDRESSES.AEPdBn_D =>
				BiasConfigReg_DN.AEPdBn_D                               <= BiasInput_DP(tBiasConfig.AEPdBn_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.AEPdBn_D'length - 1 downto 0) <= BiasConfigReg_DP.AEPdBn_D;

			when BIASCONFIG_PARAM_ADDRESSES.LcolTimeoutBn_D =>
				BiasConfigReg_DN.LcolTimeoutBn_D                               <= BiasInput_DP(tBiasConfig.LcolTimeoutBn_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.LcolTimeoutBn_D'length - 1 downto 0) <= BiasConfigReg_DP.LcolTimeoutBn_D;

			when BIASCONFIG_PARAM_ADDRESSES.AEPuXBp_D =>
				BiasConfigReg_DN.AEPuXBp_D                               <= BiasInput_DP(tBiasConfig.AEPuXBp_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.AEPuXBp_D'length - 1 downto 0) <= BiasConfigReg_DP.AEPuXBp_D;

			when BIASCONFIG_PARAM_ADDRESSES.AEPuYBp_D =>
				BiasConfigReg_DN.AEPuYBp_D                               <= BiasInput_DP(tBiasConfig.AEPuYBp_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.AEPuYBp_D'length - 1 downto 0) <= BiasConfigReg_DP.AEPuYBp_D;

			when BIASCONFIG_PARAM_ADDRESSES.IFThrBn_D =>
				BiasConfigReg_DN.IFThrBn_D                               <= BiasInput_DP(tBiasConfig.IFThrBn_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.IFThrBn_D'length - 1 downto 0) <= BiasConfigReg_DP.IFThrBn_D;

			when BIASCONFIG_PARAM_ADDRESSES.IFRefrBn_D =>
				BiasConfigReg_DN.IFRefrBn_D                               <= BiasInput_DP(tBiasConfig.IFRefrBn_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.IFRefrBn_D'length - 1 downto 0) <= BiasConfigReg_DP.IFRefrBn_D;

			when BIASCONFIG_PARAM_ADDRESSES.PadFollBn_D =>
				BiasConfigReg_DN.PadFollBn_D                               <= BiasInput_DP(tBiasConfig.PadFollBn_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.PadFollBn_D'length - 1 downto 0) <= BiasConfigReg_DP.PadFollBn_D;

			when BIASCONFIG_PARAM_ADDRESSES.ApsOverflowLevel_D =>
				BiasConfigReg_DN.ApsOverflowLevel_D                               <= BiasInput_DP(tBiasConfig.ApsOverflowLevel_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.ApsOverflowLevel_D'length - 1 downto 0) <= BiasConfigReg_DP.ApsOverflowLevel_D;

			when BIASCONFIG_PARAM_ADDRESSES.BiasBuffer_D =>
				BiasConfigReg_DN.BiasBuffer_D                               <= BiasInput_DP(tBiasConfig.BiasBuffer_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.BiasBuffer_D'length - 1 downto 0) <= BiasConfigReg_DP.BiasBuffer_D;

			when BIASCONFIG_PARAM_ADDRESSES.SSP_D =>
				BiasConfigReg_DN.SSP_D                               <= BiasInput_DP(tBiasConfig.SSP_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.SSP_D'length - 1 downto 0) <= BiasConfigReg_DP.SSP_D;

			when BIASCONFIG_PARAM_ADDRESSES.SSN_D =>
				BiasConfigReg_DN.SSN_D                               <= BiasInput_DP(tBiasConfig.SSN_D'length - 1 downto 0);
				BiasOutput_DN(tBiasConfig.SSN_D'length - 1 downto 0) <= BiasConfigReg_DP.SSN_D;

			when others => null;
		end case;
	end process biasIO;

	biasUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			LatchBiasReg_SP <= '0';
			BiasInput_DP    <= (others => '0');
			BiasOutput_DP   <= (others => '0');

			BiasConfigReg_DP <= tBiasConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			LatchBiasReg_SP <= LatchBiasReg_SN;
			BiasInput_DP    <= BiasInput_DN;
			BiasOutput_DP   <= BiasOutput_DN;

			if LatchBiasReg_SP = '1' and LatchInputReg_SP = '1' then
				BiasConfigReg_DP <= BiasConfigReg_DN;
			end if;
		end if;
	end process biasUpdate;

	chipIO : process(ParamAddressReg_DP, ParamInput_DP, ChipInput_DP, ChipConfigReg_DP)
	begin
		ChipConfigReg_DN <= ChipConfigReg_DP;
		ChipInput_DN     <= ParamInput_DP;
		ChipOutput_DN    <= (others => '0');

		case ParamAddressReg_DP is
			when CHIPCONFIG_PARAM_ADDRESSES.DigitalMux0_D =>
				ChipConfigReg_DN.DigitalMux0_D                               <= unsigned(ChipInput_DP(tChipConfig.DigitalMux0_D'length - 1 downto 0));
				ChipOutput_DN(tChipConfig.DigitalMux0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.DigitalMux0_D);

			when CHIPCONFIG_PARAM_ADDRESSES.DigitalMux1_D =>
				ChipConfigReg_DN.DigitalMux1_D                               <= unsigned(ChipInput_DP(tChipConfig.DigitalMux1_D'length - 1 downto 0));
				ChipOutput_DN(tChipConfig.DigitalMux1_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.DigitalMux1_D);

			when CHIPCONFIG_PARAM_ADDRESSES.DigitalMux2_D =>
				ChipConfigReg_DN.DigitalMux2_D                               <= unsigned(ChipInput_DP(tChipConfig.DigitalMux2_D'length - 1 downto 0));
				ChipOutput_DN(tChipConfig.DigitalMux2_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.DigitalMux2_D);

			when CHIPCONFIG_PARAM_ADDRESSES.DigitalMux3_D =>
				ChipConfigReg_DN.DigitalMux3_D                               <= unsigned(ChipInput_DP(tChipConfig.DigitalMux3_D'length - 1 downto 0));
				ChipOutput_DN(tChipConfig.DigitalMux3_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.DigitalMux3_D);

			when CHIPCONFIG_PARAM_ADDRESSES.AnalogMux0_D =>
				ChipConfigReg_DN.AnalogMux0_D                               <= unsigned(ChipInput_DP(tChipConfig.AnalogMux0_D'length - 1 downto 0));
				ChipOutput_DN(tChipConfig.AnalogMux0_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.AnalogMux0_D);

			when CHIPCONFIG_PARAM_ADDRESSES.AnalogMux1_D =>
				ChipConfigReg_DN.AnalogMux1_D                               <= unsigned(ChipInput_DP(tChipConfig.AnalogMux1_D'length - 1 downto 0));
				ChipOutput_DN(tChipConfig.AnalogMux1_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.AnalogMux1_D);

			when CHIPCONFIG_PARAM_ADDRESSES.AnalogMux2_D =>
				ChipConfigReg_DN.AnalogMux2_D                               <= unsigned(ChipInput_DP(tChipConfig.AnalogMux2_D'length - 1 downto 0));
				ChipOutput_DN(tChipConfig.AnalogMux2_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.AnalogMux2_D);

			when CHIPCONFIG_PARAM_ADDRESSES.BiasOutMux_D =>
				ChipConfigReg_DN.BiasOutMux_D                               <= unsigned(ChipInput_DP(tChipConfig.BiasOutMux_D'length - 1 downto 0));
				ChipOutput_DN(tChipConfig.BiasOutMux_D'length - 1 downto 0) <= std_logic_vector(ChipConfigReg_DP.BiasOutMux_D);

			when CHIPCONFIG_PARAM_ADDRESSES.ResetCalibNeuron_S =>
				ChipConfigReg_DN.ResetCalibNeuron_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                    <= ChipConfigReg_DP.ResetCalibNeuron_S;

			when CHIPCONFIG_PARAM_ADDRESSES.TypeNCalibNeuron_S =>
				ChipConfigReg_DN.TypeNCalibNeuron_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                    <= ChipConfigReg_DP.TypeNCalibNeuron_S;

			when CHIPCONFIG_PARAM_ADDRESSES.ResetTestPixel_S =>
				ChipConfigReg_DN.ResetTestPixel_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                  <= ChipConfigReg_DP.ResetTestPixel_S;

			when CHIPCONFIG_PARAM_ADDRESSES.HotPixelSuppression_S =>
				ChipConfigReg_DN.HotPixelSuppression_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                       <= ChipConfigReg_DP.HotPixelSuppression_S;

			when CHIPCONFIG_PARAM_ADDRESSES.AERnArow_S =>
				ChipConfigReg_DN.AERnArow_S <= ChipInput_DP(0);
				ChipOutput_DN(0)            <= ChipConfigReg_DP.AERnArow_S;

			when CHIPCONFIG_PARAM_ADDRESSES.UseAOut_S =>
				ChipConfigReg_DN.UseAOut_S <= ChipInput_DP(0);
				ChipOutput_DN(0)           <= ChipConfigReg_DP.UseAOut_S;

			when CHIPCONFIG_PARAM_ADDRESSES.GlobalShutter_S =>
				ChipConfigReg_DN.GlobalShutter_S <= ChipInput_DP(0);
				ChipOutput_DN(0)                 <= ChipConfigReg_DP.GlobalShutter_S;

			when others => null;
		end case;
	end process chipIO;

	chipUpdate : process(Clock_CI, Reset_RI) is
	begin
		if Reset_RI = '1' then          -- asynchronous reset (active high)
			LatchChipReg_SP <= '0';
			ChipInput_DP    <= (others => '0');
			ChipOutput_DP   <= (others => '0');

			ChipConfigReg_DP <= tChipConfigDefault;
		elsif rising_edge(Clock_CI) then -- rising clock edge
			LatchChipReg_SP <= LatchChipReg_SN;
			ChipInput_DP    <= ChipInput_DN;
			ChipOutput_DP   <= ChipOutput_DN;

			if LatchChipReg_SP = '1' and LatchInputReg_SP = '1' then
				ChipConfigReg_DP <= ChipConfigReg_DN;
			end if;
		end if;
	end process chipUpdate;

	-- Connect configuration modules outputs
	MultiplexerConfig_DO <= MultiplexerConfigReg_DP;
	DVSAERConfig_DO      <= DVSAERConfigReg_DP;
	BiasConfig_DO        <= BiasConfigReg_DP;
	ChipConfig_DO        <= ChipConfigReg_DP;
end architecture Behavioral;
