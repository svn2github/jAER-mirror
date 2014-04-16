package net.sf.jaer2.devices.components.misc.memory;

import java.io.IOException;
import java.nio.ByteBuffer;

import net.sf.jaer2.devices.components.controllers.Controller.Command;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.SSHSNode;
import net.sf.jaer2.util.TypedMap;

import org.usb4java.BufferUtils;

public class Flash_SPI extends Memory {
	private final int spiAddress;

	public Flash_SPI(final SSHSNode componentConfigNode, int size, final int spiAddress) {
		this("Flash", componentConfigNode, size, spiAddress);
	}

	public Flash_SPI(final String componentName, final SSHSNode componentConfigNode, final int size,
		final int spiAddress) {
		super(componentName, componentConfigNode, size);

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

		try {
			getProgrammer().program(Command.SPI_WRITE, args, this);
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

		args.put("spiAddress", Integer.class, getSpiAddress());
		args.put("memoryAddress", Integer.class, memAddress);
		args.put("dataIn", ByteBuffer.class, buf);

		try {
			getProgrammer().program(Command.SPI_READ, args, this);
		}
		catch (IOException e) {
			GUISupport.showDialogException(e);
			return null;
		}

		return buf;
	}
}
