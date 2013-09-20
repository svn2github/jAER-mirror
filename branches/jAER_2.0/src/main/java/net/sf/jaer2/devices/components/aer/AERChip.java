package net.sf.jaer2.devices.components.aer;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.config.pots.IPot;
import net.sf.jaer2.devices.config.pots.Masterbias;

public abstract class AERChip extends Component {
	/**
	 *
	 */
	private static final long serialVersionUID = 3997803229199934198L;
	protected static final int MASTERBIAS_ADDRESS = -1;

	public AERChip(final String componentName) {
		super(componentName);
	}

	public abstract int getSizeX();

	public abstract int getSizeY();

	public abstract int getNumCellTypes();

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
	public int getNumCells() {
		return getSizeX() * getSizeY() * getNumCellTypes();
	}

	/**
	 * Total number of pixels on the chip.
	 *
	 * @return number of pixels.
	 */
	public int getNumPixels() {
		return getSizeX() * getSizeY();
	}

	public boolean compatibleWith(final AERChip chip) {
		// If sizes match, let's for now say it's compatible.
		if ((getSizeX() == chip.getSizeX()) && (getSizeY() == chip.getSizeY())) {
			return true;
		}

		return false;
	}

	public void addSetting(final IPot bias, final int address) {
		final Masterbias masterbias = (Masterbias) getSetting(AERChip.MASTERBIAS_ADDRESS);

		if (masterbias == null) {
			throw new IllegalStateException("You must add a Masterbias before adding any IPots!");
		}

		bias.setMasterbias(masterbias);
		super.addSetting(bias, address);
	}
}
