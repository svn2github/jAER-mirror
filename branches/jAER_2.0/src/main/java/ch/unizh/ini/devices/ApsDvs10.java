package ch.unizh.ini.devices;

import li.longi.libusb4java.Device;
import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.components.controllers.FX2;
import net.sf.jaer2.devices.components.controllers.logic.LatticeMachX0;
import net.sf.jaer2.devices.components.controllers.logic.Logic;
import net.sf.jaer2.devices.components.misc.memory.EEPROM_I2C;
import net.sf.jaer2.devices.components.misc.memory.Memory;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ConfigInt;
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

		final FX2 fx2 = new FX2();
		addComponent(fx2);

		fx2.firmwareToRam(true);

		fx2.addSetting(new ConfigBit("extTrigger", "External trigger.", false), FX2.Ports.PA1);
		fx2.addSetting(new ConfigBit("runCpld", "Enable the CPLD.", true), FX2.Ports.PA3);
		fx2.addSetting(new ConfigBit("runAdc", "Enable the ADC.", true), FX2.Ports.PC0);
		fx2.addSetting(new ConfigBit("powerDown", "Power down the chip.", false), FX2.Ports.PE2);
		fx2.addSetting(new ConfigBit("nChipReset", "Keeps chip out of reset.", true), FX2.Ports.PE3);

		// Size in KB and I2C address.
		final Memory eeprom = new EEPROM_I2C(32, 0x51);
		eeprom.setProgrammer(fx2);
		addComponent(eeprom);

		// Support flashing FX2 firmware.
		fx2.firmwareToFlash(eeprom);

		final Logic latticeMachX0 = new LatticeMachX0();
		latticeMachX0.setProgrammer(fx2);
		addComponent(latticeMachX0);

		latticeMachX0.addSetting(new ConfigInt("exposure", ".", 0), 0, 16);
		latticeMachX0.addSetting(new ConfigInt("colSettle", ".", 0), 16, 16);
		latticeMachX0.addSetting(new ConfigInt("rowSettle", ".", 0), 32, 16);
		latticeMachX0.addSetting(new ConfigInt("resSettle", ".", 0), 48, 16);
		latticeMachX0.addSetting(new ConfigInt("frameDelay", ".", 0), 64, 16);

		// ADC adcTHS1030 = new THS1030();
		// Not actively configurable.

		final AERChip sbret10 = new SBRet10();
		sbret10.setProgrammer(fx2);
		addComponent(sbret10);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// TODO Auto-generated method stub
		return null;
	}
}
