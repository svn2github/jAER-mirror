package net.sf.jaer2.devices.config.pots;

public class ShiftedSourceBiasCoarseFine extends AddressedIPot {
	private static final long serialVersionUID = -4838678921924901764L;

	public ShiftedSourceBiasCoarseFine(final String name, final String description, final Type type, final Sex sex,
		final int defaultValue) {
		super(name, description, type, sex, defaultValue);
	}
}
