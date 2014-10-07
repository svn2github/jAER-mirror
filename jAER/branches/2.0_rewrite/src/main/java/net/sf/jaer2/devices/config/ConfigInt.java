package net.sf.jaer2.devices.config;

import java.util.EnumSet;

import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.Numbers.NumberFormat;
import net.sf.jaer2.util.Numbers.NumberOptions;
import net.sf.jaer2.util.SSHSAttribute;
import net.sf.jaer2.util.SSHSNode;

public final class ConfigInt extends ConfigBase {
	private final int address;
	private final SSHSAttribute<Integer> configAttr;

	public ConfigInt(final String name, final String description, final SSHSNode configNode, final int defaultValue) {
		this(name, description, configNode, null, defaultValue);
	}

	public ConfigInt(final String name, final String description, final SSHSNode configNode, final Address address,
		final int defaultValue) {
		this(name, description, configNode, address, defaultValue, Integer.SIZE);
	}

	public ConfigInt(final String name, final String description, final SSHSNode configNode, final int defaultValue,
		final int numBits) {
		this(name, description, configNode, null, defaultValue, numBits);
	}

	public ConfigInt(final String name, final String description, final SSHSNode configNode, final Address address,
		final int defaultValue, final int numBits) {
		super(name, description, configNode, numBits);

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

		configAttr = configNode.getAttribute(name, Integer.class);
		setValue(defaultValue);
	}

	public int getValue() {
		return configAttr.getValue();
	}

	public void setValue(final int val) {
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

		GUISupport.addTextNumberField(rootConfigLayout, configAttr, 10, (int) getMinBitValue(), (int) getMaxBitValue(),
			NumberFormat.DECIMAL, EnumSet.of(NumberOptions.UNSIGNED), null);

		GUISupport.addTextNumberField(rootConfigLayout, configAttr, getNumBits(), (int) getMinBitValue(),
			(int) getMaxBitValue(), NumberFormat.BINARY,
			EnumSet.of(NumberOptions.UNSIGNED, NumberOptions.LEFT_PADDING, NumberOptions.ZERO_PADDING), null);
	}

	@Override
	public String toString() {
		return String.format("%s, value=%d", super.toString(), getValue());
	}
}
