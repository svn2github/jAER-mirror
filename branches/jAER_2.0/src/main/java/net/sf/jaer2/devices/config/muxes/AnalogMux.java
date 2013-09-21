package net.sf.jaer2.devices.config.muxes;

import java.util.HashMap;

public class AnalogMux extends Mux {
	private static final long serialVersionUID = 6177068974879970663L;

	public AnalogMux(final String name, final String description) {
		super(name, description);

		// super(sbChip, 4, 8, (OutputMap) (new VoltageOutputMap()));
		// setName("Voltages" + n);

		put(0, 1);
		put(1, 3);
		put(2, 5);
		put(3, 7);
		put(4, 9);
		put(5, 11);
		put(6, 13);
		put(7, 15);
	}

	public HashMap<Integer, Integer> outputMap = new HashMap<>();
	public HashMap<Integer, String> nameMap = new HashMap<>();

	public void put(final int k, final int v, final String name) {
		outputMap.put(k, v);
		nameMap.put(k, name);
	}

	@Override
	public void put(final int k, final String name) {
		nameMap.put(k, name);
	}

	final void put(final int k, final int v) {
		put(k, v, "Voltage " + k);
	}
}
