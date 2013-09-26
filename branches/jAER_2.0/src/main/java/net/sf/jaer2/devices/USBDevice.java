package net.sf.jaer2.devices;

import java.io.IOException;
import java.nio.ByteBuffer;

import li.longi.libusb4java.DeviceHandle;
import li.longi.libusb4java.LibUsb;
import li.longi.libusb4java.utils.BufferUtils;

public abstract class USBDevice extends Device {
	private static final long serialVersionUID = -1443942547496897821L;

	// Default VID/PID/DID from Thesycon.
	public static final short VID = 0x152A;
	public static final short PID = (short) 0x8400;
	public static final short DID = 0x0000;

	protected final short devVID;
	protected final short devPID;
	protected final short devDID;

	transient protected final li.longi.libusb4java.Device usbDevice;
	transient protected final DeviceHandle usbDeviceHandle;
	transient private boolean isOpen = false;

	public USBDevice(final String deviceName, final String deviceDescription, final short deviceVID,
		final short devicePID, final short deviceDID, final li.longi.libusb4java.Device device) {
		super(deviceName, deviceDescription);

		devVID = deviceVID;
		devPID = devicePID;
		devDID = deviceDID;

		usbDevice = device;
		usbDeviceHandle = new DeviceHandle();
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

	synchronized public boolean isOpen() {
		return isOpen;
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

	/**
	 * Sends a vendor request without any data packet, value and index are set
	 * to zero. This is a blocking method.
	 *
	 * @param request
	 *            the vendor request byte, identifies the request on the device
	 * @throws IOException
	 */
	synchronized public void sendVendorRequest(final byte request) throws IOException {
		sendVendorRequest(request, (short) 0, (short) 0);
	}

	/**
	 * Sends a vendor request without any data packet but with request, value
	 * and index. This is a blocking method.
	 *
	 * @param request
	 *            the vendor request byte, identifies the request on the device
	 * @param value
	 *            the value of the request (bValue USB field)
	 * @param index
	 *            the "index" of the request (bIndex USB field)
	 * @throws IOException
	 */
	synchronized public void sendVendorRequest(final byte request, final short value, final short index)
		throws IOException {
		sendVendorRequest(request, value, index, (ByteBuffer) null);
	}

	/**
	 * Sends a vendor request with data (including special bits). This is a
	 * blocking method.
	 *
	 * @param requestType
	 *            the vendor requestType byte (used for special cases, usually
	 *            0)
	 * @param request
	 *            the vendor request byte, identifies the request on the device
	 * @param value
	 *            the value of the request (bValue USB field)
	 * @param index
	 *            the "index" of the request (bIndex USB field)
	 * @param buffer
	 *            the data which is to be transmitted to the device (null means
	 *            no data)
	 * @throws IOException
	 */
	synchronized public void sendVendorRequest(final byte request, final short value, final short index,
		final ByteBuffer buffer) throws IOException {
		if (!isOpen()) {
			open();
		}

		final ByteBuffer dataBuffer = (buffer == null) ? (BufferUtils.allocateByteBuffer(0)) : (buffer);

		final byte bmRequestType = (byte) (LibUsb.ENDPOINT_OUT | LibUsb.REQUEST_TYPE_VENDOR | LibUsb.RECIPIENT_DEVICE);

		final int status = LibUsb.controlTransfer(usbDeviceHandle, bmRequestType, request, value, index, dataBuffer, 0);
		if (status < LibUsb.SUCCESS) {
			throw new IOException("Unable to send vendor request (direction OUT) " + String.format("0x%x", request)
				+ ": " + LibUsb.errorName(status));
		}

		if (status != dataBuffer.capacity()) {
			throw new IOException("Wrong number of bytes transferred, wanted: " + dataBuffer.capacity() + ", got: "
				+ status);
		}
	}

	/**
	 * Sends a vendor request to receive (IN direction) data. This is a blocking
	 * method.
	 *
	 * @param request
	 *            the vendor request byte, identifies the request on the device
	 * @param value
	 *            the value of the request (bValue USB field)
	 * @param index
	 *            the "index" of the request (bIndex USB field)
	 * @param dataLength
	 *            amount of data to receive, determines size of returned buffer
	 *            (must be greater than 0)
	 * @return a buffer containing the data requested from the device
	 * @throws IOException
	 */
	synchronized public ByteBuffer sendVendorRequestIN(final byte request, final short value, final short index,
		final int dataLength) throws IOException {
		if (dataLength == 0) {
			throw new IllegalArgumentException("Unable to send vendor request (direction IN) with dataLength of zero!");
		}

		if (!isOpen()) {
			open();
		}

		final ByteBuffer dataBuffer = BufferUtils.allocateByteBuffer(dataLength);

		final byte bmRequestType = (byte) (LibUsb.ENDPOINT_IN | LibUsb.REQUEST_TYPE_VENDOR | LibUsb.RECIPIENT_DEVICE);

		final int status = LibUsb.controlTransfer(usbDeviceHandle, bmRequestType, request, value, index, dataBuffer, 0);
		if (status < LibUsb.SUCCESS) {
			throw new IOException("Unable to send vendor request (direction IN) " + String.format("0x%x", request)
				+ ": " + LibUsb.errorName(status));
		}

		if (status != dataLength) {
			throw new IOException("Wrong number of bytes transferred, wanted: " + dataLength + ", got: " + status);
		}

		// Update ByteBuffer internal limit to show how much was successfully
		// read. usb4java never touches the ByteBuffer's internals by design, so
		// we do it here.
		dataBuffer.limit(dataLength);

		return (dataBuffer);
	}

	@Override
	public String toString() {
		return String.format("%s [%X:%X:%X]", getName(), devVID, devPID, devDID);
	}
}
