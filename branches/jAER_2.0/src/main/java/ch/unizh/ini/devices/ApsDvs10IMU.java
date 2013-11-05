package ch.unizh.ini.devices;

import li.longi.libusb4java.Device;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.controllers.FX2;
import net.sf.jaer2.devices.components.misc.InvenSense6050;
import net.sf.jaer2.eventio.translators.Translator;
import ch.unizh.ini.eventio.translator.INIv1;

public class ApsDvs10IMU extends ApsDvs10 {
	private static final long serialVersionUID = 3287324623698834991L;

	@SuppressWarnings("hiding")
	public static final short DID = 0x0100;

	public ApsDvs10IMU(final Device usbDevice) {
		super(usbDevice, ApsDvs10IMU.DID);

		// Add inertial measurement unit.
		final Component invenSenseIMU = new InvenSense6050(0x68);
		invenSenseIMU.setProgrammer(getComponent(FX2.class, "FX2"));
		addComponent(invenSenseIMU);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		return INIv1.class;
	}
}
