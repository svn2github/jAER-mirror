package net.sf.jaer2.devices.components;

import java.util.LinkedHashMap;
import java.util.Map;

import javafx.geometry.Insets;
import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import net.sf.jaer2.devices.Device;
import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.config.ConfigBase;
import net.sf.jaer2.util.SSHSNode;

public abstract class Component {
	private final Map<String, ConfigBase> settingsMap = new LinkedHashMap<>();

	private final String name;
	private Controller programmer;
	private Device device;

	/** Central configuration holding node. */
	protected final SSHSNode configNode;

	protected VBox rootConfigLayout;

	public Component(final String componentName, final SSHSNode componentConfigNode) {
		name = componentName;
		configNode = componentConfigNode;
	}

	public final String getName() {
		return name;
	}

	public Controller getProgrammer() {
		if (programmer == null) {
			throw new UnsupportedOperationException("Programming not supported, no programmer configured.");
		}

		return programmer;
	}

	public void setProgrammer(final Controller programmer) {
		this.programmer = programmer;
	}

	public Device getDevice() {
		if (device == null) {
			throw new IllegalStateException("No device associated, device is null.");
		}

		return device;
	}

	public void setDevice(Device device) {
		this.device = device;
	}

	public SSHSNode getConfigNode() {
		return configNode;
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
			rootConfigLayout.setPadding(new Insets(10));

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
