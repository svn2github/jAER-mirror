package ch.unizh.ini.devices;

import li.longi.libusb4java.Device;
import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.components.controllers.FX2;
import net.sf.jaer2.devices.components.controllers.logic.LatticeMachX0;
import net.sf.jaer2.devices.components.controllers.logic.Logic;
import net.sf.jaer2.devices.components.misc.memory.EEPROM_I2C;
import net.sf.jaer2.devices.components.misc.memory.Memory;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ConfigInt;
import net.sf.jaer2.devices.config.pots.AddressedIPotCoarseFine;
import net.sf.jaer2.devices.config.pots.Pot;
import net.sf.jaer2.devices.config.pots.ShiftedSourceBiasCoarseFine;
import net.sf.jaer2.eventio.translators.Translator;
import ch.unizh.ini.devices.components.aer.SBRet10;

public class ApsDvs10 extends USBDevice {
	@SuppressWarnings("hiding")
	public static final short PID = (short) 0x840D;

	public ApsDvs10(final Device usbDevice) {
		this(usbDevice, USBDevice.DID);
	}

	protected ApsDvs10(final Device usbDevice, final short deviceDID) {
		super("ApsDVS 10", "USB vision sensor with active and dynamic pixels, using the SBRet10 chip.", USBDevice.VID,
			ApsDvs10.PID, deviceDID, usbDevice);

		final Controller fx2 = new FX2();
		fx2.firmwareToRam(true);

		fx2.addSetting(new ConfigBit("extTrigger", "External trigger.", false), FX2.Ports.PA1);
		fx2.addSetting(new ConfigBit("runCpld", "Enable the CPLD.", true), FX2.Ports.PA3);
		fx2.addSetting(new ConfigBit("runAdc", "Enable the ADC.", true), FX2.Ports.PC0);
		fx2.addSetting(new ConfigBit("powerDown", "Power down the chip.", false), FX2.Ports.PE2);
		fx2.addSetting(new ConfigBit("nChipReset", "Keeps chip out of reset.", true), FX2.Ports.PE3);

		// Size in KB and I2C address.
		final Memory eeprom = new EEPROM_I2C(32, 0x51);
		eeprom.setProgrammer(fx2);

		// Support flashing FX2 firmware.
		fx2.firmwareToFlash(eeprom);

		final Logic latticeMachX0 = new LatticeMachX0();
		latticeMachX0.setProgrammer(fx2);

		latticeMachX0.addSetting(new ConfigInt("exposure", ".", 0), 15, 0);
		latticeMachX0.addSetting(new ConfigInt("colSettle", ".", 0), 31, 16);
		latticeMachX0.addSetting(new ConfigInt("rowSettle", ".", 0), 47, 32);
		latticeMachX0.addSetting(new ConfigInt("resSettle", ".", 0), 63, 48);
		latticeMachX0.addSetting(new ConfigInt("frameDelay", ".", 0), 79, 64);

		// ADC adcTHS1030 = new THS1030();
		// Not actively configurable.

		final AERChip sbret10 = new SBRet10();
		sbret10.setProgrammer(fx2);

		sbret10.addBias(new AddressedIPotCoarseFine("DiffBn", ".", 0, Pot.Type.NORMAL, Pot.Sex.N, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("OnBn", ".", 1, Pot.Type.NORMAL, Pot.Sex.N, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("OffBn", ".", 2, Pot.Type.NORMAL, Pot.Sex.N, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("ApsCasEpc", ".", 3, Pot.Type.CASCODE, Pot.Sex.P, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("DiffCasBnc", ".", 4, Pot.Type.CASCODE, Pot.Sex.N, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("ApsROSFBn", ".", 5, Pot.Type.NORMAL, Pot.Sex.N, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("LocalBufBn", ".", 6, Pot.Type.NORMAL, Pot.Sex.N, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("PixInvBn", ".", 7, Pot.Type.NORMAL, Pot.Sex.N, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("PrBp", ".", 8, Pot.Type.NORMAL, Pot.Sex.P, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("PrSFBp", ".", 9, Pot.Type.NORMAL, Pot.Sex.P, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("RefrBp", ".", 10, Pot.Type.NORMAL, Pot.Sex.P, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("AEPdBn", ".", 11, Pot.Type.NORMAL, Pot.Sex.N, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("LcolTimeoutBn", ".", 12, Pot.Type.NORMAL, Pot.Sex.N, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("AEPuXBp", ".", 13, Pot.Type.NORMAL, Pot.Sex.P, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("AEPuYBp", ".", 14, Pot.Type.NORMAL, Pot.Sex.P, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("IFThrBn", ".", 15, Pot.Type.NORMAL, Pot.Sex.N, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("IFRefrBn", ".", 16, Pot.Type.NORMAL, Pot.Sex.N, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("PadFollBn", ".", 17, Pot.Type.NORMAL, Pot.Sex.N, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("apsOverflowLevel", ".", 18, Pot.Type.NORMAL, Pot.Sex.N, 0));
		sbret10.addBias(new AddressedIPotCoarseFine("biasBuffer", ".", 19, Pot.Type.NORMAL, Pot.Sex.N, 0));

		sbret10.addBias(new ShiftedSourceBiasCoarseFine("SSP", ".", 20, Pot.Type.NORMAL, Pot.Sex.P, 0));
		sbret10.addBias(new ShiftedSourceBiasCoarseFine("SSN", ".", 21, Pot.Type.NORMAL, Pot.Sex.N, 0));

		sbret10.addSetting(new ConfigBit("resetCalib", ".", true), 0);
		sbret10.addSetting(new ConfigBit("typeNCalib", ".", false), 1);
		sbret10.addSetting(new ConfigBit("resetTestpixel", ".", true), 2);
		sbret10.addSetting(new ConfigBit("hotPixelSuppression", ".", false), 3);
		sbret10.addSetting(new ConfigBit("nArow", ".", false), 4);
		sbret10.addSetting(new ConfigBit("useAout", ".", true), 5);
		sbret10.addSetting(new ConfigBit("globalShutter", ".", false), 6);

		sbret10.addMux(new AnalogMux("AnaMux2", "."), 1);
		sbret10.addMux(new AnalogMux("AnaMux1", "."), 2);
		sbret10.addMux(new AnalogMux("AnaMux0", "."), 3);

		sbret10.addMux(new DigitalMux("DigMux3", "."), 1);
		sbret10.addMux(new DigitalMux("DigMux2", "."), 2);
		sbret10.addMux(new DigitalMux("DigMux1", "."), 3);
		sbret10.addMux(new DigitalMux("DigMux0", "."), 4);

		sbret10.addMux(new BiasMux("BiasOutMux", "."), 0);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// TODO Auto-generated method stub
		return null;
	}
}
