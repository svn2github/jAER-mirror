package net.sf.jaer2.devices.config;

import java.util.EnumSet;

import javafx.scene.control.ComboBox;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.SSHSAttribute;
import net.sf.jaer2.util.SSHSNode;

public final class ConfigBitTristate extends ConfigBase {
	public static enum Tristate {
		LOW(0),
		HIGH(1),
		HIZ(2);

		private final String str;
		private final int bitValue;
		private final String bitValueAsString;

		private Tristate(final int i) {
			str = (i == 0) ? ("LOW") : ((i == 1) ? ("HIGH") : ("HIZ"));
			bitValue = i;
			bitValueAsString = Integer.toBinaryString(i);
		}

		@Override
		public final String toString() {
			return str;
		}

		public final int bitValue() {
			return bitValue;
		}

		public final String bitValueAsString() {
			return bitValueAsString;
		}

		public final boolean isLow() {
			return (this == Tristate.LOW);
		}

		public final boolean isHigh() {
			return (this == Tristate.HIGH);
		}

		public final boolean isHiZ() {
			return (this == Tristate.HIZ);
		}
	}

	private final int address;
	private final SSHSAttribute<Tristate> configAttr;

	public ConfigBitTristate(final String name, final String description, final SSHSNode configNode,
		final Tristate defaultValue) {
		this(name, description, configNode, null, defaultValue);
	}

	public ConfigBitTristate(final String name, final String description, final SSHSNode configNode,
		final Address address, final Tristate defaultValue) {
		super(name, description, configNode, 2);

		if (address != null) {
			if (address.address() < 0) {
				throw new IllegalArgumentException("Negative addresses are not allowed!");
			}

			this.address = address.address();
		}
		else {
			this.address = -1;
		}

		configAttr = configNode.getAttribute(name, Tristate.class);
		setValue(defaultValue);
	}

	public Tristate getValue() {
		return configAttr.getValue();
	}

	public void setValue(final Tristate val) {
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
	public long getMaxBitValue() {
		return 2;
	}

	@Override
	protected long computeBinaryRepresentation() {
		return getValue().bitValue();
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		final ComboBox<Tristate> triBox = GUISupport.addComboBox(rootConfigLayout, EnumSet.allOf(Tristate.class),
			getValue().ordinal());

		triBox.valueProperty().addListener((valueRef, oldValue, newValue) -> setValue(newValue));

		configAttr.addListener(
			(node, userData, event, oldValue, newValue) -> triBox.valueProperty().setValue(newValue), null);
	}

	@Override
	public String toString() {
		return String.format("%s, value=%s", super.toString(), getValue().toString());
	}
}
