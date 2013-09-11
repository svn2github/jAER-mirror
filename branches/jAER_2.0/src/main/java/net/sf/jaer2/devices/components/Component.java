package net.sf.jaer2.devices.components;

import javafx.scene.layout.Pane;
import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.config.ConfigBase;

public interface Component {
	public String getName();

	public Pane getConfigGUI();

	public void setProgrammer(Controller programmer);

	public void addSetting(ConfigBase setting, int address);
}
