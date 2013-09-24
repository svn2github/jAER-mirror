package net.sf.jaer2.devices.components;

import java.io.Serializable;
import java.util.LinkedHashMap;
import java.util.Map;

import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.config.ConfigBase;

public abstract class Component implements Serializable {
	private static final long serialVersionUID = 1690782428425851787L;

	private final Map<String, ConfigBase> settingsMap = new LinkedHashMap<>();

	private final String name;
	private Controller programmer;

	transient protected VBox rootConfigLayout;

	public Component(final String componentName) {
		name = componentName;
	}

	public String getName() {
		return name;
	}

	public Controller getProgrammer() {
		return programmer;
	}

	public void setProgrammer(final Controller programmer) {
		this.programmer = programmer;
	}

	public void addSetting(final ConfigBase setting) {
		settingsMap.put(setting.getName(), setting);
	}

	public ConfigBase getSetting(final String sname) {
		return settingsMap.get(sname);
	}

	synchronized public Pane getConfigGUI() {
		if (rootConfigLayout == null) {
			rootConfigLayout = new VBox(10);

			buildConfigGUI();
		}

		return rootConfigLayout;
	}

	protected void buildConfigGUI() {
		// Fill the vertical box with the settings.
		for (final ConfigBase cfg : settingsMap.values()) {
			rootConfigLayout.getChildren().add(cfg.getConfigGUI());
		}
	}

	@Override
	public String toString() {
		return getName();
	}
}
