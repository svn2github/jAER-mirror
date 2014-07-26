library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package BiasGenConfigRecords is
	constant BIASGENCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(5, 7);

	type tBiasGenConfigParamAddresses is record
		DiffBn_D           : unsigned(7 downto 0);
		OnBn_D             : unsigned(7 downto 0);
		OffBn_D            : unsigned(7 downto 0);
		ApsCasEpc_D        : unsigned(7 downto 0);
		DiffCasBnc_D       : unsigned(7 downto 0);
		ApsROSFBn_D        : unsigned(7 downto 0);
		LocalBufBn_D       : unsigned(7 downto 0);
		PixInvBn_D         : unsigned(7 downto 0);
		PrBp_D             : unsigned(7 downto 0);
		PrSFBp_D           : unsigned(7 downto 0);
		RefrBp_D           : unsigned(7 downto 0);
		AEPdBn_D           : unsigned(7 downto 0);
		LcolTimeoutBn_D    : unsigned(7 downto 0);
		AEPuXBp_D          : unsigned(7 downto 0);
		AEPuYBp_D          : unsigned(7 downto 0);
		IFThrBn_D          : unsigned(7 downto 0);
		IFRefrBn_D         : unsigned(7 downto 0);
		PadFollBn_D        : unsigned(7 downto 0);
		apsOverflowLevel_D : unsigned(7 downto 0);
		biasBuffer_D       : unsigned(7 downto 0);
		SSP_D              : unsigned(7 downto 0);
		SSN_D              : unsigned(7 downto 0);
	end record tBiasGenConfigParamAddresses;

	constant BIASGENCONFIG_PARAM_ADDRESSES : tBiasGenConfigParamAddresses := (
		DiffBn_D           => to_unsigned(0, 8),
		OnBn_D             => to_unsigned(1, 8),
		OffBn_D            => to_unsigned(2, 8),
		ApsCasEpc_D        => to_unsigned(3, 8),
		DiffCasBnc_D       => to_unsigned(4, 8),
		ApsROSFBn_D        => to_unsigned(5, 8),
		LocalBufBn_D       => to_unsigned(6, 8),
		PixInvBn_D         => to_unsigned(7, 8),
		PrBp_D             => to_unsigned(8, 8),
		PrSFBp_D           => to_unsigned(9, 8),
		RefrBp_D           => to_unsigned(10, 8),
		AEPdBn_D           => to_unsigned(11, 8),
		LcolTimeoutBn_D    => to_unsigned(12, 8),
		AEPuXBp_D          => to_unsigned(13, 8),
		AEPuYBp_D          => to_unsigned(14, 8),
		IFThrBn_D          => to_unsigned(15, 8),
		IFRefrBn_D         => to_unsigned(16, 8),
		PadFollBn_D        => to_unsigned(17, 8),
		apsOverflowLevel_D => to_unsigned(18, 8),
		biasBuffer_D       => to_unsigned(19, 8),
		SSP_D              => to_unsigned(20, 8),
		SSN_D              => to_unsigned(21, 8));

	type tBiasGenConfig is record
		Run_S          : std_logic;
		AckDelay_D     : unsigned(4 downto 0);
		AckExtension_D : unsigned(4 downto 0);
	end record tBiasGenConfig;

	constant tBiasGenConfigDefault : tBiasGenConfig := (
		Run_S          => '0',
		AckDelay_D     => to_unsigned(2, tBiasGenConfig.AckDelay_D'length),
		AckExtension_D => to_unsigned(1, tBiasGenConfig.AckExtension_D'length));
end package BiasGenConfigRecords;
