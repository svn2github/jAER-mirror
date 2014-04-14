package net.sf.jaer2.devices.config;

import java.util.EnumSet;

import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.SSHSAttribute;
import net.sf.jaer2.util.SSHSNode;

public final class ConfigLong extends ConfigBase {
	private final int address;
	private final SSHSAttribute<Long> configAttr;

	public ConfigLong(final String name, final String description, final SSHSNode configNode, final long defaultValue) {
		this(name, description, configNode, null, defaultValue);
	}

	public ConfigLong(final String name, final String description, final SSHSNode configNode, final Address address,
		final long defaultValue) {
		this(name, description, configNode, address, defaultValue, Long.SIZE);
	}

	public ConfigLong(final String name, final String description, final SSHSNode configNode, final long defaultValue,
		final int numBits) {
		this(name, description, configNode, null, defaultValue, numBits);
	}

	public ConfigLong(final String name, final String description, final SSHSNode configNode, final Address address,
		final long defaultValue, final int numBits) {
		super(name, description, configNode, numBits);

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

		configAttr = configNode.getAttribute(name, Long.class);
		setValue(defaultValue);
	}

	public long getValue() {
		return configAttr.getValue();
	}

	public void setValue(final long val) {
		configAttr.setValue(val);
	}

	@Override
	public int getAddress() {
		if (address == -1) {
			throw new UnsupportedOperationException("Addressed mode not supported.");
		}

		return address;
	}

	@Override
	protected long computeBinaryRepresentation() {
		return getValue();
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		GUISupport.addTextNumberField(rootConfigLayout, configAttr, 19, getMinBitValue(), getMaxBitValue(),
			NumberFormat.DECIMAL, EnumSet.of(NumberOptions.UNSIGNED), null);

		GUISupport.addTextNumberField(rootConfigLayout, configAttr, getNumBits(), getMinBitValue(), getMaxBitValue(),
			NumberFormat.BINARY,
			EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.LEFT_PADDING, NumberOptions.ZERO_PADDING), null);
	}

	@Override
	public String toString() {
		return String.format("%s, value=%d", super.toString(), getValue());
	}
}
