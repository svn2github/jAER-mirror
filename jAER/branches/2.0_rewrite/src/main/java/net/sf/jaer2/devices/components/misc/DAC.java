package net.sf.jaer2.devices.components.misc;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.util.SSHSNode;

public class DAC extends Component {
	private final int numChannels;
	private final int resolutionBits;
	private final float refMinVolts;
	private final float refMaxVolts;
	private final float vdd;

	public DAC(final String componentName, final SSHSNode componentConfigNode, int numChannels, int resolutionBits,
		float refMinVolts, float refMaxVolts, float vdd) {
		super(componentName, componentConfigNode);

		this.numChannels = numChannels;
		this.resolutionBits = resolutionBits;
		this.refMinVolts = refMinVolts;
		this.refMaxVolts = refMaxVolts;
		this.vdd = vdd;
	}

	public int getNumChannels() {
		return numChannels;
	}

	public int getResolutionBits() {
		return resolutionBits;
	}

	public float getRefMinVolts() {
		return refMinVolts;
	}

	public float getRefMaxVolts() {
		return refMaxVolts;
	}

	public float getVdd() {
		return vdd;
	}
}
