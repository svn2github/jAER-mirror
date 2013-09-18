package net.sf.jaer2.devices.config;

public class ConfigByte extends ConfigBase {
	/**
	 * 
	 */
	private static final long serialVersionUID = 3829509887024505749L;
	private byte value;

	public ConfigByte(final String name, final String description, final byte defaultValue) {
		super(name, description);
		value = defaultValue;
	}

	public byte getValue() {
		return value;
	}

	public void setValue(final byte value) {
		this.value = value;
	}
}
