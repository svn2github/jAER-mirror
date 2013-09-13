package net.sf.jaer2.devices.config;

import javafx.scene.layout.HBox;
import javafx.scene.layout.Pane;
import net.sf.jaer2.util.GUISupport;

public abstract class ConfigBase {
	protected final String name;
	protected final String description;

	protected HBox rootConfigLayout;

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

	synchronized public Pane getConfigGUI() {
		if (rootConfigLayout == null) {
			rootConfigLayout = new HBox(10);

			buildConfigGUI();
		}

		return rootConfigLayout;
	}

	protected void buildConfigGUI() {
		// Add name label, with description as tool-tip.
		GUISupport.addLabel(rootConfigLayout, name, description, null, null);
	}

	@Override
	public String toString() {
		return String.format("%s - %s", name, description);
	}
}
