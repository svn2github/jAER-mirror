package net.sf.jaer2.devices.discovery;

import java.util.ArrayList;
import java.util.List;

import javafx.collections.FXCollections;
import javafx.collections.ListChangeListener;
import javafx.collections.ObservableList;

import com.google.common.collect.Lists;

import de.ailis.usb4java.libusb.Context;
import de.ailis.usb4java.libusb.Device;
import de.ailis.usb4java.libusb.DeviceList;
import de.ailis.usb4java.libusb.HotplugCallback;
import de.ailis.usb4java.libusb.HotplugCallbackHandle;
import de.ailis.usb4java.libusb.LibUsb;

public class USBDeviceList implements Runnable {
	private static ObservableList<Device> usbDevices = FXCollections.observableArrayList();

	public static void subscribe(final ListChangeListener<? super Device> listener) {
		USBDeviceList.usbDevices.addListener(listener);
	}

	private static void updateDevices() {
		final DeviceList l = new DeviceList();
		LibUsb.getDeviceList(null, l);

		// Temporary storage to allow modification.
		final List<Device> newUsbDevices = Lists.newArrayList(l);

		// Replace with new data in a non-destructive way, by not touching
		// values that were already present.
		final List<Device> removals = new ArrayList<>();

		for (final Device device : USBDeviceList.usbDevices) {
			if (newUsbDevices.contains(device)) {
				newUsbDevices.remove(device);
			}
			else {
				removals.add(device);
			}
		}

		// Remove all items that need to be deleted and add all the new ones in
		// only one call each, updating the reference counts.
		for (final Device device : removals) {
			USBDeviceList.usbDevices.remove(device);
			LibUsb.unrefDevice(device);
		}

		for (final Device device : newUsbDevices) {
			USBDeviceList.usbDevices.add(LibUsb.refDevice(device));
		}

		// Clear temporary storage.
		removals.clear();
		newUsbDevices.clear();

		LibUsb.freeDeviceList(l, true);
	}

	private static class HotplugMaintainList implements HotplugCallback {
		@Override
		public int processEvent(@SuppressWarnings("unused") final Context context, final Device device,
			final int event, @SuppressWarnings("unused") final Object userData) {
			// Add or remove devices from global list.
			if (event == LibUsb.HOTPLUG_EVENT_DEVICE_ARRIVED) {
				USBDeviceList.usbDevices.add(LibUsb.refDevice(device));
			}

			if (event == LibUsb.HOTPLUG_EVENT_DEVICE_LEFT) {
				USBDeviceList.usbDevices.remove(device);
				LibUsb.unrefDevice(device);
			}

			// Continue to serve hotplug events.
			return 0;
		}
	}

	@Override
	public void run() {
		LibUsb.init(null);

		// Determine USB devices connected at startup.
		USBDeviceList.updateDevices();

		// Setup hotplug callback to update the global list every time there are
		// changes to the connected USB devices.
		final HotplugCallbackHandle hotplugHandle = new HotplugCallbackHandle();

		if (LibUsb.hasCapability(LibUsb.CAP_HAS_HOTPLUG)) {
			LibUsb.hotplugRegisterCallback(null,
				LibUsb.HOTPLUG_EVENT_DEVICE_ARRIVED | LibUsb.HOTPLUG_EVENT_DEVICE_LEFT, 0, LibUsb.HOTPLUG_MATCH_ANY,
				LibUsb.HOTPLUG_MATCH_ANY, LibUsb.HOTPLUG_MATCH_ANY, new HotplugMaintainList(), null, hotplugHandle);
		}

		while (!Thread.currentThread().isInterrupted()) {
			// Update devices list manually if no Hotplug available.
			if (!LibUsb.hasCapability(LibUsb.CAP_HAS_HOTPLUG)) {
				USBDeviceList.updateDevices();
			}

			// Handle USB events (1 second timeout).
			LibUsb.handleEventsTimeout(null, 1000000);
		}

		// Cleanup and exit.
		if (LibUsb.hasCapability(LibUsb.CAP_HAS_HOTPLUG)) {
			LibUsb.hotplugDeregisterCallback(null, hotplugHandle);
		}

		LibUsb.exit(null);
	}
}
