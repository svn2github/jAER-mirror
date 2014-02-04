package net.sf.jaer;

import li.longi.libusb4java.Device;
import li.longi.libusb4java.DeviceDescriptor;
import li.longi.libusb4java.DeviceHandle;
import li.longi.libusb4java.LibUsb;
import li.longi.libusb4java.utils.DescriptorUtils;

public class UsbDevice {
	private Device dev;
	private DeviceDescriptor devDesc;
	private short devVID;
	private short devPID;
	private int busAddr;
	private int devAddr;

	private DeviceHandle devHandle;
	private String devManufacturer;
	private String devProduct;
	private String devSerialNumber;

	public UsbDevice(Device device) {
		dev = LibUsb.refDevice(device);

		devDesc = new DeviceDescriptor();
		LibUsb.getDeviceDescriptor(dev, devDesc);

		devVID = devDesc.idVendor();
		devPID = devDesc.idProduct();

		busAddr = LibUsb.getBusNumber(dev);
		devAddr = LibUsb.getDeviceAddress(dev);
	}

	public void open() throws Exception {
		devHandle = new DeviceHandle();
		if (LibUsb.open(dev, devHandle) != LibUsb.SUCCESS) {
			devHandle = null;
			System.out.println("Failopen");
			throw new Exception("Impossible to open USB device.");
		}
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
			catch (Exception e) {
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
		close();
	}

	public String fullDescription() {
		getStringDescriptors();

		StringBuilder desc = new StringBuilder();

		desc.append(toString() + "\n");
		desc.append(String.format("Device VID: %H, PID: %H\n", devVID & 0xFFFF, devPID & 0xFFFF));
		desc.append(String.format("Device Speed: %s\n", DescriptorUtils.getSpeedName(LibUsb.getDeviceSpeed(dev))));
		desc.append(DescriptorUtils.dump(devDesc, devManufacturer, devProduct, devSerialNumber));

		return (desc.toString());
	}

	public short getDevVID() {
		return devVID;
	}

	public void setDevVID(short devVID) {
		this.devVID = devVID;
	}

	public short getDevPID() {
		return devPID;
	}

	public void setDevPID(short devPID) {
		this.devPID = devPID;
	}

	@Override
	public String toString() {
		getStringDescriptors();

		return (String.format("%s %s %s [Bus: %d, Addr: %d]", devManufacturer, devProduct, devSerialNumber, busAddr, devAddr));
	}
}
