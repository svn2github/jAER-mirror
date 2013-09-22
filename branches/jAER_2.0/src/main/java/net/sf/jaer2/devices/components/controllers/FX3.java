package net.sf.jaer2.devices.components.controllers;

import net.sf.jaer2.devices.config.ConfigBase;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ConfigInt;

public class FX3 extends Controller {
	/**
	 *
	 */
	private static final long serialVersionUID = 7230612434040940891L;

	public static enum Ports {
		GPIO26(26),
		GPIO27(27),
		GPIO33(33),
		GPIO34(34),
		GPIO35(35),
		GPIO36(36),
		GPIO37(37),
		GPIO38(38),
		GPIO39(39),
		GPIO40(40),
		GPIO41(41),
		GPIO42(42),
		GPIO43(43),
		GPIO44(44),
		GPIO45(45),
		GPIO46(46),
		GPIO47(47),
		GPIO48(48),
		GPIO49(49),
		GPIO50(50),
		GPIO51(51),
		GPIO52(52),
		GPIO57(57);

		private final int gpioId;

		private Ports(final int id) {
			gpioId = id;
		}

		@Override
		public final String toString() {
			return String.format("GPIO %d", gpioId);
		}
	}

	public static enum VendorRequests {
		VR_TEST((short) 0xB0),
		VR_LOG_LEVEL((short) 0xB1),
		VR_FX3_RESET((short) 0xB2),
		VR_STATUS((short) 0xB3),
		VR_SUPPORTED((short) 0xB4),
		VR_GPIO_GET((short) 0xB5),
		VR_GPIO_SET((short) 0xB6),
		VR_I2C_CONFIG((short) 0xB7),
		VR_I2C_TRANSFER((short) 0xB8),
		VR_SPI_CONFIG((short) 0xB9),
		VR_SPI_CMD((short) 0xBA),
		VR_SPI_TRANSFER((short) 0xBB),
		VR_SPI_ERASE((short) 0xBC);

		private final short vr;

		private VendorRequests(final short s) {
			vr = s;
		}

		@Override
		public final String toString() {
			return String.format("0x%X", vr);
		}
	}

	public FX3() {
		this("FX3");
	}

	public FX3(final String componentName) {
		super(componentName);

		addSetting(new ConfigInt("LOG_LEVEL",
			"Set the logging level, to restrict which error messages will be sent over the Status EP1.", (byte) 6),
			FX3.VendorRequests.VR_LOG_LEVEL);
		addSetting(new ConfigBit("FX3_RESET", "Hard-reset the FX3 microcontroller", false),
			FX3.VendorRequests.VR_FX3_RESET);
	}

	public void addSetting(final ConfigBase setting, final Ports port) {
		// TODO Auto-generated method stub
	}

	public void addSetting(final ConfigBase setting, final VendorRequests vr) {
		// TODO Auto-generated method stub
	}

	@SuppressWarnings("unused")
	@Override
	public void addSetting(final ConfigBase setting) {
		throw new UnsupportedOperationException("General order unsupported, use either Ports or Vendor Requests.");
	}

	@Override
	public void setProgrammer(final Controller programmer) {
		throw new UnsupportedOperationException("FX3 cannot be programmed by others, as it is the initial controller.");
	}
}