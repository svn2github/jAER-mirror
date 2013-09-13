package net.sf.jaer2.devices.components.controllers;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.misc.memory.Memory;

public abstract class Controller extends Component {
	public Controller(final String componentName) {
		super(componentName);
	}

	public void firmwareToRam(final boolean fwRAM) {

	}

	public void firmwareToFlash(final Memory fwMemory) {

	}
}
