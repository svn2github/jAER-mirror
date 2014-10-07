package net.sf.jaer2.devices.components.controllers.logic;

import net.sf.jaer2.devices.components.controllers.Controller;
import net.sf.jaer2.util.SSHSNode;

public abstract class Logic extends Controller {
	public Logic(final String componentName, final SSHSNode componentConfigNode) {
		super(componentName, componentConfigNode);
	}
}
