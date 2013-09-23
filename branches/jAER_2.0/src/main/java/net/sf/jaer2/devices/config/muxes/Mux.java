package net.sf.jaer2.devices.config.muxes;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Map.Entry;

import javafx.beans.binding.LongBinding;
import javafx.beans.property.IntegerProperty;
import javafx.scene.control.ComboBox;
import javafx.util.StringConverter;
import net.sf.jaer2.devices.config.ConfigBase;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.serializable.SerializableIntegerProperty;

public class Mux extends ConfigBase {
	private static final long serialVersionUID = -9024024193567293234L;

	private final Map<Integer, Integer> outputMap = new LinkedHashMap<>();
	private final Map<Integer, String> nameMap = new LinkedHashMap<>();

	private final SerializableIntegerProperty channel = new SerializableIntegerProperty();

	public Mux(final String name, final String description, final int numBits) {
		super(name, description, numBits);

		setChannel(0);
	}

	public int getChannel() {
		return channel.property().get();
	}

	public void setChannel(final int chan) {
		channel.property().set(chan);
	}

	public IntegerProperty getChannelProperty() {
		return channel.property();
	}

	public int getCode(final int chan) {
		return outputMap.get(chan);
	}

	public void put(final int k, final int v, final String name) {
		// Add both code and name.
		outputMap.put(k, v);
		nameMap.put(k, name);
	}

	public void put(final int k, final String name) {
		// Rename only.
		nameMap.put(k, name);
	}

	@Override
	protected void buildChangeBinding() {
		changeBinding = new LongBinding() {
			{
				super.bind(getChannelProperty());
			}

			@Override
			protected long computeValue() {
				return System.currentTimeMillis();
			}
		};
	}

	@Override
	protected long computeBinaryRepresentation() {
		return getCode(getChannel());
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		final ComboBox<Integer> channelBox = GUISupport.addComboBox(rootConfigLayout, nameMap.keySet(), getChannel());

		channelBox.setConverter(new StringConverter<Integer>() {
			@Override
			public String toString(final Integer i) {
				return nameMap.get(i);
			}

			@Override
			public Integer fromString(final String str) {
				for (final Entry<Integer, String> entry : nameMap.entrySet()) {
					if (entry.getValue().equals(str)) {
						return entry.getKey();
					}
				}

				return 0;
			}
		});

		channelBox.valueProperty().bindBidirectional(getChannelProperty().asObject());
	}

	@Override
	public String toString() {
		return String.format("%s, channel=%d", super.toString(), getChannel());
	}
}
