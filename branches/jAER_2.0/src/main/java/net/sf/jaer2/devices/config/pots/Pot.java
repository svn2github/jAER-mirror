package net.sf.jaer2.devices.config.pots;

import java.util.EnumSet;

import javafx.scene.control.TextField;
import javafx.util.StringConverter;
import net.sf.jaer2.devices.config.ConfigBase;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.serializable.SerializableIntegerProperty;
import net.sf.jaer2.util.serializable.SerializableObjectProperty;

public abstract class Pot extends ConfigBase {
	private static final long serialVersionUID = -4040508924962174123L;

	/** Type of bias, NORMAL, CASCODE or REFERENCE. */
	public static enum Type {
		NORMAL("Normal"),
		CASCODE("Cascode"),
		REFERENCE("Reference");

		private final String str;

		private Type(final String s) {
			str = s;
		}

		@Override
		public final String toString() {
			return str;
		}
	}

	/** Transistor type for bias, N, P or not available (na). */
	public static enum Sex {
		N("N"),
		P("P"),
		na("N/A");

		private final String str;

		private Sex(final String s) {
			str = s;
		}

		@Override
		public final String toString() {
			return str;
		}
	}

	protected final SerializableObjectProperty<Type> type = new SerializableObjectProperty<>();
	protected final SerializableObjectProperty<Sex> sex = new SerializableObjectProperty<>();

	/** The current value of the bias in bits. */
	protected final SerializableIntegerProperty bitValue = new SerializableIntegerProperty(0);

	/**
	 * The number of bits of resolution for this bias. This number is used to
	 * compute the maximum bit value and also for computing the number of bits
	 * or bytes to send to a device.
	 */
	private int numBits = 24;

	public Pot(final String name, final String description, final Type type, final Sex sex) {
		this(name, description, type, sex, 0);
	}

	public Pot(final String name, final String description, final Type type, final Sex sex, final int defaultValue) {
		super(name, description);

		setType(type);
		setSex(sex);

		setBitValue(defaultValue);
	}

	public Type getType() {
		return type.property().get();
	}

	public void setType(final Type t) {
		type.property().set(t);
	}

	public Sex getSex() {
		return sex.property().get();
	}

	public void setSex(final Sex s) {
		sex.property().set(s);
	}

	public int getBitValue() {
		return bitValue.property().get();
	}

	public void setBitValue(final int bitVal) {
		bitValue.property().set(clip(bitVal));
	}

	/**
	 * Return the maximum value representing all stages of current splitter
	 * enabled.
	 */
	public int getMaxBitValue() {
		return (int) ((1L << (getNumBits())) - 1);
	}

	/** Return the minimum value, no current: zero. */
	public static int getMinBitValue() {
		return 0;
	}

	protected int clip(final int in) {
		int out = in;

		if (in < Pot.getMinBitValue()) {
			out = Pot.getMinBitValue();
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
		return (getNumBits() / 8) + (((getNumBits() % 8) == 0) ? (0) : (1));
	}

	public void setNumBytes(final int nBytes) {
		setNumBits(nBytes * 8);
	}

	/** Increment bias value by one count. */
	public boolean incrementBitValue() {
		if (getBitValue() == getMaxBitValue()) {
			return false;
		}

		setBitValue(getBitValue() + 1);
		return true;
	}

	/** Decrement bias value by one count. */
	public boolean decrementBitValue() {
		if (getBitValue() == Pot.getMinBitValue()) {
			return false;
		}

		setBitValue(getBitValue() - 1);
		return true;
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

		GUISupport.addLabel(rootConfigLayout, getType().toString(), null, null, null);

		GUISupport.addLabel(rootConfigLayout, getSex().toString(), null, null, null);

		final TextField valueBits = GUISupport.addTextNumberField(rootConfigLayout, bitValue.property(),
			Pot.getMinBitValue(), getMaxBitValue(), null);
		valueBits.setPrefColumnCount(getNumBits());

		valueBits.textProperty().bindBidirectional(bitValue.property().asObject(), new StringConverter<Integer>() {
			@Override
			public Integer fromString(final String str) {
				return clip(Numbers.stringToInteger(str, NumberFormat.BINARY, NumberOptions.UNSIGNED));
			}

			@Override
			public String toString(final Integer i) {
				return Numbers.integerToString(clip(i), NumberFormat.BINARY,
					EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.ZERO_PADDING, NumberOptions.LEFT_PADDING))
					.substring(32 - getNumBits(), 32);
			}
		});

		final TextField valueInt = GUISupport.addTextNumberField(rootConfigLayout, bitValue.property(),
			Pot.getMinBitValue(), getMaxBitValue(), null);
		valueInt.setPrefColumnCount(10);

		valueInt.textProperty().bindBidirectional(bitValue.property().asObject(), new StringConverter<Integer>() {
			@Override
			public Integer fromString(final String str) {
				return clip(Numbers.stringToInteger(str, NumberFormat.DECIMAL, NumberOptions.UNSIGNED));
			}

			@Override
			public String toString(final Integer i) {
				return Numbers.integerToString(clip(i), NumberFormat.DECIMAL, NumberOptions.UNSIGNED);
			}
		});
	}

	@Override
	public String toString() {
		return String.format("Pot %s with bitValue=%d", getName(), getBitValue());
	}
}
