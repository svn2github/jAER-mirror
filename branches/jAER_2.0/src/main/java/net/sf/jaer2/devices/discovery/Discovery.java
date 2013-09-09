package net.sf.jaer2.devices.discovery;

import javafx.collections.ListChangeListener;
import de.ailis.usb4java.libusb.Device;


public class Discovery {
	//private static final SortedSet<Class<? extends Device>> deviceTypes = Reflections.getSubClasses(Device.class);

	static {
		USBDeviceList.subscribe(new ListChangeListener<Device>() {
			@Override
			public void onChanged(Change<? extends Device> list) {

			}
		});
	}

	synchronized public static void start() {

	}

	synchronized public static void stop() {

	}
}
