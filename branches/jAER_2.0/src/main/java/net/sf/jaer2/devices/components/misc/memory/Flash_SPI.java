package net.sf.jaer2.devices.components.misc.memory;

public class Flash_SPI extends Memory {
	/**
	 * 
	 */
	private static final long serialVersionUID = -5149304076077627592L;

	public Flash_SPI(final int size, final int spiAddress) {
		this("Flash", size, spiAddress);
	}

	public Flash_SPI(final String componentName, final int size, final int spiAddress) {
		super(componentName, size);
	}
}
