package ch.unizh.ini.devices;

import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.Component;
import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.components.controllers.FX3;
import net.sf.jaer2.devices.components.controllers.logic.LatticeECP3;
import net.sf.jaer2.devices.components.controllers.logic.Logic;
import net.sf.jaer2.devices.components.misc.InvenSense6050;
import net.sf.jaer2.devices.components.misc.memory.Flash_SPI;
import net.sf.jaer2.devices.components.misc.memory.Memory;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ConfigInt;
import net.sf.jaer2.devices.config.ShiftRegisterContainer;
import net.sf.jaer2.eventio.translators.Translator;

import org.usb4java.Device;

import ch.unizh.ini.devices.components.aer.SBRet10;

public class ApsDvs10FX3 extends USBDevice {
	@SuppressWarnings("hiding")
	public static final short PID = (short) 0x841A;

	public ApsDvs10FX3(final Device usbDevice) {
		super("DAViS_FX3", "DAVIS vision sensor with active and dynamic pixels, 6-axis IMU, USB 3.0.",
			USBDevice.VID, ApsDvs10FX3.PID, USBDevice.DID, usbDevice);

		final FX3 fx3 = new FX3(getConfigNode());
		addComponent(fx3);

		fx3.addSetting(new ConfigBit("extTrigger", "External trigger.", getConfigNode(), FX3.GPIOs.GPIO40, false));
		fx3.addSetting(new ConfigBit("runCpld", "Enable the CPLD.", getConfigNode(), FX3.GPIOs.GPIO41, true));
		fx3.addSetting(new ConfigBit("runAdc", "Enable the ADC.", getConfigNode(), FX3.GPIOs.GPIO35, true));
		fx3.addSetting(new ConfigBit("powerDown", "Power down the chip.", getConfigNode(), FX3.GPIOs.GPIO42, false));
		fx3.addSetting(new ConfigBit("nChipReset", "Keeps chip out of reset.", getConfigNode(), FX3.GPIOs.GPIO43, true));

		// Size in KB and SPI address.
		final Memory flash = new Flash_SPI(getConfigNode(), 512, 0);
		flash.setProgrammer(fx3);
		addComponent(flash);

		// Support flashing FX3 firmware.
		fx3.firmwareToFlash(flash);

		final Logic latticeECP3 = new LatticeECP3(getConfigNode());
		latticeECP3.setProgrammer(fx3);
		addComponent(latticeECP3);

		latticeECP3.firmwareToRam(true);

		// Support flashing LatticeECP3 firmware.
		latticeECP3.firmwareToFlash(flash);

		final ShiftRegisterContainer fpgaSR = new ShiftRegisterContainer("fpgaSR",
			"ShiftRegister for on-FPGA configuration.", getConfigNode(), 80);

		fpgaSR.addSetting(new ConfigInt("frameDelay", ".", fpgaSR.getConfigNode(), 0, 16));
		fpgaSR.addSetting(new ConfigInt("resSettle", ".", fpgaSR.getConfigNode(), 0, 16));
		fpgaSR.addSetting(new ConfigInt("rowSettle", ".", fpgaSR.getConfigNode(), 0, 16));
		fpgaSR.addSetting(new ConfigInt("colSettle", ".", fpgaSR.getConfigNode(), 0, 16));
		fpgaSR.addSetting(new ConfigInt("exposure", ".", fpgaSR.getConfigNode(), 0, 16));

		latticeECP3.addSetting(fpgaSR);

		// ADC adcTHS1030 = new THS1030();
		// Not actively configurable.

		final AERChip sbret10 = new SBRet10(getConfigNode());
		sbret10.setProgrammer(fx3);
		addComponent(sbret10);

		// Add inertial measurement unit.
		final Component invenSenseIMU = new InvenSense6050(getConfigNode(), 0x68);
		invenSenseIMU.setProgrammer(fx3);
		addComponent(invenSenseIMU);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		return null;
	}
}
