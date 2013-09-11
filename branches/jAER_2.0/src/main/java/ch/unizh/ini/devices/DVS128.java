package ch.unizh.ini.devices;

import li.longi.libusb4java.Device;
import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.components.controllers.FX2;
import net.sf.jaer2.devices.components.misc.memory.EEPROM_I2C;
import net.sf.jaer2.devices.components.misc.memory.Memory;
import net.sf.jaer2.devices.config.pots.IPot;
import net.sf.jaer2.devices.config.pots.Pot;
import net.sf.jaer2.eventio.translators.Translator;
import ch.unizh.ini.devices.components.aer.Tmpdiff128;

public class DVS128 extends USBDevice {
	public DVS128(final Device usbDevice) {
		super("DVS 128", "USB Dynamic Vision Sensor, 128x128 pixels.", USBDevice.VID, USBDevice.PID, USBDevice.DID,
			usbDevice);

		final Controller fx2 = new FX2();
		fx2.firmwareToRam(true);

		// Size in KB and I2C address.
		final Memory eeprom = new EEPROM_I2C(32, 0x51);
		eeprom.setProgrammer(fx2);

		// Support flashing FX2 firmware.
		fx2.firmwareToFlash(eeprom);

		// Logic xilinxCoolRunner2 = new XilinxCoolRunner2();
		// Not actively configurable.

		final AERChip tmpdiff128 = new Tmpdiff128();
		tmpdiff128.setProgrammer(fx2);

		tmpdiff128.addSetting(new IPot("pr", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 0);
		tmpdiff128.addSetting(new IPot("foll", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 1);
		tmpdiff128.addSetting(new IPot("diff", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 2);
		tmpdiff128.addSetting(new IPot("diffOn", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 3);
		tmpdiff128.addSetting(new IPot("puY", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 4);
		tmpdiff128.addSetting(new IPot("refr", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 5);
		tmpdiff128.addSetting(new IPot("req", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 6);
		tmpdiff128.addSetting(new IPot("diffOff", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 7);
		tmpdiff128.addSetting(new IPot("puX", ".", Pot.Type.NORMAL, Pot.Sex.P, 0), 8);
		tmpdiff128.addSetting(new IPot("reqPd", ".", Pot.Type.NORMAL, Pot.Sex.N, 0), 9);
		tmpdiff128.addSetting(new IPot("injGnd", ".", Pot.Type.CASCODE, Pot.Sex.P, 0), 10);
		tmpdiff128.addSetting(new IPot("cas", ".", Pot.Type.CASCODE, Pot.Sex.N, 0), 11);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// TODO Auto-generated method stub
		return null;
	}
}
