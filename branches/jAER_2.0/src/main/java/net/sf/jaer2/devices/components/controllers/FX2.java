package net.sf.jaer2.devices.components.controllers;

import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.config.ConfigBase;
import net.sf.jaer2.devices.config.ConfigBase.Address;
import net.sf.jaer2.util.SSHSNode;
import net.sf.jaer2.util.TypedMap;

public class FX2 extends Controller {
	public static enum Ports implements Address {
		PA0((short) ((0 << 8) + (1 << 0))),
		PA1((short) ((0 << 8) + (1 << 1))),
		PA3((short) ((0 << 8) + (1 << 3))),
		PA7((short) ((0 << 8) + (1 << 7))),
		PC0((short) ((1 << 8) + (1 << 0))),
		PC1((short) ((1 << 8) + (1 << 1))),
		PC2((short) ((1 << 8) + (1 << 2))),
		PC3((short) ((1 << 8) + (1 << 3))),
		PC4((short) ((1 << 8) + (1 << 4))), // JTAG
		PC5((short) ((1 << 8) + (1 << 5))), // JTAG
		PC6((short) ((1 << 8) + (1 << 6))), // JTAG
		PC7((short) ((1 << 8) + (1 << 7))), // JTAG
		PD0((short) ((2 << 8) + (1 << 0))), // FD 8
		PD1((short) ((2 << 8) + (1 << 1))), // FD 9
		PD2((short) ((2 << 8) + (1 << 2))), // FD 10
		PD3((short) ((2 << 8) + (1 << 3))), // FD 11
		PD4((short) ((2 << 8) + (1 << 4))), // FD 12
		PD5((short) ((2 << 8) + (1 << 5))), // FD 13
		PD6((short) ((2 << 8) + (1 << 6))), // FD 14
		PD7((short) ((2 << 8) + (1 << 7))), // FD 15
		PE0((short) ((3 << 8) + (1 << 0))),
		PE1((short) ((3 << 8) + (1 << 1))),
		PE2((short) ((3 << 8) + (1 << 2))),
		PE3((short) ((3 << 8) + (1 << 3))),
		PE4((short) ((3 << 8) + (1 << 4))),
		PE5((short) ((3 << 8) + (1 << 5))),
		PE6((short) ((3 << 8) + (1 << 6))),
		PE7((short) ((3 << 8) + (1 << 7))), ;

		private final short portId;

		private Ports(final short id) {
			portId = id;
		}

		public final short getPortId() {
			return portId;
		}

		@Override
		public final int address() {
			return getPortId() & 0xFFFF;
		}

		@Override
		public final String toString() {
			return String.format("Port ID 0x%X", getPortId());
		}
	}

	public static enum VendorRequests implements Address {
		VR_NONE((byte) 0x00);

		private final byte vr;

		private VendorRequests(final byte b) {
			vr = b;
		}

		public final byte getVR() {
			return vr;
		}

		@Override
		public final int address() {
			return getVR() & 0xFF;
		}

		@Override
		public final String toString() {
			return String.format("VendorRequest 0x%X", getVR());
		}
	}

	public FX2(final SSHSNode componentConfigNode) {
		this("FX2", componentConfigNode);
	}

	public FX2(final String componentName, final SSHSNode componentConfigNode) {
		super(componentName, componentConfigNode);
	}

	@Override
	public void addSetting(final ConfigBase setting) {
		// Check that an address is set.
		try {
			setting.getAddress();
		}
		catch (final UnsupportedOperationException e) {
			throw new UnsupportedOperationException(
				"General order unsupported, use either Ports or VendorRequests to specify an address.");
		}

		super.addSetting(setting);
	}

	@Override
	public USBDevice getDevice() {
		// FX microcontrollers are always part of a USB device, nothing else
		// makes even remotely sense.
		return (USBDevice) super.getDevice();
	}

	@SuppressWarnings("unused")
	@Override
	public void setProgrammer(final Controller programmer) {
		throw new UnsupportedOperationException("FX2 cannot be programmed by others, as it is the initial controller.");
	}

	@Override
	synchronized public void program(final Command command, final TypedMap<String> args, final Component origin) {
		// TODO Auto-generated method stub
	}
}
