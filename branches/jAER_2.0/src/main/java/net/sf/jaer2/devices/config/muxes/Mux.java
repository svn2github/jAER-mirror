package net.sf.jaer2.devices.config.muxes;

import net.sf.jaer2.devices.config.ConfigBase;

public class Mux extends ConfigBase {
	private static final long serialVersionUID = -9024024193567293234L;

	public Mux(final String name, final String description) {
		super(name, description, 16);
	}

	@Override
	protected long computeBinaryRepresentation() {
		// TODO Auto-generated method stub
		return 0;
	}
}
