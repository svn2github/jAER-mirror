package ch.unizh.ini.devices;

import li.longi.libusb4java.Device;
import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.components.controllers.FX2;
import net.sf.jaer2.devices.components.misc.memory.EEPROM_I2C;
import net.sf.jaer2.devices.components.misc.memory.Memory;
import net.sf.jaer2.eventio.translators.Translator;
import ch.unizh.ini.devices.components.aer.Tmpdiff128;

public class DVS128 extends USBDevice {
	private static final long serialVersionUID = 8948891814252920904L;

	public DVS128(final Device usbDevice) {
		super("DVS 128", "USB Dynamic Vision Sensor, 128x128 pixels.", USBDevice.VID, USBDevice.PID, USBDevice.DID,
			usbDevice);

		final Controller fx2 = new FX2();
		addComponent(fx2);

		fx2.firmwareToRam(true);

		// Size in KB and I2C address.
		final Memory eeprom = new EEPROM_I2C(32, 0x51);
		eeprom.setProgrammer(fx2);
		addComponent(eeprom);

		// Support flashing FX2 firmware.
		fx2.firmwareToFlash(eeprom);

		// Logic xilinxCoolRunner2 = new XilinxCoolRunner2();
		// Not actively configurable.

		final AERChip tmpdiff128 = new Tmpdiff128();
		tmpdiff128.setProgrammer(fx2);
		addComponent(tmpdiff128);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		return Tmpdiff128.class;
	}
}
