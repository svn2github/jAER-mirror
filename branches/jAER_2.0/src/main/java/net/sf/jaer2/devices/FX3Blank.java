package net.sf.jaer2.devices;

import net.sf.jaer2.devices.controllers.FX3;

public class FX3Blank {
	public FX3Blank() {
		final Controller fx3 = new FX3();
		fx3.firmwareToRam(true);

		final SPI flash = new FLASH_SPI(512, 0); // Size in KB and SPI address.
		flash.setProgrammer(fx3);

		// Support flashing FX3 firmware.
		fx3.firmwareToFlash(flash);
	}
}
