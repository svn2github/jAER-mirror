package net.sf.jaer.controllers;

import li.longi.libusb4java.Device;

public class FX2 extends Controller {
	public static final short VID = 0x04B4;
	public static final short PID = (short) 0x8613;

	public FX2(Device d) {
		super(d);
	}
}
