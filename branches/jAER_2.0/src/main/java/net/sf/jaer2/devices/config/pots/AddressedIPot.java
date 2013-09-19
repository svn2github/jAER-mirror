package net.sf.jaer2.devices.config.pots;

public class AddressedIPot extends IPot {
	private static final long serialVersionUID = -5358834574149903002L;

	public AddressedIPot(final String name, final String description, final Type type, final Sex sex,
		final int defaultValue) {
		super(name, description, type, sex, defaultValue);
	}
}
