package net.sf.jaer2.devices.config.muxes;

import java.util.ArrayList;
import java.util.List;

import javafx.scene.control.ComboBox;
import net.sf.jaer2.devices.config.ConfigBase;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.SSHSAttribute;
import net.sf.jaer2.util.SSHSNode;

public class Mux extends ConfigBase {
	public static final class MuxChannel {
		private final int channel;
		private final String name;
		private final int code;

		public MuxChannel(final int chan, final String cname, final int ccode) {
			channel = chan;
			name = cname;
			code = ccode;
		}

		public int getChannel() {
			return channel;
		}

		public String getName() {
			return name;
		}

		public int getCode() {
			return code;
		}

		@Override
		public String toString() {
			return getName();
		}
	}

	private final List<MuxChannel> channels = new ArrayList<>();
	private final SSHSAttribute<MuxChannel> configAttr;

	public Mux(final String name, final String description, final SSHSNode configNode, final int numBits) {
		super(name, description, configNode, numBits);

		configAttr = configNode.getAttribute(name, MuxChannel.class);

		// By default, no channel is selected.
		setChannel(null);
	}

	public MuxChannel getChannel() {
		return configAttr.getValue();
	}

	public void setChannel(final MuxChannel chan) {
		configAttr.setValue(chan);
	}

	public void put(final int chan, final String name) {
		put(chan, name, chan);
	}

	public void put(final int chan, final String name, final int code) {
		if ((code < getMinBitValue()) || (code > getMaxBitValue())) {
			throw new IllegalArgumentException("Invalid code, either too small or too big compared to number of bits.");
		}

		channels.add(new MuxChannel(chan, name, code));
	}

	@Override
	protected long computeBinaryRepresentation() {
		return (getChannel() != null) ? (getChannel().getCode()) : (0);
	}

	@Override
	protected void buildConfigGUI() {
		super.buildConfigGUI();

		final ComboBox<MuxChannel> channelBox = GUISupport.addComboBox(rootConfigLayout, channels, -1);

		// Show all options at once.
		channelBox.setVisibleRowCount(channels.size());

		channelBox.valueProperty().addListener((valueRef, oldValue, newValue) -> setChannel(newValue));

		configAttr.addListener(
			(node, userData, event, oldValue, newValue) -> channelBox.valueProperty().setValue(newValue), null);
	}

	@Override
	public String toString() {
		return String.format("%s, channel=%d", super.toString(), (getChannel() != null) ? (getChannel().getChannel())
			: (-1));
	}
}
