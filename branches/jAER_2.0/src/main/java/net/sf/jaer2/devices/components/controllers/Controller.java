package net.sf.jaer2.devices.components.controllers;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.misc.memory.Memory;

public abstract class Controller extends Component {
	/**
	 *
	 */
	private static final long serialVersionUID = -8449535038409300001L;

	public Controller(final String componentName) {
		super(componentName);
	}

	public void firmwareToRam(final boolean fwRAM) {

	}

	public void firmwareToFlash(final Memory fwMemory) {

	}
}
