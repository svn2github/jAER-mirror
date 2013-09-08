package ch.unizh.ini.devices;

import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.components.controllers.FX2;
import net.sf.jaer2.devices.components.misc.memory.EEPROM_I2C;
import net.sf.jaer2.devices.components.misc.memory.Memory;
import net.sf.jaer2.devices.config.pots.Pot;
import net.sf.jaer2.eventio.translators.Translator;
import ch.unizh.ini.devices.components.aer.Tmpdiff128;

public class DVS128 extends USBDevice {
	public DVS128() {
		super("DVS 128", "USB Dynamic Vision Sensor, 128x128 pixels.", USBDevice.VID_THESYCON, (short) 0x8400);

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

		tmpdiff128.addBias(new IPot("pr", 0, Pot.Type.NORMAL, Pot.Sex.P, 0));
		tmpdiff128.addBias(new IPot("foll", 1, Pot.Type.NORMAL, Pot.Sex.P, 0));
		tmpdiff128.addBias(new IPot("diff", 2, Pot.Type.NORMAL, Pot.Sex.N, 0));
		tmpdiff128.addBias(new IPot("diffOn", 3, Pot.Type.NORMAL, Pot.Sex.N, 0));
		tmpdiff128.addBias(new IPot("puY", 4, Pot.Type.NORMAL, Pot.Sex.P, 0));
		tmpdiff128.addBias(new IPot("refr", 5, Pot.Type.NORMAL, Pot.Sex.P, 0));
		tmpdiff128.addBias(new IPot("req", 6, Pot.Type.NORMAL, Pot.Sex.N, 0));
		tmpdiff128.addBias(new IPot("diffOff", 7, Pot.Type.NORMAL, Pot.Sex.N, 0));
		tmpdiff128.addBias(new IPot("puX", 8, Pot.Type.NORMAL, Pot.Sex.P, 0));
		tmpdiff128.addBias(new IPot("reqPd", 9, Pot.Type.NORMAL, Pot.Sex.N, 0));
		tmpdiff128.addBias(new IPot("injGnd", 10, Pot.Type.CASCODE, Pot.Sex.P, 0));
		tmpdiff128.addBias(new IPot("cas", 11, Pot.Type.CASCODE, Pot.Sex.N, 0));
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// TODO Auto-generated method stub
		return null;
	}
}
