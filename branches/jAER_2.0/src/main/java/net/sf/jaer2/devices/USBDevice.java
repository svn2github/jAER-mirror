package net.sf.jaer2.devices;

import li.longi.libusb4java.DeviceHandle;
import li.longi.libusb4java.LibUsb;

public abstract class USBDevice extends Device {
	// Default VID/PID/DID from Thesycon.
	public static final short VID = 0x152A;
	public static final short PID = (short) 0x8400;
	public static final short DID = 0x0000;

	protected final short devVID;
	protected final short devPID;
	protected final short devDID;

	protected final li.longi.libusb4java.Device usbDevice;
	protected final DeviceHandle usbDeviceHandle = new DeviceHandle();
	private boolean isOpen = false;

	public USBDevice(final String deviceName, final String deviceDescription, final short deviceVID,
		final short devicePID, final short deviceDID, li.longi.libusb4java.Device device) {
		super(deviceName, deviceDescription);

		devVID = deviceVID;
		devPID = devicePID;
		devDID = deviceDID;

		usbDevice = device;
	}

	public short getVID() {
		return devVID;
	}

	public short getPID() {
		return devPID;
	}

	public short getDID() {
		return devDID;
	}

	@Override
	synchronized public void open() {
		if (isOpen) {
			return;
		}

		// TODO: implement.
		LibUsb.open(usbDevice, usbDeviceHandle);

		isOpen = true;
	}

	@Override
	synchronized public void close() {
		if (!isOpen) {
			return;
		}

		// TODO: implement.
		LibUsb.close(usbDeviceHandle);

		isOpen = false;
	}

	@Override
	public String toString() {
		return String.format("%s [%X:%X:%X]", name, devVID, devPID, devDID);
	}
}
