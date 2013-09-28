package net.sf.jaer2.devices.config.pots;

public class AddressedIPot extends IPot {
	private static final long serialVersionUID = -5358834574149903002L;

	/** The address to send in advance of this Pot. */
	private final int address;

	public AddressedIPot(final String name, final String description, final int address, final Masterbias masterbias,
		final Type type, final Sex sex) {
		this(name, description, address, masterbias, type, sex, 0, 24);
	}

	public AddressedIPot(final String name, final String description, final int address, final Masterbias masterbias,
		final Type type, final Sex sex, final int defaultValue, final int numBits) {
		super(name, description, masterbias, type, sex, defaultValue, numBits);

		if (address < 0) {
			throw new IllegalArgumentException("Negative addresses are not allowed!");
		}

		this.address = address;
	}

	@Override
	public int getAddress() {
		return address;
	}

	@Override
	public String toString() {
		return String.format("%s, address=%d", super.toString(), getAddress());
	}
}
