package net.sf.jaer2.devices;

public class ConfigLong extends ConfigBase {
	private long value;

	public ConfigLong(final String name, final String description, final long defaultValue) {
		super(name, description);
		value = defaultValue;
	}

	public long getValue() {
		return value;
	}

	public void setValue(final long value) {
		this.value = value;
	}
}
