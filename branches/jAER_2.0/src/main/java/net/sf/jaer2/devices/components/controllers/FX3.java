package net.sf.jaer2.devices.components.controllers;

import java.io.IOException;
import java.nio.ByteBuffer;

import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.config.ConfigBase;
import net.sf.jaer2.devices.config.ConfigBase.Address;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ConfigInt;
import net.sf.jaer2.util.SSHSNode;
import net.sf.jaer2.util.TypedMap;

public class FX3 extends Controller {
	public static enum GPIOs implements Address {
		GPIO26((short) 26),
		GPIO27((short) 27),
		GPIO33((short) 33),
		GPIO34((short) 34),
		GPIO35((short) 35),
		GPIO36((short) 36),
		GPIO37((short) 37),
		GPIO38((short) 38),
		GPIO39((short) 39),
		GPIO40((short) 40),
		GPIO41((short) 41),
		GPIO42((short) 42),
		GPIO43((short) 43),
		GPIO44((short) 44),
		GPIO45((short) 45),
		GPIO46((short) 46),
		GPIO47((short) 47),
		GPIO48((short) 48),
		GPIO49((short) 49),
		GPIO50((short) 50),
		GPIO51((short) 51),
		GPIO52((short) 52),
		GPIO57((short) 57);

		private final short gpioId;

		private GPIOs(final short id) {
			gpioId = id;
		}

		public final short getGpioId() {
			return gpioId;
		}

		@Override
		public final int address() {
			return getGpioId() & 0xFFFF;
		}

		@Override
		public final String toString() {
			return String.format("GPIO %d", getGpioId());
		}
	}

	public static enum VendorRequests implements Address {
		VR_TEST((byte) 0xB0),
		VR_LOG_LEVEL((byte) 0xB1),
		VR_FX3_RESET((byte) 0xB2),
		VR_STATUS((byte) 0xB3),
		VR_SUPPORTED((byte) 0xB4),
		VR_GPIO_GET((byte) 0xB5),
		VR_GPIO_SET((byte) 0xB6),
		VR_I2C_CONFIG((byte) 0xB7),
		VR_I2C_TRANSFER((byte) 0xB8),
		VR_SPI_CONFIG((byte) 0xB9),
		VR_SPI_CMD((byte) 0xBA),
		VR_SPI_TRANSFER((byte) 0xBB),
		VR_SPI_ERASE((byte) 0xBC);

		private final byte vr;

		private VendorRequests(final byte b) {
			vr = b;
		}

		public final byte getVR() {
			return vr;
		}

		@Override
		public final int address() {
			return getVR() & 0xFF;
		}

		@Override
		public final String toString() {
			return String.format("VendorRequest 0x%X", getVR());
		}
	}

	public FX3(final SSHSNode componentConfigNode) {
		this("FX3", componentConfigNode);
	}

	public FX3(final String componentName, final SSHSNode componentConfigNode) {
		super(componentName, componentConfigNode);

		// All FX3 firmwares support these two VRs for internal configuration.
		addSetting(new ConfigInt("LOG_LEVEL",
			"Set the logging level, to restrict which error messages will be sent over the Status EP1.",
			componentConfigNode, FX3.VendorRequests.VR_LOG_LEVEL, 6, 3));
		addSetting(new ConfigBit("FX3_RESET", "Hard-reset the FX3 microcontroller", componentConfigNode,
			FX3.VendorRequests.VR_FX3_RESET, false));
	}

	@Override
	public void addSetting(final ConfigBase setting) {
		// Check that an address is set.
		try {
			setting.getAddress();
		}
		catch (final UnsupportedOperationException e) {
			throw new UnsupportedOperationException(
				"General order unsupported, use either GPIOs or VendorRequests to specify an address.");
		}

		super.addSetting(setting);
	}

	@Override
	public USBDevice getDevice() {
		// FX microcontrollers are always part of a USB device, nothing else
		// makes even remotely sense.
		return (USBDevice) super.getDevice();
	}

	@SuppressWarnings("unused")
	@Override
	public void setProgrammer(final Controller programmer) {
		throw new UnsupportedOperationException("FX3 cannot be programmed by others, as it is the initial controller.");
	}

	@Override
	synchronized public void program(final Command command, final TypedMap<String> args, final Component origin)
		throws IOException {
		switch (command) {
			case SPI_READ: {
				getDevice().sendVendorRequestOut(VendorRequests.VR_SPI_CONFIG.getVR(),
					args.get("spiAddress", Integer.class).shortValue(), (short) 0);

				final int memoryAddress = args.get("memoryAddress", Integer.class);
				getDevice().sendVendorRequestIn(VendorRequests.VR_SPI_TRANSFER.getVR(), (short) (memoryAddress >>> 16),
					(short) (memoryAddress & 0xFFFF), args.get("dataIn", ByteBuffer.class));

				break;
			}

			case SPI_WRITE: {
				getDevice().sendVendorRequestOut(VendorRequests.VR_SPI_CONFIG.getVR(),
					args.get("spiAddress", Integer.class).shortValue(), (short) 0);

				final int memoryAddress = args.get("memoryAddress", Integer.class);
				getDevice().sendVendorRequestOut(VendorRequests.VR_SPI_TRANSFER.getVR(),
					(short) (memoryAddress >>> 16), (short) (memoryAddress & 0xFFFF),
					args.get("dataOut", ByteBuffer.class));

				break;
			}

			case I2C_READ: {
				getDevice().sendVendorRequestOut(VendorRequests.VR_I2C_CONFIG.getVR(),
					args.get("i2cAddress", Integer.class).shortValue(), (short) 0);

				final int memoryAddress = args.get("memoryAddress", Integer.class);
				getDevice().sendVendorRequestIn(VendorRequests.VR_I2C_TRANSFER.getVR(), (short) (memoryAddress >>> 16),
					(short) (memoryAddress & 0xFFFF), args.get("dataIn", ByteBuffer.class));

				break;
			}

			case I2C_WRITE: {
				getDevice().sendVendorRequestOut(VendorRequests.VR_I2C_CONFIG.getVR(),
					args.get("i2cAddress", Integer.class).shortValue(), (short) 0);

				final int memoryAddress = args.get("memoryAddress", Integer.class);
				getDevice().sendVendorRequestOut(VendorRequests.VR_I2C_TRANSFER.getVR(),
					(short) (memoryAddress >>> 16), (short) (memoryAddress & 0xFFFF),
					args.get("dataOut", ByteBuffer.class));

				break;
			}

			default:
				throw new UnsupportedOperationException();
		}
	}
}
