package net.sf.jaer2.devices.config;

import java.util.EnumSet;

import javafx.beans.binding.LongBinding;
import javafx.beans.property.IntegerProperty;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.serializable.SerializableIntegerProperty;

public final class ConfigInt extends ConfigBase {
	private static final long serialVersionUID = 1886982916541742697L;

	private final int address;

	private final SerializableIntegerProperty value = new SerializableIntegerProperty();

	public ConfigInt(final String name, final String description, final int defaultValue) {
		this(name, description, null, defaultValue);
	}

	public ConfigInt(final String name, final String description, final Address address, final int defaultValue) {
		this(name, description, address, defaultValue, Integer.SIZE);
	}

	public ConfigInt(final String name, final String description, final int defaultValue, final int numBits) {
		this(name, description, null, defaultValue, numBits);
	}

	public ConfigInt(final String name, final String description, final Address address, final int defaultValue,
		final int numBits) {
		super(name, description, numBits);

		if (numBits < 2) {
			throw new IllegalArgumentException(
				"Invalid numBits value, must be at least 2. Use ConfigBit for 1 bit quantities.");
		}

		if (numBits > 32) {
			throw new IllegalArgumentException(
				"Invalid numBits value, must be at most 32. Use ConfigLong for larger quantities.");
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

		GUISupport.addTextNumberField(rootConfigLayout, getValueProperty(), 10, (int) getMinBitValue(),
			(int) getMaxBitValue(), NumberFormat.DECIMAL, EnumSet.of(NumberOptions.UNSIGNED), null);

		GUISupport.addTextNumberField(rootConfigLayout, getValueProperty(), getNumBits(), (int) getMinBitValue(),
			(int) getMaxBitValue(), NumberFormat.BINARY,
			EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.LEFT_PADDING, NumberOptions.ZERO_PADDING), null);
	}

	@Override
	public String toString() {
		return String.format("%s, value=%d", super.toString(), getValue());
	}
}
