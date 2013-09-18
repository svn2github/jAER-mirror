package net.sf.jaer2.devices.config;

public class ConfigBit extends ConfigBase {
	/**
	 * 
	 */
	private static final long serialVersionUID = 4713262582313018900L;
	private boolean value;

	public ConfigBit(final String name, final String description, final boolean defaultValue) {
		super(name, description);
		value = defaultValue;
	}

	public boolean getValue() {
		return value;
	}

	public void setValue(final boolean value) {
		this.value = value;
	}
}
