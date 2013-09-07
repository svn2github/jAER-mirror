package net.sf.jaer2.devices.chips;


public interface Chip {
	public int getSizeX();

	public int getSizeY();

	public int getMaxSize();

	public int getMinSize();

	/**
	 * Total number of cells on the chip.
	 *
	 * @return number of cells.
	 */
	public int getNumCells();

	/**
	 * Total number of pixels on the chip.
	 *
	 * @return number of pixels.
	 */
	public int getNumPixels();

	public boolean compatibleWith(final Chip chip);
}
