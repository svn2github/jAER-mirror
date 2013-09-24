package net.sf.jaer2.devices.components.misc;

import net.sf.jaer2.devices.components.Component;

public class DAC extends Component {
	private static final long serialVersionUID = 419464332057192955L;

	private final int numChannels;
	private final int resolutionBits;
	private final float refMinVolts;
	private final float refMaxVolts;
	private final float vdd;

	public DAC(int numChannels, int resolutionBits, float refMinVolts, float refMaxVolts, float vdd) {
		this("DAC", numChannels, resolutionBits, refMinVolts, refMaxVolts, vdd);
	}

	public DAC(final String componentName, int numChannels, int resolutionBits, float refMinVolts, float refMaxVolts,
		float vdd) {
		super(componentName);

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
