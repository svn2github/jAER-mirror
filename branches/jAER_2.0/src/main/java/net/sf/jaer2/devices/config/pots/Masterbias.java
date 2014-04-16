package net.sf.jaer2.devices.config.pots;

import javafx.scene.control.CheckBox;
import javafx.scene.layout.VBox;
import net.sf.jaer2.devices.config.ConfigBase;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.SSHSNode;

public class Masterbias extends ConfigBase {
	/** the total multiplier for the n-type current mirror */
	private float multiplier = (9f * 24f) / 4.8f;

	/** W/L ratio of input side of n-type current mirror */
	private float WOverL = 4.8f / 2.4f;

	/**
	 * boolean that is true if we are using the internal resistor in series with
	 * an off-chip external resistor
	 */
	private boolean internalResistorUsed = false;

	/**
	 * internal (on-chip) resistor value. This is what you get when you tie pin
	 * rInternal to ground.
	 */
	private float rInternal = 46e3f;

	/**
	 * external resistor used. This can be the only capacitance
	 * if you tie it in line with rExternal, "rx". If you tie it to rInternal,
	 * you get the sum.
	 */
	private float rExternal = 8.2e3f;

	/** Temperature in degrees celsius */
	private float temperatureCelsius = 25f;

	/**
	 * The value of beta=mu*Cox*W/L in Amps/Volt^2, called gain factor KPN by
	 * some fabs:
	 * Gain factor KP is measured from the slope of the large transistor, where
	 * Weff / Leff ~ W/L.
	 * <p>
	 * The drain voltage is forced to 0.1V, source and bulk are connected to
	 * ground. The gate voltage is swept to find the maximum slope of the drain
	 * current as a function of the gate voltage, i.e., the transconductance for
	 * triode/linear/ohmic operation.
	 * <p>
	 * A linear regression is performed around this operating point. The voltage
	 * sweep is positive for n-channel devices and negative for p-channel
	 * devices.
	 */
	private float kPrimeNFet = 170e-6f;

	public Masterbias(final String name, final String description, final SSHSNode configNode) {
		super(name, description, configNode, 0);
	}

	public float getTotalResistance() {
		if (isInternalResistorUsed()) {
			return getRInternal() + getRExternal();
		}

		return getRExternal();
	}

	/** @return thermal voltage, computed from temperature */
	private float getThermalVoltage() {
		return (26e-3f * (getTemperatureCelsius() + 273f)) / 300f;
	}

	/**
	 * Estimated weak inversion current: log(M) UT/R.
	 *
	 * @return current in amps.
	 */
	public float getCurrentWeakInversion() {
		final float iweak = (float) ((getThermalVoltage() / getTotalResistance()) * Math.log(getMultiplier()));
		return iweak;
	}

	/**
	 * Estimated current if master running in strong inversion,
	 * computed from formula in
	 * http://www.ini.unizh.ch/~tobi/biasgen
	 * paper.
	 *
	 * @return current in amps.
	 */
	public float getCurrentStrongInversion() {
		final float r = getTotalResistance();
		final float r2 = r * r;
		// beta is mu*Cox*W/L, kPrimeNFet=beta*(W/L)
		final float beta = getKPrimeNFet() * getWOverL();
		final float rfac = 2 / (beta * r2);
		float mfac = (float) (1 - (1 / Math.sqrt(getMultiplier())));
		mfac = mfac * mfac;

		final float istrong = rfac * mfac;
		return istrong;
	}

	/**
	 * The sum of weak and strong inversion master current estimates.
	 *
	 * @return current in amps.
	 */
	public float getCurrent() {
		return getCurrentStrongInversion() + getCurrentWeakInversion();
	}

	public float getRInternal() {
		return rInternal;
	}

	public void setRInternal(final float rInt) {
		rInternal = rInt;
	}

	public float getRExternal() {
		return rExternal;
	}

	public void setRExternal(final float rExt) {
		rExternal = rExt;
	}

	public boolean isInternalResistorUsed() {
		return internalResistorUsed;
	}

	public void setInternalResistorUsed(final boolean internalResistorUsed) {
		this.internalResistorUsed = internalResistorUsed;
	}

	public float getTemperatureCelsius() {
		return temperatureCelsius;
	}

	public void setTemperatureCelsius(final float temperatureCelsius) {
		this.temperatureCelsius = temperatureCelsius;
	}

	public float getMultiplier() {
		return multiplier;
	}

	/**
	 * The mirror ratio in the Widlar bootstrapped mirror.
	 *
	 * @param multiplier
	 */
	public void setMultiplier(final float multiplier) {
		this.multiplier = multiplier;
	}

	public float getWOverL() {
		return WOverL;
	}

	/**
	 * The W/L aspect ratio of the Widlar bootstrapped mirror n-type multiplying
	 * mirror.
	 *
	 * @param WOverL
	 */
	public void setWOverL(final float WOverL) {
		this.WOverL = WOverL;
	}

	public float getKPrimeNFet() {
		return kPrimeNFet;
	}

	/**
	 * The K' parameter for nfets which is beta*W/L = mu*Cox*W/L for the basic
	 * above-threshold MOS model.
	 * beta is mu*Cox*W/L, kPrimeNFet=beta*(W/L).
	 *
	 * @param kPrimeNFet
	 */
	public void setKPrimeNFet(final float kPrimeNFet) {
		this.kPrimeNFet = kPrimeNFet;
	}

	@Override
	protected long computeBinaryRepresentation() {
		// No binary representation exists here.
		return 0;
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		// Add vertical box to contain the configuration parameters.
		final VBox vConfig = new VBox(5);
		rootConfigLayout.getChildren().add(vConfig);

		// Label for internal resistor.
		GUISupport.addLabel(vConfig, "Rint: " + Float.toString(getRInternal()), "The internal resistor value.", null,
			null);

		// Label for external resistor.
		GUISupport.addLabel(vConfig, "Rext: " + Float.toString(getRExternal()), "The external resistor value.", null,
			null);

		// Checkbox for internal resistor usage.
		final CheckBox rIntUsed = GUISupport.addCheckBox(vConfig, "Use internal resistor", isInternalResistorUsed());
		rIntUsed.disableProperty().set(true);

		// Labels to show resistance and current.
		GUISupport.addLabel(vConfig, "Total resistance: " + Float.toString(getTotalResistance()), "Total resistance.",
			null, null);
		GUISupport.addLabel(vConfig, "Current: " + Float.toString(getCurrent()), "Current.", null, null);
	}

	@Override
	public String toString() {
		return String.format("Masterbias with Rexternal=%f, temperature(C)=%f, masterCurrent=%f", getRExternal(),
			getTemperatureCelsius(), getCurrent());
	}
}
