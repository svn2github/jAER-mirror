package net.sf.jaer2.devices.config;

import javafx.beans.binding.LongBinding;
import javafx.beans.property.BooleanProperty;
import javafx.scene.control.CheckBox;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.serializable.SerializableBooleanProperty;

public final class ConfigBit extends ConfigBase {
	private static final long serialVersionUID = 4713262582313018900L;

	private final SerializableBooleanProperty value = new SerializableBooleanProperty();

	public ConfigBit(final String name, final String description, final boolean defaultValue) {
		super(name, description, 1);

		setValue(defaultValue);
	}

	public boolean getValue() {
		return value.property().get();
	}

	public void setValue(final boolean val) {
		value.property().set(val);
	}

	public BooleanProperty getValueProperty() {
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
		return (getValue() == true) ? (1) : (0);
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		final CheckBox valBox = GUISupport.addCheckBox(rootConfigLayout, null, getValue());
		valBox.selectedProperty().bindBidirectional(getValueProperty());
	}

	@Override
	public String toString() {
		return String.format("%s, value=%b", super.toString(), getValue());
	}
}
