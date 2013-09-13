package net.sf.jaer2.devices.components.misc;

import net.sf.jaer2.devices.components.Component;

public class InvenSense6050 extends Component {
	public InvenSense6050(final int i2cAddress) {
		this("InvenSense6050", i2cAddress);
	}

	public InvenSense6050(final String componentName, final int i2cAddress) {
		super(componentName);
	}
}
