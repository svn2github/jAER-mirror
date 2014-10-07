package net.sf.jaer2.devices.components.aer;

import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.util.SSHSNode;

public abstract class AERChip extends Component {
	public AERChip(final String componentName, final SSHSNode componentConfigNode) {
		super(componentName, componentConfigNode);
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
}
