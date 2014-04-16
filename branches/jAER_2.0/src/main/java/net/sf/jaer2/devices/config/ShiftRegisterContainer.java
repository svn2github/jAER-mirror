package net.sf.jaer2.devices.config;

import java.util.LinkedHashMap;
import java.util.Map;

import javafx.scene.control.Label;
import javafx.scene.layout.VBox;
import net.sf.jaer2.util.GUISupport;
import net.sf.jaer2.util.SSHS;
import net.sf.jaer2.util.SSHSNode;
import net.sf.jaer2.util.SSHSNode.SSHSNodeListener.NodeEvents;

/**
 * This configuration component is just a container for other settings.
 * It uses the length information of each setting, as well as the order they
 * were added to this container, to figure out how to format the content as one,
 * single shift register. The given length of the shift register is used to
 * verify that all bits are configured and ensure that the contained settings do
 * not overflow the shift register.
 *
 * @author llongi
 */
public final class ShiftRegisterContainer extends ConfigBase {
	private final Map<String, ConfigBase> settingsMap = new LinkedHashMap<>();

	private int currentNumBitsUsed = 0;

	public ShiftRegisterContainer(final String name, final String description, final SSHSNode configNode,
		final int numBits) {
		super(name, description, configNode, numBits);

		// Reset config node to be one level deeper that what is passed in, so
		// that each shift register appears isolated inside their own node.
		this.configNode = SSHS.getRelativeNode(this.configNode, name + "/");
		// TODO: fix SR inside SR, no update notification because listeners
		// don't get notified levels up.

		if ((numBits % Byte.SIZE) != 0) {
			throw new IllegalArgumentException("Invalid numBits value, must be a multiple of 8 for byte alignment.");
		}
	}

	public void addSetting(final ConfigBase setting) {
		if ((currentNumBitsUsed + setting.getNumBits()) > getNumBits()) {
			// Overflowing register!
			throw new IllegalStateException("ShiftRegister overflow, check what you're adding to it!");
		}

		settingsMap.put(setting.getName(), setting);
		currentNumBitsUsed += setting.getNumBits();
	}

	public ConfigBase getSetting(final String sname) {
		return settingsMap.get(sname);
	}

	@Override
	protected long computeBinaryRepresentation() {
		// A long is too limiting for what we want to do here, so we override
		// the getBinaryRepresentation() method directly.
		throw new UnsupportedOperationException("Use getBinaryRepresentation() directly.");
	}

	@Override
	public byte[] getBinaryRepresentation() {
		if (currentNumBitsUsed != getNumBits()) {
			throw new IllegalStateException(
				"Not all ShiftRegister bits have been explicitly assigned. Either do so or add PlaceholderBits as appropriate.");
		}

		final byte[] bytes = new byte[getNumBytes()];

		int bitPosition = 0;

		for (final ConfigBase cfg : settingsMap.values()) {
			ShiftRegisterContainer.bitArrayCopy(cfg.getBinaryRepresentation(),
				(cfg.getNumBytes() * Byte.SIZE) - cfg.getNumBits(), bytes, bitPosition, cfg.getNumBits());
			bitPosition += cfg.getNumBits();
		}

		return bytes;
	}

	/**
	 * Copy from byte array src to byte array dest bit-wise up to length bits,
	 * starting at the defined bit position inside each array.
	 *
	 * @param src
	 *            source byte array (copy from this).
	 * @param srcPos
	 *            position in bits from which to start copying from.
	 * @param dest
	 *            destination byte array (copy to this).
	 * @param destPos
	 *            position in bits to which to start copying to.
	 * @param length
	 *            number of bits to copy.
	 */
	private static void bitArrayCopy(final byte[] src, final int srcPos, final byte[] dest, final int destPos,
		final int length) {
		int copyOffset = 0;

		while (copyOffset < length) {
			final int srcBytePos = (srcPos + copyOffset) / Byte.SIZE;
			final int srcBitPos = (srcPos + copyOffset) % Byte.SIZE;
			final byte srcBitMask = (byte) (0x80 >>> srcBitPos);

			final boolean bitValue = ((src[srcBytePos] & srcBitMask) != 0);

			if (bitValue) {
				final int destBytePos = (destPos + copyOffset) / Byte.SIZE;
				final int destBitPos = (destPos + copyOffset) % Byte.SIZE;
				final byte destBitMask = (byte) (0x80 >>> destBitPos);

				dest[destBytePos] |= destBitMask;
			}

			copyOffset++;
		}
	}

	@Override
	protected void buildConfigGUI() {
		// Put all settings vertically.
		final VBox vSettings = new VBox(5);

		final Label binaryRep = GUISupport.addLabel(vSettings, getBinaryRepresentationAsString(),
			"Binary data to be sent to the device.", null, null);

		// Add listener directly to the node, so that any change to a
		// subordinate setting results in the update of the shift register
		// display value.
		configNode.addNodeListener((node, userData, event, key) -> {
			if (event == NodeEvents.ATTRIBUTE_MODIFIED) {
				// On any subordinate attribute update, refresh the
				// displayed value.
			binaryRep.setText(getBinaryRepresentationAsString());
		}
	}, null);

		// Fill the vertical box with the settings.
		for (final ConfigBase cfg : settingsMap.values()) {
			vSettings.getChildren().add(cfg.getConfigGUI());
		}

		rootConfigLayout.getChildren().add(vSettings);
	}

	@Override
	public String toString() {
		return String.format("%s, contained settings=%d", super.toString(), settingsMap.size());
	}

	public static final class PlaceholderBits extends ConfigBase {
		public PlaceholderBits(final String name, final int numBits) {
			// Placeholder bits don't get exported to the configuration, so the
			// reference to the config node is kept null.
			super(name, "Placeholder bits, all zero.", null, numBits);
		}

		@Override
		public long getMaxBitValue() {
			return 0;
		}

		@Override
		protected long computeBinaryRepresentation() {
			// Empty numBits, all zero.
			return 0;
		}

		@Override
		protected void buildConfigGUI() {
			// No GUI to build here!
		}
	}
}
