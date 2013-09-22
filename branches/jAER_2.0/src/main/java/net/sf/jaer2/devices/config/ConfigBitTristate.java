package net.sf.jaer2.devices.config;

import java.util.EnumSet;

import javafx.beans.binding.LongBinding;
import javafx.beans.property.ObjectProperty;
import javafx.scene.control.ComboBox;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.serializable.SerializableObjectProperty;

public final class ConfigBitTristate extends ConfigBase {
	private static final long serialVersionUID = -554758992623341136L;

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

	private final SerializableObjectProperty<Tristate> value = new SerializableObjectProperty<>();

	public ConfigBitTristate(final String name, final String description, final Tristate defaultValue) {
		super(name, description, 2);

		setValue(defaultValue);
	}

	public Tristate getValue() {
		return value.property().get();
	}

	public void setValue(final Tristate val) {
		value.property().set(val);
	}

	public ObjectProperty<Tristate> getValueProperty() {
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
	public long getMaxBitValue() {
		return 3;
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
		triBox.valueProperty().bindBidirectional(getValueProperty());
	}

	@Override
	public String toString() {
		return String.format("%s, value=%s", super.toString(), getValue().toString());
	}
}
