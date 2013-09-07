package net.sf.jaer2.devices;

public abstract class USBDevice extends Device {
	protected static final short VID_THESYCON = 0x152A;

	protected final short VID;
	protected final short PID;
	protected final short DID;

	public USBDevice(String deviceName, String deviceDescription, short deviceVID, short devicePID) {
		this(deviceName, deviceDescription, deviceVID, devicePID, (short) 0x0000);
	}

	public USBDevice(String deviceName, String deviceDescription, short deviceVID, short devicePID, short deviceDID) {
		super(deviceName, deviceDescription);

		VID = deviceVID;
		PID = devicePID;
		DID = deviceDID;
	}

	public short getVID() {
		return VID;
	}

	public short getPID() {
		return PID;
	}

	public short getDID() {
		return DID;
	}

	@Override
	public String toString() {
		return String.format("%s [%X:%X:%X]", name, VID, PID, DID);
	}
}
