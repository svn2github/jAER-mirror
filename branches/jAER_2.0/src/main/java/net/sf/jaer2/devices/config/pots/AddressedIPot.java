package net.sf.jaer2.devices.config.pots;

public class AddressedIPot extends IPot {
	public AddressedIPot(final String name, final String description, final int address, final Type type, final Sex sex, final int defaultValue) {
		super(name, description, address, type, sex, defaultValue);
	}
}
