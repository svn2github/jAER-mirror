package net.sf.jaer2.devices.config.pots;

public class AddressedIPot extends IPot {
	private static final long serialVersionUID = -5358834574149903002L;

	/** The address to send in advance of this Pot. */
	private final int address;

	public AddressedIPot(final String name, final String description, final int address, final Type type, final Sex sex) {
		this(name, description, address, type, sex, 0, 24);
	}

	public AddressedIPot(final String name, final String description, final int address, final Type type,
		final Sex sex, final int defaultValue, final int numBits) {
		super(name, description, type, sex, defaultValue, numBits);

		this.address = address;
	}

	public int getAddress() {
		return address;
	}
}
