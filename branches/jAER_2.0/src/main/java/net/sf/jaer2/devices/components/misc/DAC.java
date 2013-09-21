package net.sf.jaer2.devices.components.misc;

import net.sf.jaer2.devices.components.Component;

public class DAC extends Component {
	private static final long serialVersionUID = 419464332057192955L;

	public DAC() {
		this("DAC");
	}

	public DAC(final String componentName) {
		super(componentName);
	}

	public float getVdd() {
		// TODO Auto-generated method stub
		return 0;
	}

	public float getRefMaxVolts() {
		// TODO Auto-generated method stub
		return 0;
	}

	public float getRefMinVolts() {
		// TODO Auto-generated method stub
		return 0;
	}
}
