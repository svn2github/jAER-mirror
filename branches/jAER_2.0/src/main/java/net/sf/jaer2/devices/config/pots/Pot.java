package net.sf.jaer2.devices.config.pots;

import net.sf.jaer2.devices.config.ConfigBase;

public class Pot extends ConfigBase {
	public Pot(final String name, final String description) {
		super(name, description);
	}

	/** Type of bias, NORMAL, CASCODE or REFERENCE. */
	public static enum Type {
		NORMAL,
		CASCODE,
		REFERENCE,
	}

	/** Transistor type for bias, N, P or not available (na). */
	public static enum Sex {
		N,
		P,
		na,
	}
}
