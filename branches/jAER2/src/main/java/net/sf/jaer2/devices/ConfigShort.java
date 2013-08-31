package net.sf.jaer2.devices;

public class ConfigShort extends ConfigBase {
	private short value;

	public ConfigShort(final String name, final String description, final short defaultValue) {
		super(name, description);
		value = defaultValue;
	}

	public short getValue() {
		return value;
	}

	public void setValue(final short value) {
		this.value = value;
	}
}
