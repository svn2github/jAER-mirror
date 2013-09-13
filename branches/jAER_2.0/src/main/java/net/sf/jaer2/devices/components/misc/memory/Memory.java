package net.sf.jaer2.devices.components.misc.memory;

import net.sf.jaer2.devices.components.Component;

public abstract class Memory extends Component {
	private final int sizeKB;

	public Memory(final String memName, final int memSizeKB) {
		super(memName);

		sizeKB = memSizeKB;
	}

	public int getSize() {
		return sizeKB;
	}
}
