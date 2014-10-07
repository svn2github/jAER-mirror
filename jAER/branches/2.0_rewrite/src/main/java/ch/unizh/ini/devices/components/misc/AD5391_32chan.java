package ch.unizh.ini.devices.components.misc;

import net.sf.jaer2.devices.components.misc.DAC;
import net.sf.jaer2.util.SSHSNode;

public class AD5391_32chan extends DAC {
	public AD5391_32chan(final SSHSNode componentConfigNode) {
		super("AD5391", componentConfigNode, 32, 12, 0.0f, 5.0f, 3.3f);
	}
}
