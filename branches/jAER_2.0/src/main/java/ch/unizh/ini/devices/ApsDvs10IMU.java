package ch.unizh.ini.devices;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.controllers.FX2;
import net.sf.jaer2.devices.components.misc.InvenSense6050;
import net.sf.jaer2.eventio.translators.Translator;
import net.sf.jaer2.util.Reflections;

public class ApsDvs10IMU extends ApsDvs10 {
	public ApsDvs10IMU() {
		super();

		// Differentiate between versions with IMU and without using DID.
		Reflections.setFinalField(this, "DID", 0x0100);

		// Add inertial measurement unit.
		final Component invenSenseIMU = new InvenSense6050(0x68);
		invenSenseIMU.setProgrammer(getComponent(FX2.class, "FX2"));
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// TODO Auto-generated method stub
		return null;
	}
}
