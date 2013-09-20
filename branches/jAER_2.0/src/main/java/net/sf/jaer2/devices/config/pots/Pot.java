package net.sf.jaer2.devices.config.pots;

import java.util.EnumSet;

import javafx.beans.binding.StringBinding;
import javafx.scene.control.Label;
import javafx.scene.control.Slider;
import javafx.scene.control.TextField;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
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
	protected final SerializableIntegerProperty bitValue = new SerializableIntegerProperty();

	public Pot(final String name, final String description, final Type type, final Sex sex) {
		this(name, description, type, sex, 0, 24);
	}

	public Pot(final String name, final String description, final Type type, final Sex sex, final int defaultValue,
		final int numBits) {
		super(name, description, numBits);

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

	protected int clip(final int in) {
		int out = in;

		if (in < ConfigBase.getMinBitValue()) {
			out = (int) ConfigBase.getMinBitValue();
		}
		if (in > getMaxBitValue()) {
			out = (int) getMaxBitValue();
		}

		return out;
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
		if (getBitValue() == ConfigBase.getMinBitValue()) {
			return false;
		}

		setBitValue(getBitValue() - 1);
		return true;
	}

	public String getBitValueAsString() {
		return Numbers.integerToString(getBitValue(), NumberFormat.BINARY,
			EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.ZERO_PADDING, NumberOptions.LEFT_PADDING)).substring(
			32 - getNumBits(), 32);
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

	@Override
	protected long computeBinaryRepresentation() {
		return getBitValue();
	}

	transient protected Slider mainSlider;

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		GUISupport.addLabel(rootConfigLayout, getType().toString(), null, null, null);

		GUISupport.addLabel(rootConfigLayout, getSex().toString(), null, null, null);

		final TextField valueBits = GUISupport.addTextNumberField(rootConfigLayout, bitValue.property(),
			ConfigBase.getMinBitValue(), getMaxBitValue(), null);
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
			ConfigBase.getMinBitValue(), getMaxBitValue(), null);
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

		mainSlider = GUISupport.addSlider(rootConfigLayout, 0, 4095,
			Math.round(((double) getBitValue() / getMaxBitValue()) * 4095), 10);
		HBox.setHgrow(mainSlider, Priority.ALWAYS);

		final Label binaryRep = GUISupport.addLabel(rootConfigLayout, getBinaryRepresentationAsString(),
			"Binary data to be sent to the device.", null, null);

		final StringBinding binStr = new StringBinding() {
			{
				super.bind(bitValue.property(), type.property(), sex.property());
			}

			@Override
			protected String computeValue() {
				return getBinaryRepresentationAsString();
			}
		};

		binaryRep.textProperty().bind(binStr);
	}

	@Override
	public String toString() {
		return String.format("Pot %s with bitValue=%d", getName(), getBitValue());
	}
}
