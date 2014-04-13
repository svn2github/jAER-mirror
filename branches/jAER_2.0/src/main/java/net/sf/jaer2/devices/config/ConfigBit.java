package net.sf.jaer2.devices.config;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.scene.control.CheckBox;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.SSHSNode;
import net.sf.jaer2.util.SSHSNode.SSHSAttrListener;

public final class ConfigBit extends ConfigBase {
	private final int address;

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

		setValue(defaultValue);
	}

	public boolean getValue() {
		return configNode.getBool(getName());
	}

	public void setValue(final boolean val) {
		configNode.putBool(getName(), val);
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

		valBox.selectedProperty().addListener(new ChangeListener<Boolean>() {
			@Override
			public void changed(final ObservableValue<? extends Boolean> changed, final Boolean oldVal,
				final Boolean newVal) {
				setValue(newVal);
			}
		});

		configNode.addAttrListener(new SSHSAttrListener() {
			@Override
			public <V> void attributeChanged(final SSHSNode node, final Object userData, final AttributeEvents event,
				final String changeKey, final Class<V> changeType, final V changeValue) {
				if ((event == AttributeEvents.ATTRIBUTE_MODIFIED) && changeKey.equals(getName())
					&& (changeType == Boolean.class)) {
					valBox.selectedProperty().setValue((Boolean) changeValue);
				}
			}
		}, null);
	}

	@Override
	public String toString() {
		return String.format("%s, value=%b", super.toString(), getValue());
	}
}
