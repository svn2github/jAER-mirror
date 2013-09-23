package net.sf.jaer2.devices.config.muxes;

public class DigitalMux extends Mux {
	private static final long serialVersionUID = -3219574302447530043L;

	public DigitalMux(final String name, final String description, final int numBits) {
		super(name, description, numBits);

		for (int i = 0; i < 16; i++) {
			put(i, i, "DigOut " + i);
		}
	}
}
