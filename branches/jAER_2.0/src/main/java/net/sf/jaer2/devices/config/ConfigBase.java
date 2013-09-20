package net.sf.jaer2.devices.config;

import java.io.Serializable;

import javafx.geometry.Pos;
import javafx.scene.control.Label;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Pane;
import net.sf.jaer2.util.GUISupport;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class ConfigBase implements Serializable {
	private static final long serialVersionUID = -4814139458067416419L;

	/** Local logger for log messages. */
	protected static final Logger logger = LoggerFactory.getLogger(ConfigBase.class);

	protected final String name;
	protected final String description;

	transient protected HBox rootConfigLayout;

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
		final Label l = GUISupport.addLabel(rootConfigLayout, name, description, null, null);

		l.setPrefWidth(80);
		l.setAlignment(Pos.CENTER_RIGHT);
	}

	@Override
	public String toString() {
		return String.format("%s - %s", name, description);
	}
}
