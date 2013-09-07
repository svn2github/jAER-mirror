package ch.unizh.ini.devices;

import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ConfigByte;
import net.sf.jaer2.devices.config.ConfigInt;
import net.sf.jaer2.devices.controllers.FX3;
import net.sf.jaer2.eventio.translators.Translator;

import com.sun.org.apache.bcel.internal.generic.I2C;

public class ApsDvs10FX3 extends USBDevice  {
	public ApsDvs10FX3() {
		super("ApsDVS 10 FX3", "USB 3.0 vision sensor with active and dynamic pixels, using the SBRet10 chip.", VID_THESYCON,
			(short) 0x841A);

		final Controller fx3 = new FX3();
		fx3.firmwareToRam(false);

		fx3.addSetting(new ConfigByte("LOG_LEVEL",
			"Set the logging level, to restrict which error messages will be sent over the Status EP1.", (byte) 6),
			FX3.VR_LOG_LEVEL);
		fx3.addSetting(new ConfigBit("FX3_RESET", "Hard-reset the FX3 microcontroller", false), FX3.VR_FX3_RESET);

		fx3.addSetting(new ConfigBit("extTrigger", false), FX3.Ports.GPIO40);
		fx3.addSetting(new ConfigBit("runCpld", true), FX3.Ports.GPIO41);
		fx3.addSetting(new ConfigBit("runAdc", true), FX3.Ports.GPIO35);
		fx3.addSetting(new ConfigBit("powerDown", false), FX3.Ports.GPIO42);
		fx3.addSetting(new ConfigBit("nChipReset", true), FX3.Ports.GPIO43);

		final SPI flash = new FLASH_SPI(512, 0); // Size in KB and SPI address.
		flash.setProgrammer(fx3);

		// Support flashing FX3 firmware.
		fx3.firmwareToFlash(flash);

		final Logic latticeECP3 = new LatticeECP3();
		latticeECP3.setProgrammer(fx3);
		latticeECP3.firmwareToRam(true);

		// Support flashing LatticeECP3 firmware.
		latticeECP3.firmwareToFlash(flash);

		latticeECP3.addSetting(new ConfigInt("exposure", 0), 15, 0);
		latticeECP3.addSetting(new ConfigInt("colSettle", 0), 31, 16);
		latticeECP3.addSetting(new ConfigInt("rowSettle", 0), 47, 32);
		latticeECP3.addSetting(new ConfigInt("resSettle", 0), 63, 48);
		latticeECP3.addSetting(new ConfigInt("frameDelay", 0), 79, 64);

		// ADC adcTHS1030 = new THS1030();
		// Not actively configurable.

		final AER sbret10 = new ApsDvs10();
		sbret10.setBiasProgrammer(fx3);

		sbret10.addBias(new AddressedIPotCF("DiffBn", 0, NORMAL, N, 0));
		sbret10.addBias(new AddressedIPotCF("OnBn", 1, NORMAL, N, 0));
		sbret10.addBias(new AddressedIPotCF("OffBn", 2, NORMAL, N, 0));
		sbret10.addBias(new AddressedIPotCF("ApsCasEpc", 3, CASCODE, P, 0));
		sbret10.addBias(new AddressedIPotCF("DiffCasBnc", 4, CASCODE, N, 0));
		sbret10.addBias(new AddressedIPotCF("ApsROSFBn", 5, NORMAL, N, 0));
		sbret10.addBias(new AddressedIPotCF("LocalBufBn", 6, NORMAL, N, 0));
		sbret10.addBias(new AddressedIPotCF("PixInvBn", 7, NORMAL, N, 0));
		sbret10.addBias(new AddressedIPotCF("PrBp", 8, NORMAL, P, 0));
		sbret10.addBias(new AddressedIPotCF("PrSFBp", 9, NORMAL, P, 0));
		sbret10.addBias(new AddressedIPotCF("RefrBp", 10, NORMAL, P, 0));
		sbret10.addBias(new AddressedIPotCF("AEPdBn", 11, NORMAL, N, 0));
		sbret10.addBias(new AddressedIPotCF("LcolTimeoutBn", 12, NORMAL, N, 0));
		sbret10.addBias(new AddressedIPotCF("AEPuXBp", 13, NORMAL, P, 0));
		sbret10.addBias(new AddressedIPotCF("AEPuYBp", 14, NORMAL, P, 0));
		sbret10.addBias(new AddressedIPotCF("IFThrBn", 15, NORMAL, N, 0));
		sbret10.addBias(new AddressedIPotCF("IFRefrBn", 16, NORMAL, N, 0));
		sbret10.addBias(new AddressedIPotCF("PadFollBn", 17, NORMAL, N, 0));
		sbret10.addBias(new AddressedIPotCF("apsOverflowLevel", 18, NORMAL, N, 0));
		sbret10.addBias(new AddressedIPotCF("biasBuffer", 19, NORMAL, N, 0));

		sbret10.addBias(new ShiftedSourceBiasCF("SSP", 20, NORMAL, P, 0));
		sbret10.addBias(new ShiftedSourceBiasCF("SSN", 21, NORMAL, N, 0));

		sbret10.addSetting(new ConfigBit("resetCalib", true), 0);
		sbret10.addSetting(new ConfigBit("typeNCalib", false), 1);
		sbret10.addSetting(new ConfigBit("resetTestpixel", true), 2);
		sbret10.addSetting(new ConfigBit("hotPixelSuppression", false), 3);
		sbret10.addSetting(new ConfigBit("nArow", false), 4);
		sbret10.addSetting(new ConfigBit("useAout", true), 5);
		sbret10.addSetting(new ConfigBit("globalShutter", false), 6);

		sbret10.addMux(new AnalogMux("AnaMux2"), 1);
		sbret10.addMux(new AnalogMux("AnaMux1"), 2);
		sbret10.addMux(new AnalogMux("AnaMux0"), 3);

		sbret10.addMux(new DigitalMux("DigMux3"), 1);
		sbret10.addMux(new DigitalMux("DigMux2"), 2);
		sbret10.addMux(new DigitalMux("DigMux1"), 3);
		sbret10.addMux(new DigitalMux("DigMux0"), 4);

		sbret10.addMux(new BiasMux("BiasOutMux"), 0);

		// Add inertial measurement unit.
		final I2C invenSenseIMU = new InvenSense6050(0x68);
		invenSenseIMU.setProgrammer(fx3);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// TODO Auto-generated method stub
		return null;
	}
}
