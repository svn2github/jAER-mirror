package net.sf.jaer2.devices.components.misc.memory;

import java.nio.ByteBuffer;

import net.sf.jaer2.devices.components.controllers.Controller.Command;
import net.sf.jaer2.util.TypedMap;

public class EEPROM_I2C extends Memory {
	private static final long serialVersionUID = 6483810761979125129L;

	private final int i2cAddress;

	public EEPROM_I2C(final int size, final int i2cAddress) {
		this("EEPROM", size, i2cAddress);
	}

	public EEPROM_I2C(final String componentName, final int size, final int i2cAddress) {
		super(componentName, size);

		this.i2cAddress = i2cAddress;
	}

	public int getI2cAddress() {
		return i2cAddress;
	}

	@Override
	public void writeToMemory(final int memAddress, final ByteBuffer content) {
		final TypedMap<String> args = new TypedMap<>();

		args.put("i2cAddress", Integer.class, getI2cAddress());
		args.put("memoryAddress", Integer.class, memAddress);
		args.put("dataOut", ByteBuffer.class, content);

		getProgrammer().program(Command.WRITE_I2C, args, this);
	}

	@Override
	public ByteBuffer readFromMemory(final int memAddress, final int length) {
		final ByteBuffer buf = ByteBuffer.allocate(length);

		final TypedMap<String> args = new TypedMap<>();

		args.put("i2cAddress", Integer.class, getI2cAddress());
		args.put("memoryAddress", Integer.class, memAddress);
		args.put("dataIn", ByteBuffer.class, buf);

		getProgrammer().program(Command.READ_I2C, args, this);

		return buf;
	}
}
