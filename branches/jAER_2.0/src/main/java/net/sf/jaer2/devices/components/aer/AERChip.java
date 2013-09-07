package net.sf.jaer2.devices.components.aer;

import net.sf.jaer2.devices.components.Component;

public abstract class AERChip implements Component {
	public abstract int getSizeX();

	public abstract int getSizeY();

	public int getMaxSize() {
		return Math.max(getSizeX(), getSizeY());
	}

	public int getMinSize() {
		return Math.min(getSizeX(), getSizeY());
	}

	/**
	 * Total number of cells on the chip.
	 *
	 * @return number of cells.
	 */
	public abstract int getNumCells();

	/**
	 * Total number of pixels on the chip.
	 *
	 * @return number of pixels.
	 */
	public abstract int getNumPixels();

	public abstract boolean compatibleWith(final AERChip chip);
}
