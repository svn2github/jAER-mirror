package net.sf.jaer2.devices.components.controllers;

import javafx.scene.layout.Pane;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.misc.memory.Memory;

public abstract class Controller implements Component {
	@Override
	public String getName() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public void setProgrammer(final Controller programmer) {
		// TODO Auto-generated method stub

	}

	@Override
	public Pane getConfigGUI() {
		// TODO Auto-generated method stub
		return null;
	}

	public void firmwareToRam(final boolean fwRAM) {

	}

	public void firmwareToFlash(final Memory fwMemory) {

	}
}
