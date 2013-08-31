package net.sf.jaer2.devices;

public class ConfigByte extends ConfigBase {
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
