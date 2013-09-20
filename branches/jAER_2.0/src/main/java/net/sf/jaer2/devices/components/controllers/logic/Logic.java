package net.sf.jaer2.devices.components.controllers.logic;

import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.config.ConfigBase;

public abstract class Logic extends Controller {
	/**
	 *
	 */
	private static final long serialVersionUID = 3443733104842889174L;

	public Logic(final String componentName) {
		super(componentName);
	}

	public abstract void addSetting(ConfigBase setting, int bitAddress, int bitLength);
}
