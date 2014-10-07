package net.sf.jaer2.devices.config;

import javafx.scene.control.CheckBox;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.SSHSAttribute;
import net.sf.jaer2.util.SSHSNode;

public final class ConfigBit extends ConfigBase {
	private final int address;
	private final SSHSAttribute<Boolean> configAttr;

	public ConfigBit(final String name, final String description, final SSHSNode configNode, final boolean defaultValue) {
		this(name, description, configNode, null, defaultValue);
	}

	public ConfigBit(final String name, final String description, final SSHSNode configNode, final Address address,
		final boolean defaultValue) {
		super(name, description, configNode, 1);

		if (address != null) {
			if (address.address() < 0) {
				throw new IllegalArgumentException("Negative addresses are not allowed!");
			}

			this.address = address.address();
		}
		else {
			this.address = -1;
		}

		configAttr = configNode.getAttribute(name, Boolean.class);
		setValue(defaultValue);
	}

	public boolean getValue() {
		return configAttr.getValue();
	}

	public void setValue(final boolean val) {
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
		return (getValue() == true) ? (1) : (0);
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		final CheckBox valBox = GUISupport.addCheckBox(rootConfigLayout, null, getValue());

		valBox.selectedProperty().addListener((valueRef, oldValue, newValue) -> setValue(newValue));

		configAttr.addListener(
			(node, userData, event, oldValue, newValue) -> valBox.selectedProperty().setValue(newValue), null);
	}

	@Override
	public String toString() {
		return String.format("%s, value=%b", super.toString(), getValue());
	}
}
