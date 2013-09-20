package net.sf.jaer2.devices.config;

import java.util.EnumSet;

import javafx.scene.control.TextField;
import javafx.util.StringConverter;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.serializable.SerializableLongProperty;

public class ConfigLong extends ConfigBase {
	private static final long serialVersionUID = -5688508941627375976L;

	private final SerializableLongProperty value = new SerializableLongProperty();

	public ConfigLong(final String name, final String description, final long defaultValue) {
		this(name, description, defaultValue, 64);
	}

	public ConfigLong(final String name, final String description, final long defaultValue, final int numBits) {
		super(name, description, numBits);

		setValue(defaultValue);
	}

	public long getValue() {
		return value.property().get();
	}

	public void setValue(final long val) {
		value.property().set(val);
	}

	@Override
	protected long computeBinaryRepresentation() {
		return getValue();
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		final TextField valueLong = GUISupport.addTextNumberField(rootConfigLayout, value.property(),
			ConfigBase.getMinBitValue(), getMaxBitValue(), null);
		valueLong.setPrefColumnCount(19);

		valueLong.textProperty().bindBidirectional(value.property().asObject(), new StringConverter<Long>() {
			@Override
			public Long fromString(final String str) {
				return Numbers.stringToLong(str, NumberFormat.DECIMAL, NumberOptions.UNSIGNED);
			}

			@Override
			public String toString(final Long i) {
				return Numbers.longToString(i, NumberFormat.DECIMAL, NumberOptions.UNSIGNED);
			}
		});

		final TextField valueBits = GUISupport.addTextNumberField(rootConfigLayout, value.property(),
			ConfigBase.getMinBitValue(), getMaxBitValue(), null);
		valueBits.setPrefColumnCount(getNumBits());

		valueBits.textProperty().bindBidirectional(value.property().asObject(), new StringConverter<Long>() {
			@Override
			public Long fromString(final String str) {
				return Numbers.stringToLong(str, NumberFormat.BINARY, NumberOptions.UNSIGNED);
			}

			@Override
			public String toString(final Long i) {
				return Numbers.longToString(i, NumberFormat.BINARY,
					EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.ZERO_PADDING, NumberOptions.LEFT_PADDING))
					.substring(64 - getNumBits(), 64);
			}
		});
	}

	@Override
	public String toString() {
		return String.format("%s, value=%d", super.toString(), getValue());
	}
}
