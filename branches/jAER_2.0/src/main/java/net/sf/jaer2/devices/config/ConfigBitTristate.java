package net.sf.jaer2.devices.config;

import java.util.EnumSet;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.scene.control.ComboBox;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.SSHSNode;
import net.sf.jaer2.util.SSHSNode.SSHSAttrListener;

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

		setValue(defaultValue);
	}

	public Tristate getValue() {
		if (configNode.getByte(getName()) == 0) {
			return Tristate.LOW;
		}
		else if (configNode.getByte(getName()) == 1) {
			return Tristate.HIGH;
		}
		else {
			return Tristate.HIZ;
		}
	}

	public void setValue(final Tristate val) {
		configNode.putByte(getName(), (byte) val.bitValue());
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

		triBox.valueProperty().addListener(new ChangeListener<Tristate>() {
			@Override
			public void changed(final ObservableValue<? extends Tristate> changed, final Tristate oldVal,
				final Tristate newVal) {
				setValue(newVal);
			}
		});

		configNode.addAttrListener(new SSHSAttrListener() {
			@Override
			public <V> void attributeChanged(final SSHSNode node, final Object userData, final AttributeEvents event,
				final String changeKey, final Class<V> changeType, final V changeValue) {
				if ((event == AttributeEvents.ATTRIBUTE_MODIFIED) && changeKey.equals(getName())
					&& (changeType == Byte.class)) {
					if ((Byte) changeValue == 0) {
						triBox.valueProperty().setValue(Tristate.LOW);
					}
					else if ((Byte) changeValue == 1) {
						triBox.valueProperty().setValue(Tristate.HIGH);
					}
					else {
						triBox.valueProperty().setValue(Tristate.HIZ);
					}
				}
			}
		}, null);
	}

	@Override
	public String toString() {
		return String.format("%s, value=%s", super.toString(), getValue().toString());
	}
}
