package net.sf.jaer2.devices.config.pots;

import net.sf.jaer2.devices.config.ConfigBase;

public class Pot extends ConfigBase {
	protected final Type type;
	protected final Sex sex;

	public Pot(final String name, final String description, final Type type, final Sex sex) {
		super(name, description);

		this.type = type;
		this.sex = sex;
	}

	/** Type of bias, NORMAL, CASCODE or REFERENCE. */
	public static enum Type {
		NORMAL,
		CASCODE,
		REFERENCE;
	}

	/** Transistor type for bias, N, P or not available (na). */
	public static enum Sex {
		N,
		P,
		na;
	}
}
