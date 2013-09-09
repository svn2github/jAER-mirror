package net.sf.jaer2.devices.discovery;

import java.util.ArrayList;
import java.util.List;

import net.sf.jaer2.devices.Device;

public class Discovery {
	private static final List<Device> compatibleDevices = new ArrayList<>();
	private static boolean discoveryActive = false;

	synchronized public static void start() {
		if (discoveryActive) {
			return;
		}

		// Start discovery on all supported interfaces.
		Thread usbDiscovery = new Thread(new USBDeviceList());
		usbDiscovery.start();

		discoveryActive = true;
	}

	synchronized public static void stop() {
		if (!discoveryActive) {
			return;
		}

		// TODO: implement.

		discoveryActive = false;
	}
}
