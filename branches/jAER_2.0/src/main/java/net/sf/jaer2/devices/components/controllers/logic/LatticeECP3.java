package net.sf.jaer2.devices.components.controllers.logic;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.util.TypedMap;

public class LatticeECP3 extends Logic {
	private static final long serialVersionUID = 4245851377878757216L;

	public LatticeECP3() {
		this("LatticeECP3");
	}

	public LatticeECP3(final String componentName) {
		super(componentName);
	}

	@Override
	public void program(final Command command, final TypedMap<String> arguments,
		@SuppressWarnings("unused") final Component origin) {
		// For now, pass up to parent Controller, since the FPGA doesn't program
		// anything itself or needs any special format conversions.
		getProgrammer().program(command, arguments, this);
	}
}
