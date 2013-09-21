package net.sf.jaer2.devices.config.muxes;

import java.util.HashMap;

public class DigitalMux extends Mux {
	private static final long serialVersionUID = -3219574302447530043L;

	public DigitalMux(final String name, final String description) {
		super(name, description);

		// super(sbChip, 4, 16, (OutputMap) (new DigitalOutputMap()));
		// setName("LogicSignals" + n);

		for (int i = 0; i < 16; i++) {
			put(i, i, "DigOut " + i);
		}
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
}
