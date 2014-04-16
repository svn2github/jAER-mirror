package ch.unizh.ini.devices;

import net.sf.jaer2.devices.USBDevice;
import net.sf.jaer2.devices.components.aer.AERChip;
import net.sf.jaer2.devices.components.controllers.FX2;
import net.sf.jaer2.devices.components.controllers.logic.LatticeMachX0;
import net.sf.jaer2.devices.components.controllers.logic.Logic;
import net.sf.jaer2.devices.components.misc.memory.EEPROM_I2C;
import net.sf.jaer2.devices.components.misc.memory.Memory;
import net.sf.jaer2.devices.config.ConfigBit;
import net.sf.jaer2.devices.config.ConfigInt;
import net.sf.jaer2.devices.config.ShiftRegisterContainer;
import net.sf.jaer2.eventio.translators.Translator;

import org.usb4java.Device;

import ch.unizh.ini.devices.components.aer.SBRet10;

public class ApsDvs10 extends USBDevice {
	@SuppressWarnings("hiding")
	public static final short PID = (short) 0x840D;

	public ApsDvs10(final Device usbDevice) {
		this(usbDevice, USBDevice.DID);
	}

	protected ApsDvs10(final Device usbDevice, final short deviceDID) {
		super("ApsDVS 10", "DAVIS vision sensor with active and dynamic pixels, USB 2.0.", USBDevice.VID, ApsDvs10.PID,
			deviceDID, usbDevice);

		final FX2 fx2 = new FX2(getConfigNode());
		addComponent(fx2);

		fx2.firmwareToRam(true);

		fx2.addSetting(new ConfigBit("extTrigger", "External trigger.", getConfigNode(), FX2.Ports.PA1, false));
		fx2.addSetting(new ConfigBit("runCpld", "Enable the CPLD.", getConfigNode(), FX2.Ports.PA3, true));
		fx2.addSetting(new ConfigBit("runAdc", "Enable the ADC.", getConfigNode(), FX2.Ports.PC0, true));
		fx2.addSetting(new ConfigBit("powerDown", "Power down the chip.", getConfigNode(), FX2.Ports.PE2, false));
		fx2.addSetting(new ConfigBit("nChipReset", "Keeps chip out of reset.", getConfigNode(), FX2.Ports.PE3, true));

		// Size in KB and I2C address.
		final Memory eeprom = new EEPROM_I2C(getConfigNode(), 32, 0x51);
		eeprom.setProgrammer(fx2);
		addComponent(eeprom);

		// Support flashing FX2 firmware.
		fx2.firmwareToFlash(eeprom);

		final Logic latticeMachX0 = new LatticeMachX0(getConfigNode());
		latticeMachX0.setProgrammer(fx2);
		addComponent(latticeMachX0);

		final ShiftRegisterContainer cpldSR = new ShiftRegisterContainer("cpldSR",
			"ShiftRegister for on-CPLD configuration.", getConfigNode(), 80);

		cpldSR.addSetting(new ConfigInt("frameDelay", ".", cpldSR.getConfigNode(), 0, 16));
		cpldSR.addSetting(new ConfigInt("resSettle", ".", cpldSR.getConfigNode(), 0, 16));
		cpldSR.addSetting(new ConfigInt("rowSettle", ".", cpldSR.getConfigNode(), 0, 16));
		cpldSR.addSetting(new ConfigInt("colSettle", ".", cpldSR.getConfigNode(), 0, 16));
		cpldSR.addSetting(new ConfigInt("exposure", ".", cpldSR.getConfigNode(), 0, 16));

		latticeMachX0.addSetting(cpldSR);

		// ADC adcTHS1030 = new THS1030();
		// Not actively configurable.

		final AERChip sbret10 = new SBRet10(getConfigNode());
		sbret10.setProgrammer(fx2);
		addComponent(sbret10);
	}

	@Override
	public Class<? extends Translator> getPreferredTranslator() {
		return null;
	}
}
