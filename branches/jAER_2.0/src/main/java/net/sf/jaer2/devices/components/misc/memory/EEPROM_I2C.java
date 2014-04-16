package net.sf.jaer2.devices.components.misc.memory;

import java.io.IOException;
import java.nio.ByteBuffer;

import net.sf.jaer2.devices.components.controllers.Controller.Command;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.SSHSNode;
import net.sf.jaer2.util.TypedMap;

import org.usb4java.BufferUtils;

public class EEPROM_I2C extends Memory {
	private final int i2cAddress;

	public EEPROM_I2C(final SSHSNode componentConfigNode, final int size, final int i2cAddress) {
		this("EEPROM", componentConfigNode, size, i2cAddress);
	}

	public EEPROM_I2C(final String componentName, final SSHSNode componentConfigNode, final int size, final int i2cAddress) {
		super(componentName, componentConfigNode, size);

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

		try {
			getProgrammer().program(Command.I2C_WRITE, args, this);
		}
		catch (IOException e) {
			GUISupport.showDialogException(e);
			return;
		}
	}

	@Override
	public ByteBuffer readFromMemory(final int memAddress, final int length) {
		final ByteBuffer buf = BufferUtils.allocateByteBuffer(length);

		final TypedMap<String> args = new TypedMap<>();

		args.put("i2cAddress", Integer.class, getI2cAddress());
		args.put("memoryAddress", Integer.class, memAddress);
		args.put("dataIn", ByteBuffer.class, buf);

		try {
			getProgrammer().program(Command.I2C_READ, args, this);
		}
		catch (IOException e) {
			GUISupport.showDialogException(e);
			return null;
		}

		return buf;
	}
}
