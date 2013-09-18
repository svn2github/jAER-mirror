package net.sf.jaer2.devices.config;

public class ConfigShort extends ConfigBase {
	/**
	 * 
	 */
	private static final long serialVersionUID = 3845479397628108503L;
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
