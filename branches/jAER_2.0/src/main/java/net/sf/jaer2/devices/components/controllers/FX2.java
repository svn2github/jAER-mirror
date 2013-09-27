package net.sf.jaer2.devices.components.controllers;

import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.config.ConfigBase;
import net.sf.jaer2.util.TypedMap;

public class FX2 extends Controller {
	private static final long serialVersionUID = -8642369183345730219L;

	public static enum Ports {
		PA0,
		PA1,
		PA3,
		PA7,
		PC0,
		PC1,
		PC2,
		PC3,
		PC4, // JTAG
		PC5, // JTAG
		PC6, // JTAG
		PC7, // JTAG
		PD0, // FD 8
		PD1, // FD 9
		PD2, // FD 10
		PD3, // FD 11
		PD4, // FD 12
		PD5, // FD 13
		PD6, // FD 14
		PD7, // FD 15
		PE0,
		PE1,
		PE2,
		PE3,
		PE4,
		PE5,
		PE6,
		PE7;
	}

	public static enum VendorRequests {
		VR_NONE((byte) 0x00);

		private final byte vr;

		private VendorRequests(final byte b) {
			vr = b;
		}

		public final byte getVR() {
			return vr;
		}

		@Override
		public final String toString() {
			return String.format("0x%X", vr);
		}
	}

	public FX2() {
		this("FX2");
	}

	public FX2(final String componentName) {
		super(componentName);
	}

	public void addSetting(final ConfigBase setting, final Ports port) {
		// TODO Auto-generated method stub
	}

	public void addSetting(final ConfigBase setting, final VendorRequests vr) {
		// TODO Auto-generated method stub
	}

	@Override
	public USBDevice getDevice() {
		// FX microcontrollers are always part of a USB device, nothing else
		// makes even remotely sense.
		return (USBDevice) super.getDevice();
	}

	@SuppressWarnings("unused")
	@Override
	public void addSetting(final ConfigBase setting) {
		throw new UnsupportedOperationException("General order unsupported, use either Ports or Vendor Requests.");
	}

	@SuppressWarnings("unused")
	@Override
	public void setProgrammer(final Controller programmer) {
		throw new UnsupportedOperationException("FX2 cannot be programmed by others, as it is the initial controller.");
	}

	@Override
	synchronized public void program(Command command, TypedMap<String> args, Component origin) {
		// TODO Auto-generated method stub

	}
}
