package net.sf.jaer2.devices.components;

import javafx.scene.layout.Pane;

public interface Component {
	public String getName();

	public Pane getConfigGUI();
}
