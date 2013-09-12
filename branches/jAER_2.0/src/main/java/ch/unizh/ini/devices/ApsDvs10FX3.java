package ch.unizh.ini.devices;

import li.longi.libusb4java.Device;
import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.components.controllers.FX3;
import net.sf.jaer2.devices.components.controllers.logic.LatticeECP3;
import net.sf.jaer2.devices.components.controllers.logic.Logic;
import net.sf.jaer2.devices.components.misc.InvenSense6050;
import net.sf.jaer2.devices.components.misc.memory.Flash_SPI;
import net.sf.jaer2.devices.components.misc.memory.Memory;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ConfigInt;
import net.sf.jaer2.eventio.translators.Translator;
import ch.unizh.ini.devices.components.aer.SBRet10;

public class ApsDvs10FX3 extends USBDevice {
	@SuppressWarnings("hiding")
	public static final short PID = (short) 0x841A;

	public ApsDvs10FX3(final Device usbDevice) {
		super("ApsDVS 10 FX3", "USB 3.0 vision sensor with active and dynamic pixels, using the SBRet10 chip.",
			USBDevice.VID, ApsDvs10FX3.PID, USBDevice.DID, usbDevice);

		final FX3 fx3 = new FX3();
		fx3.firmwareToRam(false);

		fx3.addSetting(new ConfigBit("extTrigger", "External trigger.", false), FX3.Ports.GPIO40);
		fx3.addSetting(new ConfigBit("runCpld", "Enable the CPLD.", true), FX3.Ports.GPIO41);
		fx3.addSetting(new ConfigBit("runAdc", "Enable the ADC.", true), FX3.Ports.GPIO35);
		fx3.addSetting(new ConfigBit("powerDown", "Power down the chip.", false), FX3.Ports.GPIO42);
		fx3.addSetting(new ConfigBit("nChipReset", "Keeps chip out of reset.", true), FX3.Ports.GPIO43);

		// Size in KB and SPI address.
		final Memory flash = new Flash_SPI(512, 0);
		flash.setProgrammer(fx3);

		// Support flashing FX3 firmware.
		fx3.firmwareToFlash(flash);

		final Logic latticeECP3 = new LatticeECP3();
		latticeECP3.setProgrammer(fx3);
		latticeECP3.firmwareToRam(true);

		// Support flashing LatticeECP3 firmware.
		latticeECP3.firmwareToFlash(flash);

		latticeECP3.addSetting(new ConfigInt("exposure", ".", 0), 0, 16);
		latticeECP3.addSetting(new ConfigInt("colSettle", ".", 0), 16, 16);
		latticeECP3.addSetting(new ConfigInt("rowSettle", ".", 0), 32, 16);
		latticeECP3.addSetting(new ConfigInt("resSettle", ".", 0), 48, 16);
		latticeECP3.addSetting(new ConfigInt("frameDelay", ".", 0), 64, 16);

		// ADC adcTHS1030 = new THS1030();
		// Not actively configurable.

		final AERChip sbret10 = new SBRet10();
		sbret10.setProgrammer(fx3);

		// Add inertial measurement unit.
		final Component invenSenseIMU = new InvenSense6050(0x68);
		invenSenseIMU.setProgrammer(fx3);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// TODO Auto-generated method stub
		return null;
	}
}
