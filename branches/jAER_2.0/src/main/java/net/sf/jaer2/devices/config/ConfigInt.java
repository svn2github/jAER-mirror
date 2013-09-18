package net.sf.jaer2.devices.config;

public class ConfigInt extends ConfigBase {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1886982916541742697L;
	private int value;

	public ConfigInt(final String name, final String description, final int defaultValue) {
		super(name, description);
		value = defaultValue;
	}

	public int getValue() {
		return value;
	}

	public void setValue(final int value) {
		this.value = value;
	}
}
