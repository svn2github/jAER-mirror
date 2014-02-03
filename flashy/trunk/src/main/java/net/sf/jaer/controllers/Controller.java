package net.sf.jaer.controllers;

import li.longi.libusb4java.Device;
import li.longi.libusb4java.DeviceDescriptor;
import li.longi.libusb4java.LibUsb;

public class Controller {
	private final Device device;
	protected final short devVID;
	protected final short devPID;

	public Controller(Device dev) {
		device = dev;

		DeviceDescriptor devDesc = new DeviceDescriptor();
		LibUsb.getDeviceDescriptor(device, devDesc);

		devVID = devDesc.idVendor();
		devPID = devDesc.idProduct();

		LibUsb.freeDeviceDescriptor(devDesc);
	}

	@Override
	public String toString() {
		return (String.format("%s [%d,  %d]", this.getClass().getCanonicalName(), devVID, devPID));
	}
}
