package net.sf.jaer2.devices.components.controllers.logic;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.util.TypedMap;

public class LatticeMachX0 extends Logic {
	private static final long serialVersionUID = 8956964709797461828L;

	public LatticeMachX0() {
		this("LatticeMachX0");
	}

	public LatticeMachX0(final String componentName) {
		super(componentName);
	}

	@Override
	public void program(final Command command, final TypedMap<String> arguments,
		@SuppressWarnings("unused") final Component origin) {
		// For now, pass up to parent Controller, since the CPLD doesn't program
		// anything itself or needs any special format conversions.
		getProgrammer().program(command, arguments, this);
	}
}
