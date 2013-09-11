package net.sf.jaer2.devices.discovery;

import java.util.ArrayList;
import java.util.List;

import net.sf.jaer2.devices.Device;

public class Discovery {
	private static final List<Device> compatibleDevices = new ArrayList<>();
	private static boolean discoveryActive = false;

	synchronized public static void start() {
		if (Discovery.discoveryActive) {
			return;
		}

		USBDiscovery.start();

		Discovery.discoveryActive = true;
	}

	synchronized public static void stop() {
		if (!Discovery.discoveryActive) {
			return;
		}

		USBDiscovery.stop();

		Discovery.discoveryActive = false;
	}
}
