package net.sf.jaer2.devices.components.controllers;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.misc.memory.Memory;
import net.sf.jaer2.util.TypedMap;

public abstract class Controller extends Component {
	private static final long serialVersionUID = -8449535038409300001L;

	/**
	 * The Command enumeration holds all possible commands that a component can
	 * send to its controller/programmer to be executed. This allows components
	 * down the component tree to simply ask their upper level for something to
	 * happen in a very generic way. These controllers can then decide to either
	 * directly implement the asked for command, executing some action, or pass
	 * it on to their own upper layer, maybe after some kind of format
	 * transformation, if any such is needed. This enables great flexibility in
	 * deciding who is responsible for what ultimately.
	 *
	 * @author llongi
	 */
	public static enum Command {
		/**
		 * Read from a generic I2C memory-like device.
		 *
		 * Required parameters:
		 * i2cAddress - Integer
		 * memoryAddress - Integer
		 * dataIn - ByteBuffer
		 */
		READ_I2C,
		/**
		 * Write to a generic I2C memory-like device.
		 *
		 * Required parameters:
		 * i2cAddress - Integer
		 * memoryAddress - Integer
		 * dataOut - ByteBuffer
		 */
		WRITE_I2C,
		/**
		 * Read from a generic SPI memory-like device.
		 *
		 * Required parameters:
		 * spiAddress - Integer
		 * memoryAddress - Integer
		 * dataIn - ByteBuffer
		 */
		READ_SPI,
		/**
		 * Write to a generic SPI memory-like device.
		 *
		 * Required parameters:
		 * spiAddress - Integer
		 * memoryAddress - Integer
		 * dataOut - ByteBuffer
		 */
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

	public abstract void program(final Command command, final TypedMap<String> args, final Component origin);
}
