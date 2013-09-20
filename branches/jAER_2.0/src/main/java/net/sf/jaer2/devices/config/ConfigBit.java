package net.sf.jaer2.devices.config;

import javafx.scene.control.CheckBox;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.serializable.SerializableBooleanProperty;

public class ConfigBit extends ConfigBase {
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

	@Override
	protected long computeBinaryRepresentation() {
		return (getValue() == true) ? (1) : (0);
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		final CheckBox valBox = GUISupport.addCheckBox(rootConfigLayout, null, getValue());
		valBox.selectedProperty().bindBidirectional(value.property());
	}

	@Override
	public String toString() {
		return String.format("%s, value=%d", super.toString(), getValue());
	}
}
