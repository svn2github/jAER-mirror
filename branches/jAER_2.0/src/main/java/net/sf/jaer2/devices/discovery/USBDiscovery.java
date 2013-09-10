package net.sf.jaer2.devices.discovery;

import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.Map;

import javafx.collections.ListChangeListener;
import li.longi.libusb4java.Device;
import li.longi.libusb4java.DeviceDescriptor;
import li.longi.libusb4java.LibUsb;
import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.util.Reflections;
import net.sf.jaer2.util.TripleRO;

public class USBDiscovery {
	private static final Map<TripleRO<Short, Short, Short>, Class<? extends USBDevice>> compatibleUSBDevices = new HashMap<>();
	private static final Map<Device, USBDevice> currentUSBDevices = new HashMap<>();

	/**
	 * Fill compatibleUSBDevices map at startup with the needed data on the VID,
	 * PID and DID of the various supported devices, to later construct the
	 * right instances for these devices, when they are detected.
	 */
	static {
		for (final Class<? extends USBDevice> usbDevice : Reflections.getSubClasses(USBDevice.class)) {
			Field vidField;
			short vid;

			try {
				vidField = usbDevice.getField("VID");
				vid = vidField.getShort(null);
			}
			catch (NoSuchFieldException | SecurityException | IllegalArgumentException | IllegalAccessException e) {
				// TODO: log.
				continue;
			}

			Field pidField;
			short pid;

			try {
				pidField = usbDevice.getField("PID");
				pid = pidField.getShort(null);
			}
			catch (NoSuchFieldException | SecurityException | IllegalArgumentException | IllegalAccessException e) {
				// TODO: log.
				continue;
			}

			Field didField;
			short did;

			try {
				didField = usbDevice.getField("DID");
				did = didField.getShort(null);
			}
			catch (NoSuchFieldException | SecurityException | IllegalArgumentException | IllegalAccessException e) {
				// TODO: log.
				continue;
			}

			// Add to compatible devices list.
			USBDiscovery.compatibleUSBDevices.put(new TripleRO<>(vid, pid, did), usbDevice);
		}
	}

	/** USB device discovery needs a running background thread. */
	private static Thread usbDiscovery;
	private static boolean discoveryActive = false;

	synchronized public static void start() {
		if (USBDiscovery.discoveryActive) {
			return;
		}

		// Configure USB device list thread.
		final USBDeviceList usbList = new USBDeviceList();

		USBDeviceList.subscribe(new ListChangeListener<Device>() {
			@Override
			public void onChanged(final Change<? extends Device> c) {
				while (c.next()) {
					final DeviceDescriptor devDesc = new DeviceDescriptor();

					for (final Device removedDevice : c.getRemoved()) {
						// Device was removed, make sure to close it, if it's
						// open, and then remove it from the global list.
						final USBDevice device = USBDiscovery.currentUSBDevices.remove(removedDevice);

						if (device != null) {
							device.close();
						}
					}

					for (final Device addedDevice : c.getAddedSubList()) {
						LibUsb.getDeviceDescriptor(addedDevice, devDesc);

						// Check if any compatible device exists.
						final Class<? extends USBDevice> deviceClass = USBDiscovery.compatibleUSBDevices
							.get(new TripleRO<>(devDesc.idVendor(), devDesc.idProduct(), devDesc.bcdDevice()));

						LibUsb.freeDeviceDescriptor(devDesc);

						// Unknown device, skip.
						if (deviceClass == null) {
							continue;
						}

						// Compatible device found, instantiate it.
						final USBDevice device = Reflections.newInstanceForClassWithArgument(deviceClass, Device.class,
							addedDevice);

						// Error in above call to instantiate device, skip.
						// Check
						// logs for real failure cause.
						if (device == null) {
							continue;
						}

						USBDiscovery.currentUSBDevices.put(addedDevice, device);
					}
				}
			}
		});

		// Start discovery on all USB interfaces.
		USBDiscovery.usbDiscovery = new Thread(usbList);
		USBDiscovery.usbDiscovery.start();

		USBDiscovery.discoveryActive = true;
	}

	synchronized public static void stop() {
		if (!USBDiscovery.discoveryActive) {
			return;
		}

		USBDiscovery.usbDiscovery.interrupt();

		try {
			USBDiscovery.usbDiscovery.join();
		}
		catch (final InterruptedException e) {
			// Can't happen, as we interrupted it ourself before.
		}

		// TODO: how to deregister listener?

		USBDiscovery.discoveryActive = false;
	}
}
