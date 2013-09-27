package net.sf.jaer2.devices.components.misc.memory;

import java.nio.ByteBuffer;

import li.longi.libusb4java.utils.BufferUtils;
import net.sf.jaer2.devices.components.controllers.Controller.Command;
import net.sf.jaer2.util.TypedMap;

public class Flash_SPI extends Memory {
	private static final long serialVersionUID = -5149304076077627592L;

	private final int spiAddress;

	public Flash_SPI(final int size, final int spiAddress) {
		this("Flash", size, spiAddress);
	}

	public Flash_SPI(final String componentName, final int size, final int spiAddress) {
		super(componentName, size);

		this.spiAddress = spiAddress;
	}

	public int getSpiAddress() {
		return spiAddress;
	}

	@Override
	public void writeToMemory(final int memAddress, final ByteBuffer content) {
		final TypedMap<String> args = new TypedMap<>();

		args.put("spiAddress", Integer.class, getSpiAddress());
		args.put("memoryAddress", Integer.class, memAddress);
		args.put("dataOut", ByteBuffer.class, content);

		getProgrammer().program(Command.SPI_WRITE, args, this);
	}

	@Override
	public ByteBuffer readFromMemory(final int memAddress, final int length) {
		final ByteBuffer buf = BufferUtils.allocateByteBuffer(length);

		final TypedMap<String> args = new TypedMap<>();

		args.put("spiAddress", Integer.class, getSpiAddress());
		args.put("memoryAddress", Integer.class, memAddress);
		args.put("dataIn", ByteBuffer.class, buf);

		getProgrammer().program(Command.SPI_READ, args, this);

		return buf;
	}
}
