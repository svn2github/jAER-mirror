package net.sf.jaer2.devices.components.controllers.logic;

import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.devices.config.ConfigBase;

public abstract class Logic extends Controller {
	public abstract void addSetting(ConfigBase setting, int bitAddress, int bitLength);
}
