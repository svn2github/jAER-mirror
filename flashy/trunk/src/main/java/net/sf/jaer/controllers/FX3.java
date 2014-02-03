package net.sf.jaer.controllers;

import li.longi.libusb4java.Device;

public class FX3 extends Controller {
	public static final short VID = 0x04B4;
	public static final short PID = 0x00F3;

	public FX3(Device d) {
		super(d);
	}
}
