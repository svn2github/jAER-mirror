package net.sf.jaer2.devices.config;

import java.util.SortedMap;
import java.util.TreeMap;

public class ShiftRegisterContainer extends ConfigBase {
	private static final long serialVersionUID = 3690235063194244838L;

	private final SortedMap<Integer, ConfigBase> addressSettingMap = new TreeMap<>();

	public ShiftRegisterContainer(final int numBits) {
		super("ShiftRegister", "Container for other settings that format them like a ShiftRegister would.", numBits);
	}

	public void addSetting(final ConfigBase setting, final int address) {
		// TODO: check setting length against total length.
		addressSettingMap.put(address, setting);
	}

	public ConfigBase getSetting(final int address) {
		return addressSettingMap.get(address);
	}

	@Override
	protected long computeBinaryRepresentation() {
		// A long is too limiting for what we want to do here, so we override
		// the getBinaryRepresentation() method directly.
		throw new UnsupportedOperationException("Use getBinaryRepresentation() directly.");
	}

	@Override
	public byte[] getBinaryRepresentation() {
		final byte[] bytes = new byte[getNumBytes()];

		int bitPosition = 0;

		for (final ConfigBase cfg : addressSettingMap.values()) {
			mergeAtPosition(bytes, bitPosition, cfg.getBinaryRepresentation());
			bitPosition += cfg.getNumBits();
		}

		return bytes;
	}

	private void mergeAtPosition(final byte[] bytes, final int bitPosition, final byte[] binaryRepresentation) {

	}

	@Override
	protected void buildConfigGUI() {
		// Fill the vertical box with the settings.
		for (final ConfigBase cfg : addressSettingMap.values()) {
			rootConfigLayout.getChildren().add(cfg.getConfigGUI());
		}
	}

	@Override
	public String toString() {
		return String.format("%s with %d settings contained", getName(), addressSettingMap.size());
	}
}
