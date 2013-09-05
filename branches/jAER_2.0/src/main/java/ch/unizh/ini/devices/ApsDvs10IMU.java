package ch.unizh.ini.devices;

import com.sun.org.apache.bcel.internal.generic.I2C;

public class ApsDvs10IMU extends ApsDvs10 {
	public ApsDvs10IMU() {
		super();

		// Add inertial measurement unit.
		I2C invenSenseIMU = new InvenSense6050(0x68);
		invenSenseIMU.setProgrammer(fx2);
	}
}
