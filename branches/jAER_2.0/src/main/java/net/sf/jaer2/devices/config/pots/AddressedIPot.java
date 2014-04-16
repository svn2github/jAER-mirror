package net.sf.jaer2.devices.config.pots;

import net.sf.jaer2.util.SSHSNode;

public class AddressedIPot extends IPot {
	/** The address to send in advance of this Pot. */
	private final int address;

	public AddressedIPot(final String name, final String description, final SSHSNode configNode, final int address,
		final Masterbias masterbias, final Type type, final Sex sex) {
		this(name, description, configNode, address, masterbias, type, sex, 0, 24);
	}

	public AddressedIPot(final String name, final String description, final SSHSNode configNode, final int address,
		final Masterbias masterbias, final Type type, final Sex sex, final int defaultValue, final int numBits) {
		super(name, description, configNode, masterbias, type, sex, defaultValue, numBits);

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
