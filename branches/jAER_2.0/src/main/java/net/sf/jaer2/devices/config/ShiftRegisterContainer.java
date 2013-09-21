package net.sf.jaer2.devices.config;

import java.util.LinkedHashMap;
import java.util.Map;

import javafx.scene.layout.VBox;

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
	private static final long serialVersionUID = 3690235063194244838L;

	private final Map<String, ConfigBase> settingsMap = new LinkedHashMap<>();

	private int currentNumBitsUsed = 0;

	public ShiftRegisterContainer(final String name, final String description, final int numBits) {
		super(name, description, numBits);

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
			bitArrayCopy(cfg.getBinaryRepresentation(), (cfg.getNumBytes() * Byte.SIZE) - cfg.getNumBits(), bytes,
				bitPosition, cfg.getNumBits());
			bitPosition += cfg.getNumBits();
		}

		return bytes;
	}

	private void bitArrayCopy(final byte[] src, final int srcPos, final byte[] dest, final int destPos, final int length) {
		// TODO: add copy functionality.
	}

	@Override
	protected void buildConfigGUI() {
		// Put all settings vertically.
		final VBox vSettings = new VBox(5);

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
		private static final long serialVersionUID = 797523306123062939L;

		public PlaceholderBits(final String name, final int numBits) {
			super(name, "Placeholder bits, all zero.", numBits);
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
