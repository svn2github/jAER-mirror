package net.sf.jaer2.devices.config;

public abstract class ConfigBase {
	private final String name;
	private final String description;

	public ConfigBase(final String name, final String description) {
		this.name = name;
		this.description = description;
	}

	public String getName() {
		return name;
	}

	public String getDescription() {
		return description;
	}
}
