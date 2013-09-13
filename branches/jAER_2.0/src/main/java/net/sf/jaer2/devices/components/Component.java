package net.sf.jaer2.devices.components;

import java.util.SortedMap;
import java.util.TreeMap;

import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.config.ConfigBase;

public abstract class Component {
	protected final SortedMap<Integer, ConfigBase> addressSettingMap = new TreeMap<>();

	protected final String name;
	protected Controller programmer;

	protected VBox rootConfigLayout;

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

	public void addSetting(final ConfigBase setting, final int address) {
		addressSettingMap.put(address, setting);
	}

	public ConfigBase getSetting(final int address) {
		return addressSettingMap.get(address);
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
		for (final ConfigBase cfg : addressSettingMap.values()) {
			rootConfigLayout.getChildren().add(cfg.getConfigGUI());
		}
	}

	@Override
	public String toString() {
		return name;
	}
}
