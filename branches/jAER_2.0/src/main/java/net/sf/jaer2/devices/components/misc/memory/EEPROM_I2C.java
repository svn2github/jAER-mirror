package net.sf.jaer2.devices.components.misc.memory;

public class EEPROM_I2C extends Memory {
	private static final long serialVersionUID = 6483810761979125129L;

	private final int i2cAddress;

	public EEPROM_I2C(final int size, final int i2cAddress) {
		this("EEPROM", size, i2cAddress);
	}

	public EEPROM_I2C(final String componentName, final int size, final int i2cAddress) {
		super(componentName, size);

		this.i2cAddress = i2cAddress;
	}

	public int getI2cAddress() {
		return i2cAddress;
	}
}
