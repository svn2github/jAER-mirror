package net.sf.jaer2.devices.components.misc.memory;

import net.sf.jaer2.devices.components.Component;

public abstract class Memory extends Component {
	private static final long serialVersionUID = 1918978964879724132L;

	private final int sizeKB;

	public Memory(final String memName, final int memSizeKB) {
		super(memName);

		sizeKB = memSizeKB;
	}

	public int getSize() {
		return sizeKB;
	}
}
