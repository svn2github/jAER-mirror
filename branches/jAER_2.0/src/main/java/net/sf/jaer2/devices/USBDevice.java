package net.sf.jaer2.devices;

public abstract class USBDevice extends Device {
	// Default VID/PID/DID from Thesycon.
	public static final short VID = 0x152A;
	public static final short PID = (short) 0x8400;
	public static final short DID = 0x0000;

	private final short devVID;
	private final short devPID;
	private final short devDID;
	private boolean isOpen = false;

	public USBDevice(final String deviceName, final String deviceDescription, final short deviceVID,
		final short devicePID, final short deviceDID) {
		super(deviceName, deviceDescription);

		devVID = deviceVID;
		devPID = devicePID;
		devDID = deviceDID;
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

		isOpen = true;
	}

	@Override
	synchronized public void close() {
		if (!isOpen) {
			return;
		}

		// TODO: implement.

		isOpen = false;
	}

	@Override
	public String toString() {
		return String.format("%s [%X:%X:%X]", name, devVID, devPID, devDID);
	}
}
