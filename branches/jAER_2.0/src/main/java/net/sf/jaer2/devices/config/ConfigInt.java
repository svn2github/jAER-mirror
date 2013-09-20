package net.sf.jaer2.devices.config;

import java.util.EnumSet;

import javafx.scene.control.TextField;
import javafx.util.StringConverter;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.serializable.SerializableIntegerProperty;

public class ConfigInt extends ConfigBase {
	private static final long serialVersionUID = 1886982916541742697L;

	private final SerializableIntegerProperty value = new SerializableIntegerProperty();

	public ConfigInt(final String name, final String description, final int defaultValue) {
		this(name, description, defaultValue, 32);
	}

	public ConfigInt(final String name, final String description, final int defaultValue, final int numBits) {
		super(name, description, numBits);

		setValue(defaultValue);
	}

	public int getValue() {
		return value.property().get();
	}

	public void setValue(final int val) {
		value.property().set(val);
	}

	@Override
	protected long computeBinaryRepresentation() {
		return getValue();
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		final TextField valueInt = GUISupport.addTextNumberField(rootConfigLayout, value.property(),
			ConfigBase.getMinBitValue(), getMaxBitValue(), null);
		valueInt.setPrefColumnCount(10);

		valueInt.textProperty().bindBidirectional(value.property().asObject(), new StringConverter<Integer>() {
			@Override
			public Integer fromString(final String str) {
				return Numbers.stringToInteger(str, NumberFormat.DECIMAL, NumberOptions.UNSIGNED);
			}

			@Override
			public String toString(final Integer i) {
				return Numbers.integerToString(i, NumberFormat.DECIMAL, NumberOptions.UNSIGNED);
			}
		});

		final TextField valueBits = GUISupport.addTextNumberField(rootConfigLayout, value.property(),
			ConfigBase.getMinBitValue(), getMaxBitValue(), null);
		valueBits.setPrefColumnCount(getNumBits());

		valueBits.textProperty().bindBidirectional(value.property().asObject(), new StringConverter<Integer>() {
			@Override
			public Integer fromString(final String str) {
				return Numbers.stringToInteger(str, NumberFormat.BINARY, NumberOptions.UNSIGNED);
			}

			@Override
			public String toString(final Integer i) {
				return Numbers.integerToString(i, NumberFormat.BINARY,
					EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.ZERO_PADDING, NumberOptions.LEFT_PADDING))
					.substring(32 - getNumBits(), 32);
			}
		});
	}

	@Override
	public String toString() {
		return String.format("%s, value=%d", super.toString(), getValue());
	}
}
