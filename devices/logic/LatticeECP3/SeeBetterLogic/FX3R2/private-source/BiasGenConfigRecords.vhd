library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package BiasGenConfigRecords is
	constant BIASGENCONFIG_MODULE_ADDRESS : unsigned(6 downto 0) := to_unsigned(6, 7);

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
		DiffBn_D => to_unsigned(1, 8),
		OnBn_D   => to_unsigned(2, 8),
		OffBn_D  => to_unsigned(3, 8));

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
