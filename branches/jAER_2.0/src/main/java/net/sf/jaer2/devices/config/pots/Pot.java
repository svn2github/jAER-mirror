package net.sf.jaer2.devices.config.pots;

import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import net.sf.jaer2.devices.config.ConfigBase;
import net.sf.jaer2.util.GUISupport;

public abstract class Pot extends ConfigBase {
	/** Type of bias, NORMAL, CASCODE or REFERENCE. */
	public static enum Type {
		NORMAL,
		CASCODE,
		REFERENCE;
	}

	/** Transistor type for bias, N, P or not available (na). */
	public static enum Sex {
		N,
		P,
		na;
	}

	private final Type type;
	private final Sex sex;

	/** The current value of the bias in bits. */
	private int bitValue = 0;

	/**
	 * The number of bits of resolution for this bias. This number is used to
	 * compute the maximum bit value and also for computing the number of bits
	 * or bytes to send to a device.
	 */
	private int numBits = 24;

	public Pot(final String name, final String description, final Type type, final Sex sex, final int defaultValue) {
		super(name, description);

		this.type = type;
		this.sex = sex;

		bitValue = defaultValue;
	}

	public Type getType() {
		return type;
	}

	public Sex getSex() {
		return sex;
	}

	public int getBitValue() {
		return bitValue;
	}

	public void setBitValue(final int bitVal) {
		bitValue = clip(bitVal);
	}

	/**
	 * Return the maximum value representing all stages of current splitter
	 * enabled.
	 */
	public int getMaxBitValue() {
		return (int) ((1L << (getNumBits())) - 1);
	}

	/** Return the minimum value, no current: zero. */
	@SuppressWarnings("static-method")
	public int getMinBitValue() {
		return 0;
	}

	private int clip(final int in) {
		int out = in;

		if (in < getMinBitValue()) {
			out = getMinBitValue();
		}
		if (in > getMaxBitValue()) {
			out = getMaxBitValue();
		}

		return out;
	}

	public int getNumBits() {
		return numBits;
	}

	public void setNumBits(final int nBits) {
		numBits = nBits;
	}

	public int getNumBytes() {
		return getNumBits() >>> 3;
	}

	public void setNumBytes(final int nBytes) {
		setNumBits(nBytes << 3);
	}

	/** Increment bias value by one count. */
	public void incrementBitValue() {
		setBitValue(getBitValue() + 1);
	}

	/** Decrement bias value by one count. */
	public void decrementBitValue() {
		setBitValue(getBitValue() - 1);
	}

	public String toBitPatternString() {
		final StringBuilder s = new StringBuilder(getNumBits());

		for (int k = getNumBits() - 1; k >= 0; k--) {
			if ((getBitValue() & (1 << k)) != 0) {
				s.append("1");
			}
			else {
				s.append("0");
			}
		}

		return s.toString();
	}

	/**
	 * Returns the physical value of the bias, e.g. for current Amps or for
	 * voltage Volts.
	 *
	 * @return physical value.
	 */
	abstract public float getPhysicalValue();

	/**
	 * Sets the physical value of the bias.
	 *
	 * @param value
	 *            the physical value, e.g. in Amps or Volts.
	 */
	abstract public void setPhysicalValue(float value);

	/** Return the unit (e.g. A, mV) of the physical value for this bias. */
	abstract public String getPhysicalValueUnits();

	/**
	 * Computes and returns a new array of bytes representing the bias to be
	 * sent over the hardware interface to the device.
	 *
	 * @return array of bytes to be sent, by convention values are ordered in
	 *         big-endian format so that byte 0 is the most significant byte and
	 *         is sent first to the hardware.
	 */
	public byte[] getBinaryRepresentation() {
		final byte[] bytes = new byte[getNumBytes()];

		final int val = getBitValue();

		int k = 0;
		for (int i = bytes.length - 1; i >= 0; i--) {
			bytes[k++] = (byte) (0xFF & (val >>> (i * 8)));
		}

		return bytes;
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		HBox.setHgrow(GUISupport.addSlider(rootConfigLayout, 0, 1000, 0, 10), Priority.ALWAYS);
	}

	@Override
	public String toString() {
		return String.format("Pot %s with bitValue=%d", getName(), getBitValue());
	}
}
