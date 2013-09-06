package net.sf.jaer2.devices;

import net.sf.jaer2.devices.controllers.FX2;

import com.sun.org.apache.bcel.internal.generic.I2C;

public class FX2Blank {
	public FX2Blank() {
		final Controller fx2 = new FX2();
		fx2.firmwareToRam(true);

		 // Size in KB and I2C address.
		final I2C eeprom = new EEPROM_I2C(32, 0x51);
		eeprom.setProgrammer(fx2);

		// Support flashing FX2 firmware.
		fx2.firmwareToFlash(eeprom);
	}
}
