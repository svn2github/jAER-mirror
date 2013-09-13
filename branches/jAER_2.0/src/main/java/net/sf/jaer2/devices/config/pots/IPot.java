package net.sf.jaer2.devices.config.pots;

public class IPot extends Pot {
	/** Fraction that bias current changes on increment or decrement. */
	public static final float CHANGE_FRACTION = 0.1f;

	/** The Masterbias supplying reference current to this bias. */
	private Masterbias masterbias;

	public IPot(final String name, final String description, final Type type, final Sex sex, final int defaultValue) {
		super(name, description, type, sex, defaultValue);
	}

	public Masterbias getMasterbias() {
		return masterbias;
	}

	public void setMasterbias(final Masterbias masterbias) {
		this.masterbias = masterbias;
	}

	/**
	 * Computes the estimated current based on the bit value for the current
	 * splitter and the {@link #masterbias}.
	 *
	 * @return current in Amps.
	 */
	public float getCurrent() {
		final float im = masterbias.getCurrent();
		final float i = (im * getBitValue()) / getMaxBitValue();

		return i;
	}

	/**
	 * Sets the bit value based on desired current and {@link #masterbias}
	 * current.
	 *
	 * @param current
	 *            the current in Amps.
	 * @return actual float value of current after resolution clipping.
	 */
	public float setCurrent(final float current) {
		final float im = masterbias.getCurrent();
		final float r = current / im;

		setBitValue(Math.round(r * getMaxBitValue()));

		return getCurrent();
	}

	/** @return max possible current (master current) */
	public float getMaxCurrent() {
		return masterbias.getCurrent();
	}

	/**
	 * @return min possible current (presently zero, although in reality limited
	 *         by off-current and substrate leakage).
	 */
	@SuppressWarnings("static-method")
	public float getMinCurrent() {
		return 0f;
	}

	/**
	 * return resolution of pot in current. This is just Im/2^nbits.
	 *
	 * @return smallest possible current change -- in principle
	 */
	public float getCurrentResolution() {
		return 1f / ((1 << getNumBits()) - 1);
	}

	/** increment pot value by {@link #CHANGE_FRACTION} ratio */
	public void incrementCurrent() {
		final int v = Math.round(1 + ((1 + IPot.CHANGE_FRACTION) * getBitValue()));

		setBitValue(v);
	}

	/** decrement pot value by ratio */
	public void decrementCurrent() {
		final int v = Math.round(-1 + ((1 - IPot.CHANGE_FRACTION) * getBitValue()));

		setBitValue(v);
	}

	/**
	 * Change current value by ratio, or at least by one bit value.
	 *
	 * @param ratio
	 *            between new current and old value, e.g. 1.1f or 0.9f
	 */
	public void changeByRatio(final float ratio) {
		int v = Math.round(getBitValue() * ratio);
		if (v == getBitValue()) {
			v += (ratio >= 1 ? 1 : -1);
		}

		setBitValue(v);
	}

	@Override
	public float getPhysicalValue() {
		return getCurrent();
	}

	@Override
	public String getPhysicalValueUnits() {
		return "A";
	}

	@Override
	public void setPhysicalValue(final float value) {
		setCurrent(value);
	}

	@Override
	public String toString() {
		return String.format("IPot %s with bitValue=%d, current=%f", getName(), getBitValue(), getCurrent());
	}
}
