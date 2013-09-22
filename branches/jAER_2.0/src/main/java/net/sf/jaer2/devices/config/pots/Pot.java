package net.sf.jaer2.devices.config.pots;

import java.util.EnumSet;

import javafx.beans.binding.LongBinding;
import javafx.beans.property.IntegerProperty;
import javafx.beans.property.ObjectProperty;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.scene.control.Label;
import javafx.scene.control.Slider;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
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

	private final SerializableObjectProperty<Type> type = new SerializableObjectProperty<>();
	private final SerializableObjectProperty<Sex> sex = new SerializableObjectProperty<>();

	/** The current value of the bias in bits. */
	private final SerializableIntegerProperty bitValue = new SerializableIntegerProperty();

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

	public ObjectProperty<Type> getTypeProperty() {
		return type.property();
	}

	public Sex getSex() {
		return sex.property().get();
	}

	public void setSex(final Sex s) {
		sex.property().set(s);
	}

	public ObjectProperty<Sex> getSexProperty() {
		return sex.property();
	}

	public int getBitValue() {
		return bitValue.property().get();
	}

	public void setBitValue(final int bitVal) {
		bitValue.property().set(clip(bitVal));
	}

	public IntegerProperty getBitValueProperty() {
		return bitValue.property();
	}

	private int clip(final int in) {
		int out = in;

		if (in < getMinBitValue()) {
			out = (int) getMinBitValue();
		}
		if (in > getMaxBitValue()) {
			out = (int) getMaxBitValue();
		}

		return out;
	}

	public int getBitValueBits() {
		return getNumBits();
	}

	@Override
	public long getMaxBitValue() {
		return ((1L << getBitValueBits()) - 1);
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
		if (getBitValue() == getMinBitValue()) {
			return false;
		}

		setBitValue(getBitValue() - 1);
		return true;
	}

	public String getBitValueAsString() {
		return Numbers.integerToString(getBitValue(), NumberFormat.BINARY,
			EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.ZERO_PADDING, NumberOptions.LEFT_PADDING)).substring(
			Integer.SIZE - getBitValueBits(), Integer.SIZE);
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
	protected void buildChangeBinding() {
		changeBinding = new LongBinding() {
			{
				super.bind(getBitValueProperty(), getTypeProperty(), getSexProperty());
			}

			@Override
			protected long computeValue() {
				return System.currentTimeMillis();
			}
		};
	}

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

		GUISupport.addTextNumberField(rootConfigLayout, getBitValueProperty(), 10, (int) getMinBitValue(),
			(int) getMaxBitValue(), NumberFormat.DECIMAL, EnumSet.of(NumberOptions.UNSIGNED), null);

		GUISupport.addTextNumberField(rootConfigLayout, getBitValueProperty(), getBitValueBits(),
			(int) getMinBitValue(), (int) getMaxBitValue(), NumberFormat.BINARY,
			EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.LEFT_PADDING, NumberOptions.ZERO_PADDING), null);

		final long minBitValueSlider = getMinBitValue();
		final long maxBitValueSlider = (getMaxBitValue() < 4095) ? (getMaxBitValue()) : (4095);

		mainSlider = GUISupport.addSlider(rootConfigLayout, minBitValueSlider, maxBitValueSlider,
			Math.round(((double) getBitValue() / getMaxBitValue()) * maxBitValueSlider), 10);
		HBox.setHgrow(mainSlider, Priority.ALWAYS);

		final Label binaryRep = GUISupport.addLabel(rootConfigLayout, getBinaryRepresentationAsString(),
			"Binary data to be sent to the device.", null, null);

		getChangeBinding().addListener(new ChangeListener<Number>() {
			@SuppressWarnings("unused")
			@Override
			public void changed(final ObservableValue<? extends Number> val, final Number oldVal, final Number newVal) {
				binaryRep.setText(getBinaryRepresentationAsString());
			}
		});
	}

	@Override
	public String toString() {
		return String.format("%s, Type=%s, Sex=%s, bitValue=%d", super.toString(), getType().toString(), getSex()
			.toString(), getBitValue());
	}
}
