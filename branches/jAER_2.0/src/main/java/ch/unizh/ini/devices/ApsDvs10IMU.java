package ch.unizh.ini.devices;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.controllers.FX2;
import net.sf.jaer2.devices.components.misc.InvenSense6050;
import net.sf.jaer2.eventio.translators.Translator;

import org.usb4java.Device;

public class ApsDvs10IMU extends ApsDvs10 {
	@SuppressWarnings("hiding")
	public static final short DID = 0x0100;

	public ApsDvs10IMU(final Device usbDevice) {
		super(usbDevice, ApsDvs10IMU.DID);

		// Add inertial measurement unit.
		final Component invenSenseIMU = new InvenSense6050(getConfigNode(), 0x68);
		invenSenseIMU.setProgrammer(getComponent(FX2.class, "FX2"));
		addComponent(invenSenseIMU);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		return null;
	}
}
