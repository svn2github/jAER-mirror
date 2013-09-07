package ch.unizh.ini.devices;

import net.sf.jaer2.devices.components.misc.InvenSense6050;
import net.sf.jaer2.eventio.translators.Translator;

import com.sun.org.apache.bcel.internal.generic.I2C;

public class ApsDvs10IMU extends ApsDvs10 {
	public ApsDvs10IMU() {
		super();

		// Differentiate between versions with IMU and without using DID.
		DID = 0x0100;

		// Add inertial measurement unit.
		final I2C invenSenseIMU = new InvenSense6050(0x68);
		invenSenseIMU.setProgrammer(fx2);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		// TODO Auto-generated method stub
		return null;
	}
}
