package ch.unizh.ini.devices;

import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ConfigInt;
import net.sf.jaer2.devices.controllers.FX2;
import net.sf.jaer2.eventio.translators.Translator;

import com.sun.org.apache.bcel.internal.generic.I2C;

public class ApsDvs10 extends USBDevice {
	public ApsDvs10() {
		super("ApsDVS 10", "USB vision sensor with active and dynamic pixels, using the SBRet10 chip.", VID_THESYCON,
			(short) 0x840D);

		final Controller fx2 = new FX2();
		fx2.firmwareToRam(true);

		fx2.addSetting(new ConfigBit("extTrigger", false), FX2.Ports.PA1);
		fx2.addSetting(new ConfigBit("runCpld", true), FX2.Ports.PA3);
		fx2.addSetting(new ConfigBit("runAdc", true), FX2.Ports.PC0);
		fx2.addSetting(new ConfigBit("powerDown", false), FX2.Ports.PE2);
		fx2.addSetting(new ConfigBit("nChipReset", true), FX2.Ports.PE3);

		final I2C eeprom = new EEPROM_I2C(32, 0x51); // Size in KB and I2C
														// address.
		eeprom.setProgrammer(fx2);

		// Support flashing FX2 firmware.
		fx2.firmwareToFlash(eeprom);

		final Logic latticeMachX0 = new LatticeMachX0();
		latticeMachX0.setProgrammer(fx2);

		latticeMachX0.addSetting(new ConfigInt("exposure", 0), 15, 0);
		latticeMachX0.addSetting(new ConfigInt("colSettle", 0), 31, 16);
		latticeMachX0.addSetting(new ConfigInt("rowSettle", 0), 47, 32);
		latticeMachX0.addSetting(new ConfigInt("resSettle", 0), 63, 48);
		latticeMachX0.addSetting(new ConfigInt("frameDelay", 0), 79, 64);

		// ADC adcTHS1030 = new THS1030();
		// Not actively configurable.

		final AER sbret10 = new ApsDvs10();
		sbret10.setBiasProgrammer(fx2);

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
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// TODO Auto-generated method stub
		return null;
	}
}
