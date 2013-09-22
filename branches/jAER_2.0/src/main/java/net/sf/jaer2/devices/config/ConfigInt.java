package net.sf.jaer2.devices.config;

import java.util.EnumSet;

import javafx.beans.binding.LongBinding;
import javafx.beans.property.IntegerProperty;
import javafx.scene.control.TextField;
import javafx.util.StringConverter;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.serializable.SerializableIntegerProperty;

public final class ConfigInt extends ConfigBase {
	private static final long serialVersionUID = 1886982916541742697L;

	private final SerializableIntegerProperty value = new SerializableIntegerProperty();

	public ConfigInt(final String name, final String description, final int defaultValue) {
		this(name, description, defaultValue, Integer.SIZE);
	}

	public ConfigInt(final String name, final String description, final int defaultValue, final int numBits) {
		super(name, description, numBits);

		if (numBits < 2) {
			throw new IllegalArgumentException(
				"Invalid numBits value, must be at least 2. Use ConfigBit for 1 bit quantities.");
		}

		if (numBits > 32) {
			throw new IllegalArgumentException(
				"Invalid numBits value, must be at most 32. Use ConfigLong for larger quantities.");
		}

		setValue(defaultValue);
	}

	public int getValue() {
		return value.property().get();
	}

	public void setValue(final int val) {
		value.property().set(val);
	}

	public IntegerProperty getValueProperty() {
		return value.property();
	}

	@Override
	protected void buildChangeBinding() {
		changeBinding = new LongBinding() {
			{
				super.bind(getValueProperty());
			}

			@Override
			protected long computeValue() {
				return System.currentTimeMillis();
			}
		};
	}

	@Override
	protected long computeBinaryRepresentation() {
		return getValue();
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		final TextField valueInt = GUISupport.addTextNumberField(rootConfigLayout, getValueProperty(),
			getMinBitValue(), getMaxBitValue(), null);
		valueInt.setPrefColumnCount(10);

		valueInt.textProperty().bindBidirectional(getValueProperty().asObject(), new StringConverter<Integer>() {
			@Override
			public Integer fromString(final String str) {
				return Numbers.stringToInteger(str, NumberFormat.DECIMAL, NumberOptions.UNSIGNED);
			}

			@Override
			public String toString(final Integer i) {
				return Numbers.integerToString(i, NumberFormat.DECIMAL, NumberOptions.UNSIGNED);
			}
		});

		final TextField valueBits = GUISupport.addTextNumberField(rootConfigLayout, getValueProperty(),
			getMinBitValue(), getMaxBitValue(), null);
		valueBits.setPrefColumnCount(getNumBits());

		valueBits.textProperty().bindBidirectional(getValueProperty().asObject(), new StringConverter<Integer>() {
			@Override
			public Integer fromString(final String str) {
				return Numbers.stringToInteger(str, NumberFormat.BINARY, NumberOptions.UNSIGNED);
			}

			@Override
			public String toString(final Integer i) {
				return Numbers.integerToString(i, NumberFormat.BINARY,
					EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.ZERO_PADDING, NumberOptions.LEFT_PADDING))
					.substring(Integer.SIZE - getNumBits(), Integer.SIZE);
			}
		});
	}

	@Override
	public String toString() {
		return String.format("%s, value=%d", super.toString(), getValue());
	}
}
