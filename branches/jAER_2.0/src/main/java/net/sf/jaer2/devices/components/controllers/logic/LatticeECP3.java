package net.sf.jaer2.devices.components.controllers.logic;

import net.sf.jaer2.devices.config.ConfigBase;

public class LatticeECP3 extends Logic {
	/**
	 * 
	 */
	private static final long serialVersionUID = 4245851377878757216L;

	public LatticeECP3() {
		this("LatticeECP3");
	}

	public LatticeECP3(final String componentName) {
		super(componentName);
	}

	@Override
	public void addSetting(final ConfigBase setting, final int bitAddress, final int bitLength) {
		// TODO Auto-generated method stub
	}
}
