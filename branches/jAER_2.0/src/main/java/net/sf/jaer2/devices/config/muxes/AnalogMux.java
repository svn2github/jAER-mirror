package net.sf.jaer2.devices.config.muxes;

public class AnalogMux extends Mux {
	private static final long serialVersionUID = 6177068974879970663L;

	public AnalogMux(final String name, final String description, final int numBits) {
		super(name, description, numBits);

		put(0, 1, "Voltage 0");
		put(1, 3, "Voltage 1");
		put(2, 5, "Voltage 2");
		put(3, 7, "Voltage 3");
		put(4, 9, "Voltage 4");
		put(5, 11, "Voltage 5");
		put(6, 13, "Voltage 6");
		put(7, 15, "Voltage 7");
	}
}
