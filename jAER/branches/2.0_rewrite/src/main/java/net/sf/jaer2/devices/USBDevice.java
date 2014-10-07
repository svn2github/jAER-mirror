package net.sf.jaer2.devices;

import java.io.IOException;
import java.nio.ByteBuffer;

import org.usb4java.BufferUtils;
import org.usb4java.DeviceHandle;
import org.usb4java.LibUsb;

public abstract class USBDevice extends Device {
	// Default VID/PID/DID from Thesycon.
	public static final short VID = 0x152A;
	public static final short PID = (short) 0x8400;
	public static final short DID = 0x0000;

	protected final short devVID;
	protected final short devPID;
	protected final short devDID;

	protected final org.usb4java.Device usbDevice;
	protected final DeviceHandle usbDeviceHandle;
	private boolean isOpen = false;

	public USBDevice(final String deviceName, final String deviceDescription, final short deviceVID,
		final short devicePID, final short deviceDID, final org.usb4java.Device device) {
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
	 * Sends a vendor request to send (OUT direction) data. Value and Index are
	 * set to zero, and no actual data is going to be sent. This is a blocking
	 * method.
	 *
	 * @param request
	 *            the vendor request byte, identifies the request on the device
	 * @throws IOException
	 */
	synchronized public void sendVendorRequestOut(final byte request) throws IOException {
		sendVendorRequestOut(request, (short) 0, (short) 0);
	}

	/**
	 * Sends a vendor request to send (OUT direction) data. No actual data is
	 * going to be sent. This is a blocking method.
	 *
	 * @param request
	 *            the vendor request byte, identifies the request on the device
	 * @param value
	 *            the value of the request (wValue USB field)
	 * @param index
	 *            the "index" of the request (wIndex USB field)
	 * @throws IOException
	 */
	synchronized public void sendVendorRequestOut(final byte request, final short value, final short index)
		throws IOException {
		sendVendorRequestOut(request, value, index, (ByteBuffer) null);
	}

	/**
	 * Sends a vendor request to send (OUT direction) data. This is a blocking
	 * method.
	 *
	 * @param request
	 *            the vendor request byte, identifies the request on the device
	 * @param value
	 *            the value of the request (wValue USB field)
	 * @param index
	 *            the "index" of the request (wIndex USB field)
	 * @param buffer
	 *            the buffer where the data being sent is held
	 * @throws IOException
	 */
	synchronized public void sendVendorRequestOut(final byte request, final short value, final short index,
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
	 *            the value of the request (wValue USB field)
	 * @param index
	 *            the "index" of the request (wIndex USB field)
	 * @param buffer
	 *            the buffer where the data being received is going to be held
	 * @throws IOException
	 */
	synchronized public void sendVendorRequestIn(final byte request, final short value, final short index,
		final ByteBuffer buffer) throws IOException {
		if (buffer.capacity() == 0) {
			throw new IllegalArgumentException("Unable to send vendor request (direction IN) with an empty buffer!");
		}

		if (!isOpen()) {
			open();
		}

		final byte bmRequestType = (byte) (LibUsb.ENDPOINT_IN | LibUsb.REQUEST_TYPE_VENDOR | LibUsb.RECIPIENT_DEVICE);

		final int status = LibUsb.controlTransfer(usbDeviceHandle, bmRequestType, request, value, index, buffer, 0);
		if (status < LibUsb.SUCCESS) {
			throw new IOException("Unable to send vendor request (direction IN) " + String.format("0x%x", request)
				+ ": " + LibUsb.errorName(status));
		}

		if (status != buffer.capacity()) {
			throw new IOException("Wrong number of bytes transferred, wanted: " + buffer.capacity() + ", got: "
				+ status);
		}

		// Update ByteBuffer internal limit to show how much was successfully
		// read. usb4java never touches the ByteBuffer's internals by design, so
		// we do it here.
		buffer.limit(buffer.capacity());
	}

	@Override
	public String toString() {
		return String.format("%s [%X:%X:%X]", getName(), devVID, devPID, devDID);
	}
}
