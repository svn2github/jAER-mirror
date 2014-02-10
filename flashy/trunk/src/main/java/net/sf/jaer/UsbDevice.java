package net.sf.jaer;

import java.nio.ByteBuffer;
import java.nio.IntBuffer;
import java.nio.charset.StandardCharsets;

import javafx.scene.control.TextArea;
import li.longi.USBTransferThread.RestrictedTransfer;
import li.longi.USBTransferThread.RestrictedTransferCallback;
import li.longi.USBTransferThread.USBTransferThread;
import li.longi.libusb4java.Device;
import li.longi.libusb4java.DeviceDescriptor;
import li.longi.libusb4java.DeviceHandle;
import li.longi.libusb4java.LibUsb;
import li.longi.libusb4java.utils.BufferUtils;
import li.longi.libusb4java.utils.DescriptorUtils;

public class UsbDevice {
	private final Device dev;
	private final DeviceDescriptor devDesc;
	private short devVID;
	private short devPID;
	private final int busAddr;
	private final int devAddr;

	private DeviceHandle devHandle;
	private String devManufacturer;
	private String devProduct;
	private String devSerialNumber;

	public UsbDevice(final Device device) {
		dev = LibUsb.refDevice(device);

		devDesc = new DeviceDescriptor();
		LibUsb.getDeviceDescriptor(dev, devDesc);

		devVID = devDesc.idVendor();
		devPID = devDesc.idProduct();

		busAddr = LibUsb.getBusNumber(dev);
		devAddr = LibUsb.getDeviceAddress(dev);
	}

	public void open() throws Exception {
		// Already opened.
		if (devHandle != null) {
			return;
		}

		devHandle = new DeviceHandle();
		if (LibUsb.open(dev, devHandle) != LibUsb.SUCCESS) {
			devHandle = null;
			System.out.println("Failopen");
			throw new Exception("Impossible to open USB device.");
		}

		final IntBuffer activeConfig = BufferUtils.allocateIntBuffer();
		LibUsb.getConfiguration(devHandle, activeConfig);

		if (activeConfig.get() != 1) {
			LibUsb.setConfiguration(devHandle, 1);
		}

		LibUsb.claimInterface(devHandle, 0);
	}

	public void close() {
		if (devHandle != null) {
			LibUsb.close(devHandle);
			devHandle = null;
		}
	}

	private void getStringDescriptors() {
		if (devManufacturer != null) {
			// Already got them, return right away.
			return;
		}

		// Get device's string descriptors.
		// Need to open it, if not already done.
		if (devHandle == null) {
			try {
				open();
			}
			catch (final Exception e) {
				// Fill with empty strings on error.
				devManufacturer = "Impossible";
				devProduct = "to open";
				devSerialNumber = "device!";

				// Impossible to open, return.
				return;
			}
		}

		// Device open, let's get the actual string descriptors.
		devManufacturer = LibUsb.getStringDescriptor(devHandle, devDesc.iManufacturer());
		devProduct = LibUsb.getStringDescriptor(devHandle, devDesc.iProduct());
		if (devDesc.iSerialNumber() != 0) {
			devSerialNumber = LibUsb.getStringDescriptor(devHandle, devDesc.iSerialNumber());
		}

		// Close again.
		// close();
	}

	public String fullDescription() {
		getStringDescriptors();

		final StringBuilder desc = new StringBuilder();

		desc.append(toString() + "\n");
		desc.append(String.format("Device VID: %04X, PID: %04X\n", devVID & 0xFFFF, devPID & 0xFFFF));
		desc.append(String.format("Device Speed: %s\n", DescriptorUtils.getSpeedName(LibUsb.getDeviceSpeed(dev))));
		desc.append(DescriptorUtils.dump(devDesc, devManufacturer, devProduct, devSerialNumber));

		return (desc.toString());
	}

	public short getDevVID() {
		return devVID;
	}

	public void setDevVID(final short devVID) {
		this.devVID = devVID;
	}

	public short getDevPID() {
		return devPID;
	}

	public void setDevPID(final short devPID) {
		this.devPID = devPID;
	}

	@Override
	public String toString() {
		getStringDescriptors();

		return (String.format("%s %s %s [Bus: %d, Addr: %d]", devManufacturer, devProduct, devSerialNumber, busAddr,
			devAddr));
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
	 * @param dataBuffer
	 *            the data which is to be transmitted to the device (null means
	 *            no data)
	 */
	synchronized public void sendVendorRequest(final byte request, final short value, final short index,
		ByteBuffer dataBuffer) throws Exception {
		if (devHandle == null) {
			open();
		}

		if (dataBuffer == null) {
			dataBuffer = BufferUtils.allocateByteBuffer(0);
		}

		final byte bmRequestType = (byte) (LibUsb.ENDPOINT_OUT | LibUsb.REQUEST_TYPE_VENDOR | LibUsb.RECIPIENT_DEVICE);

		final int status = LibUsb.controlTransfer(devHandle, bmRequestType, request, value, index, dataBuffer, 0);
		if (status < LibUsb.SUCCESS) {
			throw new Exception("Unable to send vendor OUT request " + String.format("0x%x", request) + ": "
				+ LibUsb.errorName(status));
		}

		if (status != dataBuffer.capacity()) {
			throw new Exception("Wrong number of bytes transferred, wanted: " + dataBuffer.capacity() + ", got: "
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
	 */
	synchronized public ByteBuffer sendVendorRequestIN(final byte request, final short value, final short index,
		final int dataLength) throws Exception {
		if (dataLength == 0) {
			throw new Exception("Unable to send vendor IN request with dataLength of zero!");
		}

		if (devHandle == null) {
			open();
		}

		final ByteBuffer dataBuffer = BufferUtils.allocateByteBuffer(dataLength);

		final byte bmRequestType = (byte) (LibUsb.ENDPOINT_IN | LibUsb.REQUEST_TYPE_VENDOR | LibUsb.RECIPIENT_DEVICE);

		final int status = LibUsb.controlTransfer(devHandle, bmRequestType, request, value, index, dataBuffer, 0);
		if (status < LibUsb.SUCCESS) {
			throw new Exception("Unable to send vendor IN request " + String.format("0x%x", request) + ": "
				+ LibUsb.errorName(status));
		}

		if (status != dataLength) {
			throw new Exception("Wrong number of bytes transferred, wanted: " + dataLength + ", got: " + status);
		}

		// Update ByteBuffer internal limit to show how much was successfully
		// read.
		// usb4java never touches the ByteBuffer's internals by design, so we do
		// it here.
		dataBuffer.limit(dataLength);

		return (dataBuffer);
	}

	synchronized public void listenToEP(final byte endpoint, final byte type, final int bufNum, final int bufSize,
		final TextArea outputArea) {
		final USBTransferThread usbTT = new USBTransferThread(devHandle, endpoint, type,
			new RestrictedTransferCallback() {
				@Override
				public void processTransfer(final RestrictedTransfer t) {
					// If successful transfer, append its data to the output
					// text area.
					if (t.status() == LibUsb.TRANSFER_COMPLETED) {
						// Print error messages.
						if (t.buffer().get(0) == 0x00) {
							final int errorCode = t.buffer().get(1) & 0xFF;

							final int timeStamp = t.buffer().getInt(2);

							final byte[] errorMsgBytes = new byte[t.buffer().limit() - 6];
							t.buffer().position(6);
							t.buffer().get(errorMsgBytes, 0, errorMsgBytes.length);
							t.buffer().position(0);
							final String errorMsg = new String(errorMsgBytes, StandardCharsets.UTF_8);

							final String output = String.format("%s - Error: %d, Time: %d\n", errorMsg, errorCode,
								timeStamp);

							GUISupport.runOnJavaFXThread(new Runnable() {
								@Override
								public void run() {
									outputArea.appendText(output);
								}
							});
						}
					}
				}

				@Override
				public void prepareTransfer(@SuppressWarnings("unused") final RestrictedTransfer t) {
					// Nothing to do here.
				}
			}, bufNum, bufSize);

		usbTT.start();
	}
}
