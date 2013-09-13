package net.sf.jaer2.devices.components.misc;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.config.pots.VPot;

public class DAC extends Component {
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

	public void addSetting(final VPot bias, final int dacChannel) {
		bias.setDac(this);
		super.addSetting(bias, dacChannel);
	}
}
