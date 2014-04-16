package net.sf.jaer2.devices.components.misc;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.util.SSHSNode;

public class InvenSense6050 extends Component {
	public InvenSense6050(final SSHSNode componentConfigNode, final int i2cAddress) {
		this("InvenSense6050", componentConfigNode, i2cAddress);
	}

	public InvenSense6050(final String componentName, final SSHSNode componentConfigNode, final int i2cAddress) {
		super(componentName, componentConfigNode);
	}
}
