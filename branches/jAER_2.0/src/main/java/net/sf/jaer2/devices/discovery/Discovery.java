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

		USBDiscovery.start();

		discoveryActive = true;
	}

	synchronized public static void stop() {
		if (!discoveryActive) {
			return;
		}

		USBDiscovery.stop();

		discoveryActive = false;
	}
}
