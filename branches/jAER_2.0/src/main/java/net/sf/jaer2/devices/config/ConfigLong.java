package net.sf.jaer2.devices.config;

import java.util.EnumSet;

import javafx.beans.binding.LongBinding;
import javafx.beans.property.LongProperty;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.serializable.SerializableLongProperty;

public final class ConfigLong extends ConfigBase {
	private static final long serialVersionUID = -5688508941627375976L;

	private final int address;

	private final SerializableLongProperty value = new SerializableLongProperty();

	public ConfigLong(final String name, final String description, final long defaultValue) {
		this(name, description, null, defaultValue);
	}

	public ConfigLong(final String name, final String description, final Address address, final long defaultValue) {
		this(name, description, address, defaultValue, Long.SIZE);
	}

	public ConfigLong(final String name, final String description, final long defaultValue, final int numBits) {
		this(name, description, null, defaultValue, numBits);
	}

	public ConfigLong(final String name, final String description, final Address address, final long defaultValue,
		final int numBits) {
		super(name, description, numBits);

		if (numBits < 33) {
			throw new IllegalArgumentException(
				"Invalid numBits value, must be at least 33. Use ConfigInt for smaller quantities.");
		}

		if (numBits > 64) {
			throw new IllegalArgumentException(
				"Invalid numBits value, must be at most 64. Larger quantities are not supported.");
		}

		if (address != null) {
			if (address.address() < 0) {
				throw new IllegalArgumentException("Negative addresses are not allowed!");
			}

			this.address = address.address();
		}
		else {
			this.address = -1;
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
	public int getAddress() {
		if (address == -1) {
			throw new UnsupportedOperationException("Addressed mode not supported.");
		}

		return address;
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

		GUISupport.addTextNumberField(rootConfigLayout, getValueProperty(), 19, getMinBitValue(), getMaxBitValue(),
			NumberFormat.DECIMAL, EnumSet.of(NumberOptions.UNSIGNED), null);

		GUISupport.addTextNumberField(rootConfigLayout, getValueProperty(), getNumBits(), getMinBitValue(),
			getMaxBitValue(), NumberFormat.BINARY,
			EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.LEFT_PADDING, NumberOptions.ZERO_PADDING), null);
	}

	@Override
	public String toString() {
		return String.format("%s, value=%d", super.toString(), getValue());
	}
}
