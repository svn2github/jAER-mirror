package net.sf.jaer2.devices;

import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.components.controllers.FX2;
import net.sf.jaer2.devices.components.misc.memory.EEPROM_I2C;
import net.sf.jaer2.eventio.translators.Translator;

import com.sun.org.apache.bcel.internal.generic.I2C;

public class FX2Blank extends USBDevice {
	public FX2Blank() {
		super("FX2 Blank", "Blank FX2 device, needs to have firmware loaded onto it.", (short) 0x04B4, (short) 0x8613);

		final Controller fx2 = new FX2();
		fx2.firmwareToRam(true);

		// Size in KB and I2C address.
		final I2C eeprom = new EEPROM_I2C(32, 0x51);
		eeprom.setProgrammer(fx2);

		// Support flashing FX2 firmware.
		fx2.firmwareToFlash(eeprom);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// No events can be generated by the blank devices.
		return null;
	}
}
