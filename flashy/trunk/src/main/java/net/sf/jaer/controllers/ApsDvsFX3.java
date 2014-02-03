package net.sf.jaer.controllers;

import li.longi.libusb4java.Device;

public class ApsDvsFX3 extends Controller {
	public static final short VID = 0x152A;
	public static final short PID = (short) 0x841A;

	public ApsDvsFX3(Device d) {
		super(d);
	}
}
