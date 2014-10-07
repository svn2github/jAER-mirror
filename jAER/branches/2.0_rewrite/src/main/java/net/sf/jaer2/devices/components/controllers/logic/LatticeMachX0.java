package net.sf.jaer2.devices.components.controllers.logic;

import net.sf.jaer2.util.SSHSNode;


public class LatticeMachX0 extends Logic {
	public LatticeMachX0(final SSHSNode componentConfigNode) {
		this("LatticeMachX0", componentConfigNode);
	}

	public LatticeMachX0(final String componentName, final SSHSNode componentConfigNode) {
		super(componentName, componentConfigNode);
	}
}
