package ch.unizh.ini.devices.components.misc;

import net.sf.jaer2.devices.components.misc.DAC;

public class AD5391_32chan extends DAC {
	private static final long serialVersionUID = 6135862766020180768L;

	public AD5391_32chan() {
		super("AD5391", 32, 12, 0.0f, 5.0f, 3.3f);
	}
}
