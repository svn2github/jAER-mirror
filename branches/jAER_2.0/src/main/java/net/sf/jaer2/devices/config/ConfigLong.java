package net.sf.jaer2.devices.config;

import java.util.EnumSet;

import javafx.beans.binding.LongBinding;
import javafx.beans.property.LongProperty;
import javafx.scene.control.TextField;
import javafx.util.StringConverter;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.serializable.SerializableLongProperty;

public final class ConfigLong extends ConfigBase {
	private static final long serialVersionUID = -5688508941627375976L;

	private final SerializableLongProperty value = new SerializableLongProperty();

	public ConfigLong(final String name, final String description, final long defaultValue) {
		this(name, description, defaultValue, Long.SIZE);
	}

	public ConfigLong(final String name, final String description, final long defaultValue, final int numBits) {
		super(name, description, numBits);

		if (numBits < 33) {
			throw new IllegalArgumentException(
				"Invalid numBits value, must be at least 33. Use ConfigInt for smaller quantities.");
		}

		if (numBits > 64) {
			throw new IllegalArgumentException(
				"Invalid numBits value, must be at most 64. Larger quantities are not supported.");
		}

		setValue(defaultValue);
	}

	public long getValue() {
		return value.property().get();
	}

	public void setValue(final long val) {
		value.property().set(val);
	}

	public LongProperty getValueProperty() {
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

		final TextField valueLong = GUISupport.addTextNumberField(rootConfigLayout, getValueProperty(),
			getMinBitValue(), getMaxBitValue(), null);
		valueLong.setPrefColumnCount(19);

		valueLong.textProperty().bindBidirectional(getValueProperty().asObject(), new StringConverter<Long>() {
			@Override
			public Long fromString(final String str) {
				return Numbers.stringToLong(str, NumberFormat.DECIMAL, NumberOptions.UNSIGNED);
			}

			@Override
			public String toString(final Long i) {
				return Numbers.longToString(i, NumberFormat.DECIMAL, NumberOptions.UNSIGNED);
			}
		});

		final TextField valueBits = GUISupport.addTextNumberField(rootConfigLayout, getValueProperty(),
			getMinBitValue(), getMaxBitValue(), null);
		valueBits.setPrefColumnCount(getNumBits());

		valueBits.textProperty().bindBidirectional(getValueProperty().asObject(), new StringConverter<Long>() {
			@Override
			public Long fromString(final String str) {
				return Numbers.stringToLong(str, NumberFormat.BINARY, NumberOptions.UNSIGNED);
			}

			@Override
			public String toString(final Long i) {
				return Numbers.longToString(i, NumberFormat.BINARY,
					EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.ZERO_PADDING, NumberOptions.LEFT_PADDING))
					.substring(Long.SIZE - getNumBits(), Long.SIZE);
			}
		});
	}

	@Override
	public String toString() {
		return String.format("%s, value=%d", super.toString(), getValue());
	}
}
