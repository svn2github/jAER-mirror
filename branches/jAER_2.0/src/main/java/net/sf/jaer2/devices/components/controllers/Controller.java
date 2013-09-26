package net.sf.jaer2.devices.components.controllers;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.misc.memory.Memory;
import net.sf.jaer2.util.TypedMap;

public abstract class Controller extends Component {
	private static final long serialVersionUID = -8449535038409300001L;

	public static enum Command {
		READ_I2C,
		WRITE_I2C,
		READ_SPI,
		WRITE_SPI,
		WRITE_BIASES;
	}

	public Controller(final String componentName) {
		super(componentName);
	}

	public void firmwareToRam(final boolean fwRAM) {

	}

	public void firmwareToFlash(final Memory fwMemory) {

	}

	public abstract void program(final Command command, final TypedMap<String> arguments, final Component origin);
}
