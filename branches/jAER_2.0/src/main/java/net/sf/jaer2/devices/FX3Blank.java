package net.sf.jaer2.devices;

import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.components.controllers.FX3;
import net.sf.jaer2.devices.components.misc.memory.Flash_SPI;
import net.sf.jaer2.devices.components.misc.memory.Memory;
import net.sf.jaer2.eventio.translators.Translator;

public class FX3Blank extends USBDevice {
	public FX3Blank() {
		super("FX3 Blank", "Blank FX3 device, needs to have firmware loaded onto it.", (short) 0x04B4, (short) 0x00F3);

		final Controller fx3 = new FX3();
		fx3.firmwareToRam(true);

		// Size in KB and SPI address.
		final Memory flash = new Flash_SPI(512, 0);
		flash.setProgrammer(fx3);

		// Support flashing FX3 firmware.
		fx3.firmwareToFlash(flash);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// No events can be generated by the blank devices.
		return null;
	}
}
