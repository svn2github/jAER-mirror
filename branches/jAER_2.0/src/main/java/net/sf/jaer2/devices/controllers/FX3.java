package net.sf.jaer2.devices.controllers;

public class FX3 {
	public static enum Ports {
		GPIO26,
		GPIO27,
		GPIO33,
		GPIO34,
		GPIO35,
		GPIO36,
		GPIO37,
		GPIO38,
		GPIO39,
		GPIO40,
		GPIO41,
		GPIO42,
		GPIO43,
		GPIO44,
		GPIO45,
		GPIO46,
		GPIO47,
		GPIO48,
		GPIO49,
		GPIO50,
		GPIO51,
		GPIO52,
		GPIO57,
	}

	public static final short VR_TEST = 0xB0;
	public static final short VR_LOG_LEVEL = 0xB1;
	public static final short VR_FX3_RESET = 0xB2;
	public static final short VR_STATUS = 0xB3;
	public static final short VR_SUPPORTED = 0xB4;
	public static final short VR_GPIO_GET = 0xB5;
	public static final short VR_GPIO_SET = 0xB6;
	public static final short VR_I2C_CONFIG = 0xB7;
	public static final short VR_I2C_TRANSFER = 0xB8;
	public static final short VR_SPI_CONFIG = 0xB9;
	public static final short VR_SPI_CMD = 0xBA;
	public static final short VR_SPI_TRANSFER = 0xBB;
	public static final short VR_SPI_ERASE = 0xBC;
}
